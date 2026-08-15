#!/usr/bin/env python3
"""Contract checks for the tracker-native planning lifecycle."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASK_BOSS = (ROOT / "skills/productivity/ask-boss/SKILL.md").read_text()
PRODUCT_PLANNING = (ROOT / "skills/productivity/product-planning/SKILL.md").read_text()
BACKLOG_REFINEMENT = (ROOT / "skills/productivity/backlog-refinement/SKILL.md").read_text()
SPRINT_PLANNING = (ROOT / "skills/productivity/sprint-planning/SKILL.md").read_text()
GRILL = (ROOT / "skills/productivity/grill/SKILL.md").read_text()
INTERVIEW = (ROOT / "lib/interview.md").read_text()
DECISION_MAP = (ROOT / "skills/productivity/decision-map/SKILL.md").read_text()
SPRINT = (ROOT / "skills/engineering/sprint/SKILL.md").read_text()
SPRINT_REVIEW = (ROOT / "skills/productivity/sprint-review/SKILL.md").read_text()
RETRO = (ROOT / "skills/productivity/retro/SKILL.md").read_text()
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
    "`decision-map` owns the map",
    "ask-boss decision-map handoff",
)

# The interview protocol lives in lib/interview.md, not inlined in grill (#284).
# Its cadence asks only dependency-free decisions together, then recomputes (#328).
require_words(
    INTERVIEW,
    "The **frontier** is every active, undecided decision whose prerequisites are settled.",
    "frontier eligibility",
)
require(INTERVIEW, "**Ask the whole frontier as one numbered round.**", "numbered frontier round")
require_words(
    INTERVIEW,
    "Wait for the human's answers before recomputing the frontier.",
    "round waits before recomputing",
)
require_words(
    INTERVIEW,
    "If the frontier contains one decision, the round naturally contains one question.",
    "one-node frontier fallback",
)
require_words(
    INTERVIEW,
    "An explicit defer is parked under `missing_decisions`, omitted from later rounds unless the human reopens it, and never unblocks its dependent branch.",
    "deferred decision is parked without unblocking dependents",
)
require_words(
    INTERVIEW,
    "An unresolved fact lookup is an unsettled prerequisite: it blocks only its downstream decisions, not the rest of the frontier.",
    "fact lookup blocks only downstream decisions",
)
require_words(
    INTERVIEW,
    "The answer remains unsettled, so resolving it stays on the next frontier and is asked with the exact pushback prompt; its dependent branch stays blocked.",
    "pushback blocks only its dependent branch",
)
require_words(
    INTERVIEW,
    "Evaluate progress per answered question, not per round.",
    "stopping rule counts questions",
)
require_words(
    INTERVIEW,
    "No active frontier remains; carry deferred and blocked branches as `OPEN_QUESTIONS`",
    "empty active frontier closes with visible gaps",
)
assert "**ONE question at a time.**" not in INTERVIEW, "rigid interview cadence must be retired"
assert "recommended answer" not in INTERVIEW.lower(), "frontier rounds must not import recommendations"
for skill_text, scenario in ((GRILL, "grill"), (DECISION_MAP, "decision-map"), (RESOLVER, "resolver")):
    assert "one question at a time" not in skill_text.lower(), (
        f"{scenario} must not promise the retired rigid cadence"
    )
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
require(GRILL, "**Large and foggy -> `decision-map`.**", "decision-map branch")

# decision-map owns charting: it interviews and writes the map; callers hand off.
require(GRILL, "Do not write a map here", "grill does not chart")
require(DECISION_MAP, "@lib/interview.md", "decision-map runs the interview itself")
require(DECISION_MAP, "Handoff from `ask-boss`", "decision-map receives orientation packet")
require_words(
    DECISION_MAP,
    "Do not re-run orientation or ask for facts already present in the packet",
    "decision-map does not repeat ask-boss orientation",
)
require(DECISION_MAP, "docs/briefs/{YYYY-MM-DD}-{slug}-map.md", "decision-map writes the map")
require(DECISION_MAP, "This skill owns that format", "decision-map owns the map format")
assert "Delegate charting to `grill`" not in DECISION_MAP, (
    "decision-map must not delegate charting back to grill"
)
# Both hand-off directions skip an interview that already ran (#288).
for skill_text, scenario in ((GRILL, "grill"), (DECISION_MAP, "decision-map")):
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
    "current_frontier",
    "blocked_decisions_with_prerequisites",
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
for direction in ("`/grill` typed three questions into a `decision-map`", "`/decision-map` typed during a `grill`"):
    require_words(INTERVIEW, direction, "mid-interview switch covers both directions")

require_words(
    README,
    "Product Planning → Backlog Refinement → Sprint Planning → Sprint → Sprint Review → Retro",
    "six-stage public lifecycle",
)
require(README, "to-spec --> canonical GitHub Spec", "canonical spec branch")
require(README, "to-tickets --> child Issue graph", "canonical ticket branch")
require_words(README, "one independently reviewable and revertible PR", "one issue one PR")
require_words(
    README,
    "Each stage stops after its record",
    "stages do not auto-chain",
)

require(RESOLVER, "A human selects one unblocked implementation Issue.", "ownership")
require_words(RESOLVER, "reports the frontier but does not choose work", "ownership")
require_words(
    RESOLVER,
    "Sprint Planning may invoke supporting planning procedures to repair unreliable inputs",
    "resolver planning-repair exception",
)
require_words(
    RESOLVER,
    "No stage claims a frontier Issue, schedules work, or starts implementation without a new human choice",
    "resolver no-auto-execution boundary",
)
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
# The stage layer owns familiar records without absorbing specialist contracts.
require_words(
    PRODUCT_PLANNING,
    "Stop after the record. Do not mark backlog items ready, select iteration work",
    "product planning stops before readiness and selection",
)
require(BACKLOG_REFINEMENT, "Status: READY | NOT_READY", "readiness outcome")
require_words(
    BACKLOG_REFINEMENT,
    "Stop after the readiness record. Do not publish or decompose tickets, choose iteration work",
    "refinement stops before selection and execution",
)
require(SPRINT_PLANNING, "Ask once: `[approve / reject]`.", "human selection gate")
require_words(
    SPRINT_PLANNING,
    "Do not claim or assign Issues, schedule selected work, create or switch branches, or start implementation.",
    "planning does not execute",
)
require_words(
    SPRINT_PLANNING,
    "Treat a missing input, unsupported claim, incomplete Issue, or absent source reference as unreliable. Start a Grilling Session",
    "planning grills unreliable inputs",
)
require_words(
    SPRINT_PLANNING,
    "durable requirements -> `to-spec`, which publishes the Spec and invokes its child-Issue flow",
    "planning publishes spec and children",
)
assert "Capacity basis:" not in SPRINT_PLANNING, "planning must not require capacity"
require(SPRINT_REVIEW, "Result: ACCEPTED | NEEDS_CHANGES | UNPROVEN", "product review outcome")
require_words(
    SPRINT_REVIEW,
    "Code review proves properties of a diff and QA can prove browser-visible criteria; neither alone proves",
    "product review differs from code review and QA",
)
require(RETRO, "Status: ACTION_PROPOSED | NO_SUPPORTED_ACTION", "retro outcome")
require_words(RETRO, "Emit at most one Action.", "retro action limit")
require_words(
    RETRO,
    "Do not create calendar events, personal reflection files, brain or memory entries",
    "retro stays product-engineering only",
)
for stage in ("product-planning", "backlog-refinement", "sprint-planning", "sprint", "sprint-review", "retro"):
    require(MANIFEST, f"[skill.{stage}]", f"manifest exposes {stage}")

require_words(GRILL, "routes to `to-spec`", "spec skill composition")
assert "[skill.implement]" not in MANIFEST, "must not add implement"
assert "[skill.to-prd]" not in MANIFEST, "must not add to-prd"

print("planning lifecycle contract: ok")
