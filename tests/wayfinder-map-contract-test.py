#!/usr/bin/env python3
"""Keep Wayfinder's one-entry map and trustworthy-date contract explicit."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WAYFINDER = (
    ROOT / "skills/productivity/wayfinder/SKILL.md"
).read_text(encoding="utf-8")


def section(text: str, heading: str) -> str:
    marker = f"\n## {heading}\n"
    start = text.index(marker) + len(marker)
    end = text.find("\n## ", start)
    return text[start:] if end == -1 else text[start:end]


work_map = section(WAYFINDER, "Work an existing map")
for fragment in (
    "take the first frontier entry",
    "trustworthy host context or a tool",
    "write `status: in-progress` without a date",
    "never infer or guess one",
    "Apply the same rule to the final closed status",
    "Stop after one entry",
):
    assert fragment in work_map, f"Wayfinder map-work section lost rule: {fragment!r}"

status_rules = (
    "trustworthy host context or a tool",
    "write `status: in-progress` without a date",
    "Apply the same rule to the final closed status",
)
positions = [work_map.index(fragment) for fragment in status_rules]
assert positions == sorted(positions), "Wayfinder status-date rules are out of order"

print("wayfinder map contract: ok")
