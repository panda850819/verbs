# lib/stopping-discipline.md — Lopopolo "every continue is a harness failure"

> Loaded by `careful` when a stop-to-ask is about to happen that is NOT a
> destructive-action gate.
>
> Origin: [[brain/media/videos/lopopolo-harness-engineering-talk-personalized|Lopopolo, OpenAI 2026-05]] — *"Every time I have to type continue to the agent is like a failure of the harness to provide enough context around what it means to continue to completion."* Translated to this stack: every time the user must type `continue` / `繼續` / `keep going` / `go on` to nudge me, I (the agent) stopped without enough context. The destructive-action gates in SKILL.md are the *only* legit pauses; everything else is a context-pull I should have done myself.

## Self-check before stopping mid-task

Before asking the user a question that is NOT a destructive-action gate and NOT a genuine external dependency (e.g., needs their credentials, their preference, their judgment call), pause and answer for yourself:

| Test | Action |
|---|---|
| Could I read another file / run a command / search code/brain to answer? | YES → do that first, do NOT ask |
| Could I make the call myself based on the project's conventions (CLAUDE.md, RESOLVER.md, existing patterns)? | YES → make it, log if uncertain, do NOT ask |
| Is the question a 1 / 2 multiple-choice where both are reasonable and only the user knows their preference? | NO defer-ask — ask, but log (see below) |
| Is the question "should I continue?" / "want me to proceed?" after I just laid out a plan? | YES → just do it. Stopping mid-flow with that question IS the failure. |

## Log genuine-ask events

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

## Why this matters

- A "preference" or "judgment-call" log entry once is fine — that's real context only the user has.
- The same `<question pattern>` appearing 3+ times across the log is the **skill-gap signal**: the project's defaults aren't documented, so I keep having to ask. Promote it to CLAUDE.md / RESOLVER.md / a skill rule.
- `unknown` reason is the *worst* case — means I asked because I didn't think harder. That's the Lopopolo failure mode. Refactor the question into a self-resolvable one next time.

## How this is audited

`/retro-week` Phase 1.6 GC sweep reads this log alongside `memory/feedback_*.md`:

- Past 7d log entries grouped by reason → propose CLAUDE.md additions / skill anti-patterns
- Repeated `unknown` reasons → flag as skill-gap candidate
- 0 entries in 7d = either truly stable OR the agent isn't logging (check)

This closes the loop: stopping → log → weekly review → mechanism upgrade → fewer stops.

## Anti-patterns

- ❌ Asking "should I continue?" after presenting a plan — just continue
- ❌ Asking "want me to also do X?" mid-task when X is in the original ask
- ❌ Asking the user to choose A vs B when both are equally valid and reversible — pick one, log if needed
- ❌ NOT logging when you DO have to ask — defeats the audit loop
- ❌ Logging mock entries — log only real asks, not retroactive guesses
