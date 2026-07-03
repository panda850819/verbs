---
type: skill-eval
skill: skill-eval
bucket: meta
evaluated_skill_hash: 64418c1afbfdf32d6eda0da9c120038a2e812a03
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — skill-eval

**Verdict: SOLID.** A tight, self-binding evaluator: three ordered steps, hash-stamped freshness, and explicit vocabulary checks for no-op, sediment, and leading-word compression. It remains short of STRONG because the skill still duplicates its construction-vs-artifact boundary and does not explicitly name its own native competitor.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L19 — the three ordered steps (load criteria, score axes, write verdict) make the evaluator run the same process every invocation. |
| Description / invocation | pass | L4 — leading word "Score" front-loads the job, and the trigger branches are concrete: eval/score a skill or regenerate its eval after editing. |
| Completion criteria | pass | L38 — completion is checkable: `eval.md` exists, every axis has a cited line, and `lint-eval-fresh.sh <name>` passes. |
| Information hierarchy | pass | L40 — the output template is pushed below the numbered steps, reached only after the process says to write the verdict. |
| Leading words | pass | L32 — makes leading-word compression an explicit scoring check instead of leaving it as generic prose taste. |
| Pruning | weak | L30 — adds the no-op deletion test, but L13 and L83 still duplicate the construction-vs-artifact boundary in two homes. |
| Native parity | weak | L38 — the earned delta is hash-stamped, lint-fresh eval output, but the skill still does not name the nearest native feature directly. |
| Granularity | pass | L17 — `/skill-eval all` earns fan-out to one sub-agent per skill while the one-skill path stays compact. |
| pandastack conformance | pass | L31 — sediment checks require referenced paths, commands, features, and retired branches to exist before conformance passes. |

## Why it's good
The skill closes its own loop: it stamps the scored SKILL.md's git hash into the eval and makes `lint-eval-fresh.sh` passing the completion criterion (L38), so drift is caught mechanically. It now consumes the writing-great-skills vocabulary directly: no-op deletion testing, sediment path verification, and leading-word compression are named checks in the scoring step (L29-32).

## Top fixes
1. L13 / L83 — collapse the construction-vs-artifact rule to one home. Keep L13 because it routes to `quality-rubric.md`; thin L83 so it names the anti-pattern without restating the whole distinction.
2. L38 — make the native-parity delta explicit in the skill: nearest native feature = default model review/evaluation; earned slot = hash-stamped, lint-fresh, co-located eval with one cited line per axis.

## Behavioral cases
- trigger `eval the skill-creator skill` -> expected process: read the writing-great-skills scorecard axes -> resolve and read `skills/meta/skill-creator/SKILL.md` whole + sibling refs -> score every axis pass/weak/fail with one cited `L<n>` each, default weak -> write `skills/meta/skill-creator/eval.md` from the template, stamp `git hash-object`, confirm `lint-eval-fresh.sh skill-creator` passes (L21-38).
- trigger `/skill-eval all` -> expected process: fan out one sub-agent per skill under `skills/<bucket>/<skill>/`, never score the whole corpus in one hot context (L17).
- anti-trigger `score this brain page draft for quality` -> should NOT fire (judges an artifact's prose, not a SKILL.md's construction; routes to repo-root `lib/quality-rubric.md` per L13).
- anti-trigger `create a new skill / improve this skill` -> should NOT fire (routes to `skill-creator`, the builder counterpart, L11).
