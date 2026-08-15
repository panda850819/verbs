---
name: sprint-planning
description: "Repair unreliable planning inputs through Grill and relevant planning skills, then propose one Sprint Goal and ready work for human approval."
reads:
  - repo: "**"
  - repo: AGENTS.md
  - repo: CLAUDE.md
  - skill: grill
  - skill: product-planning
  - skill: backlog-refinement
  - skill: to-spec
writes:
  - cli: stdout
domain: shared
classification: lifecycle-flow
user-invocable: true
disable-model-invocation: true
---
# Sprint Planning

Sprint Planning proposes one Sprint Goal and a coherent selection of ready
work. Selection authority stays with the human; this skill may repair planning
inputs and publish approved planning Issues, but never executes the selection.

## Surface boundary

Extends Verbs routing with a human-approved Sprint selection record; replaces no
host scheduler, tracker planning view, or Scrum role. The applicable
`.out-of-scope/persona-layer.md` precedent is preserved: this remains a
skill-as-markdown procedure, not a Scrum Master or Product Owner persona. No
other matching out-of-scope precedent exists.

## 1. Bind or repair planning inputs

Read the Product Goal, ordered backlog, readiness records, open blockers, and
relevant delivery evidence. The person running Sprint Planning is the decision
owner; do not ask for or print that default.

Treat a missing input, unsupported claim, incomplete Issue, or absent source
reference as unreliable. Start a Grilling Session instead of guessing or
returning `BLOCKED`. Carry its answers forward without repeating questions, then
route the resolved gap:

- missing product direction or priority -> `product-planning`;
- unreliable outcome, scope, or acceptance -> `grill`;
- an item that is not ready -> `backlog-refinement`;
- durable requirements -> `to-spec`, which publishes the Spec and invokes its
  child-Issue flow in the same planning invocation.

Resume here with the resulting records and Issues. If a required route cannot
produce reliable evidence, return `BLOCKED` with that exact gap.

Completion: the decision horizon and every planning input are explicit and
source-backed; newly published child Issues have returned to the backlog.

## 2. Build one coherent proposal

Draft one outcome-based Sprint Goal. Select only ready, unblocked work that
contributes to that goal within one coherent Sprint Goal. Account for dependencies and uncertainty.
List excluded candidates with reasons.

Completion: every selected item traces to the goal, names its readiness-record
reference, records `blocker status: clear` with the blocker-check evidence, and
depends on no unwritten future item. Any item with an active blocker
belongs under Excluded.

## 3. Preview and approve

Show the complete proposal once:

```markdown
Sprint Planning: <period or label>
Status: PROPOSED
Decision horizon: <period or time boundary>
Sprint Goal: <one outcome>
Selected:
- <Issue/reference> — goal: <contribution> — readiness: <record reference> — blocker status: clear — blocker check: <evidence reference and time>
Excluded:
- <Issue/reference> — <reason>
Dependencies / risks:
- <item or none>
```

Ask once: `[approve / reject]`.

- `approve`: return the same record with `Status: APPROVED` only when every
  selected item preserves its readiness reference, `blocker status: clear`, and
  blocker-check evidence.
- `reject`: return `Status: REJECTED` and stop without replacing the proposal.

Approval records the human selection only. Input repair may invoke the named
planning skills and publish Issues behind their own approval gates. Do not claim
or assign Issues, schedule selected work, create or switch branches, or start
implementation.

## Completion

Done when the proposal is `APPROVED`, `REJECTED`, or `BLOCKED`; an `APPROVED`
record includes an explicit decision horizon and usable planning inputs; every
item includes its readiness reference, clear blocker status, and blocker-check
evidence; and no selected item has been claimed or executed.
