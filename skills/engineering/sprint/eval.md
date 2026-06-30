---
type: skill-eval
skill: sprint
bucket: engineering
evaluated_skill_hash: dd5f2069a4e8980a452ed5851cb58707de8bf9c2
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — sprint

**Verdict: SOLID.** A deterministic 6-stage state machine with four computed terminal states is its leading virtue; body length and one residual duplication keep it off STRONG.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L42 — four named terminal states (SHIPPED/PAUSED/FAILED/ABORTED) with only SHIPPED triggering backflow; the whole flow is a numbered, gated state machine the agent re-runs identically every time. |
| Description / invocation | pass | L5 — front-loads "Focused execution session", lists `/sprint` + three phrase triggers, and carries anti-trigger reach clauses (UI → `ui`, bugs → `debug`). |
| Completion criteria | pass | L100 — "Execute is not complete until every unit's acceptance re-verifies" (checkable + exhaustive; subagent-reported green never trusted), reinforced by the Stage 5 state-computation block at L174. |
| Information hierarchy | pass | L294 — the rationalizations catalog is now a one-line lazy pointer to `lib/rationalizations.md` (the #106 win); steps stay inline, rule catalogs (aggregator L129, codex-delegation L115) sit behind pointers. |
| Leading words | pass | L102 — "the main session is the ARCHITECT, not the typist" anchors the whole execute-stage behaviour in one pretraining concept. |
| Pruning | weak | L237 — "Only SHIPPED runs ship/extract/backflow" restates the contract already given at L42 and enforced by the Stage 6 handlers; body is still 256 lines with rationale prose (L113, L157). |
| Granularity | pass | L77 — distinct leading-word behaviours (dojo, grill, review, ship, ui, debug) are split into their own model-invoked skills reached by pointer; only the sequence-coupled orchestration spine stays in-body. |
| pandastack conformance | pass | L3 — `type: skill` (corrected from `mode:` in #106) plus complete reads/writes/capability_required; all five `lib/` + `references/` pointers resolve on disk. |

## Why it's good
Sprint is a textbook lifecycle-flow: a whistle-to-finish-line state machine where every stage has a checkable exit and the terminal state is computed from booleans (L174), not narrated. It delegates each distinct-leading-word phase to its own skill rather than re-implementing it, so the body is orchestration, not duplication. The #106 slim correctly pushed the two largest cold catalogs (rationalizations L294, aggregator-test L129) out to lazy pointers while keeping the hot orchestration path legible.

## Top fixes
1. L235-239 — fold the "Terminal state contract" section into the Stage 6 header or delete it; "Only SHIPPED runs ship/extract/backflow" is already stated at L42 and structurally enforced by the Stage 6 per-state handlers, so this is duplication that inflates the contract's rank.
2. L163 — `verify-the-test-loop.md` is hot-`@import`ed (part of the ~5K-token capability-probe / escape-hatch / push-once bundle at L71/L89) yet only the deploy-validated branch needs it; convert it to a `Read`-pointer like the catalogs so it loads only when the deploy-proof precondition fires.
3. L5 — the description restates the full internal flow ("dojo, grill (lite), execute, review, ship"), which is identity-in-body; the triggers + routing clauses already disambiguate sprint, so the flow list is prunable context load.

## Behavioral cases
- trigger `let's ship the auth-rate-limit fix today` → expected process: Stage 0 probe → dojo → grill-lite (3-question cap) → architect/subagent execute → review gate (≤3 iterations) → Stage 5 deploy-proof + ship-gate computes terminal state; only SHIPPED runs ship+extract+backflow, the other three write a checkpoint and stop.
- trigger `/sprint --continue payments-webhook` → expected process: skip dojo+grill, load the PAUSED checkpoint + `docs/plans/payments-webhook.md`, re-derive done U-IDs from git+acceptance, resume at the first non-done task (L64).
- anti-trigger `let me think out loud about whether to build a rate limiter at all` → should NOT fire; no single concrete topic, pure ideation routes to `office-hours` (When-to-skip, L56).
- anti-trigger `review this diff before I open the PR` → should NOT fire; code-diff review routes to `review`, not the full sprint flow.
