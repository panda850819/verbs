---
name: sprint
type: skill
description: |
  Focused execution from a concrete outcome to SHIPPED, PAUSED, FAILED, or ABORTED_BY_USER. Adds acceptance-driven loops, bounded review, and delivery evidence beyond native coding behavior. Routes unclear requirements to grill, bugs to debug, UI work to ui, and completed delivery to ship. NOT for hypothetical or planning-only responses.
reads:
  - skill: grill
  - skill: ui
  - skill: debug
  - skill: review
  - skill: ship
  - skill: lib/verify-the-test-loop.md
  - skill: lib/learning-format.md
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
user-invocable: true
disable-model-invocation: true
---
# Sprint

A sprint owns one finish line and ends `SHIPPED`, `PAUSED`, `FAILED`, or
`ABORTED_BY_USER`; local edits are never `SHIPPED`.

**Planning-only boundary:** for a hypothetical, plan-only, or no-tools request,
do not enter the state machine. Return `Execution: NOT_RUN` without inventing
commands or evidence.

## 1. Bind the finish line

Read the repository contract and the issue, brief, plan, or request. State one
outcome, in-scope files or subsystem, checkable acceptance evidence, exclusions,
and irreversible operations. If one un-derivable choice changes the result,
route only that question to `grill`; route bugs to `debug` and UI work to `ui`.
For an existing plan, treat it as read-only context; re-derive progress from git
and acceptance checks instead of hand-editing status.

Completion: the finish line can be proven by commands or named human evidence.

## 2. Execute tight loops

For each smallest coherent unit: inspect the seam, make the minimum change, run
the narrowest relevant check, and inspect the diff. Execute in the main session
by default. When the user explicitly delegates through Herdr or a host-native
worker, treat the returned output as evidence, not completion: this Sprint still
owns acceptance, review, Git, and delivery. Stop immediately before destructive
or public actions that need authorization. Never weaken or skip a test.

Completion: every changed line maps to the finish line and its check passes.

## 3. Verify the artifact

Run the real acceptance path and proportionate test, lint, type, or build checks.
For human testing, apply `lib/verify-the-test-loop.md` to prove the artifact
contains this change. Self-refute once at the most likely input, state, or
integration seam; record environment gaps instead of substituting a weaker check.

Completion: acceptance is observed after the final edit and survives self-refute.

## 4. Review with bounded correction

Run `review` for non-trivial or PR-bound work. Feed findings through Steps 2–3
and review the new diff. Stop after three cycles; a remaining P0/P1, coverage
gap, or scope drift is `FAILED` or `PAUSED`, never a fourth blind retry.

Completion: review is clean, explicitly skipped by policy, or names the blocker.

## 5. Decide and deliver

`READY_TO_SHIP` requires acceptance, review, and authorization; invoke `ship`.
Set `SHIPPED` only after pushed commit or branch plus PR evidence. If ship fails,
set `PAUSED`. Otherwise report `FAILED` with the reproduced failure and last
good point, or `ABORTED_BY_USER` with diff and cleanup state.

**A `FAILED` or `ABORTED_BY_USER` sprint emits ONE learning candidate before it
prints the end state**; a validated negative result is still evidence. Nothing
validated → print no extra line. `PAUSED` emits nothing.

A sprint owns only its finish line: never schedule follow-on work or claim the
next frontier Issue. Do not create tracker or knowledge writes outside the repo.

## Output

```text
Sprint: <topic>
State: SHIPPED | PAUSED | FAILED | ABORTED_BY_USER
Scope: <files/subsystem>
Evidence: <acceptance + tests + self-refute>
Review: <clean/skipped/blocker and cycles>
Delivery: <commit/branch/PR or missing precondition>
Resume: <only when paused>
```
