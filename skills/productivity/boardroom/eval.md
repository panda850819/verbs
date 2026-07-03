---
type: skill-eval
skill: boardroom
bucket: productivity
evaluated_skill_hash: a964aaa71090d4d97706418b43263cf1c8b70702
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — boardroom

**Verdict: STRONG.** A tiny forcing-function skill whose value is native-parity clear: it beats a single in-context plan review by forcing blind, decorrelated critics and a per-finding apply gate.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L20 — the same move runs every time: spawn N mutually-blind critics, synthesize, gate. No task-specific control-flow invention. |
| Description / invocation | pass | L4 — front-loads independent critique of a prepared plan, then L6-8 fences it away from code diff review, fuzzy intake, and execution. |
| Completion criteria | pass | L41 — the per-finding `Apply? [Y / N / edit]` gate is a concrete done-state for every finding before the skill stops at L44. |
| Information hierarchy | pass | L10 — only the reusable gate contract is referenced cold; the hot body carries the complete 44-line execution spine. |
| Leading words | pass | L23 — "Mutually blind" is a compact execution anchor and the body immediately explains the groupthink failure it prevents. |
| Pruning | pass | L15 — the body names the single failure mode it exists for, then spends every remaining line on blindness, lenses, synthesis, and gate mechanics. |
| Native parity | pass | L15 — names the native/default competitor as accepting your own plan or doing a single review pass; L16 names the earned delta, independent critique you cannot self-generate. |
| Granularity | pass | L20 — this is one atomic plan-critique move; it correctly points diff review to `review` and execution to `sprint` instead of absorbing them. |
| pandastack conformance | pass | L2 — `name: boardroom` matches the folder, `lib/gate-contract.md` resolves, and the body is 44 lines with no hot/cold issue. |

## Why it's good
The skill keeps only the behavior the base model skips: independent critics, distinct risk lenses, lone-finding preservation, and a caller gate. It does not carry persona machinery or generic review advice.

## Top fixes
None.

## Behavioral cases
- trigger `critique this prepared migration plan` → expected process: run N blind critics, synthesize findings, gate each finding, stop.
- anti-trigger `review this PR diff` → should NOT fire (routes to `review`).
