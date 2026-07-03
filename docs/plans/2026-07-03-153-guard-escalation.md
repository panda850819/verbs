---
date: 2026-07-03
issue: 153
branch: feat/153-guard-escalation
type: plan
---

# Plan — guard-escalation (#153)

> When a learning describes a recurring bug class, the close-out step proposes a structural guard (lint script / test / hook) instead of prose-only learning. Source pattern: garrytan/gbrain check:all guard-script discipline. Base: main.

### guard-escalation-T01 — review Step 7 gains the clause
- scope: skills/engineering/review/SKILL.md
- goal: in Step 7 (Write Learnings), add a guard-escalation clause: if the flaw is a bug class seen before (grep learnings for the signature) or is mechanically checkable, propose a structural guard naming the exact file it would add (`scripts/lint-<class>.sh` / `tests/<class>-test.sh` / hook under `hooks/`); propose-only, consistent with Step 7.5's propose-only stance — never auto-create the guard. <= ~7 lines.
- acceptance: `grep -in "guard" skills/engineering/review/SKILL.md` shows the clause inside Step 7; diff touches Step 7 only
- depends-on: none
- status: todo

### guard-escalation-T02 — ship Step 10 points at it
- scope: skills/engineering/ship/SKILL.md
- goal: Step 10 (Write Learnings) gains one line + a pointer to the review Step 7 wording (single source — do not duplicate the full clause).
- acceptance: `grep -in "guard" skills/engineering/ship/SKILL.md` shows the one-liner in Step 10 referencing review; <= ~3 lines added
- depends-on: guard-escalation-T01
- status: todo

### guard-escalation-T03 — eval freshness + suite green
- scope: skills/engineering/review/eval.md, skills/engineering/ship/eval.md, verification
- goal: regenerate both eval.md per the hash-stamp convention in scripts/lint-eval-fresh.sh (read the script; do not guess).
- acceptance: `bash scripts/lint-eval-fresh.sh` exits 0; `bash tests/lint-suite.sh` and `bash tests/run-all.sh` report 0 failed
- depends-on: guard-escalation-T02
- status: todo
