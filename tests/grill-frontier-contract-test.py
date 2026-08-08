#!/usr/bin/env python3
"""Keep Grill's load-bearing frontier cadence in the directly loaded body."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GRILL = (ROOT / "skills/productivity/grill/SKILL.md").read_text(encoding="utf-8")
INTERVIEW = (ROOT / "lib/interview.md").read_text(encoding="utf-8")

for text, label in ((GRILL, "Grill"), (INTERVIEW, "shared interview")):
    for fragment in (
        "active decision frontier" if label == "Grill" else "frontier",
        "every" if label == "Grill" else "whole frontier",
        "numbered",
        "Q1",
        "prerequisite",
        "wait",
    ):
        assert fragment.lower() in text.lower(), f"{label} lost {fragment!r}"

for fragment in (
    "never replace a multi-decision\n   frontier with one umbrella question",
    "Start the root frontier with\n   existence/waiver, decision owner, intended outcome, and scope boundary",
    "Treat role details, lifecycle policy, edge behavior, and\n   success checks as downstream",
    "Separate repository-derivable facts into a `Fact lookups` list",
    "Never ask the human to supply a derivable value",
    "`Blocked this round` with its prerequisite",
    "Do not recompute the frontier or begin the\n   structured close",
):
    assert fragment in GRILL, f"Grill lost direct-load rule: {fragment!r}"

assert "Ask the whole frontier as one numbered round" in INTERVIEW
assert "Keep a question out of the frontier" in INTERVIEW

print("grill frontier contract: ok")
