---
type: skill-eval
skill: ceo
bucket: productivity
evaluated_skill_hash: 07f42ca1c89b5e2b7d33ca67aac6ddcc8f8f677b
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — ceo

**Verdict: SOLID.** A predictable strategic-lens process anchored in strong pretrained frameworks (Bezos doors, effort gate, framework tension) under a hard recommend-don't-act contract; both lib refs now resolve and import cleanly. Costing points: the recommend-don't-act rule is restated across three sections, and the interior On-Invoke steps (1-3) lean on judgment rather than a checkable done/not-done.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L44 — "## On Invoke" fixes the same 4-step process every run (pick frameworks → show tension → recommend → predict pushback), and L53 forks scope-topic decisions to a separate deterministic GO/ITERATE/KILL template on a clear condition; process-not-output. |
| Description / invocation | pass | L4 — front-loads the leading word "Strategic lens", enumerates one trigger per branch (scope / priority / kill-pivot-continue / door), and carries a NOT-clause routing implementation, code-review, and generic planning to plan/write/eng; no body-identity bleed. |
| Completion criteria | weak | L46 — steps 1-3 ("Pick 2-3 frameworks that create tension", "Show where they agree and disagree — that's where the insight is", "Make a recommendation") are judgment calls, not checkable done/not-done; only step 4 (L49, "Predict the top 3 pushback questions") and the GO/ITERATE/KILL gate (L59) give the run a bounded terminal, so the interior invites premature completion. |
| Information hierarchy | pass | L16 — shared persona structure is behind an `@` context pointer (persona-frame), and the BAD/GOOD pairs likewise (L71), so the hot body stays the ceo-specific contract and shared rules load on demand. |
| Leading words | pass | L40 — "Two-way / one-way doors (Bezos)", "Effort gate (compression ratio)" (L41), and "Framework tension (multi-lens)" (L42) anchor whole regions of behaviour in pretrained concepts in minimal tokens. |
| Pruning | weak | L36 — the recommend-don't-act meaning is stated three times: Iron Law 1 "AI recommends, user decides" (L32), Iron Law 5 "Never act on scope changes ... and ask" (L36), and the anti-pattern "I'll make the change and tell the user afterward → Ask first" (L66); one meaning, three slots, inflating its apparent rank. |
| Granularity | pass | L51 — the Scope Review split earns its load: a distinct branch (scope-as-topic) with its own terminal gate, justified inline ("terminate on its GO/ITERATE/KILL gate instead of the On Invoke loop"); no gratuitous section. |
| pandastack conformance | pass | L5 — `name: ceo` equals the folder, both declared `reads` (persona-frame, bad-good-calibration) resolve on disk AND are `@`-imported (L16, L71), each lib is well under 5K tokens so no hot/cold dispatch is owed, and the body is 74 lines, inside the ~<80 budget. |

## Why it's good
The skill is a tight persona lens: a fixed 4-step On-Invoke loop plus a scope-specific GO/ITERATE/KILL template give it a predictable process independent of the decision's content, and three pretrained leading words (Bezos doors, compression-ratio effort gate, framework tension) anchor the reasoning in minimal tokens. The shared persona structure and voice-calibration pairs are correctly extracted to `lib/` behind `@` pointers that resolve and import, keeping the hot body at the ceo-specific contract. The repair landed: the prior phantom `reads: lib/escape-hatch.md` and the never-imported `lib/outside-voice-rule.md` ref are both gone, and the `reads:` list now matches exactly what the body imports.

## Top fixes
1. L46 — sharpen On-Invoke steps 1-3 into checkable criteria (e.g. "name the 2-3 frameworks and state one disagreement each"); right now only step 4 and the scope gate are checkable, so the lens can declare itself done after a soft recommendation.
2. L36 — collapse the recommend-don't-act rule to one source of truth. Keep it as Iron Law 1, drop the restatements in Iron Law 5 and the L66 anti-pattern (or cross-reference rather than re-state).
3. L42 — "Framework tension ... used when single framework gives a clean answer (suspect of clean answers)" reads as a half-inverted condition; tighten to "reach for it when one framework gives a suspiciously clean answer".

## Behavioral cases
- trigger `/ceo should we kill this initiative or keep iterating?` -> expected process: scope-as-topic, so run the Scope Review template (L55) and terminate on the GO/ITERATE/KILL gate, with effort estimate and reversibility called out; never executes the kill, asks first (Iron Law 5, L36).
- trigger `is this a one-way or two-way door?` -> expected process: On-Invoke loop (L44), reach for the Bezos doors framework (L40), recommend reversible=decide-fast vs irreversible=gather-data (Iron Law 4, L35), draft top-3 pushback.
- anti-trigger `review this PR diff for correctness` -> should NOT fire (routes to eng-lead / careful per the L22 NOT-clause; implementation and code-review are explicitly disclaimed).
