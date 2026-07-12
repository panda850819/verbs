---
type: skill-eval
skill: skill-creator
bucket: meta
evaluated_skill_hash: 336eae81aa43af79ddc4ba386d765f19ceb6c09b
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — skill-creator

**Verdict: SOLID.** Its leading virtue is a refuse-before-build workflow that binds generation and `skill-creator --eval` to one scorecard, then treats `manifest.toml` plus `scripts/verbs sync` as the registration SSOT.

Grounding sample: L15 — "refusing non-skills, preventing trigger overlap, enforcing hot/cold placement,"

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L22 — numbered phases fix the order from gap identification through MECE, hot/cold choice, authoring, registration, verification, and construction self-check. |
| Description / invocation | pass | L4 — the hot description names exactly two live branches: create/improve and `skill-creator --eval`, each with a concrete trigger phrase and distinct purpose. |
| Completion criteria | pass | L147 — done requires manifest sync, eval freshness, and executable resolver-route verification rather than the mere presence of a new `SKILL.md`. |
| Information hierarchy | pass | L19 — detailed scoring steps and the eval template stay in `lib/skill-eval.md`; the body keeps only the evaluator contract, content hash, and freshness gate needed at invocation. |
| Leading words | pass | L38 — `Q0` anchors refuse-before-build before overlap analysis, with MECE, subtract-first, and hot/cold forming the rest of the construction vocabulary. |
| Pruning | weak | L56 — the hot/cold phase expands a binary placement rule into a 22-line diagram and example block; a compact rule plus a cold evidence pointer would preserve behavior and reduce the 164-line body. |
| Native parity | pass | L14 — states directly that native drafting can produce a SKILL.md, while this workflow earns its slot through Q0 refusal, overlap control, hot/cold placement, manifest-driven sync, and route verification. |
| Granularity | pass | L18 — evaluation remains a mode of the creator because generation and judgment share the same scorecard, hash contract, and completion checks; a separate evaluator surface would duplicate that core. |
| Verbs conformance | pass | L156 — foreign routing/runtime claims must map to the current contract, while stack extensions and advisory audit metadata are explicitly preserved as valid. |

## Why it's good

The workflow prevents skill sprawl through explicit refuse-before-build gates: Q0 refusal, out-of-scope precedent, full RESOLVER comparison, and subtract-first. Registration is unambiguous: update `manifest.toml`, run `scripts/verbs sync`, never hand-edit generated JSON. Two live entry points—creation and `--eval`—each with a clear completion contract and no synonyms consuming context.

## Top fixes

(None; the skill passes all axes and reflects current fixes: concise live branches and native delta plainly stated.)

## Behavioral cases

- trigger `create a skill for deployment review` → apply Q0, out-of-scope precedent, full RESOLVER overlap, subtract-first, hot/cold, then register through `manifest.toml` and `scripts/verbs sync`.
- trigger `skill-creator --eval ui` → score all nine axes against the current scorecard, stamp `git hash-object`, write the co-located eval, and run freshness lint.
- anti-trigger `make a one-line alias for this deterministic command` → should refuse skill creation and route to a script or helper under Q0.
- anti-trigger `manually update host loader JSON` → should NOT hand-edit generated output; update `manifest.toml` and run `scripts/verbs sync`.
