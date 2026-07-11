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
  - repo: lib/learning-format.md
  - repo: lib/trigger-first-skill-evolution.md
  - repo: skills/engineering/ship/lib/quote-gate.md
  - repo: skills/engineering/ship/lib/rationalizations.md
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
lifecycle and external publication remain host concerns.

## Git delivery

Test, commit, create PR. One command from "code done" to "PR open".

### Step 0: Read Config

Read verbs config from `CLAUDE.md` or `AGENTS.md` (whichever the project uses) for: test command, tag format, release preference.

### Step 1: Pre-flight

1. Run `git pull` to sync with remote (avoid conflicts from auto-backup).
2. Run the project's test/build command. If it fails, stop and report.
3. Run `git diff --stat` to see uncommitted changes.
4. Run `git log origin/{main}..HEAD --oneline` for commit history.
5. Check current branch: `git branch --show-current`.

### Step 2: Load Learnings

Search `{learnings_dir}` for `type: pitfall` related to the changed files.
If any matched pitfall touches a changed file, list it and require ack before proceeding; else skip.

### Step 3: Scope Check

If a brief exists for this branch (check `docs/briefs/`):
1. Read the brief's **Scope > In/Out** sections.
2. Get the **current** full diff: `git diff origin/{main} --stat`.
3. Compare against the brief scope. Flag any files or features outside stated scope.
4. Also compare against the diff at review time (if `/review` was run earlier). Check for **post-review additions**.
5. Output:
   - "Scope: ON TRACK" if all changes match the brief and nothing was added post-review.
   - "SCOPE DRIFT: [description]" for each out-of-scope change.
   - "POST-REVIEW CHANGES: [files]" for any files modified after the last review.
   Ask user to confirm before proceeding if either is detected.

If no brief exists, still check for post-review additions:
1. Run `git log --oneline --since="1 hour ago"` to see recent commits.
2. If there are commits after the last `/review` in this session, list them and warn.

If neither brief nor review history exists, skip silently.

### Step 4: Review Gate

If `/review` has NOT been run on the current diff in this session:
1. Warn: "Review not run. Run /review first?"
2. If user says skip, proceed. Otherwise run review.

### Step 5: Branch (mandatory, before commit)

**Never push directly to main/master.** Always ship via PR.

1. If on main/master, create a feature branch:
   - `fix/*` for bug fixes
   - `feat/*` for features
   - `refactor/*` for refactoring
2. If already on a feature branch, stay on it.

Do not stage or commit until this branch gate passes. Creating the branch after
the commit would still advance the local default branch.

### Step 6: Commit

If there are uncommitted changes:
1. Analyze the diff
2. Generate a conventional commit message (`type(scope): description`)
3. Stage relevant files (never `git add -A`)
4. Stop if `git diff --cached` is empty after staging (nothing to commit) — report and skip the commit.
5. Commit (don't amend, don't skip hooks)

### Step 7: Tag (if configured)

If verbs config has `tag: semver`:
1. Read current version from package.json, VERSION, or latest git tag
2. Determine bump type from commits (feat = minor, fix = patch)
3. Create tag: `git tag v{version}`

If `tag: none`: skip.

### Step 8: Push + PR

1. Push the branch with `-u` (and tags if created)
2. Create PR with `gh pr create`:
   - Title: short, under 70 chars
   - Body: what changed, why, how to test
   - If the host/project persisted a learning from this session, mention it
3. Return the PR URL.
4. Closure evidence before claiming done: print the PR URL and pushed
   commit/branch. Ticket or project-state transitions belong to the host; if
   required delivery evidence is missing, name the gap and do not claim done.

### Step 9: Release (if configured)

If verbs config has `release: true`:
- Create GitHub Release from the tag
- Auto-generate release notes from commits

If `release: false`: skip.

### Step 10: Surface Learning Candidates (if applicable)

Emit a learning candidate ONLY if a concrete artifact surfaced during this ship:
a test that caught a subtle bug, a deploy pattern worth remembering, or a CI
gotcha. If none surfaced, skip. Use the `lib/learning-format.md` fields in the
response and apply the quote gate before quoting:
`@skills/engineering/ship/lib/quote-gate.md`. Do not persist the candidate;
storage belongs to the host/project.

For recurring or mechanically checkable bug classes, apply review Step 7's guard-escalation wording: propose the exact guard file only, never create it here.

**Route the flaw back (propose-only).** If a flaw surfaced during ship maps to an existing Panda Verbs skill — matched against that skill's anti-pattern / checklist table, not just its trigger keywords — emit one `skill-edit candidate: <skill> — <missing check>` line into the session-end learning-candidate audit when the host provides one. See `lib/trigger-first-skill-evolution.md`. Propose-only: never edit the target skill here, and never during an autonomous build. This routes the catch back to strengthen the skill that let it through, instead of leaving only a passive pitfall.

## Common Rationalizations

Anti-bypass table tying each ship shortcut to the failure it causes: `@skills/engineering/ship/lib/rationalizations.md`.
