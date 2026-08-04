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
  - skill: wayfinder
writes:
  - cli: stdout
domain: shared
classification: lifecycle-flow
user-invocable: true
---
# Ask Boss

`ask-boss` is the thin orientation route for work whose next route, decision
owner, target, or source of truth is unclear. It is not a boss persona and not a
mandatory front door.

## Skip it

Use the named specialist directly when the request already identifies the work:

- a named Decision Map -> `wayfinder`
- a reproducible failure -> `debug`
- a production UI change -> `ui`
- a code diff or PR -> `review`
- an external artifact to adopt -> `gatekeeper`
- a clear bounded implementation -> `sprint`

Do not intercept a clear typed request just because it may touch another role.

## Route

1. **Orient.** Read the request and the smallest current context in this order:
   assignment or message, Goal / Project / Task, canonical brief / spec /
   decision, current repo or status, then review / QA / customer evidence.
2. **Retrieve.** Look up facts and references before asking. Classify what
   remains as a missing decision, contradiction, authority gap, or route gap.
3. **Choose the caller.** Select one existing specialist before opening any
   Grilling Session:

   | Remaining shape | Caller |
   |---|---|
   | Several dependent decisions across sessions | `wayfinder` |
   | One bounded requirements or acceptance gap | `grill` |
   | One design question answerable by building | `prototype` |
   | Architecture seam or module boundary | `codebase-design` |
   | Load-bearing judgment needing challenge | `advisor` |
   | Established spec-sized requirements | `to-spec` |
   | Otherwise, a known typed specialist route | that specialist |

   A contradiction goes to the caller that owns the decision axis; do not
   silently choose a side. Use minimum sufficient authority, not the highest
   title. If the authority is genuinely unknown, make that the one human
   question.
4. **Handoff.** Give the caller the packet below. The caller owns its own
   interview, artifact, and close. `ask-boss` does not start a generic
   Grilling Session and does not write a map, brief, Spec, Issue, or code.

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

`Carry-forward context` includes retrieved facts, answered questions,
contradictions, and the references that the receiving caller must not re-ask or
rediscover. If the receiving caller needs human decisions, it starts the shared
Grilling Session with this context and its own exit condition.

## Wayfinder handoff

For multi-session decision fog, hand off the destination, known context,
references, authority, and contradictions to `wayfinder`. `wayfinder` owns the
Decision Map, resolves one frontier entry per session, and stops after its own
close. Direct map requests bypass `ask-boss`.
