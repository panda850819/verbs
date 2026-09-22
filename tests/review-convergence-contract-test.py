#!/usr/bin/env python3
"""Contract and transition fixtures for bounded escalated Review."""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = (ROOT / "skills/engineering/review/SKILL.md").read_text(encoding="utf-8")
CONTRACT = (ROOT / "lib/review-convergence.md").read_text(encoding="utf-8")
CASES = json.loads(
    (ROOT / "tests/fixtures/review-convergence-cases.json").read_text(encoding="utf-8")
)
FINDING_CASES = json.loads(
    (ROOT / "tests/fixtures/review-finding-schema-cases.json").read_text(encoding="utf-8")
)
SKILL_FLAT = " ".join(SKILL.split())
CONTRACT_FLAT = " ".join(CONTRACT.split())


for fragment in (
    "lib/review-convergence.md",
    "A changed patch does not by itself restart the workflow",
    "Use at most one isolated read-only reviewer per epoch",
    "typed result schema",
    "Merge by mechanism",
    "the owning context assigns or preserves stable IDs after the merge",
    "Decision: <CLEAN|FINDINGS|BLOCKED|BLOCKED_REVIEW_LOOP>",
    "A spent budget with unresolved load-bearing findings is `BLOCKED_REVIEW_LOOP`, never clean",
    'calling repeated passes "final"',
):
    assert " ".join(fragment.split()) in SKILL_FLAT, fragment

for fragment in (
    "A patch change alone does not open a new epoch",
    "at most:",
    "`PRIMARY` — one",
    "`COLD` — one",
    "`VERIFY` — one",
    "A cold result never launches another cold reviewer",
    "IDs from an isolated result are proposals",
    "return `BLOCKED_REVIEW_LOOP`",
    "Model confidence is not evidence",
):
    assert " ".join(fragment.split()) in CONTRACT_FLAT, fragment

schema_text = CONTRACT.split("```json\n", 1)[1].split("\n```", 1)[0]
schema = json.loads(schema_text)
assert schema["additionalProperties"] is False
assert schema["properties"]["round"] == {"const": "COLD"}
assert set(schema["required"]) == {
    "epoch", "round", "patch", "decision", "findings", "coverage_gaps", "scope_drift"
}
finding = schema["properties"]["findings"]["items"]
assert finding["additionalProperties"] is False
assert {"id", "severity", "status", "trigger", "mechanism", "evidence"} <= set(
    finding["required"]
)
assert finding["properties"]["status"]["enum"] == [
    "OPEN", "REMEDIATED", "VERIFIED", "DISPUTED", "SUPERSEDED"
]
assert finding["properties"]["status_reason"] == {"type": "string", "minLength": 1}
status_rule = finding["allOf"][0]
assert status_rule["if"]["properties"]["status"]["enum"] == [
    "DISPUTED", "SUPERSEDED"
]
assert status_rule["then"]["required"] == ["status_reason"]


def finding_is_valid(value):
    """Exercise required/closed/conditional keys from the published schema."""
    if not set(finding["required"]) <= set(value):
        return False
    if not set(value) <= set(finding["properties"]):
        return False
    conditional_statuses = set(status_rule["if"]["properties"]["status"]["enum"])
    if value["status"] in conditional_statuses:
        return bool(value.get("status_reason"))
    return True


for case in FINDING_CASES:
    assert finding_is_valid(case["finding"]) is case["valid"], case["name"]


def transition(state, request):
    """Reference reducer for the documented round-admission rules."""
    round_name = request["round"]
    rounds = state["rounds"]
    if rounds[round_name] >= 1:
        return "BLOCKED_REVIEW_LOOP"
    if round_name == "PRIMARY":
        return "ALLOW" if sum(rounds.values()) == 0 else "BLOCKED_REVIEW_LOOP"
    if rounds["PRIMARY"] != 1:
        return "BLOCKED_REVIEW_LOOP"
    if round_name == "COLD":
        return "ALLOW" if request.get("cold_earned") else "BLOCKED_REVIEW_LOOP"
    if request["patch"] == state["patch"]:
        return "BLOCKED_REVIEW_LOOP"
    load_bearing = any(
        item["severity"] in {"P0", "P1"}
        and item["status"] in {"OPEN", "REMEDIATED", "DISPUTED"}
        for item in state["findings"]
    )
    return "ALLOW" if load_bearing else "BLOCKED_REVIEW_LOOP"


for case in CASES:
    actual = transition(case["state"], case["request"])
    assert actual == case["expected"], (case["name"], actual, case["expected"])

print("review convergence contract: ok")
