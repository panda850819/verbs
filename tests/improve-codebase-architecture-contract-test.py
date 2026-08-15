#!/usr/bin/env python3
"""Offline contract for the read-only architecture survey."""
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = (
    ROOT / "skills/engineering/improve-codebase-architecture/SKILL.md"
).read_text(encoding="utf-8")
REPORT = (
    ROOT / "skills/engineering/improve-codebase-architecture/HTML-REPORT.md"
).read_text(encoding="utf-8")
RESOLVER = (ROOT / "RESOLVER.md").read_text(encoding="utf-8")


def require(text, fragment, label):
    assert fragment in text, f"missing {label}: {fragment!r}"


require(SKILL, "disable-model-invocation: true", "human-only invocation")
require(SKILL, "Read `lib/codebase-design.md` first", "shared architecture vocabulary")
require(SKILL, "latest 100 commits", "bounded hot-spot scan")
require(SKILL, "do not edit repository files", "read-only repository boundary")
require(SKILL, "deletion-test result", "candidate deletion-test evidence")
require(SKILL, "unused production surface", "deletion-first candidate lane")
require(SKILL, "tests/docs are the only users", "consumer classification")
require(SKILL, "net deletion including remaining glue", "dependency net deletion")
require(SKILL, "intentional seam or defensive guarantee", "decision guard")
require(SKILL, "Merge candidates with the same seam", "candidate deduplication")
require(SKILL, "If every result is Speculative", "honest empty recommendation")
require(SKILL, "Use no CDN, remote asset,\nor executable script", "offline report")
require(SKILL, "Report the absolute path and stop", "survey stopping boundary")
require(SKILL, "later `grill` session", "selected-candidate route")
require(
    SKILL,
    "production consumers or explicit evidence that tests/docs are the only users",
    "skill card consumer alternative",
)
require(SKILL, "a current-decision check", "skill card current-decision check")

for field in (
    "repository-relative files",
    "observed friction",
    "proposed deepening or simplification",
    "production-consumer or tests/docs-only evidence",
    "locality, leverage, net-deletion, and test-surface effects",
    "explicit deletion-test result",
    "side-by-side Before / After diagram",
):
    require(REPORT, field, f"candidate field {field}")

for forbidden in ("cdn.tailwindcss.com", "cdn.jsdelivr.net", "<script"):
    assert forbidden not in REPORT.lower(), f"remote/executable report drift: {forbidden}"

require(REPORT, "HTML-escape every repository-derived value", "HTML escaping")
require(REPORT, "No investment-worthy architecture candidate found", "empty report")
require(
    RESOLVER,
    "repository area worth architectural improvement is unknown",
    "survey versus design routing",
)
require(
    RESOLVER,
    "periodic surveys do\nnot start opportunistically",
    "human-only rationale",
)
require(
    RESOLVER,
    "module is already chosen",
    "canonical resource disambiguation",
)

print("OK: architecture survey is bounded, read-only, evidence-ranked, and offline.")
