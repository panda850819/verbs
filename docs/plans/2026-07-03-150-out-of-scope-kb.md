---
date: 2026-07-03
issue: 150
branch: feat/150-out-of-scope-kb
type: plan
---

# Plan — out-of-scope-kb (#150)

> Rejected directions become agent-readable precedent files under docs/out-of-scope/, consulted by skill-creator before proposing new skills/abstractions. Source pattern: mattpocock/skills `.out-of-scope/`. Base: main.

### out-of-scope-kb-T01 — convention + directory
- scope: docs/out-of-scope/README.md (new)
- goal: README defines the entry format: one `<slug>.md` per rejected direction, frontmatter `decided: YYYY-MM-DD` + `source: <greppable repo location or PR/issue ref>`, body sections "What was rejected", "Why", "What would reopen it" (respecting the 30-day decision freeze). Advisory KB, not an enforcement surface.
- acceptance: file exists and documents format + purpose in <= ~40 lines
- depends-on: none
- status: todo

### out-of-scope-kb-T02 — seed entries from recorded rejections
- scope: docs/out-of-scope/*.md (4 new files)
- goal: seed exactly these, each sourced verbatim-greppable (quote or cite the exact ROADMAP.md section — no reconstruction from memory): (1) B-class TA / vault-less mode — ROADMAP.md "Out of v2 scope"; (2) hosted SaaS variant — same section; (3) vault-provider abstraction — ROADMAP.md 2026-05-07 re-audit paragraph; (4) persona layer — ROADMAP.md v1.x historical note (removed 2026-06-29, PR #100/#101).
- acceptance: 4 entry files exist; every `source:` points at a location where `grep` finds the cited text
- depends-on: out-of-scope-kb-T01
- status: todo

### out-of-scope-kb-T03 — wire consumers
- scope: skills/meta/skill-creator/SKILL.md, ROADMAP.md
- goal: skill-creator's MECE/RESOLVER check gains one explicit step: consult `docs/out-of-scope/` before proposing a new skill or abstraction; on a match, surface the precedent entry instead of proceeding. ROADMAP.md "Out of v2 scope" section gains a one-line pointer that entries are mirrored in docs/out-of-scope/. Total added text <= ~8 lines.
- acceptance: `grep -n "out-of-scope" skills/meta/skill-creator/SKILL.md ROADMAP.md` shows both wired; skill-creator eval.md regenerated if its hash covers SKILL.md
- depends-on: out-of-scope-kb-T02
- status: todo

### out-of-scope-kb-T04 — suite green
- scope: verification only
- goal: full deterministic suite passes.
- acceptance: `bash tests/lint-suite.sh` and `bash tests/run-all.sh` both report 0 failed
- depends-on: out-of-scope-kb-T03
- status: todo
