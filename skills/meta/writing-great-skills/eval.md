---
type: skill-eval
skill: writing-great-skills
bucket: meta
evaluated_skill_hash: e876f5ef34f3c67b7790f61c7204cbb3dcb6dd14
evaluated_at: 2026-07-01
rubric: writing-great-skills@1.0.0
---

# Eval — writing-great-skills

**Verdict: SOLID.** Leading virtue: it is its own proof — a ruthlessly pruned reference where every section header is a leading word with a single glossary definition reached by a context pointer, and the scorecard is now a pure back-index rather than a hand-synced restatement. All eight axes pass. It is held short of STRONG by one residual: the Failure-modes catalog re-glosses terms GLOSSARY.md is meant to define once (Sediment verbatim), the one duplication class the skill itself exists to police.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L12 — names predictability as "the root virtue" every lever below serves, and the doc enacts one process (consult these named levers) rather than chasing a single output. |
| Description / invocation | pass | L4 — front-loads "Reference for writing and editing pandastack skills well", one trigger per branch ("authoring, splitting, pruning, or reviewing"), keeps the reach clause (skill-eval binds it as criteria); a model description coexisting with `user-invocable` is the pandastack norm, not a contradiction. |
| Completion criteria | pass | L37 — the concept is defined *and* embodied with a worked checkable / not-checkable pair: "Every heading enumerated" is checkable and exhaustive; "reviewed the structure" is neither — and the bolded **legwork** is wired to it ("that does the real work"). The prior "no worked pair" gap is closed. |
| Information hierarchy | pass | L14 — bold terms pushed to GLOSSARY.md by a context pointer; the three-tier ladder it describes (in-skill step / in-skill reference / external reference, L37-39) is the ladder it uses, with hot/cold dispatch named (L43) and co-location held heading by heading. |
| Leading words | pass | L58 — every section header (Pruning, Sediment, Sprawl, No-op, tight loop) is a leading word, and it models collapse in place ("fast, deterministic, low-overhead" → tight). |
| Pruning | pass | L72 — the scorecard is now "the index, not a second copy": the 8 axes point back at the section headers instead of restating them, so the prior hand-synced duplication is gone; the once-orphaned **legwork** is now used at L37. Body sits at 79 lines (frontmatter excluded), inside the ~80 guide. |
| Granularity | pass | L47 — "spends one of the two loads per cut, so split only when the cut earns it"; the sole split (GLOSSARY.md, 24 definitions reached on demand by sibling evals) earns its external-reference load over inlining them hot. |
| pandastack conformance | pass | L81 — name=folder verified; SKILL-FRONTMATTER.md, GLOSSARY.md, and lib/quality-rubric.md all resolve; body 79 lines (within ~80); no >5K-token hot read, so no dispatch owed. |

## Why it's good
The skill practices its own doctrine: the smallest set of named levers, each a leading word, defined exactly once in a pushed-out glossary reached by a context pointer (L14). The invocation section (L20-23) is a clean two-cost model (context load vs cognitive load) that makes the model-vs-user choice derivable instead of memorized, and the failure-mode catalog (L64-68) hands the evaluator a diagnostic vocabulary that maps one-to-one onto the scorecard axes. Two things this revision fixed and now embodies: the completion-criterion principle carries a concrete checkable / not-checkable pair (L37) instead of only demanding checkability of other skills, and the scorecard (L70-83) is a pure back-index — "the index, not a second copy" (L72) — so the body is the single source of truth for each principle. The SSOT boundary against lib/quality-rubric.md (artifacts) vs this file (construction) is stated at L14, and all references resolve.

## Top fixes
1. L65-66 — the Failure-modes catalog re-glosses terms GLOSSARY.md is meant to hold once: the **Sediment** line "stale layers that settle because adding feels safe and removing feels risky" is verbatim in both SKILL.md (L66) and GLOSSARY.md (L25), and **Duplication** ("inflates a meaning's rank", L65) is near-verbatim with GLOSSARY.md (L12). This is a mild tension with the skill's own single-source rule (L54). Fix: let the catalog name the bolded term + its diagnostic/defence only, and rely on the glossary for the definition, so the gloss and the glossary cannot drift.

(The four fixes from the prior eval are resolved: scorecard is now a pure index; **legwork** is wired into the body; the completion criterion has a worked checkable/not-checkable example; and the body is back under the ~80-line guide.)

## Behavioral cases
- trigger `is this SKILL.md well-written / score this skill` -> expected process: load this file as the criteria SSOT, walk the 8 axes (L74-81), cite one line per axis, emit leading-virtue + 1-3 fixes (L83).
- trigger `I'm authoring / splitting / pruning a skill` -> expected process: consult the named levers (invocation, hierarchy, when-to-split, pruning) before writing, resolving bold terms via GLOSSARY.md.
- anti-trigger `score this article / draft / IC memo for quality` -> should NOT fire (routes to lib/quality-rubric.md, which scores artifacts not skills, per the explicit boundary at L14).
- anti-trigger `create the skill for me end-to-end` -> should NOT fire as builder (routes to skill-creator, which self-checks *against* this file but owns the build).
