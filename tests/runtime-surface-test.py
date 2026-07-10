#!/usr/bin/env python3
"""Offline regression tests for doctor runtime-surface parity."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


REPO = Path(__file__).resolve().parent.parent
CLI = REPO / "scripts" / "pandastack"
VERSION = "1.2.3"
EXPECTED = {"advisor", "alpha"}


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data), encoding="utf-8")


def write_skill(root, rel, name):
    path = root / rel / "SKILL.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"---\nname: {name}\nuser-invocable: false\n---\n", encoding="utf-8")


def make_fixture(base):
    root = base / "repo"
    home = base / "home"
    home.mkdir(parents=True)
    (root / "manifest.toml").parent.mkdir(parents=True, exist_ok=True)
    (root / "manifest.toml").write_text(
        "[manifest]\n"
        f'version = "{VERSION}"\n\n'
        "[skill.alpha]\n"
        'tier = "core"\n\n'
        "[skill.advisor]\n"
        'tier = "ext"\n',
        encoding="utf-8",
    )
    write_skill(root, "skills/engineering/alpha", "alpha")
    write_skill(root, "skills/engineering/advisor", "advisor")
    write_json(root / ".claude-plugin/plugin.json", {
        "name": "pandastack", "version": VERSION,
        "skills": [
            "./skills/engineering/alpha",
            "./skills/engineering/advisor",
        ],
    })
    write_json(root / ".codex-plugin/plugin.json", {
        "name": "pandastack", "version": VERSION, "skills": "./skills/",
    })
    (root / "DISPATCH.md").write_text("# Dispatch\n", encoding="utf-8")
    write_json(root / "hooks/hooks.json", {"hooks": {}})
    (root / "hooks/hook.sh").write_text("#!/bin/sh\n", encoding="utf-8")
    return root, home


def install_caches(root, home):
    claude_cache = home / ".claude/plugins/cache/pandastack/pandastack" / VERSION
    codex_cache = home / ".codex/plugins/cache/pandastack/pandastack" / VERSION
    shutil.copytree(root, claude_cache)
    shutil.copytree(root, codex_cache)
    write_json(home / ".claude/plugins/installed_plugins.json", {
        "version": 2,
        "plugins": {
            "pandastack@pandastack": [{
                "installPath": str(claude_cache),
                "version": VERSION,
                "lastUpdated": "2026-07-10T00:00:00Z",
            }],
        },
    })
    return claude_cache, codex_cache


def doctor(root, home, *args):
    env = os.environ.copy()
    env.update({
        "HOME": str(home),
        "PANDASTACK_REPO_ROOT": str(root),
        "PANDASTACK_MANIFEST": str(root / "manifest.toml"),
    })
    proc = subprocess.run(
        [sys.executable, str(CLI), "doctor", "--json", *args],
        env=env, text=True, capture_output=True, check=False,
    )
    try:
        data = json.loads(proc.stdout)
    except ValueError as exc:
        raise AssertionError(f"doctor did not emit JSON: {proc.stderr}") from exc
    return proc.returncode, data


def doctor_raw(root, home, *args):
    env = os.environ.copy()
    env.update({
        "HOME": str(home),
        "PANDASTACK_REPO_ROOT": str(root),
        "PANDASTACK_MANIFEST": str(root / "manifest.toml"),
    })
    return subprocess.run(
        [sys.executable, str(CLI), "doctor", *args],
        env=env, text=True, capture_output=True, check=False,
    )


def surface(data):
    return data["checks"]["runtime_surface"]


def case_clean_source_missing_install(base):
    root, home = make_fixture(base)
    rc, data = doctor(root, home)
    assert rc == 0
    report = surface(data)
    assert report["source"]["ok"] is True
    assert set(report["expected"]) == EXPECTED
    assert report["installed"]["claude"]["status"] == "not_installed"
    assert report["installed"]["codex"]["status"] == "not_installed"
    rc, strict = doctor(root, home, "--host", "codex", "--strict")
    assert rc == 1
    assert surface(strict)["installed"]["codex"]["status"] == "not_installed"


def case_source_registration_missing_advisor(base):
    root, home = make_fixture(base)
    manifest = root / ".claude-plugin/plugin.json"
    data = json.loads(manifest.read_text())
    data["skills"] = ["./skills/engineering/alpha"]
    write_json(manifest, data)
    _, result = doctor(root, home)
    registration = surface(result)["source"]["claude_registration"]
    assert registration["ok"] is False
    assert registration["missing"] == ["advisor"]


def case_source_recursive_extra_retired(base):
    root, home = make_fixture(base)
    write_skill(root, "skills/_deprecated/engineering/checkpoint", "checkpoint")
    _, result = doctor(root, home)
    report = surface(result)["source"]
    assert "checkpoint" in report["source_recursive"]["extra"]
    assert "checkpoint" in report["codex_registration"]["extra"]


def case_source_registration_cannot_escape_root(base):
    root, home = make_fixture(base)
    outside = base / "outside"
    write_skill(outside, "alpha", "alpha")
    write_skill(outside, "advisor", "advisor")
    write_json(root / ".claude-plugin/plugin.json", {
        "name": "pandastack", "version": VERSION,
        "skills": [str(outside / "alpha"), str(outside / "advisor")],
    })
    _, result = doctor(root, home)
    registration = surface(result)["source"]["claude_registration"]
    assert registration["ok"] is False
    assert any("escapes plugin root" in issue for issue in registration["issues"])


def case_clean_installed_caches(base):
    root, home = make_fixture(base)
    install_caches(root, home)
    rc, data = doctor(root, home)
    assert rc == 0
    report = surface(data)
    assert report["ok"] is True
    for host in ("claude", "codex"):
        assert report["installed"][host]["status"] == "ok"
        strict_rc, _ = doctor(root, home, "--host", host, "--strict")
        assert strict_rc == 0


def case_cache_skill_drift(base):
    root, home = make_fixture(base)
    claude_cache, codex_cache = install_caches(root, home)
    manifest = claude_cache / ".claude-plugin/plugin.json"
    data = json.loads(manifest.read_text())
    data["skills"] = ["./skills/engineering/alpha"]
    write_json(manifest, data)
    rc, result = doctor(root, home, "--host", "claude", "--strict")
    assert rc == 1
    claude = surface(result)["installed"]["claude"]
    assert claude["missing"] == ["advisor"] and "skills" in claude["drift"]

    write_skill(codex_cache, "skills/_deprecated/engineering/checkpoint", "checkpoint")
    rc, result = doctor(root, home, "--host", "codex", "--strict")
    assert rc == 1
    codex = surface(result)["installed"]["codex"]
    assert "checkpoint" in codex["extra"] and "skills" in codex["drift"]


def case_cache_artifact_drift(base):
    root, home = make_fixture(base)
    claude_cache, codex_cache = install_caches(root, home)

    manifest = codex_cache / ".codex-plugin/plugin.json"
    data = json.loads(manifest.read_text())
    data["version"] = "0.0.0"
    write_json(manifest, data)
    rc, result = doctor(root, home, "--host", "codex", "--strict")
    assert rc == 1 and "version" in surface(result)["installed"]["codex"]["drift"]

    (claude_cache / "DISPATCH.md").write_text("stale\n", encoding="utf-8")
    rc, result = doctor(root, home, "--host", "claude", "--strict")
    assert rc == 1
    assert "dispatch_sha256" in surface(result)["installed"]["claude"]["drift"]

    (codex_cache / "hooks/hook.sh").write_text("stale\n", encoding="utf-8")
    rc, result = doctor(root, home, "--host", "codex", "--strict")
    assert rc == 1
    assert "hooks_sha256" in surface(result)["installed"]["codex"]["drift"]


def case_strict_rejects_incompatible_outputs(base):
    root, home = make_fixture(base)
    for flag in ("--capabilities-json", "--write-capabilities"):
        proc = doctor_raw(root, home, "--host", "codex", "--strict", flag)
        assert proc.returncode == 2
        assert "--strict cannot be combined" in proc.stderr


def case_malformed_claude_registry_reports_drift(base):
    root, home = make_fixture(base)
    write_json(home / ".claude/plugins/installed_plugins.json", {
        "plugins": ["not", "an", "object"],
    })
    rc, result = doctor(root, home)
    assert rc == 0
    claude = surface(result)["installed"]["claude"]
    assert claude["status"] == "drift"
    assert claude["drift"] == ["registry"]


CASES = [
    case_clean_source_missing_install,
    case_source_registration_missing_advisor,
    case_source_recursive_extra_retired,
    case_source_registration_cannot_escape_root,
    case_clean_installed_caches,
    case_cache_skill_drift,
    case_cache_artifact_drift,
    case_strict_rejects_incompatible_outputs,
    case_malformed_claude_registry_reports_drift,
]


def main():
    with tempfile.TemporaryDirectory() as temp:
        base = Path(temp)
        for index, case in enumerate(CASES):
            case(base / str(index))
            print(f"PASS: {case.__name__}")
    print("OK: runtime-surface synthetic fixtures all green")


if __name__ == "__main__":
    main()
