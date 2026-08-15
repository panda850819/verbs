#!/usr/bin/env python3
"""Contract checks for the prose-only to-spec workflow."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills/productivity/to-spec/SKILL.md"
text = SKILL.read_text()


def require(fragment: str, scenario: str) -> None:
    assert fragment in text, f"{scenario}: missing contract fragment {fragment!r}"


require("require one unambiguous\n`tracker: github`", "missing tracker")
require("invoke\n`setup-verbs` and stop", "missing tracker")
require("Do not restart a\nrequirements interview.", "synthesis")
require("Search open Issues for the same outcome", "duplicate prevention")
require("Read `lib/durable-records.md`", "durable record guidance")
require("session-only citations", "session-vantage exclusion")

for heading in (
    "## Problem",
    "## Solution",
    "## User Stories",
    "## Implementation Decisions",
    "## Testing Decisions",
    "## Out of Scope",
    "## Further Notes",
):
    require(f"`{heading}`", "required sections")

require("existing end-to-end or behavioral contract", "test seam order")
require("a new lower-level harness only when higher seams cannot prove", "test seam order")
require("Ask once:\n`[publish / reject]`.", "seam confirmation")
require("This GitHub Spec Issue is the only requirements source of truth.", "canonical ownership")
require("create or maintain a canonical repository spec copy.", "canonical ownership")
require("Do not create child Issues, branches, commits, or PRs.", "ownership boundary")

assert not (ROOT / "docs/specs").exists(), "must not introduce docs/specs"

print("to-spec contract: ok")
