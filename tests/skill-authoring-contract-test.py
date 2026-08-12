#!/usr/bin/env python3
"""Contract for the maintainer new-skill checklist."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GUIDE = (ROOT / "maintainer/writing-great-skills.md").read_text(encoding="utf-8")
SECTION = GUIDE.split("## New skill contract checklist", 1)[1].split("\n## ", 1)[0]
NORMALIZED = " ".join(SECTION.split())

for fragment in (
    "existing surface it extends or replaces",
    "Check `.out-of-scope/`",
    "required input visible in each output record",
    "every terminal state one unambiguous result and completion condition",
    "State the stop boundary",
    "claiming, assigning, scheduling",
    "tracker mutation, successor invocation, and execution",
    "unless the skill owns that side effect",
    "required capability by semantics, not by one host's tool name",
    "host-specific transport only when that transport is the product capability",
    "fail-closed result when the semantic capability is unavailable",
):
    assert " ".join(fragment.split()) in NORMALIZED, fragment

print("skill authoring contract: ok")
