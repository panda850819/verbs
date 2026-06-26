---
type: skill-eval
skill: sprint
bucket: engineering
evaluated_skill_hash: 5b19c6f56e0df8f42e54e30a2b68d4b0f41c45c2
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — sprint

**Verdict: SOLID.** Leading virtue: a hard, computed terminal-state machine (SHIPPED/PAUSED/FAILED/ABORTED) where only one state triggers backflow, so the process repeats every run even when the outcome differs. Costs points on Codex-delegation duplication across Modes and Stage 3 plus a long lifecycle body, not on path resolution.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L191 — terminal state is a *computed* if/elif block, not narrated; Stages 0→6 are an ordered spine and modes prune whole named stages rather than improvising, so the process repeats every run |
| Description / invocation | pass | L5 — front-loads "Focused execution session", one trigger per branch (/sprint, "sprint on this", "let's ship X", "focused session"), no synonym padding, plus a real reach clause (auto-routes to design-lead on UI scope) |
| Completion criteria | pass | L100 — the no-plan conversational path now carries an explicit done-condition ("not complete until every unit's acceptance re-verifies, matching the plan-driven path's idempotency check"); terminal state computed from booleans (L194), no premature-completion bait |
| Information hierarchy | pass | L71 — heavy shared mechanics (capability-probe, push-once, escape-hatch, gate-contract, verify-the-test-loop) sit behind `@lib/` autoloads and the codex batch loop pushes to references/codex-delegation.md; body keeps orchestration, refs hold the detail |
| Leading words | pass | L102 — "the main session is the ARCHITECT, not the typist" carries the whole execution model cheaply; reinforced by "A sprint has a whistle and a finish line" (L42) and strong stage-name anchors |
| Pruning | weak | L115 — Codex-delegation rule is restated near-verbatim twice (L65 Modes, L115 Stage 3): same OFF-by-default / ≥3-mechanical-units-advisory-not-auto / synchronous-use-`--async`-to-free-session content. One source of truth would cut ~6 lines |
| Granularity | pass | L75 — each stage split earns its load (probe/dojo/grill/execute/review/ship/terminal are distinct decisions); modes are branches within one skill, the 4 terminal sub-blocks each carry unique do/do-not rules, no no-op wrappers |
| pandastack conformance | weak | L149 — the aggregator checklist now uses an explicit skill-local path (`skills/engineering/sprint/lib/aggregator-test-checklist.md`) while shared libs remain repo-root refs; all refs resolve. The weak ground is body length: 329 lines overshoots ~80, partly earned by irreducible lifecycle surface, partly the L65/L115 duplication. |

## Why it's good
The terminal-state contract is the load-bearing virtue: L194-202 computes SHIPPED/PAUSED/FAILED/ABORTED from explicit booleans and L257 makes "only SHIPPED runs ship/extract/backflow" non-negotiable, so the skill can't silently ship half-done work or treat a pause as a break. Plan-driven execution derives task status from git rather than a mutable progress field (L95), so a fresh Claude session or a Codex handoff re-derives state instead of trusting stale prose. The architect-vs-typist execution default (L102) with trivial/interface/no-subagent carve-outs and the bounded 3-loop review gate (L175) encode hard-won discipline as checkable rules, and the Common Rationalizations table (L312) pre-empts exactly the shortcuts an agent invents under time pressure.

## Top fixes
1. **L65 / L115 (pruning):** collapse the duplicated Codex-delegation rule to one source — keep the trigger summary in Modes (L65), let Stage 3 (L115) point to it plus references/codex-delegation.md, instead of restating OFF-by-default / ≥3-advisory / sync-vs-async twice.
2. **L40 / body length (conformance):** the 329-line body is mostly earned by the lifecycle's state surface, but a pass to fold the Codex duplication and tighten Stage 3 prose would pull it closer to the guidance without losing any checkable rule.

## Behavioral cases
- trigger `let's ship the rate-limiter fix today` -> expected process: open sprint default mode -> Stage 0 capability probe -> dojo -> grill (3-question lite) -> architect/subagent execute under eng-lead lens -> review gate (<=3 iterations) -> Stage 5 deploy-proof + ship gate computes terminal state -> only SHIPPED runs ship/extract/backflow
- trigger `/sprint --continue billing-fix` -> expected process: skip dojo+grill, load PAUSED checkpoint + plan, re-derive done U-IDs from git+acceptance, resume at first non-done task (L64)
- anti-trigger `let me think out loud about whether to build a rate limiter at all` -> should NOT fire; pure scoping/ideation with no single concrete topic routes to `/office-hours` (or `/boardroom`), per the When-to-skip clause (L56) and L327
