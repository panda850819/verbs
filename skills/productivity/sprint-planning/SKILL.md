---
name: sprint-planning
description: "Plan one Sprint Goal and select ready work after a human approval gate."
reads:
  - repo: "**"
  - repo: AGENTS.md
  - repo: CLAUDE.md
writes:
  - cli: stdout
domain: shared
classification: lifecycle-flow
user-invocable: true
disable-model-invocation: true
---
# Sprint Planning

Sprint Planning proposes one Sprint Goal and a feasible selection from already
ready work. Selection authority stays with the human; this skill never executes
the result.

## Surface boundary

Extends Verbs routing with a human-approved Sprint selection record; replaces no
host scheduler, tracker planning view, or Scrum role. The applicable
`.out-of-scope/persona-layer.md` precedent is preserved: this remains a
skill-as-markdown procedure, not a Scrum Master or Product Owner persona. No
other matching out-of-scope precedent exists.

## 1. Bind planning inputs

Read the Product Goal, ordered backlog, readiness records, open blockers,
available capacity, and relevant delivery evidence. Require one decision owner.
If the goal, backlog order, readiness, capacity, or authority is missing, return
`BLOCKED` with the exact gap instead of guessing.

Completion: the decision horizon and usable planning inputs are explicit.

## 2. Build one coherent proposal

Draft one outcome-based Sprint Goal. Select only ready, unblocked work that
contributes to that goal and fits the stated capacity. Account for dependencies
and uncertainty; do not use nominal capacity as evidence that an unknown item
fits. List excluded candidates with reasons.

Completion: every selected item traces to the goal, names its readiness-record
reference, records `blocker status: clear` with the blocker-check evidence, and
fits without relying on an unwritten future item. Any item with an active blocker
belongs under Excluded.

## 3. Preview and approve

Show the complete proposal once:

```markdown
Sprint Planning: <period or label>
Status: PROPOSED
Decision horizon: <period or time boundary>
Sprint Goal: <one outcome>
Selected:
- <Issue/reference> — goal: <contribution> — readiness: <record reference> — blocker status: clear — blocker check: <evidence reference and time> — capacity: <basis>
Excluded:
- <Issue/reference> — <reason>
Dependencies / risks:
- <item or none>
Capacity basis: <stated evidence>
Decision owner: <human>
```

Ask once: `[approve / reject]`.

- `approve`: return the same record with `Status: APPROVED` only when every
  selected item preserves its readiness reference, `blocker status: clear`, and
  blocker-check evidence.
- `reject`: return `Status: REJECTED` and stop without replacing the proposal.

Approval records the human selection only. Do not assign Issues, create or
switch branches, invoke another skill, mutate the tracker, or start work.

## Completion

Done when the proposal is `APPROVED`, `REJECTED`, or `BLOCKED`; an `APPROVED`
record includes an explicit decision horizon and usable planning inputs; every
item includes its readiness reference, clear blocker status, and blocker-check
evidence; and no selected item has been claimed or executed.
