---
type: skill-eval
skill: sprint
bucket: engineering
evaluated_skill_hash: 25e2a2b6e83c17df0220f2e38b17aea7fd3b1c9a
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — sprint

**Verdict: SOLID.** The new closure-evidence gate (Stage 6 SHIPPED step 4) turns "claim SHIPPED without proof" into a checkable failure, but it doesn't say what terminal state a sprint lands in when that evidence is missing — and the previous eval's "conformance: weak" call turns out to be a stale citation, not a real gap.

_2026-07-02 re-eval: T03 (#145) inserted a closure-evidence step ahead of the SHIPPED summary output, matching `ship/SKILL.md`'s identical step 4. Every axis re-read fresh against the current file (not a hash refresh) — see Top fixes #3 for what that caught._

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L179 — terminal state is still computed from booleans (`if review_clean AND deploy_proven AND user_approves_ship: state = SHIPPED`) before Stage 6 ever runs; the new evidence check doesn't touch this core computation. |
| Description / invocation | pass | L5 — front-loads "Focused execution session", lists `/sprint` + phrase triggers, carries anti-trigger reach clauses (UI → `ui`, bugs → `debug`). |
| Completion criteria | weak | L215 — "Closure evidence before claiming SHIPPED: print ticket/PR URL and the state transition performed; if either is missing, say what evidence is missing and do not claim done" is checkable but not exhaustive: it names the failure (evidence missing) without naming the resulting terminal state, so a sprint that hits this branch can dead-end outside the four states the contract at L43 promises. |
| Information hierarchy | pass | L216 — the SHIPPED summary line sits directly after the closure-evidence gate (L215) with no reference-file indirection, and doesn't collide with the Stage 5 deploy-proof precondition (L166-174), which gates a different fact (artifact-tested vs ticket-closed). |
| Leading words | pass | L118 — "'Faster if I just write it myself' is the failure mode this default exists to prevent" anchors the architect/subagent split in one pretraining concept. |
| Pruning | weak | L243 — "Only SHIPPED runs ship/extract/backflow" restates L43 near-verbatim; the new step doesn't add duplication but doesn't remove this pre-existing one either. |
| Native parity | pass | L118 — names the native default the skill overrides ("just write it myself") and the delta that earns the architect/subagent split its slot; the previous eval's table omitted this axis entirely. |
| Granularity | pass | L84 — the learnings recall stays a `lib/` pointer rather than an inlined glob or a new skill; unaffected by this edit, still the right cut. |
| pandastack conformance | pass | L11 — `reads:` already declares `- repo: lib/learning-recall.md`, and every referenced `lib/`, `skills/`, and `references/` path resolves on disk (verified: capability-probe, escape-hatch, push-once, gate-contract, learning-recall, rationalizations, aggregator-test-checklist, codex-delegation, docs/state-schema.md, scripts/pandastack-state). The prior eval's "reads: block not updated" claim does not hold against either the current file or the HEAD commit it was allegedly scored against (identical hash) — corrected here. |

## Why it's good
The closure-evidence step (L215) is a small, well-placed fix: it turns "did you actually open the ticket/PR" from an implicit expectation into a printed, checkable gate, using the exact same wording as `ship/SKILL.md`'s own step 4 (`skills/engineering/ship/SKILL.md:143`) so the two skills fail the same way at their respective closure points. It sits one line above the thing it gates (the SHIPPED summary, L216) instead of a separate stage, so the information hierarchy stays flat and legible.

## Top fixes
1. L215 — define the fallback when evidence is missing: does the sprint stay SHIPPED with a flagged gap, drop to PAUSED, or need a fifth state? "do not claim done" has no destination right now, which is inconsistent with the four-state contract at L43/L241-245 and with the `scripts/pandastack-state append --event {shipped|paused|failed|aborted}` call (L200-202), which only knows how to log one of the four known events.
2. L243 — fold "Terminal state contract" into the Stage 6 header or delete it; it restates L43 verbatim, the same pre-existing duplication the last eval flagged and still unresolved.
3. Process note, not a SKILL.md fix — the prior eval's "2026-07-02 re-stamp" bumped `evaluated_skill_hash` and wrote "verdict unchanged" without re-verifying every citation; its "reads: not declared" claim was already false at that hash (line 11 has carried `lib/learning-recall.md` since #116). A hash bump should trigger a fresh read, not just a fresh signature.

## Behavioral cases
- trigger `let's ship the auth rate-limit fix today` → expected process: Stage 0 probe → Stage 1 prep + store-agnostic learning recall (top 3-5, used in the plan) → grill-lite (3-question cap) → architect/subagent execute → review gate (≤3 iterations) → Stage 5 deploy-proof + ship-gate computes terminal state → Stage 6 SHIPPED prints closure evidence (ticket/PR URL + state transition) before the summary line.
- trigger `/sprint --continue payments-webhook` → expected process: skip prep+grill, load the PAUSED checkpoint + `docs/plans/payments-webhook.md`, re-derive done U-IDs from git+acceptance, resume at the first non-done task (L65).
- anti-trigger `should I even build a rate limiter? let me think out loud` → should NOT fire; no concrete topic, pure ideation routes to `office-hours` (When to skip, L57).
- anti-trigger `review this diff before I open the PR` → should NOT fire; code-diff review routes to `review`, not the full sprint flow (description routing clause, L5).
