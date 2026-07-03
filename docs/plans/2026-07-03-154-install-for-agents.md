---
date: 2026-07-03
issue: 154
branch: docs/154-install-for-agents
type: plan
---

# Plan — install-for-agents (#154)

> A repo-root INSTALL_FOR_AGENTS.md an agent can execute end-to-end: probe preconditions, install per runtime, verify, fix failures from a symptom table. The missing first-session-walkthrough piece of ROADMAP v2 public-ready. Source pattern: garrytan/gbrain INSTALL_FOR_AGENTS.md. Base: main.

### install-for-agents-T01 — the document
- scope: INSTALL_FOR_AGENTS.md (new, repo root)
- goal: imperative agent steps in four sections: (1) preconditions probe — which runtime am I in (Claude Code / Codex / other), git present, plugin marketplace reachable; (2) install path per runtime — Claude Code `/plugin install pandastack@pandastack`, Codex equivalent, skill-dir fallback — reusing `scripts/bootstrap.sh` + `manifest.toml` tier model, never inventing a parallel install path (read both files first and document what exists); (3) verification — run the offline checks (`bash tests/lint-suite.sh` or the public-safe subset) and interpret pass/fail; (4) failure table — symptom -> paste-ready fix command. Public-safe: no Panda-private paths (no `~/site/knowledge`, gog, bird, gbrain CLI), no brain assumptions. EVERY command in the doc must be run while writing to confirm it works in this repo today — no phantom commands.
- acceptance: file exists; `grep -n "site/knowledge\|gog\|bird\|gbrain" INSTALL_FOR_AGENTS.md` returns nothing; each command in the doc was executed during authoring (verification_summary lists them)
- depends-on: none
- status: todo

### install-for-agents-T02 — README pointer
- scope: README.md
- goal: one line near the top pointing agents at INSTALL_FOR_AGENTS.md. Nothing else in README changes.
- acceptance: `head -30 README.md | grep INSTALL_FOR_AGENTS` hits; diff is one line
- depends-on: install-for-agents-T01
- status: todo

### install-for-agents-T03 — suite green
- scope: verification only
- goal: full deterministic suite passes.
- acceptance: `bash tests/lint-suite.sh` and `bash tests/run-all.sh` report 0 failed
- depends-on: install-for-agents-T02
- status: todo
