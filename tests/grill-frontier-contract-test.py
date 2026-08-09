#!/usr/bin/env python3
"""Keep Grill's load-bearing frontier cadence in the directly loaded body."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GRILL = (ROOT / "skills/productivity/grill/SKILL.md").read_text(encoding="utf-8")
INTERVIEW = (ROOT / "lib/interview.md").read_text(encoding="utf-8")


def section(text: str, heading: str) -> str:
    marker = f"\n## {heading}\n"
    start = text.index(marker) + len(marker)
    end = text.find("\n## ", start)
    return text[start:] if end == -1 else text[start:end]


protocol = section(GRILL, "Protocol")
ordered = (
    "Start the root frontier",
    "Separate repository-derivable facts",
    "Ask **every** active decision frontier item",
    "`Blocked this round`",
    "Stop after that round and wait",
)
positions = [protocol.index(fragment) for fragment in ordered]
assert positions == sorted(positions), "Grill Protocol frontier steps are out of order"

for fragment in (
    "never replace a multi-decision\n   frontier with one umbrella question",
    "Treat role details, lifecycle policy, edge behavior, and\n   success checks as downstream",
    "Never ask the human to supply a derivable value",
    "with its prerequisite instead of asking it early",
    "Do not recompute the frontier or begin the\n   structured close",
):
    assert fragment in protocol, f"Grill Protocol lost direct-load rule: {fragment!r}"

assert "Ask the whole frontier as one numbered round" in INTERVIEW
assert "Keep a question out of the frontier" in INTERVIEW

print("grill frontier contract: ok")
