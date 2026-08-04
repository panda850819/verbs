#!/usr/bin/env python3
"""Contract checks for the tracker-native planning lifecycle."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASK_BOSS = (ROOT / "skills/productivity/ask-boss/SKILL.md").read_text()
GRILL = (ROOT / "skills/productivity/grill/SKILL.md").read_text()
INTERVIEW = (ROOT / "lib/interview.md").read_text()
WAYFINDER = (ROOT / "skills/productivity/wayfinder/SKILL.md").read_text()
SPRINT = (ROOT / "skills/engineering/sprint/SKILL.md").read_text()
README = (ROOT / "README.md").read_text()
RESOLVER = (ROOT / "RESOLVER.md").read_text()
MANIFEST = (ROOT / "manifest.toml").read_text()


def require(text: str, fragment: str, scenario: str) -> None:
    assert fragment in text, f"{scenario}: missing contract fragment {fragment!r}"


def require_words(text: str, fragment: str, scenario: str) -> None:
    require(" ".join(text.split()), " ".join(fragment.split()), scenario)


# ask-boss is orientation only: it chooses a caller before any interview and
# carries context forward instead of becoming a generic workflow engine.
require(ASK_BOSS, "## Route", "ask-boss route")
require_words(
    ASK_BOSS,
    "Select one existing specialist before opening any Grilling Session:",
    "ask-boss chooses caller before session",
)
require_words(
    ASK_BOSS,
    "does not start a generic Grilling Session",
    "ask-boss avoids generic grilling",
)
require_words(
    ASK_BOSS,
    "Do not intercept a clear typed request",
    "ask-boss preserves typed on-ramps",
)
require_words(
    ASK_BOSS,
    "Output exactly one recommended route or one human decision question",
    "ask-boss emits one route",
)
require_words(
    ASK_BOSS,
    "`wayfinder` owns the Decision Map",
    "ask-boss wayfinder handoff",
)

# The interview protocol lives in lib/interview.md, not inlined in grill (#284).
require(INTERVIEW, "**ONE question at a time.**", "interview cadence")
require(INTERVIEW, "**Facts vs decisions.**", "facts vs decisions")
require(INTERVIEW, "**Delete-first — drill whether before how.**", "delete-first")
require(INTERVIEW, "1. **Existence**", "eight-axis search space")
require(INTERVIEW, "8. **Success signal**", "eight-axis search space")
require(INTERVIEW, "### Escape hatch (hard cap)", "escape hatch")
require(GRILL, "@lib/interview.md", "grill consumes the interview primitive")
for fragment in ("1. **Existence**", "### Escape hatch (hard cap)"):
    assert fragment not in GRILL, (
        f"grill must not restate the interview protocol: found {fragment!r}. "
        "It belongs to lib/interview.md."
    )

require(GRILL, "require two or more implementation Issues", "spec threshold")
require(GRILL, "even one PR changes a\n   public contract, schema or migration, or security boundary", "spec threshold")
require(GRILL, "Do not write a competing repository brief, executable plan", "single source")
require(GRILL, "**Smaller work -> local close.** Continue to Stage C", "small-work branch")
require(GRILL, "**Large and foggy -> `wayfinder`.**", "wayfinder branch")

# wayfinder owns charting: it interviews and writes the map, grill or ask-boss
# hands off (#285).
require(GRILL, "Do not write a map here", "grill does not chart")
require(WAYFINDER, "@lib/interview.md", "wayfinder runs the interview itself")
require(WAYFINDER, "Handoff from `ask-boss`", "wayfinder receives orientation packet")
require_words(
    WAYFINDER,
    "Do not re-run orientation or ask for facts already present in the packet",
    "wayfinder does not repeat ask-boss orientation",
)
require(WAYFINDER, "docs/briefs/{YYYY-MM-DD}-{slug}-map.md", "wayfinder writes the map")
require(WAYFINDER, "This skill owns that format", "wayfinder owns the map format")
assert "Delegate charting to `grill`" not in WAYFINDER, (
    "wayfinder must not delegate charting back to grill"
)
# Both hand-off directions skip an interview that already ran (#288).
for skill_text, scenario in ((GRILL, "grill"), (WAYFINDER, "wayfinder")):
    require_words(
        skill_text,
        "**If the interview already ran this session, do not run it again.**",
        f"{scenario} carries the re-interview guard",
    )
    # The announcement must fire at injection time, so it lives in the skill the
    # host just loaded, not only in the far-upstream shared module (#289).
    require_words(
        skill_text,
        "**If an interview is still unfinished when the user switches skills, "
        "say so before the next question.**",
        f"{scenario} carries the mid-interview switch announcement",
    )

# Caller handoff carries state while the receiving caller owns the close.
require(INTERVIEW, "## Caller handoff packet", "caller handoff packet")
for fragment in (
    "workflow_intent",
    "source_references",
    "answered_questions",
    "missing_decisions",
    "open_contradictions",
    "exit_condition",
):
    require(INTERVIEW, fragment, "caller handoff packet fields")
require_words(
    INTERVIEW,
    "The receiving caller owns the artifact and close",
    "caller owns close",
)

# An unfinished interview that switches callers is defined, and visible (#289).
require(INTERVIEW, "## Switching callers mid-interview", "mid-interview switch rule")
require_words(
    INTERVIEW,
    "**The answers survive. The original caller's close does not.**",
    "mid-interview switch names both halves",
)
require_words(
    INTERVIEW,
    "Switched to {new caller}. {N} answers carry over; "
    "{original caller}'s {artifact} will not be written.",
    "mid-interview switch is announced, not silent",
)
for direction in ("`/grill` typed three questions into a `wayfinder`", "`/wayfinder` typed during a `grill`"):
    require_words(INTERVIEW, direction, "mid-interview switch covers both directions")

require(README, "to-spec --> canonical GitHub Spec Issue", "public lifecycle")
require(README, "to-tickets --> child Issue graph", "public lifecycle")
require(README, "manually selected", "manual frontier")
require_words(README, "grill -> to-spec -> to-tickets -> manually selected frontier Issue -> sprint -> review -> ship", "public lifecycle")
require_words(README, "one independently reviewable and revertible PR", "one issue one PR")

require(RESOLVER, "A human selects one unblocked implementation Issue.", "ownership")
require(RESOLVER, "reports the frontier but does not choose work", "ownership")
# The boundary must live in the sprint body itself.
require_words(
    SPRINT,
    "never schedule follow-on work or claim the next frontier Issue",
    "sprint carries its own no-claim boundary",
)
# Only SHIPPED reaches ship, so a failed attempt salvages its own learning (#295).
require_words(
    SPRINT,
    "**A `FAILED` or `ABORTED_BY_USER` sprint emits ONE learning candidate "
    "before it prints the end state**",
    "failed sprint salvages what it validated",
)
require_words(SPRINT, "Nothing validated → print no extra line.", "silent when nothing validated")
# skills/retro/ was absorbed into a pandastack skill that never came over (#295).
for path in sorted(ROOT.glob("lib/*.md")) + sorted(ROOT.glob("skills/*/*/**/*.md")):
    assert "during retro" not in path.read_text(), (
        f"{path.relative_to(ROOT)} points at a retro surface Verbs does not have"
    )
require_words(GRILL, "routes to `to-spec`", "spec skill composition")
assert "[skill.implement]" not in MANIFEST, "must not add implement"
assert "[skill.to-prd]" not in MANIFEST, "must not add to-prd"

print("planning lifecycle contract: ok")
