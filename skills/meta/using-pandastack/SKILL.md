---
name: using-pandastack
description: Use at the start of any session — establishes the cognitive contract that pandastack skills must be checked BEFORE any response or action, including clarifying questions.
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a pandastack skill might apply to what the user is about to do, you MUST invoke the skill via the `Skill` tool before responding.

This is not negotiable. Skills override default behavior. Rationalizing your way out of a skill check is the failure mode this contract exists to prevent.
</EXTREMELY-IMPORTANT>

## Why this file exists

pandastack ships dozens of skills (including documented lifecycle compositions). The surface area is too large for ad-hoc invocation. Without a forcing function, the model defaults to "I'll just answer directly" and the skills never run. This file is the forcing function.

The failure mode this exists to prevent (observed across many sessions): writing code without running `careful` for prod paths, shipping without `review`, finishing a knowledge note without `/ship knowledge`. The skills exist; they just don't get invoked unless something pressures the check.

## Instruction priority

1. **User's explicit instruction** (this turn's message, project CLAUDE.md / AGENTS.md) — highest
2. **pandastack skill content** — overrides default behavior when relevant
3. **Default Claude Code behavior** — lowest

If the user says "skip the review, just commit", do that. The contract is not a tyrant.

## Lifecycle → skill map

When the current task matches one of these signals, the corresponding skill must be **invoked this turn — or you must record an explicit skip-reason this turn**. "I checked and decided no" is not a done-state; an unrecorded skip is a skipped check.

| Signal | Invoke (or record an explicit skip-reason this turn) |
|---|---|
| About to write/edit code in any production / shared-infra path | `pandastack:careful` (gate), then dev flow |
| Bug fix / feature / refactor (3+ files OR new abstraction) | `pandastack:grill` or `pandastack:office-hours` first, NOT direct edits |
| About to commit | `pandastack:review` first, THEN `pandastack:ship` |
| Finished a knowledge note (`knowledge/<domain>/<note>.md` style) | `pandastack:ship knowledge <path>` to Close + Extract + Backflow |
| Finished a work topic with a decision to log | `pandastack:ship knowledge <decisions/path>` (decision-note variant; replaces v2.1 `/work-ship`) |
| Researching an unfamiliar concept | `pandastack:grill` (adversarial scope lock) → ad-hoc fetch (`gh`/`WebFetch`/brain query) → `pandastack:ship knowledge` |
| Don't know which skill | Read `RESOLVER.md` at pandastack repo root |

When a skill applies, announce: "Using `pandastack:<skill>` to <purpose>" — then invoke the `Skill` tool. Do not read `SKILL.md` files directly with the Read tool.

## Session opener ritual (5-step, < 5 sec)

Run at the start of any new session that touches code, brain pages, or shared infra. Skip for Hermes cron / background jobs / read-only Q&A. Adapted from Justin Young / Anthropic ([Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)) — cold-context agents drift without a forced ritual.

```
1. pwd + git status                        confirm cwd, surface uncommitted work
2. ls -t sessions/*.md 2>/dev/null | head -3   what did the last 3 sessions touch?
3. git log --oneline -10                   recent commit shape — am I on a thread?
4. autocommit health (1-liner)             is the cron loop alive? launchd ok?
5. surface 異常 only                        silent when healthy, loud when broken
```

Default behavior: run silently, output ONLY on anomaly. Healthy session = zero lines printed. Failure modes to surface:
- Uncommitted changes from a prior session you don't remember
- Autocommit cron stuck > 2 hours (launchd dead, or git push failing silently)
- HEAD detached, or on an unexpected branch

When user explicitly wants a deep state-restore (returning after long absence, post-dream consolidation), do a full session-start sync instead: a `gbrain query` for in-progress / open / blocked items, plus `pandastack:checkpoint` (resume mode) to reload the last saved working state. The 5-step ritual covers warm sessions, not cold revivals.

## Loop guard (3-strike rule)

Same file / same diagnostic / same fix variant tried 3+ times → STOP, do not attempt a 4th. When triggered, load `skills/meta/using-pandastack/lib/loop-guard.md` for the stop-and-re-grill procedure.

## Harness evolution rule

When creating, improving, splitting, merging, or reviewing skills, load `skills/meta/using-pandastack/lib/harness-evolution.md` (trigger-first posture; extract only on repeated evidence).

## Red flags (rationalizations to STOP on)

These thoughts mean you are about to skip a skill that applies. Stop and check.

| Thought | Reality |
|---|---|
| "This is just a small change" | Small changes are how prod gets broken. Run `careful` if it touches a prod path. |
| "I'll just answer directly" | Questions are tasks. The skill might tell you a better way to answer. |
| "The user probably knows what they want" | The user set up these skills *because* default behavior drifts. Trust the contract. |
| "I'll do the skill check after I look at the code" | Skill check is BEFORE exploration. Skills tell you HOW to explore. |
| "It's just a typo / rename" | Then it takes 10 seconds. Run it. |
| "Running review/ship feels like overkill" | The skill itself decides if it's overkill. Invoke it and let it short-circuit. |
| "I'll bundle the learning extract for later" | Later = never. `/ship knowledge` Stage 2 is the contract. |
| "I'll skip ship-log, the commit message captures it" | Ship logs aggregate; commit messages do not. |
| "I remember what `/ship knowledge` does" | Skills evolve. Read the current version via the Skill tool. |
| "The user said 'just do X'" | "Just do X" is WHAT, not HOW. Skills handle HOW. |
| "This is meta / harness work, not real work" | Harness work goes through the same gates. Especially `careful` on shared config. |
| "There's no exact match" | Pick the closest. Mismatch is fine; skipped check is not. |

## When NOT to invoke

- Reading code or files for orientation only (no edits planned)
- One-line answer to a factual question that does not trigger any lifecycle
- Subagent context (handled by `<SUBAGENT-STOP>` above)
- User explicitly says "skip skills this turn" or "just do X, no skill"

## Overlay extension

A personal / org overlay may be appended to this contract by the SessionStart hook. If no overlay loads, this public contract still works on its own — the lifecycle map degrades to abstract guidance. Install-time reference (resolution order, hook-logging contract, what the overlay adds): `skills/meta/using-pandastack/lib/overlay-extension.md`.
