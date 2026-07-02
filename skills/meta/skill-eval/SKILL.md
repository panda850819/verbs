---
name: skill-eval
description: |
  Score a skill's construction quality against the writing-great-skills scorecard and write a co-located eval.md verdict. Use when asked to eval/score a skill, or to regenerate its eval after editing. Evaluator counterpart to skill-creator (which builds) — both bind the same writing-great-skills SSOT.
version: 1.0.0
type: skill
---

# Skill Eval

The evaluator half of skill construction. `skill-creator` builds and self-checks; `skill-eval` judges an existing skill and leaves a greppable verdict next to it. Criteria SSOT: [`../writing-great-skills/SKILL.md`](../writing-great-skills/SKILL.md) — load its **scorecard** section; do not invent axes.

Scope note: this scores the **SKILL.md construction** (predictability, no-ops, completion criteria), NOT the artifact a skill produces — that is repo-root [`lib/quality-rubric.md`](../../../lib/quality-rubric.md).

## Invoke

`/skill-eval <name>` evaluates one skill. `/skill-eval all` fans out over every skill in `skills/<bucket>/<skill>/` (dispatch one sub-agent per skill; hot/cold rule — never score the whole corpus in one hot context).

## Steps

### 1. Load criteria → read the target

Read the writing-great-skills scorecard axes. Resolve the target: `skills/<bucket>/<name>/SKILL.md` (bucket = engineering|productivity|writing|meta). Read it whole, plus any sibling reference files it points at.

### 2. Score the axes

For each axis, return **pass / weak / fail** with exactly one cited line (`L<n>`) as evidence. A verdict with no line is not a verdict — re-read until you can cite. Default to **weak**, not pass, when uncertain; a generous scorecard is a no-op. If you took a second opinion (see below) and the two reads disagree on an axis, downgrade that axis to **weak** and note both reads.

> Second opinion (reference): for a heavily-used skill, get a cross-model read before scoring — hand the SKILL.md + the scorecard axes to Codex (`codex exec`) or `gbrain:cross-modal-review`. Feed any disagreement back into the rule above.

### 3. Write the verdict → `eval.md`

Write `skills/<bucket>/<name>/eval.md` using the template below. Stamp `evaluated_skill_hash` with `git hash-object skills/<bucket>/<name>/SKILL.md` so `lint-eval-fresh.sh` can detect when the skill drifts past its eval. Completion criterion: `eval.md` exists, every axis has a cited line, and `bash scripts/lint-eval-fresh.sh <name>` passes.

## eval.md template

```markdown
---
type: skill-eval
skill: <name>
bucket: <bucket>
evaluated_skill_hash: <git hash-object SKILL.md>
evaluated_at: <YYYY-MM-DD>
rubric: writing-great-skills@1.1.0
---

# Eval — <name>

**Verdict: STRONG | SOLID | WEAK.** <one line: the skill's leading virtue — why it is good>

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass/weak/fail | L<n> — <why> |
| Description / invocation | … | L<n> — … |
| Completion criteria | … | L<n> — … |
| Information hierarchy | … | L<n> — … |
| Leading words | … | L<n> — … |
| Pruning | … | L<n> — … |
| Native parity | … | L<n> — … |
| Granularity | … | L<n> — … |
| pandastack conformance | … | L<n> — … |

## Why it's good
<2–3 sentences: the load-bearing strengths>

## Top fixes
1. <specific, line-cited>
2. …

## Behavioral cases
- trigger `<phrase>` → expected process: <…>
- anti-trigger `<phrase>` → should NOT fire (routes to <other skill>)
```

## Anti-patterns

- **Rubber-stamping** — all-pass with vague evidence. If nothing is weak, you did not read hard enough.
- **Scoring the artifact, not the skill** — judging the prose a skill writes instead of how the SKILL.md is built. Wrong rubric.
- **Uncited verdicts** — an axis verdict with no `L<n>` is unfalsifiable; redo it.
- **Stale eval** — editing a SKILL.md without re-running; the hash header + `lint-eval-fresh.sh` exist to catch exactly this.
