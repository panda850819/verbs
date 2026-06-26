---
type: skill-eval
skill: design-lead
bucket: productivity
evaluated_skill_hash: 36b845390bc1b5a2138d7b7cbe561d99086b42be
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — design-lead

**Verdict: SOLID.** Leading virtue is a clean persona frame with strong pretrained leading words ("empty states are features", "if everything is bold, nothing is bold") and a checkable quality-rubric self-score. It still costs points on a dense NOT boundary and a few posture-shaped early On-Invoke steps.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L44 — `On Invoke` is a fixed 5-step process the agent walks identically every invocation; output varies, process does not. |
| Description / invocation | weak | L4 — the description has clear NOT-routing but is dense; the body now compresses the routing boundary to skill-name handoffs (L21) rather than restating the full prose. |
| Completion criteria | weak | L45 — step 1 now has a done-test ("restate the UX problem in one sentence the user confirms"), and step 5 is sharply checkable (L49); steps 2-4 still read more like posture than binary completion. |
| Information hierarchy | pass | L17 — the body is self-contained for a running review and only points at `lib/persona-frame.md` if the reader needs the contract itself; heavy calibration is behind `@../../../lib/bad-good-calibration.md` (L61), and quality-rubric loads only at the scoring moment (L49). |
| Leading words | pass | L33 — "If everything is bold, nothing is bold" anchors hierarchy-through-restraint in a pretrained concept; reinforced by "Empty states are features" (L32) and "AI slop" (L35). |
| Pruning | weak | L21 — the Routing Boundary still carries a compact NOT-list already present in the description, and "slop" appears in both Iron Law 4 (L34) and the slop-detector cognitive model (L41). The duplication is small but real. |
| Granularity | pass | L20 — the split off the other 4 leads earns its load: a distinct leading word ("Design lens") plus boardroom/sprint reach justify the always-loaded description. |
| pandastack conformance | pass | L2 — `name: design-lead` matches folder, body 67 lines < 80, all three lib refs resolve to repo-root `lib/`; the hot calibration import and on-demand quality-rubric stay under the 5K hot/cold dispatch threshold. |

## Why it's good
The skill keeps the persona shape compact while preserving the load-bearing design checks. Its Iron Laws and Cognitive Models are written as compact, pretrained-anchored leading words rather than vague adjectives, which is the predictability win. On-Invoke step 5 binds `lib/quality-rubric.md` at a real generation moment (self-score, any axis < 3 → revise), honouring the rubric's governance contract instead of a pointer-only link.

## Top fixes
1. L4 / L21 — collapse the remaining NOT-list duplication by keeping the full boundary in one place and using only skill-name handoffs in the other.
2. L46-48 — sharpen steps 2-4 with done-tests matching step 1 and step 5, so the whole On Invoke block is binary-completable.
3. L34 / L41 — make Iron Law 4 the canonical slop definition and let the Cognitive Model point to it instead of restating the scan.

## Behavioral cases
- trigger `/design-lead the empty and error states on this onboarding flow feel off` -> expected process: run On Invoke L44-50 — restate the real UX problem, cite 2-3 existing patterns / DESIGN.md, reject slop by name, specify a11y inline, then quality-rubric self-score on Originality + Craft before declaring ready.
- trigger `does this screen feel intentional or like AI slop?` -> expected process: fire the slop-detector cognitive model (L42), name the slop pattern, propose the principle-based alternative (L48).
- anti-trigger `which feature should we build first this quarter?` -> should NOT fire (routes to `product-lead` per L22).
- anti-trigger `how should we structure this React component tree?` -> should NOT fire (routes to `eng-lead` per L22).
