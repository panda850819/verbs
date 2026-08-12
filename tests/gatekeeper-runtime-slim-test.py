#!/usr/bin/env python3
"""Keep Gatekeeper references branch-loaded and its runtime package lean."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL_DIR = ROOT / "skills/meta/gatekeeper"
SKILL = (SKILL_DIR / "SKILL.md").read_text(encoding="utf-8")

for fragment in (
    "Load references only for the active evidence branch",
    "only when content",
    "only for install, package",
    "Do not load an unrelated pattern library merely because it is bundled",
):
    assert fragment in SKILL, fragment

assert not (SKILL_DIR / "evals").exists()
assert not (SKILL_DIR / "README.md").exists()
for path in (
    "patterns/red-flags.md",
    "patterns/social-engineering.md",
    "patterns/supply-chain.md",
    "reviews/skill-mcp.md",
    "reviews/repository.md",
    "reviews/url-document.md",
    "reviews/product-service.md",
):
    assert (SKILL_DIR / path).is_file(), path

print("gatekeeper runtime slim contract: ok")
