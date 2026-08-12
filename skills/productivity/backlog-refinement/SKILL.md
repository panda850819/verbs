---
name: backlog-refinement
description: |
  Make one backlog item READY or NOT_READY by clarifying its outcome, scope,
  acceptance criteria, dependencies, and unresolved decisions. Use when asked
  to refine, clarify, size the readiness of, or prepare an Issue for engineering.
  Reuses Grill's dependency-aware interview discipline. NOT product priority,
  iteration selection, ticket publication, or implementation.
reads:
  - repo: "**"
  - repo: AGENTS.md
  - repo: CLAUDE.md
  - skill: lib/interview.md
  - skill: lib/push-once.md
  - skill: grill
writes:
  - cli: stdout
domain: shared
classification: lifecycle-flow
user-invocable: true
---
# Backlog Refinement

Backlog Refinement owns readiness for one backlog item. `READY` means the item
is understandable and verifiable, not that it will be selected or executed.

## Surface boundary

Extends Verbs routing with backlog-item readiness; replaces no tracker, host
backlog system, or product role. The applicable
`.out-of-scope/persona-layer.md` precedent is preserved: this remains a
skill-as-markdown procedure, not a Product Owner persona. No other matching
out-of-scope precedent exists.

## 1. Bind the item

Read the source Issue, request, product outcome, repository evidence, and known
dependencies. Name the decision owner and preserve links to the source of truth.
Do not silently replace an existing requirement with a local rewrite.
Completion: one candidate item and its intended product outcome are identified.

## 2. Resolve readiness gaps

Check outcome, scope in/out, acceptance, dependencies, constraints, failure
states, and evidence seam. For unresolved product choices, run
`@lib/interview.md` with this skill as caller: ask only the active decision
frontier, carry blocked decisions forward, and do not inherit Grill's close.
When it calls for pushback, load `@lib/push-once.md` and use the exact named
pattern. A skipped push remains an open decision and forces `NOT_READY`.
Derivable repository facts are lookups, not questions for the human.

Completion: every readiness dimension is settled or named as a blocker.

## 3. Apply the readiness gate

Return `READY` only when all of these are true:

- the user-visible or engineering outcome is explicit;
- scope and exclusions are bounded;
- acceptance criteria are observable;
- dependencies and blockers are known;
- material failure or edge states are covered;
- the evidence seam can prove completion;
- no unresolved decision changes the result.

Otherwise return `NOT_READY`; never fabricate the missing requirement.

## Output and stop

```markdown
Backlog Refinement: <item>
Status: READY | NOT_READY
Outcome: <observable result>
Scope in:
- <item>
Out of scope:
- <item>
Acceptance criteria:
- AC-1: <observable proof>
Dependencies / blockers:
- <dependency or none>
Failure / edge states:
- <state>
Evidence seam: <highest practical proof>
Open decisions:
- <decision or none>
Source: <canonical reference>
```

Stop after the readiness record. Do not publish or decompose tickets, choose
iteration work, assign the item, or begin implementation.
