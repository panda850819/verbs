# Quality Rubric — 4-axis SSOT

> Single source of truth for cross-skill quality evaluation. Generator skills (`write`, `design-lead`) load this for self-check. Evaluator skills (`review`, `cross-modal-review`) load this as part of the gate criteria. Don't restate the rules elsewhere — link back to this file.

## Why this exists

Adapted from Prithvi Rajasekaran / Anthropic Labs ([Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-05). Mechanism: the same 4-axis rubric goes to both the generator agent and the evaluator agent. Generator knows the scoring axes upfront and steers toward them; evaluator doesn't invent its own standards and stays consistent across runs.

Without a shared SSOT, each skill drifts: `write` slop-check, `design-lead` anti-slop principle, `review` 3-pass — three separate quality theories. This rubric is the cross-cut.

## The 4 axes

### 1. Coherence
Does the output feel like one decision, or a stitch of parts? Strong coherence = voice, structure, examples, and conclusion all point the same direction. Reader doesn't have to reconcile contradictions.

- Anti-pattern: 前半像 hot take，後半像 textbook entry。Different paragraph energies.
- Anti-pattern: Bullet list of "考慮" with no ranking, leaving reader to choose.
- Positive signal: 一個 governing question 從頭貫到尾。

### 2. Originality
Is there evidence of judgment, or LLM-default surface? A human reader should recognize specific calls only this author would make.

- Anti-pattern: "在當今快速發展的 X 領域" / "值得注意的是" / 報告腔 (per `pandastack:write` slop-zh-report-tone reference).
- Anti-pattern: Symmetric bullet structures where every item is the same shape (LLM diversity collapse).
- Anti-pattern: "purple gradients over white cards" (design domain) — visible AI-default aesthetic.
- Positive signal: 一個 anti-thesis claim that competing AI defaults wouldn't make.

### 3. Craft
Technical execution. Typography of prose: sentence rhythm, transition logic, no broken cross-references. For design: spacing, hierarchy, contrast.

- Anti-pattern: 3 sentences in a row starting the same way.
- Anti-pattern: Wikilink that points to a non-existent slug.
- Anti-pattern: Code block without language tag / table without header alignment.
- Positive signal: 讀完不會回去找 "wait, what was that referring to?"

### 4. Functionality
Usability independent of aesthetics. Reader can ACT on this; user can complete the task; reviewer can find the load-bearing claim.

- Anti-pattern: TL;DR doesn't deliver a takeaway — just summarizes that the text exists.
- Anti-pattern: Recommendation without trigger condition ("consider doing X" with no "when").
- Anti-pattern: UI element user can't find or can't tell is interactive.
- Positive signal: 讀完一句話可以決定下一步要不要做。

## Weighting guidance

Default: Coherence + Originality weighted more than Craft + Functionality. Models tend to handle Craft and Functionality natively; Coherence and Originality are where AI-generated work characteristically drops.

Per-skill overrides allowed:

| Skill | Heaviest axes | Lightest |
|---|---|---|
| `pandastack:write` | Originality, Coherence | Craft (slop-check already covers) |
| `pandastack:design-lead` | Originality, Craft | — |
| `pandastack:review` (artifact review) | Functionality, Craft | — |
| `gbrain:cross-modal-review` | All 4 equally, plus skill's own Contract | — |

## How skills load this

Generator side (writing the artifact):
- Skill loads rubric at the start of generation phase.
- Generator's self-check before handoff: "Score 1-5 on each axis. Any axis < 3 → revise before passing to evaluator."

Evaluator side (reviewing the artifact):
- Skill loads rubric alongside the originating skill's Contract.
- Evaluator returns per-axis score + 1-sentence justification + 1 specific anti-pattern hit (if any).
- Hard threshold: any axis < 3 = fail the gate, send back to generator with the anti-pattern noted.

## Governance binding (Codex P2, 2026-05-23)

This rubric is NOT just exposed via pointer link — it binds to runtime moments:

1. **Generation moment** — `pandastack:write edit` and `pandastack:design-lead brief→design` MUST load rubric and self-score before declaring output ready.
2. **Review moment** — `pandastack:review` Step 5 spawns a per-rubric pass for any artifact in scope.
3. **Cross-model moment** — `gbrain:cross-modal-review` Phase 2 loads rubric as part of evaluator context, not separate.

Pointer-only references in SKILL.md without one of these binding moments = breaks the SSOT contract. Don't link without binding.

## Sources

- [Anthropic — Harness Design for Long-Running Apps (Prithvi Rajasekaran, 2026-05)](https://www.anthropic.com/engineering/harness-design-long-running-apps) — origin of the 4-criteria-shared-prompt mechanism.
- [Anthropic — Effective Harnesses for Long-Running Agents (Justin Young, 2026-04)](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — predecessor, established feature_list as evaluator artifact.
- Brain context: `ideas/pandastack-harness-camp-lessons-2026-05.md` Scaffold 1 / `topics/tech/harness-engineering-discipline-2026.md`.
