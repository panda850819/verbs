---
type: skill-eval
skill: eng-lead
bucket: engineering
evaluated_skill_hash: cb52fb8f9c021546e588fc41ea345586347f1f74
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — eng-lead

**Verdict: SOLID.** Disciplined persona lens with clean lib/ extraction and honest SSOT annotations at every seam; one weak axis — `verify-the-test-loop.md` is both `@`-imported in full and restated inline, leaving two surfaces for the same rules.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L60 — `On Invoke` fixes the same 4-step sequence (read learnings → understand → verify → write-learning gate) every run; no branch leaves the process underspecified. |
| Description / invocation | pass | L4 — front-loads "Engineering lens for…", lists model-facing triggers, and a tight NOT-list routing to the four sibling personas; no body-identity leak. |
| Completion criteria | pass | L65 — write-learning gate is now checkable (matched-by-key against `docs/learnings/` and Known bug classes; bump `recurrence` else write), closing the "non-obvious by judgment" premature-completion bait. |
| Information hierarchy | pass | L18 — pointer splits the running-lens structure (load now) from dispatch/boardroom/origin mechanics (load only when wiring), genuine progressive disclosure with co-located rationale. |
| Leading words | pass | L36 — Iron Laws lead with pretrained anchors ("No fix without root cause", "Minimal diff", "Boil the lake", "Search before building"); restatements that would echo a Law are collapsed with explicit notes (L46, L69). |
| Pruning | weak | L84 — `verify-the-test-loop.md` is `@`-imported whole AND its Rules 1/2/4 are paraphrased inline (L37/L38/L49); the cite-back is honest but the rule text now lives on two surfaces in one skill, inviting drift. |
| Granularity | pass | L52 — `Known bug classes` is a self-contained block (listener-lifetime / O(N^2) / schema-leak) that earns its load as code-only lore downgraded from AGENTS.md; each split carries distinct weight. |
| pandastack conformance | pass | L2 — `name: eng-lead` == folder; body ≈80 lines (earned); all four lib/ refs resolve, the two `@`-imported libs total ~2K tokens, under the 5K hot/cold dispatch threshold. |

## Why it's good
The skill is rigorously annotated about its own seams: every place a rule could be a duplicate (Iron Laws vs AGENTS.md baseline at L34, Cognitive Models vs Laws at L46, Anti-patterns vs Laws at L69) carries an explicit SSOT note saying what is new and what is inherited. lib/ extraction is correct — heavy reference (persona structure, calibration, test-loop rules, learning format) lives behind pointers or `@`-imports, keeping the body a running lens. Routing boundary and description agree and both name the exact sibling skill each anti-case belongs to.

## Top fixes
1. L84 — `verify-the-test-loop.md` is `@`-imported in full yet Rules 1/2/4 are also restated inline as Laws #2/#3 and the substrate model. Pick one surface: keep the inline compressed laws with `Rule N` pointers and drop the `@`-import (let `reads:` carry it), or keep the `@`-import and shrink the inline laws to bare pointers. Two full surfaces invites drift.
2. L5-9 vs L80/L84 — the frontmatter `reads:` lists four libs as on-demand references, but two of them (`bad-good-calibration`, `verify-the-test-loop`) are actually `@`-imported (auto-loaded), so the declared manifest understates real load. Reconcile so `reads:` is the accurate manifest of what loads.

## Behavioral cases
- trigger `/eng-lead is this DB migration's rollback path safe?` -> expected process: invoke lens, On Invoke 4-step — search `docs/learnings/`, read the migration, run/verify, write-learning gate if a new bug class; apply Law #1 (root cause before fix) and #3 (prove the test ran the real artifact).
- anti-trigger `should we even build this feature this quarter?` -> should NOT fire (routes to `ceo` for scope or `product-lead` for priority — L24 names both).
