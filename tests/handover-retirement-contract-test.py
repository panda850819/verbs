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
            assert term not in text, f"retired term {term!r} remains in {path.relative_to(ROOT)}"

sprint = (ROOT / "skills/engineering/sprint/SKILL.md").read_text(encoding="utf-8")
for fragment in (
    "Herdr or a host-native",
    "returned output as evidence, not completion",
    "owns acceptance, review, Git, and delivery",
):
    assert fragment in sprint, fragment

assert not (ROOT / "skills/engineering/handover").exists()
assert not (ROOT / "scripts/fresh_run.py").exists()
print("handover retirement contract: ok")
