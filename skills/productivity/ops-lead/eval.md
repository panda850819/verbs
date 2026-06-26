---
type: skill-eval
skill: ops-lead
bucket: productivity
evaluated_skill_hash: f5fd7e075b0678b7906390e5402370a3828ccad1
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — ops-lead

**Verdict: WEAK.** Leading virtue is a tight, predictable COO lens with a hard decision-shape output gate; two weak axes drag it down — a vague step-1 completion criterion and the "process-only-when-painful" rule echoing across five sections (two weak, no fail → WEAK).

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L44 — "On Invoke" fixes the same 3-step process every run (ground → cross-dept check → decision shape). |
| Description / invocation | pass | L4 — front-loads leading word "Operations lens", lists trigger phrases + a clean NOT-list, model-invoked is correct for a lens boardroom/sprint must reach. |
| Completion criteria | weak | L46 — step 1 ("connect every recommendation to specific people… Generic ops advice is anti-pattern") is a quality bar, not a checkable done/not-done gate; step 2 (L47) and step 3 (L48) end checkable, but the lens has no overall "done" criterion and the gating step-1 stays subjective. |
| Information hierarchy | pass | L16 — heavy persona scaffold + calibration pushed behind `@../../../lib/...` pointers; steps stay inline, reference loads on demand. |
| Leading words | pass | L14 — "COO mindset… process over heroics" and "Templates before training" (L33) anchor behaviour in pretrained concepts in few tokens. |
| Pruning | weak | L40 — "Process-when-painful" restates Iron Law 1 (L32) + Soul (L26) + both Anti-patterns (L53 twice-failed, L56 kill-when-gone); the same rule lives in five places, and "action + owner + deadline" repeats across L35/L41/L48. |
| Granularity | pass | L4 — the split earns its load: distinct leading word `/ops-lead` and independent reach by boardroom/sprint via the persona frame. |
| pandastack conformance | pass | L16 — name=folder, frontmatter valid (matches sibling `ceo`), 64-line body < 80, both lib refs resolve (~3K tokens < 5K so no sub-agent dispatch needed). |

## Why it's good
The On Invoke protocol (L44-48) makes the lens reproducible and ends on a genuinely checkable artifact — `<action> by <owner> by <deadline>` — which kills the most common ops failure mode (fuzzy non-decisions). The description (L4) and Routing Boundary (L18-22) draw crisp NOT-edges to the four sibling lenses, so dispatch is unambiguous. Reference bulk is correctly pushed to lib, keeping the body legible at 67 lines.

## Top fixes
1. Collapse the "process-only-when-painful" duplication (L26, L32, L40, L53, L56 — five places): keep it as Iron Law 1, cut the Cognitive Model (L40) and Soul (L26) restatements and fold the two Anti-patterns (L53, L56) into one; the persona-frame template invites the echo but it is genuine sediment. This is the larger of the two weak axes.
2. Sharpen step-1 completion (L46): turn "connect every recommendation to specific people… Generic ops advice is anti-pattern" into a checkable gate, e.g. "every recommendation names a person, a documented pattern, or a measurable signal — else it is not done."
3. Collapse the decision-shape triple (L35 / L41 / L48): state `action + owner + deadline` once as the On Invoke output gate and drop the Iron Law 4 + Cognitive Model copies, or have them cross-reference rather than re-state.

## Behavioral cases
- trigger `/ops-lead our weekly handoff keeps dropping things, design a cadence` -> expected process: ground in the specific team/people, check for eng/design sub-tasks to hand off, output a cadence as `<action> by <owner> by <deadline>` only if the pain failed twice.
- anti-trigger `should we kill this product line` -> should NOT fire (routes to `ceo` for kill/pivot judgment, per L22).
- anti-trigger `the deploy script is flaky, fix the automation` -> should NOT fire (routes to `eng-lead` — the fix is automation, not coordination, per L63).
