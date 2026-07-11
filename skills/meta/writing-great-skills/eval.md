---
type: skill-eval
skill: writing-great-skills
bucket: meta
evaluated_skill_hash: 018db389a706f6c93d6e0161a3753d5e95066239
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — writing-great-skills

**Verdict: SOLID.** Its leading virtue is a compact construction vocabulary tied to one nine-axis scorecard and one current evaluator entry point, `skill-creator --eval`, with native parity clearly applied to the scorecard itself.

Grounding sample: L12 — "A skill exists to wrangle determinism out of a stochastic system."

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L12 — predictability is defined as repeating the same process rather than forcing identical output, giving every later rule one root objective. |
| Description / invocation | weak | L4 — the hot description combines four authoring branches, an evaluator reach clause, and an artifact-rubric boundary in one dense line; the boundary can move to the body without weakening dispatch. |
| Completion criteria | pass | L92 — the verdict contract requires a leading virtue plus one to three line-cited fixes, giving evaluator consumers a checkable output shape. |
| Information hierarchy | pass | L35 — the three-tier ladder distinguishes in-skill steps, in-skill references, and external references by immediacy, then ties each step to a checkable completion criterion. |
| Leading words | pass | L58 — the section defines pretrained anchors, explains their invocation and execution roles, and demonstrates how one can collapse diffuse instructions. |
| Pruning | pass | L78 — the scorecard is an index back to the defining sections rather than a second copy of every criterion, and it names only `skill-creator --eval` as evaluator. |
| Native parity | pass | L75 — the section applies its own test directly: generic model guidance can draft a skill, while Verbs adds a checkable nine-axis scorecard plus local hot/cold and conformance rules. |
| Granularity | pass | L14 — definitions stay cold in the co-located glossary while criteria and the scorecard remain together in one reference skill, preserving a single construction SSOT. |
| Verbs conformance | pass | L90 — required frontmatter is valid, direct glossary and repo-lib pointers resolve, hot/cold is explicit, and the longer body is earned by the complete nine-axis SSOT. |

## Why it's good

The skill turns subjective construction advice into reusable concepts: context load, cognitive load, information hierarchy, completion criteria, leading words, and named failure modes. Each scorecard axis points back to its defining section. The native-parity section names both the baseline (generic model guidance) and the delta (checkable scorecard + Verbs conformance), modeling the very test it teaches.

## Top fixes

(None; the skill passes all axes and reflects current fixes: scorecard self native-parity clearly demonstrated.)

## Behavioral cases

- trigger `how should I structure or prune this SKILL.md?` → consult invocation, hierarchy, splitting, pruning, leading-word, failure-mode, and native-parity sections before editing.
- trigger `skill-creator --eval gatekeeper` → use this file as the criteria SSOT and return all nine axes with one cited target line each.
- anti-trigger `score this article or design artifact` → should NOT use this construction scorecard; route artifact quality to `lib/quality-rubric.md`.
- anti-trigger `create the whole skill` → should NOT own generation; route creation to `skill-creator`, which consults this scorecard.
