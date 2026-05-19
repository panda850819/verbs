---
name: careful
description: |
  Use when working on production code, shared infrastructure, or
  unfamiliar codebases. Adds confirmation gates before destructive
  commands (force push, rm -rf, publish, DROP).
reads:
  - repo: lib/verify-the-test-loop.md
writes:
  - cli: stdout
forbids:
  - cli: git push --force
  - cli: git reset --hard
  - cli: git clean -f
  - cli: rm -rf
  - cli: npm publish
  - cli: cargo publish
domain: shared
classification: exec
---

# Careful Mode

Adds a confirmation gate before destructive or high-risk actions.

## On Invoke

Announce: "CAREFUL mode ON. Will confirm before destructive actions."

## While Active

Before executing any of the following, pause and ask the user for explicit confirmation:

### Git
- `git push --force`, `git reset --hard`, `git clean -f`
- `git branch -D` (force delete)
- `git checkout .` or `git restore .` (discard all changes)
- `git rebase` on shared branches
- Any push to main/master

### Filesystem
- `rm -rf` on any directory
- Deleting more than 3 files at once
- Overwriting files outside the current project

### External
- Any API call that mutates external state (POST/PUT/DELETE to production)
- Publishing packages (`npm publish`, `cargo publish`)
- Deploying to production environments

### Database
- DROP, TRUNCATE, DELETE without WHERE
- Schema migrations on production

### Verification integrity (@../../lib/verify-the-test-loop.md)
- Before asking a human to manually test a build, or claiming done based
  on their manual test: prove the deployed artifact embeds the change
  (content marker / source-not-newer / pinned path / stable identity).
  Unproven ⇒ the bug is the pipeline; fix the loop, don't ask them to
  re-test. ("BUILD SUCCEEDED" is not deploy-proof.)
- Instrumentation you added not visible in their output ⇒ STOP, that is
  a pipeline alarm, not a fluke.
- 3 same-shape failures ⇒ switch abstraction / re-verify the loop, not a
  4th variant of the same approach.

## Confirmation Format

```
CAREFUL: About to {action}.
  Target: {what}
  Reversible: yes/no
  Proceed? [y/n]
```

## Stopping discipline (Lopopolo "every continue is a harness failure")

> Origin: [[brain/media/videos/lopopolo-harness-engineering-talk-personalized|Lopopolo, OpenAI 2026-05]] — *"Every time I have to type continue to the agent is like a failure of the harness to provide enough context around what it means to continue to completion."* Translated to this stack: every time the user must type `continue` / `繼續` / `keep going` / `go on` to nudge me, I (the agent) stopped without enough context. The destructive-action gates above are the *only* legit pauses; everything else is a context-pull I should have done myself.

### Self-check before stopping mid-task

Before asking the user a question that is NOT a destructive-action gate (above) and NOT a genuine external dependency (e.g., needs their credentials, their preference, their judgment call), pause and answer for yourself:

| Test | Action |
|---|---|
| Could I read another file / run a command / search code/brain to answer? | YES → do that first, do NOT ask |
| Could I make the call myself based on the project's conventions (CLAUDE.md, RESOLVER.md, existing patterns)? | YES → make it, log if uncertain, do NOT ask |
| Is the question a 1 / 2 multiple-choice where both are reasonable and only the user knows their preference? | NO defer-ask — ask, but log (see below) |
| Is the question "should I continue?" / "want me to proceed?" after I just laid out a plan? | YES → just do it. Stopping mid-flow with that question IS the failure. |

### Log genuine-ask events

When you DO have to ask (passes the self-check), append one line to:

```
$CLAUDE_PROJECT_DIR/memory/log_continue-failures.md
```

(Fall back to `~/.claude/projects/<auto-derived-slug>/memory/log_continue-failures.md` if the env var is unset. Create the file if it doesn't exist; do not create the directory — error out if the memory dir is missing, that's a deeper config issue.)

Format (one event per line, append-only, no edits):

```
YYYY-MM-DD HH:MM | <session-slug or "—"> | "<the question I asked, verbatim>" | <why I had to ask: external-dep | preference | judgment-call | unknown>
```

Example:

```
2026-05-12 15:32 | retro-week-gc-sprint | "Existence — GC scope: scan only feedback_*.md, or also reference_*.md / project_*.md?" | preference
2026-05-12 15:48 | continue-failure-sprint | "Commit + push the retro-week GC mode now?" | judgment-call
```

### Why this matters

- A "preference" or "judgment-call" log entry once is fine — that's real context only the user has.
- The same `<question pattern>` appearing 3+ times across the log is the **skill-gap signal**: the project's defaults aren't documented, so I keep having to ask. Promote it to CLAUDE.md / RESOLVER.md / a skill rule.
- `unknown` reason is the *worst* case — means I asked because I didn't think harder. That's the Lopopolo failure mode. Refactor the question into a self-resolvable one next time.

### How this is audited

`/retro-week` Phase 1.6 GC sweep reads this log alongside `memory/feedback_*.md`:

- Past 7d log entries grouped by reason → propose CLAUDE.md additions / skill anti-patterns
- Repeated `unknown` reasons → flag as skill-gap candidate
- 0 entries in 7d = either truly stable OR the agent isn't logging (check)

This closes the loop: stopping → log → weekly review → mechanism upgrade → fewer stops.

### Anti-patterns

- ❌ Asking "should I continue?" after presenting a plan — just continue
- ❌ Asking "want me to also do X?" mid-task when X is in the original ask
- ❌ Asking the user to choose A vs B when both are equally valid and reversible — pick one, log if needed
- ❌ NOT logging when you DO have to ask — defeats the audit loop
- ❌ Logging mock entries — log only real asks, not retroactive guesses

## Deactivate

User says "careful off" or starts a new session. Announce: "CAREFUL mode OFF."

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's not really production" | If it has prod data, prod users, or shared infra (DNS, OAuth, public packages), it's prod. The blast radius defines the gate, not the label. |
| "I've done this rebase a hundred times" | Muscle memory is precisely how branches get nuked. The confirm gate is 3 seconds; recovering a force-pushed branch is 30 minutes when it's recoverable at all. |
| "Force push is fine, it's my branch" | Anyone who pulled has a divergent local copy. They will silently rebase onto the wrong head and ship phantom commits. Force push to a shared remote is never local. |
| "The migration is read-only / SELECT only" | A long SELECT on a hot table acquires locks. Read-only on a replica is OK; read-only against prod primary at peak is not. |
| "I'll just `rm -rf node_modules` real quick" | Typo'd `rm -rf node_modules /` once. Confirm even when the path looks obvious — the typo lives in the half-second between intent and enter. |
| "Careful is for when I'm tired, not now" | The decision to skip the gate is itself a tiredness signal. The gate is cheap; the override is what should be expensive. |
| "I'll just ask the user one quick question to be sure" | If you can read a file or run a command to answer instead, that one quick question is a Lopopolo "continue" failure. The user's attention is more expensive than your tool calls. |
| "Asking is safer than guessing" | Sometimes. But "safer than guessing" cannot also mean "safer than checking". Check first; ask only when checking can't decide. |
