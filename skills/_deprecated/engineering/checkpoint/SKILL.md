---
name: checkpoint
description: |
  Save, resume, or list working state snapshots. Captures git state,
  decisions made, remaining work. Use when pausing work, switching
  context, before a long session break, or to list saved checkpoints.
user-invocable: false
---

# Checkpoint

## Detect Command

Parse the user's input:

- `/checkpoint` or `/checkpoint "{next-session focus}"` → **Save** (the optional focus arg tailors Remaining Work, Suggested Skills, and Resume Hint toward that goal)
- `/checkpoint resume` → **Resume**
- `/checkpoint list` → **List**

Read pandastack config from `CLAUDE.md` or `AGENTS.md` (whichever the project uses).

## Save (default)

1. Gather current state:
   ```bash
   git branch --show-current
   git log origin/{main}..HEAD --oneline
   git status --short
   git diff --stat
   ```

2. Write a checkpoint file to `docs/checkpoints/{branch-slug}-{YYYY-MM-DD}.md`:

   ```markdown
   ---
   branch: {branch name}
   created: {YYYY-MM-DD HH:MM}
   status: paused | blocked | ready-to-ship
   ---

   ## State
   - Branch: `{branch}`
   - Commits ahead of {main}: {N}
   - Uncommitted changes: {yes/no, summary}

   ## Decisions Made
   {List key decisions from this session — architecture choices,
   trade-offs accepted, user confirmations. Extract from conversation
   context, not invented.}

   ## Remaining Work
   {What's left to do on this branch. Be specific: file names,
   function names, test cases.}

   ## Blockers
   {Any blockers encountered. "None" if clear.}

   ## Suggested Skills
   {Which pandastack skills the resuming agent should invoke first, and why —
   one line each. e.g. `/sprint --continue {project-slug}` if this maps to a
   project; otherwise name the resume step directly, e.g. `/review` before
   ship. Routes the resume agent instead of forcing it to re-derive the next
   move.}

   ## Resume Hint
   {One sentence: what to do first when resuming. If a focus arg was passed,
   anchor the hint to it.}
   ```

   **Reference, don't duplicate.** In Decisions / Remaining / Suggested Skills,
   cite brain page paths, commit hashes, PR URLs, or plan/brief file paths —
   never re-summarize content that already lives in those artifacts. A
   checkpoint that restates a plan drifts from it; one that points to it stays
   correct.

   **Redact secrets.** Never write API keys, passwords, tokens, or PII into the
   checkpoint file.

3. If this maps to a brain project page (`projects/{slug}.md` exists), record the EVL datapoint deterministically (idempotent per-day; auto-skips METRICS for repo-backed projects, refreshing only `next`):
   ```bash
   project-state append {slug} --done {N} --open {N} --blocked {N} --next "{resume hint}"
   ```
   Best-effort — skip silently if `project-state` or the page is absent.

4. Output: "Checkpoint saved. Resume with `/checkpoint resume`."

## Resume

1. Find the most recent checkpoint for the current branch:
   ```bash
   git branch --show-current
   ```
   Then look for matching files in `docs/checkpoints/`.

2. If no checkpoint exists for this branch, fall through to the **List** branch.

3. Read the checkpoint file and output:
   ```
   RESUMING: {branch}
   Last checkpoint: {date}
   Status: {status}
   Decisions: {summary}
   Remaining: {summary}
   Resume hint: {hint}
   ```

4. After a successful resume — the RESUMING block (step 3) has printed AND the
   checkpoint file's contents are read into context — archive the file by moving
   it to `docs/checkpoints/archive/`. Archive rather than delete so a mis-fired
   resume stays recoverable.

## List

List all checkpoint files in `docs/checkpoints/`, sorted by date:

```
CHECKPOINTS:
  {branch} — {date} — {status}
  {branch} — {date} — {status}
```

If no checkpoints exist: "No checkpoints. Save one with `/checkpoint`."
