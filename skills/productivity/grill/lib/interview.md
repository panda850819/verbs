# lib/interview.md — The interview protocol

> Shared module. Loaded by skills that interrogate a human to surface unknown
> unknowns. Owns HOW to interview: question cadence, pushback, what may be asked
> at all, the search space, and when to stop. It owns nothing about what happens
> afterwards — alternatives, artifacts, maps, and routing belong to the caller.
>
> Origin: extracted from `grill` (2026-07-31, issue #284). `grill` bundled the
> interview with its own close, so a skill wanting only the interview had to
> invoke all of `grill` and stop at its routing gate. `wayfinder` was the
> casualty; see the entry 4 decision note in the v1 direction map.

## When to load

Skills that interview a human to discover requirements, scope, or intent:
`grill` before its structured close, `wayfinder` while charting a map.

Skip when scope is already concrete. An interview run against a locked scope is
theatre.

## Core rule

The point is NOT to fill a structured questionnaire. The point is to surface
**unknown unknowns** by interrogating one angle at a time until the answer
surprises you.

**ONE question at a time.** Wait for the answer. Then pick the next question based on what the answer revealed, not from a pre-baked list.

**Expect rehearsed first answers.** A polished first reply is not evidence. When
an answer is rehearsed, vague, or unsupported, use the pushback contract below;
a concrete supported answer needs no ritual second push.

**Pushback uses the 5-pattern catalog in `lib/push-once.md`.** When a reply is
rehearsed, vague, or unsupported, select the highest-leverage matching pattern,
print its label, and ask its exact prompt. Do not add a pattern-selection turn.

**Facts vs decisions.** Before asking, classify the question: an answer
derivable from the codebase, knowledge base, or docs is a **fact** — look it
up and state the finding with its source. The human gets only **decisions**:
tradeoffs, preferences, intent no source can settle. A question the agent
could have answered itself is a wasted push.

**Delete-first — drill whether before how.** Before drilling scope or edges, try to delete the whole requirement: can it be removed entirely? Who owns it, and can that person waive it? Requirements from smart or senior people are the most dangerous, because you question them least; optimizing something that should not exist is the most expensive mistake. Only what survives deletion is worth the axes below.

## The search space

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

**Second push-back (same session):** stop immediately. Write a line to the caller's log:
> `Stopped at user request after Q{N}. Unprocessed axes: {list}.`
Proceed to the caller's output. Flag unprocessed axes as OPEN_QUESTIONS.

**Do NOT ask a third time.** No "are you sure?", no "one more thing". Respect the second stop.

## Caller handoff packet

A caller chooses the workflow close; this protocol only carries the interview
state. When work moves to another caller, pass the smallest packet that prevents
lost context or repeated questions:

```text
workflow_intent
 target
 authority / decision_owner
 audience, if known
 known_context
 source_references
 answered_questions
 missing_decisions
 open_contradictions
 exit_condition
```

The receiving caller owns the artifact and close. It may replace the original
caller's close, but it must not silently change the intent. A changed intent is a
new session. Facts in the packet remain facts to retrieve or cite, not questions
to ask again.

## Switching callers mid-interview

The user names a different interviewing skill while this interview is still
unfinished — `/grill` typed three questions into a `wayfinder` charting session,
`/wayfinder` typed during a `grill` drilling session. Nothing is running that can
be interrupted, so the switch happens whatever the combined prose implies; state
it instead of letting it resolve silently.

**The answers survive. The original caller's close does not.** Do not restart
the interview and do not re-ask an answered question. Carry every answer so far,
plus the caller handoff packet, into the new caller and resume from the next
question under its contract, the same carry-forward the already-ran guard
performs for a finished interview. What
the original caller would have produced at the end — its map, its brief, its
Spec Issue — is dropped, because the new caller now owns the close.

**Say it in one line before the next question**, naming both halves:

> `Switched to {new caller}. {N} answers carry over; {original caller}'s {artifact} will not be written.`

Losing a charting session without saying so is the failure this rule exists to
prevent, and that line is also what lets the user correct a switch they did not
mean. It is a statement, not a gate: print it and continue.

## What this module does not own

- Forced alternatives, premise refresh, and any per-decision gate — the caller's
  close owns those, and `lib/stop-rule.md` owns the gate format.
- Any artifact: brief, plan, map, Spec Issue, decision note.
- Any routing decision about what the work becomes next.
- Whether a written artifact is produced at all. A caller may offer a chat-only
  mode; that is the caller's contract, not this module's.

## Anti-patterns

- ❌ Asking 5 questions in one message ("also, and what about, also")
- ❌ Reading off a checklist regardless of context
- ❌ Forcing the user to decide on the spot when they say "I haven't thought about that"
- ❌ Continuing after the user signals enough
- ❌ Switching callers mid-interview without saying which close was dropped
- ❌ Asking the human a question the repository could have answered
- ❌ Pretending to interview when scope is already concrete
