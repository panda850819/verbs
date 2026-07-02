---
type: skill-eval
skill: writing-great-skills
bucket: meta
evaluated_skill_hash: 16678fd09e8b2842ef02dd10cc400b2f2b348583
evaluated_at: 2026-07-02
rubric: writing-great-skills@1.1.0
---

# Eval — writing-great-skills

**Verdict: SOLID.** Leading virtue: it is its own construction-quality SSOT — compact, named, and now explicit that every skill competes with native harness defaults. It stays short of STRONG because the new Native parity axis is defined for other skills but this skill still does not name its own nearest native competitor and delta inside the body.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L12 — names predictability as "the root virtue" every lever below serves, and the doc enacts one process (consult these named levers) rather than chasing a single output. |
| Description / invocation | pass | L4 — front-loads "Reference for writing and editing pandastack skills well", keeps one trigger set ("authoring, splitting, pruning, or reviewing"), and names the reach clause: skill-eval scores against it. |
| Completion criteria | pass | L37 — defines completion criteria with a worked checkable / not-checkable pair, then ties demanding criteria to the **legwork** that does the real work. |
| Information hierarchy | pass | L14 — pushes bold terms into GLOSSARY.md via a context pointer and states the construction/artifact boundary without copying the artifact rubric. |
| Leading words | pass | L58 — explains leading words with concrete anchors and models collapse in place ("fast, deterministic, low-overhead" -> tight). |
| Pruning | pass | L76 — the scorecard is an index, not a second copy, so the axis criteria live in their named sections instead of being hand-synced. |
| Native parity | weak | L72 — defines the required check; nearest native feature for this skill is the model's default skill-authoring judgment, and the delta is the cited SSOT scorecard, but the skill does not name that competitor and delta for itself. |
| Granularity | pass | L47 — says granularity spends one of the two loads per cut, so the only sibling split (GLOSSARY.md) earns its load by keeping definitions out of the hot body. |
| pandastack conformance | pass | L86 — binds the local conformance checks: valid frontmatter, hot/cold dispatch, earned length, and resolving `lib/` references. |

## Why it's good
The skill practices its own doctrine: a small set of named levers, each tied back to the root virtue of predictability (L12), with definitions pushed to GLOSSARY.md instead of inlined hot (L14). The scorecard is a back-index (L76-86), so `skill-eval` can bind a single source of truth without copying rubric prose. The new Native parity section (L70-72) turns the v3.2.0 earned-slot criterion into a standing release check rather than a re-derived judgment.

## Top fixes
1. L72 — add this skill's own native-parity self-example: nearest native feature = default model skill-writing judgment / built-in skill docs; delta = line-cited pandastack scorecard plus reflex-override vocabulary. Right now the axis demands that of others but does not model it for itself.
2. L65-66 — the Failure-modes catalog still re-glosses terms GLOSSARY.md is meant to define once, especially **Sediment** and **Duplication**. Thin these lines to diagnostic use and let the glossary own the definitions.

## Behavioral cases
- trigger `is this SKILL.md well-written / score this skill` -> expected process: load this file as the criteria SSOT, walk the scorecard axes (L78-86), cite one line per axis, emit leading-virtue + 1-3 fixes (L88).
- trigger `I'm authoring / splitting / pruning a skill` -> expected process: consult the named levers (invocation, hierarchy, when-to-split, pruning, native parity) before writing, resolving bold terms via GLOSSARY.md.
- anti-trigger `score this article / draft / IC memo for quality` -> should NOT fire (routes to lib/quality-rubric.md, which scores artifacts not skills, per the explicit boundary at L14).
- anti-trigger `create the skill for me end-to-end` -> should NOT fire as builder (routes to skill-creator, which self-checks against this file but owns the build).
