---
date: 2026-07-02
issue: 139
branch: feat/139-native-parity-axis
type: plan
---

# Plan — native-parity-axis (#139)

> The v3.2.0 earned-slot criterion (a skill deserves its slot only for lore + the reflex-override the model gets wrong despite understanding) becomes a standing scorecard axis, so each harness release turns into a checklist run over the evals instead of a re-derivation. Base: chore/v3.4.0-fable5-harness-cut (8321ff4).

### native-parity-axis-T01 — scorecard axis in writing-great-skills
- scope: skills/meta/writing-great-skills/SKILL.md
- goal: (a) add a new section "## Native parity" immediately before "## The scorecard", one short paragraph, voice-matched to the surrounding sections (bold leading words, no filler). Content to convey: a skill competes with the harness's own defaults, and the harness ships faster than the pack; **native parity** asks for the nearest native feature (built-in command, tool, or default behavior) by name, and the delta that still earns the skill its slot — the lore plus reflex-override the model gets wrong despite understanding. A skill that cannot name its delta is a cut candidate at the next harness release; re-check the axis whenever the harness ships an overlapping feature. (b) in "## The scorecard", add a `Native parity` row to the axis index pointing at the new section, and change "scores a skill on these 8 axes" to "scores a skill on these axes" (drop the count — counts drift).
- acceptance: `grep -n "Native parity" skills/meta/writing-great-skills/SKILL.md` shows the section heading AND a scorecard row; `grep -c "8 axes" skills/meta/writing-great-skills/SKILL.md` prints 0
- depends-on: none
- status: todo

### native-parity-axis-T02 — skill-eval binding
- scope: skills/meta/skill-eval/SKILL.md
- goal: read the file first; wire the native-parity axis into the scoring flow exactly the way the existing axes are wired (axis list, table template, any per-axis instructions). If a rubric version string exists (e.g. `writing-great-skills@1.0.0`), bump it to `writing-great-skills@1.1.0`.
- acceptance: `grep -ic "native.parity" skills/meta/skill-eval/SKILL.md` ≥ 1
- depends-on: native-parity-axis-T01
- status: todo

### native-parity-axis-T03 — regenerate the two evals
- scope: skills/meta/writing-great-skills/eval.md, skills/meta/skill-eval/eval.md
- goal: re-score BOTH edited skills against the now-extended scorecard, following the existing eval.md structure exactly: frontmatter (type / skill / bucket / evaluated_skill_hash / evaluated_at / rubric), verdict line, per-axis table with line-cited evidence. `evaluated_skill_hash` = `git hash-object skills/meta/<name>/SKILL.md` computed AFTER the T01/T02 edits; `evaluated_at: 2026-07-02`; `rubric: writing-great-skills@1.1.0`. Score honestly — cite real line numbers, keep verdicts defensible, do not soften existing criticisms that still apply, and score the new Native-parity axis for both skills (each must name its own nearest native feature and delta).
- acceptance: `bash scripts/lint-eval-fresh.sh writing-great-skills && bash scripts/lint-eval-fresh.sh skill-eval` both print OK
- depends-on: native-parity-axis-T02
- status: todo

### native-parity-axis-T04 — de-count "8-axis" in living docs
- scope: RESOLVER.md (~line 74), README.md (~lines 342, 421)
- goal: replace "8-axis scorecard" with "scorecard" (adjusting the sentence minimally) in these living docs, so the axis count is not a hand-synced number. Do NOT touch dated artifacts (evals/2026-06-26-skill-quality-baseline.md) or anything under skills/_deprecated/.
- acceptance: `grep -rn "8-axis" README.md RESOLVER.md CLAUDE.md DISPATCH.md` returns nothing
- depends-on: native-parity-axis-T01
- status: todo

### native-parity-axis-T05 — suite green
- scope: verification only, no new files
- goal: the whole deterministic suite passes with the edits (lint-eval-fresh is part of it via tests/lint-suite.sh).
- acceptance: `bash tests/run-all.sh` reports 0 failed
- depends-on: native-parity-axis-T03, native-parity-axis-T04
- status: todo
