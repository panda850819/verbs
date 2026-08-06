#!/usr/bin/env python3
"""Keep the living roadmap distinct from historical planning artifacts."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
README = (ROOT / "README.md").read_text(encoding="utf-8")
DIRECTION_MAP = (
    ROOT / "docs/briefs/2026-07-13-verbs-v1-direction-map.md"
).read_text(encoding="utf-8")


def frontmatter(path: Path) -> dict[str, str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    assert lines and lines[0] == "---", f"{path}: missing frontmatter"
    end = lines.index("---", 1)
    fields: dict[str, str] = {}
    for line in lines[1:end]:
        if ":" in line:
            key, value = line.split(":", 1)
            fields[key.strip()] = value.strip()
    return fields


for fragment in (
    "`v0.21.0` is the install-contract reset",
    "two consecutive **tagged GitHub releases**",
    "fresh plugin\ninstall plus reinstall for Claude Code and Codex",
    "direct-load setup plus reload\nfor Pi",
    "import plus re-import of a reviewed selected skill for Hermes",
    "exact host, model, effort, and skill commit",
    "open `release-blocker` Issues",
    "GitHub Issues are the executable work\nqueue",
):
    assert fragment in README, f"README roadmap contract missing {fragment!r}"

assert "no P0/P1 product-contract failure" not in README
assert "individual Issue numbers are not copied here" in README

for fragment in (
    "**Historical decision record.**",
    "[`README.md#Roadmap`](../../README.md#roadmap)",
    "do not claim or execute\n> this file's open entries as current work",
    "GitHub Issues are the executable\n> queue",
):
    assert fragment in DIRECTION_MAP, f"historical map marker missing {fragment!r}"

shipped_plans = {
    "grill-default-close.md": "https://github.com/panda850819/verbs/pull/253",
    "verbs-public-operating-model.md": "https://github.com/panda850819/verbs/pull/264",
    "dispatch-map-signal-split.md": "https://github.com/panda850819/verbs/pull/293",
}
for filename, delivery in shipped_plans.items():
    fields = frontmatter(ROOT / "docs/plans" / filename)
    assert fields.get("status") == "shipped", f"{filename}: stale top-level status"
    assert fields.get("delivered_by") == delivery, f"{filename}: missing delivery proof"

print("roadmap contract: ok")
