#!/usr/bin/env python3
"""Offline synthetic-cache regression tests for doctor runtime-surface parity."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


REPO = Path(__file__).resolve().parent.parent
CLI = REPO / "scripts" / "verbs"
VERSION = "1.2.3"
EXPECTED = {"advisor", "alpha"}
PRODUCT = {
    "id": "verbs",
    "display_name": "Verbs",
    "marketplace_id": "verbs",
    "repository": "panda850819/verbs",
    "homepage": "https://github.com/panda850819/verbs",
    "description": (
        "An opinionated skill pack for taking software work from ambiguity "
        "to verified delivery."
    ),
    "hero": (
        "Hard-won ways of working, encoded as composable skills for coding agents."
    ),
    "support": (
        "Verified on Claude Code and Codex. Hermes supports selective manual import."
    ),
    "category": "Developer Tools",
    "archive_prefix": "verbs",
    "environment_prefix": "VERBS",
    "keywords": ["agent-skills", "coding-agents"],
}


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data) + "\n", encoding="utf-8")


def write_skill(root, rel, name):
    path = root / rel / "SKILL.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f"---\nname: {name}\nuser-invocable: false\n---\n",
        encoding="utf-8",
    )


def write_claude_settings(home, enabled):
    write_json(
        home / ".claude/settings.json",
        {"enabledPlugins": enabled},
    )


def write_codex_config(home, enabled, marketplace_source=None):
    lines = []
    for plugin_id, value in sorted(enabled.items()):
        lines.extend([
            f'[plugins."{plugin_id}"]',
            f'enabled = {str(value).lower()}',
            "",
        ])
    if marketplace_source is not None:
        lines.extend([
            "[marketplaces.verbs]",
            'source_type = "local"',
            f'source = "{marketplace_source}"',
            "",
        ])
    path = home / ".codex/config.toml"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def manifest_text():
    keywords = ", ".join(json.dumps(item) for item in PRODUCT["keywords"])
    return (
        "[product]\n"
        f'id = "{PRODUCT["id"]}"\n'
        f'display_name = "{PRODUCT["display_name"]}"\n'
        f'marketplace_id = "{PRODUCT["marketplace_id"]}"\n'
        f'repository = "{PRODUCT["repository"]}"\n'
        f'homepage = "{PRODUCT["homepage"]}"\n'
        f'description = "{PRODUCT["description"]}"\n'
        f'hero = "{PRODUCT["hero"]}"\n'
        f'support = "{PRODUCT["support"]}"\n'
        f'category = "{PRODUCT["category"]}"\n'
        f'archive_prefix = "{PRODUCT["archive_prefix"]}"\n'
        f'environment_prefix = "{PRODUCT["environment_prefix"]}"\n'
        f"keywords = [{keywords}]\n\n"
        "[manifest]\n"
        f'version = "{VERSION}"\n\n'
        "[skill.alpha]\n"
        'tier = "core"\n\n'
        "[skill.advisor]\n"
        'tier = "ext"\n'
    )


def make_fixture(base):
    root = base / "repo"
    home = base / "home"
    home.mkdir(parents=True)
    (root / "manifest.toml").parent.mkdir(parents=True, exist_ok=True)
    (root / "manifest.toml").write_text(manifest_text(), encoding="utf-8")
    write_skill(root, "skills/engineering/alpha", "alpha")
    write_skill(root, "skills/engineering/advisor", "advisor")
    write_json(
        root / ".claude-plugin/plugin.json",
        {
            "name": "verbs",
            "version": VERSION,
            "skills": [
                "./skills/engineering/alpha",
                "./skills/engineering/advisor",
            ],
        },
    )
    write_json(
        root / ".codex-plugin/plugin.json",
        {"name": "verbs", "version": VERSION, "skills": "./skills/"},
    )
    (root / "DISPATCH.md").write_text("# Dispatch\n", encoding="utf-8")
    (root / "hooks").mkdir(parents=True, exist_ok=True)
    (root / "hooks/hook.sh").write_text("#!/bin/sh\n", encoding="utf-8")
    return root, home


def install_current_caches(root, home):
    claude_cache = home / ".claude/plugins/cache/verbs/verbs" / VERSION
    codex_cache = home / ".codex/plugins/cache/verbs/verbs" / VERSION
    shutil.copytree(root, claude_cache)
    shutil.copytree(root, codex_cache)
    write_json(
        home / ".claude/plugins/installed_plugins.json",
        {
            "version": 2,
            "plugins": {
                "verbs@verbs": [
                    {
                        "installPath": str(claude_cache),
                        "version": VERSION,
                        "lastUpdated": "2026-07-10T00:00:00Z",
                    }
                ]
            },
        },
    )
    write_claude_settings(home, {"verbs@verbs": True})
    write_codex_config(home, {"verbs@verbs": True}, root)
    return claude_cache, codex_cache


def install_legacy_claude_registry(root, home):
    cache = home / ".claude/plugins/cache/pandastack/pandastack" / VERSION
    shutil.copytree(root, cache)
    write_json(
        home / ".claude/plugins/installed_plugins.json",
        {
            "version": 2,
            "plugins": {
                "pandastack@pandastack": [
                    {
                        "installPath": str(cache),
                        "version": VERSION,
                        "lastUpdated": "2026-07-10T00:00:00Z",
                    }
                ]
            },
        },
    )
    write_claude_settings(home, {"pandastack@pandastack": True})
    return cache


def install_legacy_codex_cache(root, home):
    cache = home / ".codex/plugins/cache/pandastack/pandastack" / VERSION
    shutil.copytree(root, cache)
    write_codex_config(home, {"pandastack@pandastack": True})
    return cache


def doctor(root, home, *args):
    env = os.environ.copy()
    env.update(
        {
            "HOME": str(home),
            "VERBS_REPO_ROOT": str(root),
            "VERBS_MANIFEST": str(root / "manifest.toml"),
        }
    )
    proc = subprocess.run(
        [sys.executable, str(CLI), "doctor", "--json", *args],
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    try:
        data = json.loads(proc.stdout)
    except ValueError as exc:
        raise AssertionError(f"doctor did not emit JSON: {proc.stderr}") from exc
    return proc.returncode, data


def surface(data):
    return data["checks"]["runtime_surface"]


def case_clean_source_missing_install(base):
    root, home = make_fixture(base)
    rc, data = doctor(root, home)
    assert rc == 0
    assert data["product"] == PRODUCT
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
    write_json(
        root / ".claude-plugin/plugin.json",
        {
            "name": "verbs",
            "version": VERSION,
            "skills": [str(outside / "alpha"), str(outside / "advisor")],
        },
    )
    _, result = doctor(root, home)
    registration = surface(result)["source"]["claude_registration"]
    assert registration["ok"] is False
    assert any("escapes plugin root" in issue for issue in registration["issues"])


def case_clean_installed_caches(base):
    root, home = make_fixture(base)
    install_current_caches(root, home)
    rc, data = doctor(root, home)
    assert rc == 0
    report = surface(data)
    assert report["ok"] is True
    for host in ("claude", "codex"):
        assert report["installed"][host]["status"] == "ok"
        strict_rc, _ = doctor(root, home, "--host", host, "--strict")
        assert strict_rc == 0


def case_codex_enabled_local_marketplace_source(base):
    root, home = make_fixture(base)
    write_codex_config(home, {"verbs@verbs": True}, root)
    rc, result = doctor(root, home, "--host", "codex", "--strict")
    assert rc == 0
    codex = surface(result)["installed"]["codex"]
    assert codex["status"] == "ok"
    assert codex["path"] == str(root)


def case_legacy_claude_registry_requires_migration(base):
    root, home = make_fixture(base)
    legacy_cache = install_legacy_claude_registry(root, home)
    rc, result = doctor(root, home)
    assert rc == 0
    claude = surface(result)["installed"]["claude"]
    assert surface(result)["ok"] is False
    assert claude["status"] == "migration_required"
    assert claude["ok"] is False
    assert claude["path"] == str(legacy_cache)
    assert claude["drift"] == ["legacy_identity"]
    assert any("pandastack@pandastack" in issue for issue in claude["issues"])
    strict_rc, _ = doctor(root, home, "--host", "claude", "--strict")
    assert strict_rc == 1


def case_legacy_codex_cache_requires_migration(base):
    root, home = make_fixture(base)
    legacy_cache = install_legacy_codex_cache(root, home)
    rc, result = doctor(root, home)
    assert rc == 0
    codex = surface(result)["installed"]["codex"]
    assert surface(result)["ok"] is False
    assert codex["status"] == "migration_required"
    assert codex["ok"] is False
    assert codex["path"] == str(legacy_cache.parent)
    assert codex["drift"] == ["legacy_identity"]
    assert any("legacy pandastack install" in issue for issue in codex["issues"])
    strict_rc, _ = doctor(root, home, "--host", "codex", "--strict")
    assert strict_rc == 1


def case_old_and_new_installs_conflict(base):
    root, home = make_fixture(base)
    claude_cache, _ = install_current_caches(root, home)
    registry = home / ".claude/plugins/installed_plugins.json"
    data = json.loads(registry.read_text())
    data["plugins"]["pandastack@pandastack"] = [{
        "installPath": str(home / ".claude/plugins/cache/pandastack/pandastack" / VERSION),
        "version": VERSION,
        "lastUpdated": "2026-07-10T00:00:00Z",
    }]
    write_json(registry, data)
    legacy_codex = home / ".codex/plugins/cache/pandastack/pandastack" / VERSION
    shutil.copytree(root, legacy_codex)
    write_codex_config(
        home,
        {"verbs@verbs": True, "pandastack@pandastack": True},
        root,
    )

    for host in ("claude", "codex"):
        rc, result = doctor(root, home, "--host", host, "--strict")
        assert rc == 1
        installed = surface(result)["installed"][host]
        assert installed["status"] == "drift"
        assert installed["ok"] is False
        assert "legacy_identity" in installed["drift"]
        assert any("stale v3 policies" in issue for issue in installed["issues"])


def case_cache_skill_drift(base):
    root, home = make_fixture(base)
    claude_cache, codex_cache = install_current_caches(root, home)
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
    claude_cache, codex_cache = install_current_caches(root, home)

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


def case_malformed_claude_registry_reports_drift(base):
    root, home = make_fixture(base)
    write_json(
        home / ".claude/plugins/installed_plugins.json",
        {"plugins": ["not", "an", "object"]},
    )
    rc, result = doctor(root, home)
    assert rc == 0
    claude = surface(result)["installed"]["claude"]
    assert claude["status"] == "drift"
    assert claude["drift"] == ["registry"]


def case_cache_without_enabled_receipt_fails(base):
    root, home = make_fixture(base)
    claude_cache = home / ".claude/plugins/cache/verbs/verbs" / VERSION
    codex_cache = home / ".codex/plugins/cache/verbs/verbs" / VERSION
    shutil.copytree(root, claude_cache)
    shutil.copytree(root, codex_cache)
    write_json(
        home / ".claude/plugins/installed_plugins.json",
        {
            "plugins": {
                "verbs@verbs": [{
                    "installPath": str(claude_cache),
                    "version": VERSION,
                }]
            }
        },
    )
    for host in ("claude", "codex"):
        rc, result = doctor(root, home, "--host", host, "--strict")
        assert rc == 1
        installed = surface(result)["installed"][host]
        assert installed["status"] == "drift"
        assert "enabled" in installed["drift"]


def case_disabled_receipt_fails(base):
    root, home = make_fixture(base)
    install_current_caches(root, home)
    write_claude_settings(home, {"verbs@verbs": False})
    write_codex_config(home, {"verbs@verbs": False}, root)
    for host in ("claude", "codex"):
        rc, result = doctor(root, home, "--host", host, "--strict")
        assert rc == 1
        installed = surface(result)["installed"][host]
        assert installed["status"] == "drift"
        assert installed["drift"] == ["enabled"]


CASES = [
    case_clean_source_missing_install,
    case_source_registration_missing_advisor,
    case_source_recursive_extra_retired,
    case_source_registration_cannot_escape_root,
    case_clean_installed_caches,
    case_codex_enabled_local_marketplace_source,
    case_legacy_claude_registry_requires_migration,
    case_legacy_codex_cache_requires_migration,
    case_old_and_new_installs_conflict,
    case_cache_skill_drift,
    case_cache_artifact_drift,
    case_malformed_claude_registry_reports_drift,
    case_cache_without_enabled_receipt_fails,
    case_disabled_receipt_fails,
]


def main():
    with tempfile.TemporaryDirectory() as temp:
        base = Path(temp)
        for index, case in enumerate(CASES):
            case(base / str(index))
            print(f"PASS: {case.__name__}")
    print("OK: runtime-surface synthetic-cache fixtures all green")


if __name__ == "__main__":
    main()
