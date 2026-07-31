#!/usr/bin/env python3
"""Contract checks for the tracker-native planning lifecycle."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GRILL = (ROOT / "skills/productivity/grill/SKILL.md").read_text()
INTERVIEW = (ROOT / "lib/interview.md").read_text()
WAYFINDER = (ROOT / "skills/productivity/wayfinder/SKILL.md").read_text()
SPRINT = (ROOT / "skills/engineering/sprint/SKILL.md").read_text()
README = (ROOT / "README.md").read_text()
RESOLVER = (ROOT / "RESOLVER.md").read_text()
DISPATCH = (ROOT / "DISPATCH.md").read_text()
MANIFEST = (ROOT / "manifest.toml").read_text()


def require(text: str, fragment: str, scenario: str) -> None:
    assert fragment in text, f"{scenario}: missing contract fragment {fragment!r}"


def require_words(text: str, fragment: str, scenario: str) -> None:
    require(" ".join(text.split()), " ".join(fragment.split()), scenario)


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

# wayfinder owns charting: it interviews and writes the map, grill hands off (#285).
require(GRILL, "Do not write a map here", "grill does not chart")
require(WAYFINDER, "@lib/interview.md", "wayfinder runs the interview itself")
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
require(DISPATCH, "never schedules or claims the next frontier", "non-scheduling sprint")
# The boundary must live in the body sprint loads when it runs, not only in the
# SessionStart injection it may never see (#276).
require_words(
    SPRINT,
    "never schedule follow-on work or claim the next frontier Issue",
    "sprint carries its own no-claim boundary",
)
require(DISPATCH, "canonical GitHub Spec Issue / to spec", "spec dispatch")
require(DISPATCH, "dependency graph / to tickets", "ticket dispatch")

assert "[skill.implement]" not in MANIFEST, "must not add implement"
assert "[skill.to-prd]" not in MANIFEST, "must not add to-prd"
assert "structured brief by default" not in DISPATCH, "dispatch must expose conditional close"

print("planning lifecycle contract: ok")
