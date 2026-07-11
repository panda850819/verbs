---
type: skill-eval
skill: sprint
bucket: engineering
evaluated_skill_hash: d7d46a0b92f0520ec6b495e546c986874f36b1bc
evaluated_at: 2026-07-12
rubric: writing-great-skills@1.1.0
---

# Eval — sprint

**Verdict: STRONG.** The lifecycle flow preserves acceptance, review, and delivery gates while removing default interviews, subagent fan-out, step narration, and mutable progress ceremony.

Grounding sample: L66 — "The main session executes by default."

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L39 — five ordered phases move one finish line through execution, proof, review, and delivery. |
| Description / invocation | pass | L5 — the description names terminal outcomes, earned delta, neighboring routes, and the planning-only anti-trigger. |
| Completion criteria | pass | L87 — acceptance must be observed after the final edit and survive a self-refute. |
| Information hierarchy | pass | L78 — deploy-loop proof is consulted only when a human-tested artifact exists. |
| Leading words | pass | L57 — `tight loops` anchors the smallest-unit inspect, edit, verify, and diff cycle. |
| Pruning | weak | L99 — terminal-state handling remains inline and keeps the body above the normal 80-line target. |
| Native parity | pass | L5 — the description explicitly states acceptance loops, bounded review, and delivery evidence beyond native coding. |
| Granularity | pass | L48 — sprint routes requirement discovery, debugging, UI, review, delegation, and shipping to their owners. |
| Verbs conformance | pass | L66 — delegation is conditional, heavy cross-runtime work stays in `handover`, and model selection stays in the shared anchor. |

## Why it's good

The flow now spends orchestration only where native execution tends to drift: binding acceptance, re-verifying after the final edit, bounding corrective review, and distinguishing local completion from delivery. Strong models execute directly unless an explicit contract earns delegation.

## Top fixes

1. L99 — if terminal-state prose grows, extract it to a cold contract rather than lengthening the hot body.

## Behavioral cases

- trigger `sprint on issue 200 and ship it` → bind issue acceptance, execute directly in tight loops, self-refute, review, then call ship and require pushed evidence.
- trigger `sprint on this clear one-file change` → skip grill and delegation, execute and verify directly.
- trigger `sprint on this unclear migration` → ask only the un-derivable scope choice through `grill`, then resume.
- anti-trigger `hypothetically explain how you would execute; do not use tools` → return `Execution: NOT_RUN` without fabricated evidence.
- anti-trigger `why is this crash happening` → should route root-cause work through `debug` before returning to sprint verification.
