---
name: ask-boss
type: flow
description: |
  Route an unclear workplace request to one existing specialist by retrieving
  facts and resolving intent, target, audience, and minimum sufficient authority.
  Use for an unclear starting point, owner, reference, or next route; clear typed
  requests, named maps, bugs, UI work, and code review go directly to their
  specialist.
reads:
  - skill: grill
  - skill: decision-map
writes:
  - cli: stdout
domain: shared
classification: lifecycle-flow
user-invocable: true
---
# Ask Boss

`ask-boss` is the thin orientation route for work whose next route, decision
owner, target, or source of truth is unclear. It is not a boss persona or a
mandatory front door; direct typed requests bypass it.

## Route

1. **Orient.** Read the smallest current context in this order: assignment or
   message, Goal / Project / Task, canonical brief / spec / decision, repo or
   status, then review / QA / customer evidence.
2. **Retrieve.** Look up facts and references before asking. Classify what
   remains as a missing decision, contradiction, authority gap, or route gap.
3. **Choose the caller.** Select one existing specialist before opening any
   Grilling Session: use the specialist whose description owns the remaining
   decision axis. Do not intercept a clear typed request just because it may
   touch another role. For multi-session decision fog, choose `decision-map`;
   `decision-map` owns the map. Use minimum sufficient authority, not the highest
   title; if authority is unknown, make that the one human question.
4. **Handoff.** Give the caller the packet below. The caller owns its interview,
   artifact, and close. `ask-boss` does not start a generic Grilling Session,
   write a map, brief, Spec, Issue, or code.

## Output

Output exactly one recommended route or one human decision question:

```text
Current state:
Uncertainty:
Workflow intent:
Target / artifact:
Audience:
Decision owner / role lens:
References:
Recommended route:
Why this route:
Human gate:
Carry-forward context:
```

`Carry-forward context` contains retrieved facts, answered questions,
contradictions, and references the caller must not re-ask or rediscover.

## Completion

Done when the packet names one route or one human question, preserves the
minimum sufficient authority, and gives the receiving caller enough context to
continue without restarting orientation.
