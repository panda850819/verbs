#!/usr/bin/env python3
"""Focused contracts for product-engineering stage routing and failure states."""

from pathlib import Path


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
push_once = ROOT / "skills/productivity/backlog-refinement/lib/push-once.md"
assert push_once.is_file(), "backlog refinement must vendor interview's pushback dependency"
assert "A readiness gate keeps that decision unresolved" in push_once.read_text(), (
    "pushback skip must fail closed for readiness callers"
)

# Authority-bearing stages are explicit and agree with their stop boundaries.
for name in ("sprint-planning", "sprint-review", "retro"):
    require(name, "disable-model-invocation: true")
require("sprint-planning", "Selection authority stays with the human")
require("sprint-planning", "Do not assign Issues, create or switch branches")

# Product acceptance fails closed on every material evidence gap.
review = SKILLS["sprint-review"]
for fragment in (
    "Return `UNPROVEN` immediately when the Sprint Goal is missing",
    "the delivered artifact cannot be identified",
    "stale evidence, uncovered\n untracked files, a `FAIL`, or an `UNPROVEN` criterion cannot support acceptance",
    "required human acceptance is present",
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
    "Emit at most one Action",
    "Do not create calendar events, personal reflection files",
    "Do not invoke or\n schedule another stage",
):
    assert " ".join(fragment.split()) in " ".join(retro.split()), fragment

print("product engineering stage contracts: ok")
