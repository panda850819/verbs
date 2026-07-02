---
date: 2026-07-02
issue: 145
branch: feat/145-audit-remediation
type: plan
---

# Plan — 145-audit-remediation (#145)

> Four file-scoped units from the 2026-07-02 harness audit + 23-day session-log mining (1,034 human turns, 30 interruptions). Each unit closes a measured recurring correction. Base: origin/main (2df8dee).

### audit-remediation-T01 — DISPATCH.md delegation row
- scope: DISPATCH.md
- goal: add one routing row to the dispatch table (match existing `| Signal | Invoke |` style): signal = mechanical, file-scoped build units with a locked spec (rote edits, no open judgment); invoke = delegate — `handover` (Codex) or a subagent; the main model orchestrates, it does not implement. Keep the row wording compact like the neighbors. (Pain: 10 corrections "自己下場寫 / 委託給 codex", 6 on 07-02 alone.)
- acceptance: `grep -E 'file-scoped build units' DISPATCH.md` prints exactly one table row and that row contains `handover`
- depends-on: none
- status: todo

### audit-remediation-T02 — session-start decision-discipline lines
- scope: hooks/session-start
- goal: in the injected IMPORTANT block that hooks/session-start emits, add AT MOST 3 lines (net) carrying two rules: (a) decide-and-execute — pick the single best recommendation and run it directly; no A/B/C option menus; (b) an approved plan runs to ship without stopping at step boundaries. Keep the script's existing quoting/JSON envelope intact — the hook must still emit valid output. (Pain: 13 option-menu bounce-backs + 13 checkpoint-stall re-prompts; these rules exist in AGENTS.md but body-text rules get ignored, injection has salience.)
- acceptance: `bash -n hooks/session-start` exits 0; `grep -c 'A/B/C' hooks/session-start` ≥ 1; `grep -cE 'step boundar' hooks/session-start` ≥ 1; `git diff origin/main --numstat -- hooks/session-start` shows ≤ 3 added lines
- depends-on: none
- status: todo

### audit-remediation-T03 — ship + sprint closure evidence checklist
- scope: skills/engineering/ship/SKILL.md, skills/engineering/sprint/SKILL.md
- goal: the closure/ship step in each skill must print evidence before claiming done: ticket/PR URL and the state transition performed (e.g. Linear/GitHub issue status moved, PR opened). No evidence → not done; the skill says what is missing instead. Add as a compact checklist item inside the existing closure stage, matching each file's structure — do not add a new stage. (Pain: 13 "你有開票嗎 / linear 狀態 updated?" audits.)
- acceptance: `grep -il 'evidence' skills/engineering/ship/SKILL.md skills/engineering/sprint/SKILL.md | wc -l` prints 2; `grep -lE 'ticket/PR URL|PR URL' skills/engineering/ship/SKILL.md skills/engineering/sprint/SKILL.md | wc -l` prints 2
- depends-on: none
- status: todo

### audit-remediation-T04 — skill-creator subtract-first gate
- scope: skills/meta/skill-creator/SKILL.md
- goal: add a hard gate ahead of skill creation (extend the existing MECE check, do not duplicate it): the new skill must name which existing skill it absorbs/replaces, or why extending an existing one was rejected; if neither can be named, do not create the skill. (Pain: 18 structure-bloat pushbacks, the top mined theme.)
- acceptance: `grep -icE 'subtract-first|absorbs?/replaces?|absorb' skills/meta/skill-creator/SKILL.md` ≥ 1 and the gate text appears before/within the MECE step, verifiable by `grep -nE 'subtract-first' skills/meta/skill-creator/SKILL.md`
- depends-on: none
- status: todo

### audit-remediation-T05 — suite green
- scope: verification only, no new files
- goal: the deterministic suite passes with the edits. Known caveat: if `lint-eval-fresh` fails ONLY because the edited skills' co-located eval.md went stale, do NOT hand-edit eval.md — report it as an issue (eval regeneration happens on the orchestrator via skill-eval).
- acceptance: `bash tests/run-all.sh` reports 0 failed, or the only failures are lint-eval-fresh staleness on the three edited skills (reported, not patched)
- depends-on: audit-remediation-T01, audit-remediation-T02, audit-remediation-T03, audit-remediation-T04
- status: todo
