---
type: skill-eval
skill: sprint
bucket: engineering
evaluated_skill_hash: 77094ba477cda234e5c0e128d2dc7e8e3daac1ab
evaluated_at: 2026-07-02
rubric: writing-great-skills@1.0.0
---

# Eval — sprint

**Verdict: SOLID.** A deterministic whistle-to-finish-line state machine whose new store-agnostic learning recall closes the write→read loop and removes the old `{brain}` path leak; held off STRONG by body length/duplication and one undeclared `reads:` dependency.

_2026-07-02 re-stamp: v3.4.0 retired `dojo`; Stage 1 now performs a minimal in-session prep pass before learning recall. Verdict unchanged._

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L174 — terminal state is computed from booleans (`if review_clean AND deploy_proven AND user_approves_ship: state = SHIPPED`), so the agent runs the same gated 6-stage process every time and only SHIPPED triggers backflow. |
| Description / invocation | pass | L5 — front-loads "Focused execution session", lists `/sprint` + three phrase triggers, and carries anti-trigger reach clauses (UI → `ui`, bugs → `debug`). |
| Completion criteria | pass | L100 — "Execute is not complete until every unit's acceptance re-verifies" — checkable + exhaustive, with subagent-reported green explicitly never trusted; reinforced by the Stage 5 boolean state-computation at L174. |
| Information hierarchy | pass | L79 — the changed line: learnings recall is pushed behind a store-agnostic `@../../../lib/learning-recall.md` context pointer ("`gbrain query` when present, else ranked grep over `docs/learnings/`, else skip") instead of an inline hand-rolled glob; cold rule-catalogs sit behind pointers too (rationalizations L294, aggregator-test L129). |
| Leading words | pass | L102 — "the main session is the ARCHITECT, not the typist" anchors the whole execute-stage behaviour in one pretraining concept. |
| Pruning | weak | L237 — "Only SHIPPED runs ship/extract/backflow" restates the contract already given at L42 and structurally enforced by the Stage 6 per-state handlers; the body is 294 lines with residual rationale prose (L113, L157). |
| Granularity | pass | L77 — Stage 1 now inlines only the minimum prep needed after `dojo` retirement; heavier rules remain behind library or skill pointers. |
| pandastack conformance | weak | L79 — Stage 1 now `@import`s `../../../lib/learning-recall.md`, but the frontmatter `reads:` block (L6-21) was not updated to declare it; every sibling `@import` IS declared (capability-probe L7, escape-hatch L8, push-once L9, verify-the-test-loop L17), so this is a manifest desync. The pointer itself resolves on disk and is correctly store-agnostic (no hardcoded brain path). |

## Why it's good
Sprint is a textbook lifecycle-flow: a whistle-to-finish-line machine where every stage has a checkable exit and the terminal state is computed from booleans (L174), not narrated. The #116 change is a net win — it replaces a `{brain}/learnings/` glob that both leaked a personal path placeholder and only listed lessons, with a store-agnostic `lib/learning-recall.md` pointer (L79) that resolves the store the way capture does and forces the recalled lessons to change the plan, closing the write→read loop.

## Top fixes
1. L79 + reads block L6-21 — add `- repo: lib/learning-recall.md` to the frontmatter `reads:`. The new Stage 1 `@import` introduced a repo lib dependency that every other `@import` declares (L7/L8/L9/L17); leaving it out desyncs the manifest from the body.
2. L235-239 — fold the "Terminal state contract" section into the Stage 6 header or delete it; "Only SHIPPED runs ship/extract/backflow" (L237) is already stated at L42 and enforced by the per-state handlers, so it is duplication inflating the contract's rank.
3. L77-79 — the recall runs AFTER the dojo invoke inside Stage 1, but `lib/learning-recall.md`'s "When to load" specifies right after capability-probe and BEFORE planning; dojo IS the prep/plan step, so the recalled lessons miss the dojo brief. Move the recall ahead of the dojo invoke (or into Stage 0) so prep sees them.

## Behavioral cases
- trigger `let's ship the auth rate-limit fix today` → expected process: Stage 0 probe → Stage 1 dojo + store-agnostic learning recall (top 3-5, used in the plan) → grill-lite (3-question cap) → architect/subagent execute → review gate (≤3 iterations) → Stage 5 deploy-proof + ship-gate computes terminal state; only SHIPPED runs ship+extract+backflow, the other three write a checkpoint and stop.
- trigger `/sprint --continue payments-webhook` → expected process: skip dojo+grill, load the PAUSED checkpoint + `docs/plans/payments-webhook.md`, re-derive done U-IDs from git+acceptance, resume at the first non-done task (L64).
- anti-trigger `should I even build a rate limiter? let me think out loud` → should NOT fire; no concrete topic, pure ideation routes to `office-hours` (When to skip, L56).
- anti-trigger `review this diff before I open the PR` → should NOT fire; code-diff review routes to `review`, not the full sprint flow (description routing clause, L5).
