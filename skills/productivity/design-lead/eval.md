---
type: skill-eval
skill: design-lead
bucket: productivity
evaluated_skill_hash: 366d6bd047bae4a6f980958f764450f69da54030
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — design-lead

**Verdict: SOLID.** A tight, well-anchored design persona: the leading words ("intentional over decorative", "if everything is bold, nothing is bold", "AI slop") give the agent a sharp, repeatable taste frame, and the routing boundary keeps it from straying into product/eng/strategy lanes.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L44 — "On Invoke" gives a fixed 5-step process the agent walks the same way every run. |
| Description / invocation | pass | L4 — front-loads "Design lens", lists trigger branches (UX flow, interaction, state, a11y, hierarchy) and an explicit NOT-clause routing away. |
| Completion criteria | weak | L46 — "Identify the user's actual UX problem (not their proposed solution)" has no checkable done/not-done test; only step 5 (L50, "any axis < 3 → revise") and step 2's "2-3 patterns" are exhaustive. |
| Information hierarchy | pass | L16 — persona structure pushed to `@../../../lib/persona-frame.md`; SKILL.md keeps only design-specific content, co-located under one heading each. |
| Leading words | pass | L33 — "If everything is bold, nothing is bold" anchors hierarchy-through-restraint in a pretrained concept; reinforced by "AI slop" (L35) and "Empty states are features" (L32). |
| Pruning | weak | L36 — Iron Law 5 "Decisions over preferences / 'I like it' is not feedback" restates Soul L26; "No AI slop" (L35) / "Slop detector" (L42) / NOT-clause (L4) vs Routing Boundary (L22) carry the same meaning in 3-4 places. |
| Granularity | pass | L22 — split as one of 5 lead lenses with a distinct leading word and reachable by boardroom/sprint; the cut earns its context load. |
| pandastack conformance | pass | L2 — `name: design-lead` matches folder; description present; 6-section persona-frame contract followed; all three lib `@`-includes resolve. |

## Why it's good
The skill earns predictability through strong pretrained anchors rather than vague exhortation: "intentional over decorative", "one primary action per view", "AI slop" each pin a behaviour region in a few tokens. Progressive disclosure is real — the shared persona scaffold and BAD/GOOD calibration live in `lib/` and load only when needed, so the body stays under the ~80-line budget. The Routing Boundary plus the description's NOT-clause make invocation crisp: it fires on a design question and hands off cleanly to product-lead / eng-lead / ceo / ops-lead.

## Top fixes
1. L46 — give step 1 a checkable criterion. "Identify the user's actual UX problem" should specify the artifact (e.g. "restate the problem in one sentence the user confirms before suggesting any UI") so the step has a done/not-done line.
2. L36 — collapse the "preferences not decisions" / "AI slop" meaning that now appears across Soul (L26), Iron Laws (L35, L36), Cognitive Models (L42) and Anti-patterns. Each restatement inflates the meaning's rank and pays load for nothing new; keep one canonical statement and let the others reference it.
3. L4 — the description and Routing Boundary (L20-22) state the same trigger/anti-trigger set twice. Cut the body restatement; the description is the single source for invocation.

## Behavioral cases
- trigger `/design-lead` or "the empty state and error state on this flow feel off, can you review the interaction?" → expected process: run On Invoke L44-50 — restate the real UX problem, cite 2-3 existing patterns / DESIGN.md, reject any slop by name, specify a11y inline, then quality-rubric self-score on Originality + Craft before declaring ready.
- anti-trigger `is this the right feature to build this quarter?` → should NOT fire; routes to `product-lead` per the L22 boundary (product priority is out of scope). Likewise architecture/code → `eng-lead`, strategic scope → `ceo`.
