#!/usr/bin/env python3
"""Contract checks for the prose-only to-tickets workflow."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills/productivity/to-tickets/SKILL.md"
text = SKILL.read_text()


def require(fragment: str, scenario: str) -> None:
    assert fragment in text, f"{scenario}: missing contract fragment {fragment!r}"


require("Require one unambiguous `tracker: github`", "tracker")
require("Read the entire source Issue", "complete source")
require("body contract and approved outcome match", "retry safety")
require("stop on a publication conflict", "retry safety")
require("one independently reviewable and revertible PR", "one issue one PR")
require("deliver one observable behavior through every required layer", "vertical slice")
require("fit one fresh-context implementation session", "vertical slice")

require("expand (add the compatible seam)", "wide refactor")
require("migrate batch 1..N", "wide refactor")
require("contract (remove the old seam", "wide refactor")
require("contract depends on every batch", "wide refactor")

require("Ask once:\n`[publish / reject]`.", "approval")
require("No Issue may be created before approval.", "approval")
require("GitHub's native sub-issue relation", "native relations")
require("write every native `blocked by` dependency", "native relations")
require("explicit Parent and Blocked by body references", "body fallback")
require("## Out of Scope\n- <explicit exclusion>", "body completeness")
require("Do not change the parent Issue's body, title, or state.", "parent preservation")
require("open child Issues with no open blocker", "frontier")
require("Do not assign, claim, branch for, or execute a frontier", "manual frontier")

print("to-tickets contract: ok")
