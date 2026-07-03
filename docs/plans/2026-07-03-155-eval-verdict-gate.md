---
date: 2026-07-03
issue: 155
branch: ci/155-eval-verdict-gate
type: plan
---

# Plan — eval-verdict-gate (#155)

> Upgrade eval from snapshot to gate: a skill whose eval.md carries a failing verdict turns the lint suite red. Source pattern: garrytan/gbrain benchmark-with-CI-hard-gate. Base: main.

### eval-verdict-gate-T01 — verdict parsing in the lint
- scope: scripts/lint-eval-fresh.sh (prefer extending; a separate scripts/lint-eval-verdict.sh only if mixing freshness and verdict concerns would muddy the script)
- goal: FIRST read skills/meta/skill-eval/SKILL.md to learn the exact eval.md verdict/score format — do not guess the schema. Then: parse each skill's eval.md verdict; failing-class verdicts exit 1 with a `FAIL:` line naming the skill. If the scorecard defines a numeric threshold, gate on that; do not invent a new one. If any CURRENT skill fails at introduction: do NOT weaken the gate — add an explicit, logged allowlist in the script (echo each allowlisted skill with reason, mirroring tests/run-all.sh's explicit-EXCLUDE stance) and list them in the result summary as follow-up work.
- acceptance: a fixture eval.md with a failing verdict makes the lint exit 1; passing verdict exits 0; current corpus is green or explicitly allowlisted with echoed reasons — no eval.md content edited to pass (no fake green)
- depends-on: none
- status: todo

### eval-verdict-gate-T02 — suite wiring + regression test
- scope: tests/lint-suite.sh, tests/lint-eval-verdict-test.sh (new)
- goal: the verdict gate runs inside tests/lint-suite.sh (same pattern as the existing lint-eval-fresh entry ~line 32). New test follows existing conventions (read tests/run-all.sh header: self-contained, mktemp, offline, exit-code keyed): failing-verdict fixture -> lint exits 1; passing fixture -> exits 0.
- acceptance: `bash tests/lint-eval-verdict-test.sh` passes; the new test is picked up by `bash tests/run-all.sh`
- depends-on: eval-verdict-gate-T01
- status: todo

### eval-verdict-gate-T03 — suite green
- scope: verification only
- goal: full deterministic suite passes with the gate active.
- acceptance: `bash tests/lint-suite.sh` and `bash tests/run-all.sh` report 0 failed
- depends-on: eval-verdict-gate-T02
- status: todo
