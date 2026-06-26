---
type: skill-eval
skill: sprint
bucket: engineering
evaluated_skill_hash: 996f8541ca616111d6744be92921f5825f72ae16
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — sprint

**Verdict: SOLID.** A genuinely deterministic lifecycle machine: every run resolves to one of four named terminal states by an explicit computation, and only SHIPPED triggers backflow — the process repeats every run even when the outcome differs. It carries real sprawl (346 lines vs the ~80 guideline) and a thrice-stated codex-delegation gate that hold it short of STRONG.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L195 — terminal state is *computed* by an explicit if/elif block, not narrated; Stages 0→6 are an ordered spine re-derivable from git, so the process repeats every run |
| Description / invocation | pass | L5 — front-loads "Focused execution session", one trigger per branch (/sprint, "sprint on this", "let's ship X", "focused session") with no synonym padding, plus a real reach clause (auto-routes to design-lead) |
| Completion criteria | weak | L102 — "execute conversationally as before (this block is a no-op)" leaves the no-plan execute path with no checkable done-condition; conversational Stage 3 never says what "execute is complete" means, inviting premature completion before the review gate |
| Information hierarchy | weak | L151 — the project-specific "Multi-source aggregator dispatch-branch test" checklist (companyos sprints 3/5/6, named functions like `createCallToolHandler`) is inlined hot into Stage 3; narrow reference material sitting on the step ladder instead of behind a context pointer |
| Leading words | pass | L104 — "the main session is the ARCHITECT, not the typist" carries the whole execution model cheaply; reinforced by "A sprint has a whistle and a finish line" (L44) |
| Pruning | weak | L151 — paragraph-long checklist with hardcoded project names and sprint numbers is sediment in the hot path; the `--delegate codex` gate is re-explained at L67, L117, and references/codex-delegation.md (duplication); body runs 346 lines vs the ~80-line discipline |
| Granularity | pass | L62 — modes (--quick/--design/--plan/--continue/--delegate) are branches *within* one skill, and the heavy sub-phases (dojo/grill/review/ship/design-lead) are split into separately-invoked skills; each cut spends one of the two loads deliberately |
| pandastack conformance | weak | L9 — `reads:` declares lib/stop-rule.md (L9) and lib/persona-frame.md (L11) that the body never invokes, while the @-referenced lib/skill-decision-tree.md (L119) is missing from `reads:`; frontmatter and body have drifted, and the 346-line body overshoots the ~<80 budget without clearly earning it |

## Why it's good

The terminal-state contract is the load-bearing virtue: L195-204 computes SHIPPED/PAUSED/FAILED/ABORTED_BY_USER from explicit conditions and L259 makes "only SHIPPED runs backflow" non-negotiable, so the skill can't silently ship half-done work or treat a pause as a break. Plan-driven execution derives task status from git rather than a mutable progress field (L97), so a fresh session or Codex handoff re-derives state instead of trusting stale prose. The architect-vs-typist execution default (L104) and the bounded 3-loop review gate (L177) both encode hard-won discipline as checkable rules, not exhortations.

## Top fixes

1. **L151 (information hierarchy / pruning):** push the multi-source aggregator test checklist out to `references/aggregator-test-checklist.md` behind a one-line pointer; the companyos project names and sprint numbers are case-specific sediment, not skill logic, and they sit on the hot step ladder.
2. **L67 / L117 (pruning):** collapse the duplicated `--delegate codex` gate — off-by-default / plan-required / ≥3-advisory is stated three times. State it once inline, leave a single context pointer to references/codex-delegation.md for the batch loop.
3. **L9 / L11 (conformance):** drop lib/stop-rule.md and lib/persona-frame.md from `reads:` (the body never invokes them) and add lib/skill-decision-tree.md (L119 @-references it); reconcile frontmatter declarations with actual body usage so capability probing stays honest.
4. **L102 (completion criteria):** give the no-plan conversational execute path an explicit checkable done-condition (e.g. "each build unit's `acceptance:` re-verified by the architect — subagent-reported green never trusted") so Stage 3 can't self-declare complete without a check, matching the plan-driven path.

## Behavioral cases

- trigger `let's ship the rate-limiter fix today` → expected process: open sprint default mode → Stage 0 capability probe → dojo → grill (3-question lite) → architect/subagent execute under eng-lead lens → review gate (≤3 iterations) → Stage 5 deploy-proof + ship-gate computes terminal state → only SHIPPED runs ship/extract/backflow.
- anti-trigger `let me think out loud about whether to build a rate limiter at all` → should NOT fire; pure scoping/ideation with no single concrete topic routes to `/office-hours` (or `/boardroom`), per the When-to-skip clause (L58).
