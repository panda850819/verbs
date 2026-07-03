---
name: grill
description: |
  Adversarial requirement discovery. Ask ONE question at a time, hunting for hidden
  requirements / unknown unknowns. Atomic 5-10 min tool, no brief output (just a
  confirmed/open log). Use when the user says "grill me on X", "interrogate this
  idea", "stress test this scope", "what am I missing". Skip for tasks where scope
  is already concrete. For structured-brief output, use `/office-hours` (default
  full mode) or `/office-hours --quick` (when context already loaded).
reads:
  - repo: lib/goal-mapping.md
  - repo: lib/push-once.md
  - vault: knowledge/**
writes:
  - vault: Inbox/grill-*.md
  - cli: stdout
domain: shared
classification: tool
user-invocable: false
---
# Grill

Adversarial requirement discovery. Inspired by Matt Pocock's "grill me" prompt — see [[matt-pocock-agent-coding-workflow]].

The point is NOT to fill a structured questionnaire (that's `/office-hours`). The point is to surface **unknown unknowns** by interrogating one angle at a time until the answer surprises you.

## Pre-step: Goal Mapping (recommended)

If goal mapping has not been done yet (e.g. you are running grill standalone, not after brief), run only the L1/L2/L3 identification step in `lib/goal-mapping.md`. Do not import brief-only gates or output scaffolds. Adversarial drilling lands better when the agent knows what is actually being protected — questions about edge cases hit different when L1 portability is the dominant goal vs L3 ship-this-week. Skip if user already established goal context this session.

## When to use

- Feature scope is fuzzy ("I want a points system" → backfill? retroactive? UI placement? streak rules?)
- Before writing a PRD or feeding `/office-hours --quick` (which produces a brief from the surfaced unknowns)
- When you suspect hidden constraints (compliance, migration, downstream consumers)
- User explicitly says "grill me", "stress test this", "what am I missing"

## When to skip

- Bug fix or typo
- Scope already documented (existing PRD, ticket with AC)
- User has given clear acceptance criteria
- Time-sensitive (P0 incident — just do it)

## Protocol

**ONE question at a time.** Wait for the answer. Then pick the next question based on what the answer revealed, not from a pre-baked list.

**Expect rehearsed first answers.** First reply on any axis is usually the polished version. Real answer surfaces after the second or third push. Push once minimum on every axis before switching.

**Pushback uses the 5-pattern menu in `lib/push-once.md`.** When a first reply is rehearsed / vague / unsupported, print the menu from `lib/push-once.md` (Output protocol). User picks; model uses that exact prompt as the next message. Never improvise the push without showing the menu first — that defeats the audit trail. See `lib/push-once.md` for the menu, selection rules, and anti-patterns.

**Delete-first — drill whether before how.** Before drilling scope or edges, try to delete the whole requirement: can it be removed entirely? Who owns it, and can that person waive it? Requirements from smart or senior people are the most dangerous, because you question them least; optimizing something that should not exist is the most expensive mistake. Only what survives deletion is worth the axes below.

Drill across these axes (not as a checklist — as a search space):

1. **Existence** — does this already exist partially? What's the status quo?
2. **Boundaries** — what's IN scope vs OUT? Where's the line?
3. **Retroactivity** — does this apply to existing data / users / state? Backfill?
4. **Edge cases** — what happens at zero / max / null / concurrent / offline?
5. **Stakeholders** — who else's workflow does this touch? Do they know?
6. **Failure modes** — what's the worst that can happen if this is wrong?
7. **Reversal** — how do we undo this if it turns out bad?
8. **Success signal** — how do you know it worked? What metric / observation?

For each answer:
- If the answer reveals a NEW unknown, drill into that next.
- If the answer is "I haven't thought about that", flag it and move on (don't force decisions in real time).
- If the user gives a confident answer that contradicts something earlier, surface the contradiction explicitly.

## Stopping rule

Stop when one of:
- 3 consecutive answers reveal no new unknowns
- 7+ questions answered (avoid bike-shedding)
- User triggers escape hatch (see below)

### Escape hatch (hard cap)

User signals impatience ("夠了" / "ship it" / "skip the questions" / "just do it"):

**First push-back:** acknowledge once, ask the 2 most critical remaining axes, then stop.
> "聽到。剩兩題收。"

**Second push-back (same session):** stop immediately. Write a line to the grill log:
> `Stopped at user request after Q{N}. Unprocessed axes: {list}.`
Proceed to Output. Flag unprocessed axes as OPEN_QUESTIONS in the log.

**Do NOT ask a third time.** No "are you sure?", no "one more thing". Respect the second stop.

## Output

After grilling ends, produce:

```markdown
## Grill log — <topic> — <date>

### Confirmed
- [point with answer]

### Open / deferred
- [question with "haven't thought" or "decide later" tag]

### Surfaced contradictions
- [if any]

### Recommended next step
- Feed into `/office-hours --quick` (if implementation track — produces a brief)
- Feed into PRD draft (if planning track)
- Park as memo (if not ready to act)
```

Save to:
- `Inbox/grill-<slug>-<date>.md` if topic is fresh
- Append to existing brief / PRD if drilling on a known feature

## Anti-patterns

- ❌ Asking 5 questions in one message ("also, and what about, also")
- ❌ Reading off a checklist regardless of context
- ❌ Forcing the user to decide on the spot when they say "I haven't thought about that"
- ❌ Continuing after the user signals enough
- ❌ Pretending to grill when scope is already concrete (just acknowledge and proceed)

## Relationship to other skills

- **For structured-brief output** — use `/office-hours` (default full mode) or `/office-hours --quick` (when context already loaded).
- **Before `/ship knowledge <decisions/path>` Close stage** — if you're closing a work topic and realize scope was never grilled.
