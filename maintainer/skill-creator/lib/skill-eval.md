# skill-eval — score a skill's construction

> The evaluator mechanism, consumed by `skill-creator --eval <name>` (and its Phase 7 self-check). Scores **SKILL.md construction** (predictability, no-ops, completion criteria) against the writing-great-skills scorecard — NOT the artifact a skill produces (that is repo-root `lib/quality-rubric.md`). Migrated from the retired standalone `skill-eval` skill; the generator and evaluator now bind the same SSOT under one verb.

## Steps

### 1. Load criteria → read the target

Read the co-located `writing-great-skills.md` scorecard axes. Resolve the target:
`skills/<bucket>/<name>/SKILL.md` (bucket =
engineering|productivity|writing|meta). Read it whole, plus any sibling
reference files it points at. `--eval all` fans out one sub-agent per skill
(hot/cold rule — never score the whole corpus in one hot context).

### 2. Score the axes

For each axis, return **pass / weak / fail** with exactly one cited line (`L<n>`) as evidence. A verdict with no line is not a verdict — re-read until you can cite. Default to **weak**, not pass, when uncertain; a generous scorecard is a no-op. If a second opinion disagrees on an axis, downgrade that axis to **weak** and note both reads.

Vocabulary checks from the scorecard:
- **No-op**: apply the deletion test — if removing a sentence changes no process, cite it under Pruning.
- **Sediment**: verify referenced paths, commands, features, and retired branches still exist before passing conformance.
- **Leading words**: cite compression opportunities where a pretrained concept could replace diffuse instructions.

> Second opinion (reference): for a heavily-used skill, get a cross-model read before scoring — hand the SKILL.md + the scorecard axes to `advisor` (which reaches `codex exec` / a different model). Feed any disagreement into the downgrade rule above.

### 3. Write the verdict → `eval.md`

Write `skills/<bucket>/<name>/eval.md` using the template below. Stamp `evaluated_skill_hash` with `git hash-object skills/<bucket>/<name>/SKILL.md` so `lint-eval-fresh.sh` can detect drift. Completion criterion: `eval.md` exists, every axis has a cited line, and `bash scripts/lint-eval-fresh.sh <name>` passes.

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

Grounding sample: L<n> — "<one exact quote of at least 12 characters from that SKILL.md line>"

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
| Verbs conformance | … | L<n> — … |

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
- **Ungrounded sample** — every eval carries one exact quoted SKILL.md line so
  the quote linter always exercises a real assertion instead of passing vacuously.
- **Stale eval** — editing a SKILL.md without re-running; the hash header + `lint-eval-fresh.sh` exist to catch exactly this.
