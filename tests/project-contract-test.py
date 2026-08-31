#!/usr/bin/env python3
"""Contract checks for AGENTS.md intake, Brain First, and runtime slimming."""
from pathlib import Path
import tomllib

ROOT = Path(__file__).resolve().parents[1]
agents = (ROOT / "AGENTS.md").read_text()
contract = (ROOT / "lib/project-contract.md").read_text()
learning = (ROOT / "lib/learning-format.md").read_text()
resolver = (ROOT / "RESOLVER.md").read_text()
manifest = tomllib.loads((ROOT / "manifest.toml").read_text())

for fragment in (
    "work-source: github-issues",
    "unclear-intent: automatic-grilling-session",
    "gbrain: required-lookup-fail-soft",
    "test: bash tests/run-all.sh",
    "delivery: pull-request",
    "### Intake contract",
    "Goal, Scope,",
    "wait for confirmation",
    "### Learning contract",
):
    assert fragment in agents, fragment

for fragment in (
    "## Brain First Rule",
    "historical evidence, not\npolicy",
    "If GBrain is unavailable, continue",
    "## Work Contract",
    "## Automatic Grilling Session",
    "Do not plan implementation or edit code until the contract is confirmed",
    "GBrain owns memory; it cannot mutate `AGENTS.md`",
):
    assert fragment in contract, fragment

for fragment in (
    "type: decision | convention | pitfall | preference | failed-approach",
    "confidence: candidate | confirmed | superseded",
    "GBrain failure is fail-soft",
    "GBrain never edits `AGENTS.md` autonomously",
):
    assert fragment in learning, fragment

active = set(manifest["skill"])
expected = {
    "careful", "gatekeeper", "review", "debug", "ui", "qa",
    "prototype", "ship",
}
assert active == expected, (active, expected)
retired = {
    "advisor", "ask-boss", "product-planning", "backlog-refinement",
    "sprint-planning", "sprint", "sprint-review", "retro", "grill",
    "setup-verbs", "to-spec", "to-tickets", "decision-map",
    "improve-codebase-architecture",
}
for name in retired:
    assert not list((ROOT / "skills").glob(f"*/{name}/SKILL.md")), name

assert "Grilling is Project Contract behavior" in resolver
assert "do not form a mandatory lifecycle" in (ROOT / "README.md").read_text()
print("project contract: ok")
