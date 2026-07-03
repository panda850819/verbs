---
date: 2026-07-03
issue: 152
branch: feat/152-debug-red-gate
type: plan
---

# Plan — debug-red-gate (#152)

> Two tactics from mattpocock/skills diagnosing-bugs land in the debug skill: a red-capable loop gate ending the diagnosis phase, and tagged instrumentation for one-grep cleanup. Base: main.

### debug-red-gate-T01 — the two overrides
- scope: skills/engineering/debug/SKILL.md, skills/engineering/debug/lib/diagnosis.md
- goal: (a) add to the Override section: diagnosis may only end when you can name ONE already-run command that is red-capable (can fail), deterministic, fast, and agent-runnable — with its output seen; "I understand the bug" without that command is not diagnosis-done. (b) add the instrumentation tag convention: every temporary debug print/log line carries a shared tag like `[DEBUG-a4f2]` so post-fix cleanup is one grep and leftovers are impossible to miss. Put (b) next to the existing instrument-first lore in lib/diagnosis.md if that is where instrumentation guidance lives; keep SKILL.md additions terse, matching the existing override phrasing style. Total added text <= ~15 lines across both files.
- acceptance: `grep -in "red-capable\|DEBUG-" skills/engineering/debug/` hits both tactics; diff shows no restructuring of existing phases
- depends-on: none
- status: todo

### debug-red-gate-T02 — eval freshness + suite green
- scope: skills/engineering/debug/eval.md, verification
- goal: regenerate debug's eval.md per the hash-stamp convention in scripts/lint-eval-fresh.sh (read the script; do not guess).
- acceptance: `bash scripts/lint-eval-fresh.sh debug` exits 0; `bash tests/lint-suite.sh` and `bash tests/run-all.sh` report 0 failed
- depends-on: debug-red-gate-T01
- status: todo
