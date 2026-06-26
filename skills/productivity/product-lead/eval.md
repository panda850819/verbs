---
type: skill-eval
skill: product-lead
bucket: productivity
evaluated_skill_hash: 6be71bc505ca7ca6716f26bb9e9501a15434cc54
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — product-lead

**Verdict: SOLID.** A disciplined persona lens whose Iron Laws and pretrained cognitive anchors (leaky bucket, job-to-be-done) give a sharp, repeatable product-review process — held back only by triple-encoded routing and soft completion criteria in the lens steps.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L46 — "On Invoke" fixes the same 4-step process (problem → metric → non-scope → failure mode) every run, the right form of predictability for a lens. |
| Description / invocation | pass | L4 — front-loads "Product lens for…", lists trigger branches, ends with a tight NOT-clause that discriminates from ceo/eng/design/ops. |
| Completion criteria | weak | L49 — "Predict the failure mode" has no checkable done-condition (predict from what evidence, against what bar?); a persona step like this can be declared done trivially → premature-completion bait. |
| Information hierarchy | pass | L16 — the shared 6-section persona contract is pushed behind an `@../../../lib/persona-frame.md` pointer instead of inlined, keeping the top legible. |
| Leading words | pass | L41 — "Leaky bucket" / "Job-to-be-done" / "Focus through subtraction" anchor behaviour in concepts already in pretraining; no weak "be thorough"-class fillers. |
| Pruning | weak | L22 — the Routing Boundary NOT-clause restates the description's NOT-clause (L4) verbatim in meaning, and Team protocol (L65-67) encodes the same hand-off routing a third time: one fact, three places. |
| Granularity | pass | L16 — the cut to `lib/persona-frame.md` earns its context load: the contract is shared by 5 lead skills + boardroom, so the split removes duplication rather than creating reach cost. |
| pandastack conformance | pass | L5 — frontmatter is valid per SKILL-FRONTMATTER (name+description required; reads/domain/classification are sanctioned advisory fields); lib refs resolve, body ~67 lines (<80), no >5K hot-read so hot/cold is moot. |

## Why it's good

The skill earns its keep through five non-negotiable Iron Laws (L32-36) and three pretrained cognitive anchors (L40-42) that let the agent run a product critique the same way every time without a long body. The description (L4) is a model of branch-plus-NOT-clause discrimination, so the router can keep this lens from firing on strategy, code, or UI questions. Progressive disclosure to `lib/persona-frame.md` and `lib/bad-good-calibration.md` keeps the SKILL.md itself under 80 lines while staying load-bearing for boardroom's voice extraction.

## Top fixes

1. **Collapse the triple-encoded routing.** The description NOT-clause (L4), the Routing Boundary (L19-22), and Team protocol (L65-67) say the same "this not that / hand off to X" facts three times. Keep the description as the single source for routing-away; cut the Routing Boundary section, leave only the positive hand-off triggers in Team protocol.
2. **Sharpen the soft On-Invoke criteria.** L49 ("Predict the failure mode") and L48 ("what we are explicitly NOT solving") have no checkable done-bar. Tie each to a concrete artifact, e.g. "name one named failure mode (low retention / wrong segment / replacement) with the signal that would confirm it" so the step can be marked done vs not-done.
3. **De-no-op the anti-patterns.** Several entries (L56 "Let's ship and iterate" without a signal, L57 adding features because competitors have them) restate the Iron Laws a VP-Product-framed model already obeys; keep the ones that catch real drift (L54 multi-metric, L53 no-user-evidence) and prune the restatements.

## Behavioral cases

- trigger `"is this feature worth building? what's the metric?"` → expected process: invoke product-lead, run On Invoke L46-49 — state the user problem in one sentence, name the single proving metric, declare what is NOT in scope, predict the failure mode.
- anti-trigger `"should we kill this product line or pivot?"` → should NOT fire; that is a strategy-only kill/pivot call and routes to `ceo` per the L4 / L22 NOT-clause.
