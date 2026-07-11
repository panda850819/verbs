# Current-model recut: with-skill / without-skill

Date: 2026-07-12  
Model: Claude Sonnet 5, medium effort  
Isolation: `--safe-mode`, tools disabled, no session persistence  
Fixtures: [`fixtures/current-model-recut/`](fixtures/current-model-recut/)

## Method

Each fixture ran twice with the same model and prompt. The baseline had no
customizations. The treatment appended only the target `SKILL.md` to the system
prompt. Input totals below include direct, cache-created, and cache-read tokens;
they are useful overhead estimates, not billing-normalized figures.

## Results

| Fixture | Arm | Input total | Output | Cost USD | Behavior |
|---|---:|---:|---:|---:|---|
| review-low | without | 612 | 350 | 0.007748 | Correct approve; added two speculative non-blocking checks. |
| review-low | with | 2,435 | 523 | 0.012418 | Same outcome; explicit low lane, no fan-out, self-refute and residual gap. |
| review-high | without | 636 | 697 | 0.013039 | Caught missing-key authentication bypass and missing test. |
| review-high | with | 2,459 | 1,075 | 0.031554 | Same core findings; added severity/evidence contract, coverage gap, and cold-review gap. |
| sprint-clear | without | 668 | 1,199 | 0.020691 | Produced a valid hypothetical implementation and PR plan. |
| sprint-clear | with, final | 2,651 | 960 | 0.031002 | Honored `NOT_RUN`, skipped grill/delegation, preserved acceptance/review/ship gates. |
| sprint-ambiguous | without | 583 | 481 | 0.009617 | Correctly refused to guess four migration decisions. |
| sprint-ambiguous | with | 2,441 | 504 | 0.022853 | Same outcome; explicitly routed the four linked choices to `grill`. |

## Behavior delta

- Strong native review already found the toy auth defect. `review` did not
  improve defect recall on these fixtures and cost about 1.8K input tokens per
  call. Its retained delta is process-level: bound scope, risk lanes, finding
  evidence, self-refutation, and an earned cold-context branch on real diffs.
- Fixed three-pass and always-on cross-model behavior is gone. The low-risk arm
  performed one pass and explicitly marked cold review `not earned`.
- Native execution already handled both clear and ambiguous planning cases.
  `sprint` remains justified by the real execution contract: acceptance after
  the final edit, bounded review correction, and delivery evidence before
  `SHIPPED`.
- The first treatment run of `sprint-clear` fabricated tests, review, push, and
  PR evidence despite the fixture forbidding tools. That was a skill-caused fake
  green. The skill now has a planning-only anti-trigger and `Execution: NOT_RUN`
  boundary; the rerun obeyed it and emitted 239 fewer output tokens than baseline.

## Decision

- Keep `review`, in its risk-adaptive slim form. Do not claim quality lift from
  toy defects; re-evaluate on real repository diffs at the next model release.
- Keep `sprint`, with planning-only requests excluded. Its slot is tied to
  observed delivery-state failures, not generic decomposition.
- Retire `write` to Panda's overlay, move `skill-creator` to maintainer-only,
  and make `writing-great-skills` a co-located library. These three no longer
  consume default runtime slots.

## Re-run gate

At a major model upgrade, run these exact fixtures in safe mode. A default skill
is a cut candidate if baseline matches its primary outcome and the treatment
adds no critical-failure prevention, or if treatment again causes fabricated
evidence, unnecessary interrogation, or fixed fan-out.
