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

def check_routed_definitions(text):
    """Routed reviews/templates require all five tiers and four risk actions."""
    rows = {}
    for line in text.splitlines():
        if line.startswith("| "):
            cells = [cell.strip() for cell in line.strip("|").split("|")]
            rows[cells[0]] = " ".join(cells[1:]).lower()
    required = {
        "1": ("official", "moderate"),
        "2": ("security", "moderate"),
        "3": ("cli", "moderate-high"),
        "4": ("repository", "high"),
        "5": ("unknown", "maximum"),
        "LOW": ("information-only", "requested"),
        "MEDIUM": ("limited", "caution"),
        "HIGH": ("credentials", "approval"),
        "REJECT": ("malicious", "refuse"),
    }
    for key, terms in required.items():
        assert key in rows, f"missing routed definition: {key}"
        assert all(term in rows[key] for term in terms), (key, rows[key])


check_routed_definitions(SKILL)
# Removing any definition must fail, even when the routing files still exist.
for key in ("1", "2", "3", "4", "5", "LOW", "MEDIUM", "HIGH", "REJECT"):
    mutant = "\n".join(line for line in SKILL.splitlines()
                       if not line.startswith(f"| {key} |"))
    try:
        check_routed_definitions(mutant)
    except AssertionError:
        pass
    else:
        raise AssertionError(f"accepted missing definition: {key}")

print("gatekeeper runtime slim contract: ok")
