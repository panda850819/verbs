#!/usr/bin/env python3
"""Focused contracts for product-engineering stage routing and failure states."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SKILLS = {
    name: next(ROOT.glob(f"skills/*/{name}/SKILL.md")).read_text(encoding="utf-8")
    for name in (
        "product-planning",
        "backlog-refinement",
        "sprint-planning",
        "sprint-review",
        "retro",
    )
}


def require(name: str, fragment: str) -> None:
    """Assert that one skill contains a whitespace-normalized contract fragment."""
    text = " ".join(SKILLS[name].split())
    expected = " ".join(fragment.split())
    assert expected in text, f"{name}: missing {fragment!r}"


# Product planning and refinement are natural-language routes.
for name in ("product-planning", "backlog-refinement"):
    frontmatter = SKILLS[name].split("\n---\n", 1)[0]
    assert "disable-model-invocation: true" not in frontmatter
require("product-planning", "Use when deciding what product work should happen next")
require("product-planning", "Return `INSUFFICIENT_EVIDENCE` when the visible outcomes cannot be compared")
require("product-planning", "Return `DECISION_REQUIRED` when evidence supports the tradeoff")
require("backlog-refinement", "Use when asked\n  to refine, clarify")
require("backlog-refinement", "load `@lib/push-once.md` and use the exact named pattern")
require("backlog-refinement", "A skipped push remains an open decision and forces `NOT_READY`")
manifest_text = (ROOT / "manifest.toml").read_text(encoding="utf-8")
push_once_consumers = {
    name
    for name, body in re.findall(
        r"^\[skill\.([a-z0-9-]+)\]\n(.*?)(?=^\[|\Z)", manifest_text, re.M | re.S
    )
    if re.search(r'^resources\s*=\s*\[[^\n]*"lib/push-once\.md"', body, re.M)
}
expected_push_once = {ROOT / "lib/push-once.md"} | {
    next(ROOT.glob(f"skills/*/{name}")) / "lib/push-once.md"
    for name in push_once_consumers
}
actual_push_once = {ROOT / "lib/push-once.md"} | set(
    ROOT.glob("skills/*/*/lib/push-once.md")
)
assert actual_push_once == expected_push_once, "push-once generated copies must follow manifest resources"
for push_once in expected_push_once:
    text = " ".join(push_once.read_text(encoding="utf-8").split())
    for fragment in (
        "accepted without push",
        "A readiness gate keeps that decision unresolved",
        "returns `NOT_READY`",
        "caveat visible",
    ):
        assert fragment in text, f"{push_once}: missing {fragment!r}"

# Authority-bearing stages are explicit and agree with their stop boundaries.
for name in ("sprint-planning", "sprint-review", "retro"):
    frontmatter = SKILLS[name].split("\n---\n", 1)[0]
    assert "disable-model-invocation: true" in frontmatter, (
        f"{name}: authority-bearing stages must disable model invocation"
    )
require("product-planning", "Decision owner: <named human>")
require("product-planning", "Decision horizon: <time boundary>")
require("sprint-planning", "Selection authority stays with the human")
require("sprint-planning", "readiness: <record reference>")
require("sprint-planning", "blocker status: clear")
require("sprint-planning", "blocker check: <evidence reference and time>")
require("sprint-planning", "Any item with an active blocker belongs under Excluded")
require("sprint-planning", "every item in an `APPROVED` record includes its readiness reference, clear blocker status")
require("sprint-planning", "Do not assign Issues, create or switch branches")

# Product acceptance fails closed on every material evidence gap.
review = SKILLS["sprint-review"]
for fragment in (
    "Return `UNPROVEN` immediately when the Sprint Goal is missing",
    "the exact delivered artifact identity cannot be established",
    "full commit SHA or `patch-sha256:<digest>`",
    "patch evidence also requires the full base SHA",
    "stale evidence, uncovered\n untracked files, a `FAIL`, or an `UNPROVEN` criterion cannot support acceptance",
    "explicitly records `Stakeholder decision: accepted`",
    "`Stakeholder decision: changes requested`",
    "the stakeholder decision is pending, absent, or marked not required",
    "Never convert missing evidence into `ACCEPTED`",
):
    assert " ".join(fragment.split()) in " ".join(review.split()), fragment
require("sprint-review", "Do not edit code, redefine acceptance criteria")

# Retro stays engineering-only, emits one evidenced action, and fails closed.
retro = SKILLS["retro"]
for fragment in (
    "not a personal reflection, scheduled journal",
    "return `NO_SUPPORTED_ACTION`",
    "Do not invent a lesson",
    "If no change survives, return `NO_SUPPORTED_ACTION`",
    "never emit `ACTION_PROPOSED` without a supported Action",
    "Emit at most one Action",
    "Do not create calendar events, personal reflection files",
    "Do not invoke or\n schedule another stage",
):
    assert " ".join(fragment.split()) in " ".join(retro.split()), fragment

print("product engineering stage contracts: ok")
