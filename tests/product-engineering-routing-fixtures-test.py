#!/usr/bin/env python3
"""Ensure the stage routing canary set covers positives and neighboring negatives."""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CASES = json.loads(
    (ROOT / "evals/fixtures/2026-08-product-engineering-workflow/routing-cases.json")
    .read_text(encoding="utf-8")
)
by_id = {case["id"]: case for case in CASES}
assert len(by_id) == len(CASES), "routing case ids must be unique"

for stage in (
    "product-planning", "backlog-refinement", "sprint-planning", "sprint",
    "sprint-review", "retro",
):
    assert any(case["expected_route"] == stage for case in CASES), f"missing {stage} positive"

for neighbor in ("debug", "review", "qa"):
    assert any(case["expected_route"] == neighbor for case in CASES), f"missing {neighbor} negative"

for stage in ("sprint-planning", "sprint", "sprint-review", "retro"):
    positive = next(case for case in CASES if case["expected_route"] == stage)
    assert positive["invocation"] == "explicit"
    assert any(
        case["id"] == f"{stage}-implicit-negative"
        and case["invocation"] == "implicit"
        and case["expected_route"] is None
        for case in CASES
    ), f"missing {stage} implicit-negative"

print(f"product engineering routing fixtures: {len(CASES)} cases")
