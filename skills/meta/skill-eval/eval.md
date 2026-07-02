---
type: skill-eval
skill: skill-eval
bucket: meta
evaluated_skill_hash: 6a2549f2cf9da3a115fddb156e601ac9b0c18ee9
evaluated_at: 2026-07-02
rubric: writing-great-skills@1.1.0
---

# Eval — skill-eval

**Verdict: SOLID.** A tight, self-binding evaluator: three checkable steps, a hash-stamped output, and the new Native parity axis wired into the template. It remains short of STRONG because the skill still duplicates its construction-vs-artifact boundary and does not explicitly name its own native competitor.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L19 — three ordered steps (load criteria -> score -> write verdict) run the same process every invocation; no branch reorders them. |
| Description / invocation | pass | L4 — leading word "Score" front-loads the job, and the trigger branches are concrete: eval/score a skill, or regenerate its eval after editing. |
| Completion criteria | pass | L33 — exhaustive and checkable: `eval.md` exists, every axis has a cited line, and `lint-eval-fresh.sh <name>` passes. |
| Information hierarchy | pass | L35 — the output contract is pushed below the numbered steps as a template, reached only after the process says to write the verdict. |
| Leading words | pass | L17 — "fans out" and "hot/cold rule" compact the all-skills branch into a model-native execution anchor. |
| Pruning | weak | L13 — the construction-vs-artifact scope note is useful, but the same meaning is repeated as an anti-pattern later, so one rule has two homes. |
| Native parity | weak | L33 — nearest native feature is the model's default evaluation/review behavior; the delta is hash-stamped freshness plus lint enforcement, but the skill does not name that native competitor directly. |
| Granularity | pass | L17 — `/skill-eval all` earns fan-out to one sub-agent per skill; the normal one-skill path stays in one compact evaluator. |
| pandastack conformance | pass | L11 — name=folder is valid, the criteria SSOT reference resolves, hot/cold fan-out is honoured, and the body stays short enough that no reference extraction is owed. |

## Why it's good
The skill closes its own loop: it stamps the scored SKILL.md's git hash into the eval and makes `lint-eval-fresh.sh` passing the completion criterion (L33), so drift is caught mechanically instead of trusted to memory. It binds writing-great-skills by reference (L11), then mirrors that SSOT in the template (L51-61) without inventing private axes. The default-to-weak and no-uncited-verdict rules (L27, L79) directly fight the rubber-stamp failure this evaluator is prone to.

## Top fixes
1. L13 / L78 — collapse the "construction vs artifact" rule to one home. Keep L13 because it routes to `quality-rubric.md`; thin L78 so it names the anti-pattern without restating the whole distinction.
2. L33 — make the native-parity delta explicit in the skill: nearest native feature = default model review/evaluation; earned slot = hash-stamped, lint-fresh, co-located eval with one cited line per axis.

## Behavioral cases
- trigger `eval the skill-creator skill` -> expected process: read the writing-great-skills scorecard axes -> resolve and read `skills/meta/skill-creator/SKILL.md` whole + sibling refs -> score every axis pass/weak/fail with one cited `L<n>` each, default weak -> write `skills/meta/skill-creator/eval.md` from the template, stamp `git hash-object`, confirm `lint-eval-fresh.sh skill-creator` passes (L19-33).
- trigger `/skill-eval all` -> expected process: fan out one sub-agent per skill under `skills/<bucket>/<skill>/`, never score the whole corpus in one hot context (L17).
- anti-trigger `score this brain page draft for quality` -> should NOT fire (judges an artifact's prose, not a SKILL.md's construction; routes to repo-root `lib/quality-rubric.md` per L13).
- anti-trigger `create a new skill / improve this skill` -> should NOT fire (routes to `skill-creator`, the builder counterpart, L11).
