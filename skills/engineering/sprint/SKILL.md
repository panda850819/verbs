---
name: sprint
type: skill
description: |
  Focused execution from a concrete outcome to SHIPPED, PAUSED, FAILED, or ABORTED_BY_USER. Adds acceptance-driven loops, bounded review, and delivery evidence beyond native coding behavior. Routes unclear requirements to grill, bugs to debug, UI work to ui, and completed delivery to ship. NOT for hypothetical or planning-only responses.
reads:
  - skill: lib/model-anchors.md
  - skill: grill
  - skill: ui
  - skill: debug
  - skill: review
  - skill: ship
  - skill: handover
  - skill: lib/verify-the-test-loop.md
writes:
  - cli: stdout
  - git: commits via ship
domain: shared
classification: lifecycle-flow
capability_required:
  - writable-cwd
  - skill: grill
  - skill: ui
  - skill: debug
  - skill: review
  - skill: ship
user-invocable: false
---
# Sprint

A sprint owns one finish line. It ends as `SHIPPED`, `PAUSED`, `FAILED`, or
`ABORTED_BY_USER`; local edits alone are never `SHIPPED`.

**Planning-only boundary:** when the request says hypothetical, asks only for a
plan, or forbids action/tools, do not enter the sprint state machine. Return a
concise execution outline labeled `Execution: NOT_RUN`. Never invent commands,
test results, review findings, commits, pushes, or PR evidence.

## 1. Bind the finish line

Read the repository contract and the issue, brief, plan, or request. State:

- one outcome;
- in-scope files or subsystem;
- checkable acceptance evidence;
- explicit exclusions and irreversible operations.

If the outcome is already concrete, execute. If one un-derivable choice changes
the result, invoke `grill` for that question only. Route root-cause work through
`debug` and visual implementation through `ui`; return here for verification.

For an existing plan, treat it as read-only decision context. Re-derive progress
from git and acceptance checks before doing work, so resume is idempotent.

Completion: the finish line can be proven by commands or named human evidence.

## 2. Execute in tight loops

For each smallest coherent unit:

1. inspect the actual seam and nearby style;
2. make the minimum change that reaches the acceptance condition;
3. run the narrowest relevant check;
4. inspect the diff for unintended scope.

The main session executes by default. Delegate only when the user or repository
contract asks for it and the units are file-disjoint or mechanical. `handover`
owns cross-runtime delegation. Consult `lib/model-anchors.md` for its model seat;
never select a model ad hoc. Re-run acceptance locally after delegated work.

Stop immediately on destructive or public actions that need authorization.
Never weaken, skip, or special-case a test to manufacture green.

Completion: every changed line maps to the finish line and its check passes.

## 3. Verify the artifact

Run the real acceptance path, then the proportionate test, lint, type, or build
checks required by the repository. If a human will test a build or deployment,
use `lib/verify-the-test-loop.md` first to prove that artifact contains this
change. An unproven artifact invalidates the human result.

Self-refute once: identify the most likely input, state, or integration seam
that could break the conclusion and exercise it. Record environment gaps as
gaps; a weaker check cannot substitute for missing runtime proof.

Completion: acceptance is observed after the final edit and survives self-refute.

## 4. Review with a bounded correction loop

Invoke `review` for non-trivial work or anything heading to a PR. A trivial
single-file local change may use direct diff inspection when repository policy
allows it. Feed actionable findings back through Steps 2 and 3, then review the
new diff. Stop after three review cycles; a remaining P0/P1, coverage gap, or
scope drift makes the sprint `FAILED` or `PAUSED`, never a fourth blind retry.

Completion: review is clean, explicitly skipped by policy, or names the blocker.

## 5. Decide and deliver

- `READY_TO_SHIP`: acceptance and review are green, and shipping is authorized.
  Invoke `ship`. Set `SHIPPED` only after it returns pushed commit or branch plus
  PR evidence when a PR applies.
- `PAUSED`: work is recoverable but an authorization, environment, dependency,
  or review precondition is missing. Print the exact resume command or check.
- `FAILED`: acceptance failed or the bounded review loop was exhausted. Print
  the reproduced failure and last known-good point.
- `ABORTED_BY_USER`: stop all writes and print current diff and cleanup state.

If `ship` fails, the sprint is `PAUSED`; do not relabel local completion as
delivery. Do not create tracker or knowledge writes outside the target repo.

## Output format

```text
Sprint: <topic>
State: SHIPPED | PAUSED | FAILED | ABORTED_BY_USER
Scope: <files/subsystem>
Evidence: <acceptance + tests + self-refute>
Review: <clean/skipped/blocker and cycles>
Delivery: <commit/branch/PR or missing precondition>
Resume: <only when paused>
```

## Anti-patterns

- Running a requirements interview after scope and acceptance are already clear.
- Default subagent fan-out for work the active model can complete directly.
- Step-by-step narration that costs more attention than the work.
- Marking build, commit, or local green as `SHIPPED` without delivery evidence.
- Continuing after three same-shape review failures.
