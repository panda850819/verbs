---
type: skill-eval
skill: skill-eval
bucket: meta
evaluated_skill_hash: 012a6d8bdc530c86ebd26cd6be5120ac23764845
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — skill-eval

**Verdict: SOLID.** A tight, self-binding evaluator: three checkable steps anchored on a hard completion criterion (lint-fresh), losing a single point to a scope statement restated as an anti-pattern.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L19 — three numbered `## Steps` (load criteria → score → write+stamp) run the same process every invocation; no branch reorders them. |
| Description / invocation | pass | L4 — leading word "Score" front-loads; model-facing; one trigger per branch (eval/score a skill, regenerate-after-edit) with the synonym pile collapsed; no body-identity restated. |
| Completion criteria | pass | L33 — exhaustive and checkable: `eval.md` exists AND every axis cites a line AND `lint-eval-fresh.sh <name>` passes; not "reviewed the skill". |
| Information hierarchy | pass | L35 — the output contract is pushed below the steps as "## eval.md template", reached by the L33 pointer "using the template below"; the second-opinion note is demoted to an L29 reference blockquote, keeping the hot path the steps. |
| Leading words | pass | L17 — "fans out" + "hot/cold rule — never score the whole corpus in one hot context", plus "rubber-stamping"/"no-op" (L76), are pretrained anchors doing invocation and execution work in few tokens. |
| Pruning | weak | L13 — the scope statement "scores the SKILL.md construction NOT the artifact" is restated at L77 as the "Scoring the artifact, not the skill" anti-pattern; the same meaning lives in two places (Duplication, WGS L65). |
| Granularity | pass | L17 — the `/skill-eval all` fan-out earns the hot/cold sub-agent split; the step splits each carry distinct load (criteria vs score vs write). |
| pandastack conformance | pass | L17 — frontmatter `name: skill-eval` = folder; hot/cold dispatch honoured; ~33 prose lines (the embedded template earns the rest); both lib refs resolve — `../writing-great-skills/SKILL.md` and `../../../lib/quality-rubric.md` (= repo-root `lib/`). |

## Why it's good
The skill closes its own loop: it stamps the scored SKILL.md's git hash into the eval and makes `lint-eval-fresh.sh` passing a completion criterion (L33), so a stale eval is a caught signal rather than silent sediment — the exact failure the skill names at L79. It binds the writing-great-skills scorecard by reference instead of copying axes (L11, "do not invent axes"), keeping the two in sync. The anti-default rules — default to weak (L27), no uncited verdicts (L78) — actively fight the rubber-stamp failure this kind of skill is most prone to.

## Top fixes
1. L13 / L77 — collapse the "construction vs artifact" point to one home. Keep the L13 scope note (it routes the reader to `quality-rubric.md`) and thin L77 to reference it rather than restate the same distinction.
2. L29 — the second-opinion blockquote is reference-tier ("for a heavily-used skill") and correctly demoted out of the numbered steps; if it rarely fires, a context pointer to a lib note would keep the hot body even tighter, though at this length it does not yet sprawl.

## Behavioral cases
- trigger `eval the skill-creator skill` -> expected process: read the writing-great-skills scorecard → resolve & read `skills/meta/skill-creator/SKILL.md` whole + its sibling refs → score 8 axes pass/weak/fail with one cited `L<n>` each, default weak → write `skills/meta/skill-creator/eval.md` from the template, stamp `git hash-object`, confirm `lint-eval-fresh.sh skill-creator` passes (L19-33).
- trigger `/skill-eval all` -> expected process: fan out one sub-agent per skill under `skills/<bucket>/<skill>/`, never score the whole corpus in one hot context (L17).
- anti-trigger `score this brain page draft for quality` -> should NOT fire (judges an artifact's prose, not a SKILL.md's construction; routes to repo-root `lib/quality-rubric.md` per L13).
- anti-trigger `create a new skill / improve this skill` -> should NOT fire (routes to `skill-creator`, the builder counterpart, L11).
