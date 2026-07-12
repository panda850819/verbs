---
name: ship
description: |
  Close completed code work through test, commit, push, and PR. Use when asked
  to "ship", "create PR", or publish the current branch. To hand unfinished
  work to Codex, use handover.
reads:
  - repo: "**"
  - repo: CLAUDE.md
  - repo: AGENTS.md
  - repo: docs/briefs/**
  - repo: docs/learnings/**
  - skill: lib/learning-format.md
  - skill: lib/trigger-first-skill-evolution.md
  - skill: lib/quote-gate.md
  - skill: lib/rationalizations.md
  - cli: git
writes:
  - repo: "**"
  - cli: git commit
  - cli: git branch
  - cli: git tag
  - cli: git push
  - cli: gh pr create
  - cli: gh release create
  - cli: stdout
forbids:
  - cli: git push --force
  - cli: git push origin main
domain: shared
classification: exec
user-invocable: false
---
# Ship

`/ship` closes completed code work through a pull request. Knowledge-note
lifecycle and external publication remain host concerns. You already know how
to write a commit; this skill is the gate sequence, not the coaching.

## Gates (in order, none skippable silently)

1. **Config** — read the `## verbs` block from `CLAUDE.md` or `AGENTS.md` for
   the test command, tag format, and release preference.
2. **Pre-flight** — `git pull`; run the project's test/build command and STOP
   on failure with the output; inspect `git diff --stat`,
   `git log origin/{main}..HEAD --oneline`, and the current branch.
3. **Pitfall ack** — search `{learnings_dir}` for `type: pitfall` entries
   touching changed files; a match must be listed and acknowledged before
   proceeding.
4. **Scope check** — if a brief for this branch exists in `docs/briefs/`,
   compare the current full diff against its Scope In/Out and the diff at
   review time. Print `Scope: ON TRACK`, or `SCOPE DRIFT: [...]` /
   `POST-REVIEW CHANGES: [...]` and ask before proceeding. No brief → still
   warn on commits made after the last `/review` this session.
5. **Review gate** — if `/review` has not run on the current diff this
   session, warn: "Review not run. Run /review first?" Proceed only on an
   explicit skip.
6. **Branch before commit (hard rule)** — never push to main/master; always
   ship via PR. On main → create `fix/*` / `feat/*` / `refactor/*` BEFORE
   staging; a branch created after the commit still advances the local
   default branch.
7. **Commit** — stage relevant files only (never `git add -A`); conventional
   message `type(scope): description`; empty `git diff --cached` after
   staging → report and skip the commit; never amend, never skip hooks.
8. **Tag / release (config-gated)** — `tag: semver` → derive the bump from
   commits (feat = minor, fix = patch) and tag; `release: true` → GitHub
   Release from the tag with generated notes. Otherwise skip both.
9. **Push + PR + closure evidence** — push with `-u` (plus tags if created);
   `gh pr create` with a title under 70 chars and a what/why/how-to-test
   body. Done means the PR URL and pushed commit/branch are printed. Missing
   delivery evidence → name the gap and do not claim done.

## Learning candidate

Emit ONE candidate only when a concrete artifact surfaced during this ship (a
test that caught a subtle bug, a deploy pattern, a CI gotcha) — fields per
`lib/learning-format.md`, quotes gated by `@lib/quote-gate.md`; storage
belongs to the host/project. If a flaw maps to an existing Verbs skill —
matched against that skill's anti-pattern/checklist table, not its trigger
keywords — emit one `skill-edit candidate: <skill> — <missing check>` line for
the host's session-end audit (see `lib/trigger-first-skill-evolution.md`).
Propose-only: never edit the target skill here. Nothing surfaced → skip
silently.

## Common Rationalizations

Anti-bypass table tying each ship shortcut to the failure it causes: `@lib/rationalizations.md`.
