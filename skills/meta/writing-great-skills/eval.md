---
type: skill-eval
skill: writing-great-skills
bucket: meta
evaluated_skill_hash: 62a9f0c81072b89c39f81bd8704dceb7062f895e
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — writing-great-skills

**Verdict: SOLID.** Leading virtue: it is its own construction-quality SSOT, with the failure-mode vocabulary now explicit enough for downstream evaluators to test. It stays short of STRONG because the Native parity axis still does not model this skill's own nearest native competitor and delta.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L12 — names predictability as the root virtue every lever below serves, anchoring one repeatable process rather than a single desired output. |
| Description / invocation | pass | L4 — front-loads "Reference for writing and editing pandastack skills well", then names concrete trigger branches: authoring, splitting, pruning, or reviewing. |
| Completion criteria | pass | L37 — defines completion criteria with a checkable / not-checkable pair and ties vague criteria to premature completion. |
| Information hierarchy | pass | L35 — defines the in-skill step -> in-skill reference -> external reference ladder that decides where material belongs. |
| Leading words | pass | L58 — explains leading words with concrete pretrained anchors and shows compression from diffuse prose to "tight". |
| Pruning | pass | L54 — gives the sentence-level no-op deletion test and says failed lines should usually be deleted, not reworded. |
| Native parity | weak | L72 — defines the required native-parity check, but this skill still does not name its own native competitor and earned delta. |
| Granularity | pass | L47 — says each split spends load, so cuts must earn their keep before a skill is divided. |
| pandastack conformance | pass | L86 — binds local conformance to valid frontmatter, hot/cold dispatch, earned length, and resolving `lib/` references. |

## Why it's good
The skill keeps construction quality in one place: definitions live behind the GLOSSARY.md pointer (L14), rubric axes are indexed without duplicating their criteria (L76-86), and the failure-mode catalog is short enough to stay hot (L60-68). The new sediment, sprawl, and no-op wording turns vague quality instincts into checks an evaluator can run.

## Top fixes
1. L72 — add this skill's own native-parity self-example: nearest native feature = default model skill-writing judgment / built-in skill docs; delta = line-cited pandastack scorecard plus reflex-override vocabulary.
2. L64-68 — the Failure modes section is now useful but still partly redefines terms owned by GLOSSARY.md. If it grows again, thin this section to diagnostic use and leave definitions in the glossary.

## Behavioral cases
- trigger `is this SKILL.md well-written / score this skill` -> expected process: load this file as the criteria SSOT, walk the scorecard axes (L78-86), cite one line per axis, and emit leading virtue plus 1-3 fixes (L88).
- trigger `I'm authoring / splitting / pruning a skill` -> expected process: consult invocation, hierarchy, splitting, pruning, leading words, failure modes, and native parity before writing.
- anti-trigger `score this article / draft / IC memo for quality` -> should NOT fire (routes to `lib/quality-rubric.md`, which scores artifacts, not skills, per L14).
- anti-trigger `create the skill for me end-to-end` -> should NOT fire as builder (routes to skill-creator, which self-checks against this file but owns the build).
