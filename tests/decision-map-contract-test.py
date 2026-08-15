#!/usr/bin/env python3
"""Keep Decision Map's one-entry and trustworthy-date contract explicit."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DECISION_MAP = (
    ROOT / "skills/productivity/decision-map/SKILL.md"
).read_text(encoding="utf-8")
DURABLE = (ROOT / "lib/durable-records.md").read_text(encoding="utf-8")


def section(text: str, heading: str) -> str:
    marker = f"\n## {heading}\n"
    start = text.index(marker) + len(marker)
    end = text.find("\n## ", start)
    return text[start:] if end == -1 else text[start:end]


work_map = section(DECISION_MAP, "Work an existing map")
for fragment in (
    "take the first frontier entry",
    "trustworthy host context or a tool",
    "write `status: in-progress` without a date",
    "never infer or guess one",
    "Apply the same rule to the final closed status",
    "Stop after one entry",
):
    assert fragment in work_map, f"Decision Map work section lost rule: {fragment!r}"

status_rules = (
    "trustworthy host context or a tool",
    "write `status: in-progress` without a date",
    "Apply the same rule to the final closed status",
)
positions = [work_map.index(fragment) for fragment in status_rules]
assert positions == sorted(positions), "Decision Map status-date rules are out of order"

for fragment in (
    "Read `lib/durable-records.md`",
    "session-only citations",
    "future\ndecision value",
):
    assert fragment in DECISION_MAP, f"Decision Map lost durable-record rule: {fragment!r}"

for state in ("Active", "Consolidate", "Historical", "Guardrail", "Delete"):
    assert f"**{state}:**" in DURABLE, f"durable-record lifecycle lost {state}"

print("decision map contract: ok")
