#!/usr/bin/env python3
"""Keep the retired Handover transport out of active product surfaces."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ACTIVE = [
    ROOT / "README.md",
    ROOT / "RESOLVER.md",
    ROOT / "manifest.toml",
    ROOT / "scripts",
    ROOT / "skills",
    ROOT / "lib",
    ROOT / ".claude-plugin",
    ROOT / ".codex-plugin",
    ROOT / ".agents",
    ROOT / "maintainer",
]
TERMS = ("handover", "fresh-run", "fresh_run", "agent worker", "codex-delegation")

for surface in ACTIVE:
    paths = [surface] if surface.is_file() else surface.rglob("*")
    for path in paths:
        if (
            not path.is_file()
            or path.name == "CHANGELOG.md"
            or "__pycache__" in path.parts
        ):
            continue
        text = path.read_text(encoding="utf-8", errors="ignore").lower()
        for term in TERMS:
            if term in text:
                raise AssertionError(
                    f"retired term {term!r} remains in {path.relative_to(ROOT)}"
                )

sprint = (ROOT / "skills/engineering/sprint/SKILL.md").read_text(encoding="utf-8")
for fragment in (
    "Herdr or a host-native",
    "returned output as evidence, not completion",
    "owns acceptance, review, Git, and delivery",
):
    if fragment not in sprint:
        raise AssertionError(fragment)

for retired_path in (
    ROOT / "skills/engineering/handover",
    ROOT / "scripts/fresh_run.py",
):
    if retired_path.exists():
        raise AssertionError(f"retired path remains: {retired_path.relative_to(ROOT)}")

print("handover retirement contract: ok")
