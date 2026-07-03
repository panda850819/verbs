---
date: 2026-07-03
issue: 149
branch: feat/149-invocation-axis
type: plan
---

# Plan — invocation-axis (#149)

> Make `user-invocable` mandatory with priced descriptions (user-invoked-only skills get short human descriptions, model-invoked keep triggers), audit all skills, add a lint so the field cannot go undeclared again. Source pattern: mattpocock/skills `.agents/invocation.md`. Base: main.

### invocation-axis-T01 — frontmatter spec: semantics + description cost rule
- scope: SKILL-FRONTMATTER.md
- goal: promote `user-invocable` from optional to required. Add a "Description cost rule" subsection: skills that are user-invoked-only (`user-invocable: true` AND not model-dispatched) carry a one-line human-facing description with trigger lists stripped; model-invoked skills keep rich "Use when / Triggers" phrasing. Add the dependency rule: a user-invoked skill's body may reference model-invoked skills, never another user-invoked one. Keep additions <= ~20 lines, match the file's existing tone.
- acceptance: `grep -n "user-invocable" SKILL-FRONTMATTER.md` shows it under required keys; the two new rules are present as named subsections
- depends-on: none
- status: todo

### invocation-axis-T02 — corpus audit: declare user-invocable on every skill
- scope: skills/*/*/SKILL.md (all SKILL.md files under skills/, excluding _deprecated)
- goal: every SKILL.md declares `user-invocable` explicitly. Decide per skill from RESOLVER.md + DISPATCH.md: a skill routed by the dispatch table or carrying "Use when"/trigger phrasing is model-invoked (keep triggers); a skill only ever typed by the user (e.g. init) is user-invoked-only — strip trigger lists from its description down to one human line, and if a stripped trigger was load-bearing for routing, confirm DISPATCH.md already carries the route (do not remove any dispatch capability). Do NOT restructure any skill body.
- acceptance: `for f in skills/*/*/SKILL.md; do grep -L "user-invocable" "$f"; done` prints nothing (excluding `skills/_deprecated/`); DISPATCH.md unchanged or only gained rows, never lost routing
- depends-on: invocation-axis-T01
- status: todo

### invocation-axis-T03 — lint: undeclared invocation axis fails the suite
- scope: scripts/lint-invocation-axis.sh (new), tests/lint-suite.sh
- goal: new lint script fails (exit 1, `FAIL:` message per offender) when any `skills/*/*/SKILL.md` outside `_deprecated/` lacks an explicit `user-invocable`; green on the audited corpus. Match the style of existing `scripts/lint-*.sh` (fail accumulation, bash 3.2-safe). Wire into tests/lint-suite.sh next to the other lint entries.
- acceptance: removing `user-invocable` from any one SKILL.md makes `bash scripts/lint-invocation-axis.sh` exit 1 naming that file (revert after checking); clean tree exits 0; the script runs inside `bash tests/lint-suite.sh`
- depends-on: invocation-axis-T02
- status: todo

### invocation-axis-T04 — suite green
- scope: verification only
- goal: full deterministic suite passes; eval freshness unaffected or regenerated where frontmatter edits changed hashed content.
- acceptance: `bash tests/lint-suite.sh` and `bash tests/run-all.sh` both report 0 failed
- depends-on: invocation-axis-T03
- status: todo
