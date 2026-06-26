---
type: skill-eval
skill: ops-lead
bucket: productivity
evaluated_skill_hash: ccfaa3df07b86d0cff20676b4cf4d24dd50d9659
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — ops-lead

**Verdict: SOLID.** A tight, pretraining-anchored COO lens whose Iron Laws and decision-shape rule make the process repeatable; two real construction weaknesses (duplicated identity and one soft step) keep it short of STRONG.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L44 — "On Invoke" fixes a 3-step process (ground → cross-dept check → decision shape) the agent reruns identically every invocation. |
| Description / invocation | pass | L4 — front-loads the leading word "Operations lens", lists trigger branches, and carries an explicit NOT-clause routing away. |
| Completion criteria | weak | L46 — "Ground in team reality" is a directive, not a checkable done-condition; only L48's `<action> by <owner> by <deadline>` is checkable, and the lens has no overall "done" criterion. |
| Information hierarchy | pass | L60 — `@../../../lib/bad-good-calibration.md` pushes calibration pairs behind a context pointer (progressive disclosure); per-section co-location held. |
| Leading words | pass | L33 — "Templates before training" anchors a region of behaviour in a compact, memorable phrase rather than restated prose. |
| Pruning | weak | L26 — Soul ("Thinks in systems, not tasks. Builds process only when there is real pain") substantially restates L14 and L32; Routing Boundary (L20-22) restates the description's NOT-clause (L4). Duplication inflates the meaning's rank and costs maintenance. |
| Granularity | pass | L16 — `@../../../lib/persona-frame.md` is a shared split across 5 persona skills + boardroom; the cut earns its load via independent reach. |
| pandastack conformance | pass | L8 — `domain`/`classification` are valid advisory firewall fields per SKILL-FRONTMATTER.md; body ~57 lines (<80), both lib refs resolve. |

## Why it's good
The skill anchors a stochastic "ops lens" to a deterministic spine: five numbered Iron Laws (L32-36), three named cognitive models (L40-42), and a hard decision-shape contract `<action> by <owner> by <deadline>` (L48) that turns fuzzy advice into a checkable output. Leading words ("process over heroics", "Templates before training", "process-when-painful") do invocation and execution work in few tokens. Routing boundaries (L22) and the Team protocol handoffs (L62-66) keep it MECE against ceo / eng-lead / design-lead / product-lead.

## Top fixes
1. L26 — collapse the Soul paragraph into L14; it adds no behaviour the header line and Iron Laws don't already set. Cut the duplicated "builds process only when pain" clause (also in L32 and L40).
2. L46 — give "On Invoke" step 1 a checkable criterion: name the specific person/pattern/signal each recommendation must cite, so "ground in team reality" can be marked done vs not-done instead of read as a vibe.
3. L20-22 — the Routing Boundary restates the description's NOT-clause. Keep one source of truth; trim the body version to only what the description can't carry (the "one-off tasks where process is heavier than the work" carve-out is the only non-duplicate line).

## Behavioral cases
- trigger `/ops-lead our two teams keep dropping handoffs at sprint boundary` → expected process: invoke the ops lens, apply Iron Law 1 (twice-failed = process candidate), output a `<action> by <owner> by <deadline>` SOP, scan for eng/design sub-tasks and hand off (L47).
- anti-trigger `should we kill this feature or pivot?` → should NOT fire; routes to `ceo` for strategic kill/pivot judgment (L22).
