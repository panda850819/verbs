---
type: skill-eval
skill: sprint
bucket: engineering
evaluated_skill_hash: 39f2c5db8d995c6ec0f83c98f407792a0ff1409c
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — sprint

**Verdict: SOLID.** The lifecycle has an explicit intermediate `READY_TO_SHIP`, an unconditional review gate, evidence-gated delivery, and host-owned checkpoint candidates; the very large hot body remains its main construction cost.

Grounding sample: L202 — "READY_TO_SHIP → SHIPPED or PAUSED"

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L142 — Stage 4 is an unconditional review gate, matching every mode's execute → review → ship sequence. |
| Description / invocation | pass | L5 — the description front-loads focused execution, names the four outcomes, lists triggers, and routes UI and bug work to their specialist skills. |
| Completion criteria | pass | L204 — SHIPPED requires successful ship output containing PR and pushed commit/branch evidence; missing evidence deterministically becomes PAUSED. |
| Information hierarchy | pass | L126 — optional Codex batching and circuit-breaker mechanics stay behind a branch-specific reference instead of bloating the base execution steps. |
| Leading words | pass | L41 — “a whistle and a finish line” anchors bounded execution and makes terminal-state discipline memorable. |
| Pruning | weak | L65 — the `--plan` mode bullet repeats read-only and progress-derivation mechanics owned by Stage 3, making the invocation index carry execution detail. |
| Native parity | pass | L117 — architect re-verification of acceptance is the earned delta over native subagent delegation and blocks self-reported false green. |
| Granularity | pass | L58 — pure planning routes to `grill --brief`, keeping sprint focused on execution through delivery or an explicit stop state. |
| Verbs conformance | weak | L292 — references resolve and optional heavy mechanics are externalized, but the 254-line body is far above the normal hot-skill budget. |

## Why it's good

`READY_TO_SHIP` cleanly separates “all gates passed” from “delivery actually happened,” and every mode now crosses the same review gate first. Stage 6 promotes it to SHIPPED only with PR and pushed commit/branch evidence; every non-shipping outcome emits a checkpoint candidate to stdout and leaves persistence or project tracking to the host.

## Top fixes

1. L65 — keep the `--plan` mode bullet to syntax plus its Stage 3 pointer; let Stage 3 own read-only progress derivation and auto-detection mechanics.
2. L70 — keep the `--delegate codex` mode bullet to explicit opt-in, plan requirement, and its reference pointer; the linked reference already owns batching and invocation details.

## Behavioral cases

- trigger `/sprint --plan payments-webhook` → expected process: read the plan without mutating it, derive progress from git plus acceptance, execute and re-verify units, review, compute `READY_TO_SHIP`, then invoke ship and promote to SHIPPED only after PR and pushed commit/branch evidence.
- trigger `/sprint --continue payments-webhook` with a host-supplied checkpoint → expected process: use the checkpoint only as context, re-derive done work from the plan and git, and resume without selecting or writing a project-state path.
- trigger a paused or failed sprint → expected process: emit a checkpoint candidate to stdout; do not persist it or mutate a project tracker.
- anti-trigger `help me scope whether this project is worth doing` → should NOT fire; route to `grill --brief`.
