---
date: 2026-07-03
issue: 151
branch: feat/151-failure-mode-vocab
type: plan
---

# Plan — failure-mode-vocab (#151)

> Absorb mattpocock/skills writing-great-skills vocabulary (sediment, sprawl, no-op, premature completion, leading words, information-hierarchy ladder) into the pandastack construction-quality SSOT and the skill-eval scorecard. Base: main.

### failure-mode-vocab-T01 — SSOT gains the vocabulary
- scope: skills/meta/writing-great-skills/SKILL.md (and its references/ file if the skill splits hot body from cold reference — put definitions where existing depth lives)
- goal: add six concepts, one-line definition each, attributed to mattpocock/skills: sediment (stale instructions accumulating across edits), sprawl (scope creep into other skills' territory), no-op (a sentence whose deletion changes no behavior — include the per-sentence deletion test), premature completion (declaring done before the artifact is verifiable), leading words (compact pretrained concepts like "tight", "tracer bullet" that anchor behavior in few tokens), information-hierarchy ladder (in-skill step -> in-skill reference -> external reference). Definitions are one-liners, not essays.
- acceptance: `grep -in "sediment\|sprawl\|no-op\|leading words" skills/meta/writing-great-skills/` hits all four core terms; added text <= ~25 lines total
- depends-on: none
- status: todo

### failure-mode-vocab-T02 — scorecard consumes it
- scope: skills/meta/skill-eval/SKILL.md
- goal: scorecard gains checks keyed to the new vocabulary: no-op sentences (per-sentence deletion test on a sample), sediment (instructions referencing retired paths/features — verify referenced paths exist), and compression opportunities via leading words. No existing scorecard item removed or weakened.
- acceptance: `grep -in "no-op\|sediment" skills/meta/skill-eval/SKILL.md` shows the new checks; existing checks intact (git diff shows additions only in the scorecard section)
- depends-on: failure-mode-vocab-T01
- status: todo

### failure-mode-vocab-T03 — eval freshness + suite green
- scope: skills/meta/writing-great-skills/eval.md, skills/meta/skill-eval/eval.md, verification
- goal: regenerate the co-located eval.md for both edited skills per the hash-stamp convention read from scripts/lint-eval-fresh.sh (read the script first; do not guess the stamp format).
- acceptance: `bash scripts/lint-eval-fresh.sh` exits 0; `bash tests/lint-suite.sh` and `bash tests/run-all.sh` report 0 failed
- depends-on: failure-mode-vocab-T02
- status: todo
