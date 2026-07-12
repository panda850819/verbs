#!/usr/bin/env python3
"""Offline contract tests for the flattened skills.sh payload boundary."""
import argparse
import copy
import importlib.machinery
import importlib.util
import re
import shutil
import stat
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
EXPECTED_COUNT = 11
FRONTMATTER_NAME = re.compile(r"^name:\s*([^\s#]+)\s*$", re.MULTILINE)
RELATIVE_RUNTIME_PATH = re.compile(
    r"(?<![A-Za-z0-9_])((?:\.\./)+(?:lib|references|patterns|reviews|"
    r"templates|skills)/[A-Za-z0-9_./-]+)"
)


def load_verbs_module():
    loader = importlib.machinery.SourceFileLoader(
        "verbs_cli_for_portable_test", str(REPO / "scripts/verbs")
    )
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def load_manifest():
    text = (REPO / "manifest.toml").read_text(encoding="utf-8")
    try:
        import tomllib
        return tomllib.loads(text)
    except ImportError:
        return load_verbs_module()._parse_toml_minimal(text)


def source_skill_dirs():
    found = {}
    for skill_file in sorted((REPO / "skills").rglob("SKILL.md")):
        match = FRONTMATTER_NAME.search(skill_file.read_text(encoding="utf-8"))
        if not match:
            raise AssertionError(f"missing frontmatter name: {skill_file}")
        name = match.group(1)
        if name in found:
            raise AssertionError(f"duplicate skill name: {name}")
        found[name] = skill_file.parent
    return found


def runtime_markdown(skill_dir):
    for path in sorted(skill_dir.rglob("*.md")):
        relative = path.relative_to(skill_dir)
        if path.name == "eval.md" or "evals" in relative.parts:
            continue
        yield path


def is_within(root, path):
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except (OSError, ValueError):
        return False


def has_symlink_component(root, path):
    try:
        relative = path.relative_to(root)
    except ValueError:
        return True
    current = root
    if current.is_symlink():
        return True
    for part in relative.parts:
        current = current / part
        if current.is_symlink():
            return True
    return False


def validate_installed(installed_root, manifest, source_dirs):
    errors = []
    specs = manifest.get("skill", {})
    expected = set(specs)
    installed = {}
    if installed_root.is_symlink():
        errors.append("installed root is a symlink")
    if installed_root.is_dir():
        for path in installed_root.iterdir():
            if path.is_symlink():
                errors.append(f"installed skill is a symlink: {path.name}")
                continue
            if path.is_dir() and (path / "SKILL.md").is_file():
                installed[path.name] = path

    missing = sorted(expected - set(installed))
    extra = sorted(set(installed) - expected)
    if missing:
        errors.append("missing installed skills: " + ", ".join(missing))
    if extra:
        errors.append("unexpected installed skills: " + ", ".join(extra))

    source_prefixes = [
        source.relative_to(REPO).as_posix() + "/"
        for source in source_dirs.values()
    ]
    for name in sorted(expected & set(installed)):
        spec = specs[name]
        resources = spec.get("resources")
        composes = spec.get("composes")
        if not isinstance(resources, list):
            errors.append(f"{name}: resources must be a list")
            resources = []
        if not isinstance(composes, list):
            errors.append(f"{name}: composes must be a list")
            composes = []

        skill_dir = installed[name]
        if not is_within(installed_root, skill_dir):
            errors.append(f"{name}: installed skill escapes installed root")
        for bundled in skill_dir.rglob("*"):
            if bundled.is_symlink():
                errors.append(
                    f"{name}: installed payload contains symlink: "
                    f"{bundled.relative_to(skill_dir)}"
                )
        for relative_text in resources:
            relative = Path(relative_text)
            if relative.is_absolute() or ".." in relative.parts:
                errors.append(f"{name}: resource path escapes skill: {relative_text}")
                continue
            canonical = REPO / relative
            installed_resource = skill_dir / relative
            if not canonical.is_file():
                errors.append(f"{name}: canonical resource missing: {relative_text}")
            elif has_symlink_component(skill_dir, installed_resource):
                errors.append(f"{name}: installed resource uses symlink: {relative_text}")
            elif not is_within(skill_dir, installed_resource):
                errors.append(f"{name}: installed resource escapes skill: {relative_text}")
            elif not installed_resource.is_file():
                errors.append(f"{name}: installed resource missing: {relative_text}")
            elif installed_resource.read_bytes() != canonical.read_bytes():
                errors.append(f"{name}: installed resource drift: {relative_text}")
            elif stat.S_IMODE(installed_resource.stat().st_mode) != 0o644:
                errors.append(f"{name}: installed resource mode is not 0644: {relative_text}")

        for companion in composes:
            if companion not in installed:
                errors.append(f"{name}: composed skill missing: {companion}")

        for path in runtime_markdown(skill_dir):
            text = path.read_text(encoding="utf-8")
            for match in RELATIVE_RUNTIME_PATH.finditer(text):
                candidate = path.parent / match.group(1)
                if not is_within(skill_dir, candidate):
                    errors.append(
                        f"{name}: runtime path escapes skill in "
                        f"{path.relative_to(skill_dir)}: {match.group(1)}"
                    )
            for prefix in source_prefixes:
                if prefix in text:
                    errors.append(
                        f"{name}: source-tree skill path {prefix} in "
                        f"{path.relative_to(skill_dir)}"
                    )

    return errors


def assert_clean(errors, label):
    if errors:
        raise AssertionError(label + ":\n  " + "\n  ".join(errors))


def copy_flat_payload(source_dirs, destination):
    destination.mkdir(parents=True)
    for name, source in source_dirs.items():
        shutil.copytree(source, destination / name)


def run_offline_contract():
    manifest = load_manifest()
    source_dirs = source_skill_dirs()
    specs = manifest.get("skill", {})
    assert len(specs) == EXPECTED_COUNT, len(specs)
    assert set(specs) == set(source_dirs)
    for name, spec in specs.items():
        assert isinstance(spec.get("resources"), list), name
        assert isinstance(spec.get("composes"), list), name
    assert sum(len(spec["resources"]) for spec in specs.values()) == 19
    assert sum(len(spec["composes"]) for spec in specs.values()) == 6

    verbs = load_verbs_module()
    invalid_specs = (
        "not-a-table",
        {"resources": [["lib/gate-contract.md"]], "composes": []},
        {"resources": [], "composes": [["review"]]},
    )
    for invalid in invalid_specs:
        mutated = copy.deepcopy(manifest)
        mutated["skill"]["advisor"] = invalid
        try:
            verbs._generated_resources(mutated)
        except ValueError:
            pass
        else:
            raise AssertionError(f"invalid skill spec accepted: {invalid!r}")

    external = (REPO / "tests/skills-sh-installer-external.sh").read_text(
        encoding="utf-8"
    )
    for required in (
        'skills_version="1.5.16"',
        "env -i",
        "DISABLE_TELEMETRY=1",
        "DO_NOT_TRACK=1",
        "--skill '*'",
        "--global --agent claude-code codex --yes --copy",
    ):
        assert required in external, required

    with tempfile.TemporaryDirectory(prefix="verbs-portable-") as tmp:
        installed = Path(tmp) / "skills"
        copy_flat_payload(source_dirs, installed)
        assert_clean(
            validate_installed(installed, manifest, source_dirs),
            "complete flattened payload",
        )

        first_name = next(
            name for name, spec in sorted(specs.items()) if spec["resources"]
        )
        first_resource = Path(specs[first_name]["resources"][0])
        removed = installed / first_name / first_resource
        original = removed.read_bytes()
        removed.unlink()
        errors = validate_installed(installed, manifest, source_dirs)
        assert any("installed resource missing" in item for item in errors), errors
        removed.parent.mkdir(parents=True, exist_ok=True)
        removed.write_bytes(original)

        advisor_skill = installed / "advisor" / "SKILL.md"
        advisor_text = advisor_skill.read_text(encoding="utf-8")
        advisor_skill.write_text(
            advisor_text + "\nLoad `../lib/escape.md`.\n", encoding="utf-8"
        )
        errors = validate_installed(installed, manifest, source_dirs)
        assert any("runtime path escapes skill" in item for item in errors), errors
        advisor_skill.write_text(advisor_text, encoding="utf-8")

        linked_resource = installed / "advisor/lib/gate-contract.md"
        linked_bytes = linked_resource.read_bytes()
        linked_resource.unlink()
        linked_resource.symlink_to(REPO / "lib/gate-contract.md")
        errors = validate_installed(installed, manifest, source_dirs)
        assert any("installed payload contains symlink" in item for item in errors), errors
        linked_resource.unlink()
        linked_resource.write_bytes(linked_bytes)
        linked_resource.chmod(0o644)

        review = installed / "review"
        shutil.rmtree(review)
        errors = validate_installed(installed, manifest, source_dirs)
        assert any(
            item == "sprint: composed skill missing: review" for item in errors
        ), errors

    print(
        "OK: portable skill contract validates 11 flattened skills, resources, "
        "path containment, companion edges, and negative mutations"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--installed-root", type=Path)
    args = parser.parse_args()
    if args.installed_root is None:
        run_offline_contract()
        return

    manifest = load_manifest()
    source_dirs = source_skill_dirs()
    errors = validate_installed(args.installed_root, manifest, source_dirs)
    if errors:
        print("FAIL: installed portable skill contract:", file=sys.stderr)
        for error in errors:
            print(f"  {error}", file=sys.stderr)
        raise SystemExit(1)
    print(f"OK: installed portable skill contract ({len(source_dirs)} skills)")


if __name__ == "__main__":
    main()
