---
type: skill-eval
skill: writing-great-skills
bucket: meta
evaluated_skill_hash: e876f5ef34f3c67b7790f61c7204cbb3dcb6dd14
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — writing-great-skills

**Verdict: SOLID.** Leading virtue: it is its own proof — a ruthlessly pruned reference where every section header is a leading word with a single definition pushed to GLOSSARY.md. It loses points because the scorecard (L72-81) self-admittedly restates the body and must be hand-synced, carries one orphan glossary definition (*Legwork*, GLOSSARY.md L27, never referenced in SKILL.md), and because as a flat reference it teaches completion criteria without embodying any.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L12 — names predictability as the root virtue every lever serves, and the doc enacts one process (consult these named levers) rather than chasing one output. |
| Description / invocation | pass | L4 — front-loads "Reference for writing and editing pandastack skills", one trigger per branch (authoring / splitting / pruning / reviewing), keeps the reach clause (skill-eval binds it); model description coexisting with `user-invocable` is the pandastack norm, not a contradiction. |
| Completion criteria | weak | L37 — the completion-criterion concept is defined and demanded *of other skills*, but this reference has no ordered steps to end on a checkable criterion, and "where it matters" stays abstract with no worked checkable / not-checkable pair, so the axis is taught, not embodied. |
| Information hierarchy | pass | L14 — bold terms pushed to GLOSSARY.md via a context pointer, hot/cold dispatch named (L43), co-location held heading by heading; the ladder it describes is the ladder it uses. |
| Leading words | pass | L58 — every section header (Pruning, Sediment, Sprawl, No-op, tight loop) is a leading word, and it models collapse in place ("fast, deterministic, low-overhead" → tight). |
| Pruning | weak | L72 — "keep it in sync with them" concedes the scorecard (L74-81) restates the L12-68 principles; a hand-synced condensation is duplication by the doc's own definition (L65), the one place a meaning lives in two spots. Plus orphan **sediment**: GLOSSARY.md L27 defines *Legwork*, but the term is bolded/used zero times in SKILL.md (every other glossary entry appears ≥1), violating GLOSSARY L3's "bolded in SKILL.md, defined once here" — a dead definition by the doc's own Sediment definition (L66). |
| Granularity | pass | L47 — the only split (GLOSSARY.md) earns its load: 24 definitions reached on demand by sibling evals justify the external-reference cut over inlining them hot. |
| pandastack conformance | pass | L81 — name=folder verified, SKILL-FRONTMATTER.md / lib/quality-rubric.md / GLOSSARY.md all resolve; body 87 lines, modestly over the ~80 guide but a dense reference earns it; no >5K hot read so no dispatch owed. |

## Why it's good
The skill practices its own doctrine: the smallest set of named levers, each a leading word, defined in a pushed-out glossary reached by a context pointer (L14) — defined exactly once each, modulo the one orphan (*Legwork*) flagged under Pruning. The invocation section (L20-23) is a clean two-cost model that makes the model-vs-user choice derivable instead of memorized, and the failure-mode catalog (L64-68) hands the evaluator a diagnostic vocabulary that maps one-to-one onto the scorecard axes. The SSOT boundary against lib/quality-rubric.md (artifacts) vs this file (construction) is stated explicitly at L14, and all references resolve.

## Top fixes
1. L72-81 — the scorecard duplicates the body's principles and leans on a manual "keep in sync" note. Make the 8-axis list a pure index that points back at the section headers (the source), so there is one source of truth, not two that drift.
2. GLOSSARY.md L27 — *Legwork* is defined but bolded/used nowhere in SKILL.md (every other entry appears ≥1). Either wire the term into the body (e.g. under Completion criteria, where "legwork" is the digging a demanding criterion forces) or delete the dead definition; an unreferenced glossary entry is sediment by the doc's own L66.
3. L37 — give the completion-criterion principle one concrete checkable / not-checkable example (e.g. "exhaustive = every heading enumerated, not sampled") so the doc embodies the checkability it demands of other skills.
4. L81 — body is 87 lines vs the self-stated ~80; trimming the scorecard restatement (fix 1) is what brings the meta-skill back under the line it teaches.

## Behavioral cases
- trigger `is this SKILL.md well-written / score this skill` -> expected process: load this file as the criteria SSOT, walk the 8 axes (L74-81), cite one line per axis, emit leading-virtue + 1-3 fixes (L83).
- trigger `I'm authoring / splitting / pruning a skill` -> expected process: consult the named levers (invocation, hierarchy, when-to-split, pruning) before writing, resolving bold terms via GLOSSARY.md.
- anti-trigger `score this article / draft / IC memo for quality` -> should NOT fire (routes to lib/quality-rubric.md, which scores artifacts not skills, per the explicit boundary at L14).
- anti-trigger `create the skill for me end-to-end` -> should NOT fire as builder (routes to skill-creator, which self-checks *against* this file but owns the build).
