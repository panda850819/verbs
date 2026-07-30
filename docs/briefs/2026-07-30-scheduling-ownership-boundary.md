---
date: 2026-07-30
type: brief
source: grill
topic: Scheduling ownership boundary (v1 map entry 5)
tags: [brief, grill]
---

# Scheduling ownership boundary

## Problem

The v1 direction map carries a decision that the shipped product has since
reversed twice, and an acceptance gate that nothing can satisfy. Map entry 5
asks where to draw the scheduling ownership line on the assumption that
scheduling entered Verbs scope on 2026-07-13. It did not.

- `README.md:115-116` (Product boundary) and `README.md:262-263` (v1.0 cut
  criteria) both name **scheduling** and **autonomous drivers** as things Verbs
  does not own. Shipped in #264, reaffirmed in the v0.17.0 CHANGELOG (#269).
- No implementation has landed against the map's INTO-scope line in the three
  months since it was written.
- Map acceptance gate **G-A** (`map:17-22`) requires 10 merged unattended PRs
  with "≥5 of them fired by a scheduler rather than a manually started
  session". With scheduling out of scope, nothing in Verbs can fire them.

## Original premise

Scheduling is now in scope. Pick what Verbs owns — protocol only, protocol plus
one reference trigger on one host, or trigger implementations per host — and
rewrite the out-of-scope boundary text accordingly.

## Revised premise (after grill)

Scheduling never actually entered scope, and "it stays out" already shipped.
The unanswered question was never the three-way pick. It is: **what must the
ticket-side contract specify so that a scheduler Verbs does not own can drive a
Verbs lifecycle safely.**

The original three options are dead as a choice. "Protocol only" survives as
the answer, reached by deletion rather than selection.

Also surfaced, and load-bearing for how far the deletion goes: **unattended is
not the same as scheduled.** An unattended session can be manually fired — a
`claude -p` loop, an Action triggered by a PR comment. Entry 7 governs the
permission envelope for unattended sessions and does not die with entry 5.

## Alternatives considered

- A: Delete entry 5 only — re-scope entry 7, strip the scheduler clause from
  G-A — **Reject**. Leaves G-A as a gate with no trigger; defers the problem
  instead of answering it.
- B: Delete 5 and 7, drop G-A, cut v1.0 as attended-only — **Reject**. Removes
  the "complete under BOTH human triggering and AI triggering" clause that
  defines v1.0.
- C: Delete 5, keep 7, Verbs owns only the ticket shape and the
  claim/write-back contract; G-A is satisfied by a host-native scheduler —
  **Add**.

## Chosen approach

C — the only option that leaves the shipped README boundary intact, keeps AI
triggering in the v1.0 definition, and states what Verbs owns as something
writable rather than an unimplemented intent.

Verbs never owns a scheduler, a trigger, or a driver. It owns the ticket-side
contract that an externally scheduled agent reads and writes: what a claimable
ticket looks like, what claiming means, what the agent must write back, and
where the PR ceiling is asserted. G-A's scheduler clause is satisfied by
GitHub Actions or a `claude schedule` routine — infrastructure Verbs depends on
and does not ship.

## Scope

In:
- Map entry 5 closed by reversal, with the README evidence recorded.
- The "Scheduling / autonomous drivers move INTO Verbs scope" line under
  "Decisions so far" replaced by the reversal.
- G-A reworded so its scheduler clause names a host-native scheduler as the
  trigger and Verbs' ticket contract as the thing under test.
- Entry 7 re-scoped to unattended-not-scheduled, and named as the entry that
  must define the ticket-side contract.

Out:
- Any change to `README.md`. Leaving it unchanged is the point of C.
- Defining the ticket shape or the claim/write-back contract. That is entry 7's
  deliverable, not this brief's.
- Implementing or selecting a scheduler on any host.
- The `.out-of-scope/` files. None of them covers scheduling; the boundary
  lives in `README.md`.

## Next skill (recommended)

```
Shape: pure-decision
Reasoning: the deliverable is the map correction and its decision note; there
is no build work, so no plan file and no sprint.

Recommended skill:
  → none — apply the map edits directly from this brief, then entry 7 is the
    next frontier (HITL, and now the only open entry on the unattended line).
```

## Gotchas surfaced

- The contradiction was not "map versus one CHANGELOG line". `README.md` states
  the boundary twice, including inside the v1.0 cut criteria. Checking only the
  CHANGELOG would have understated how settled the boundary already was.
- Deleting a map entry can silently break an acceptance gate. G-A is in the
  Destination section, far from the entry list; nothing links them.
- `claude schedule` cloud routines have no plugin surface at all, so none of
  the four Verbs hooks fire there
  (`docs/briefs/2026-07-13-verbs-v1-direction-map/02-unattended-runtime-options.md`).
  If G-A is satisfied by a cloud routine, the ticket contract is the *only*
  enforcement that exists in that lane. That is the strongest argument for
  entry 7 and the sharpest risk in approach C.

## Gate Log

- Stage 1 (load context): read `README.md` product boundary and cut criteria,
  `CHANGELOG.md` v0.17.0, the v1 map, and the entry 2 decision note.
- Stage 2 (premise challenge): 1 question (delete-first), 1 push via push-once
  on an ambiguous "yes", escape-hatch fired? N
- Stage 3 (alternatives): A Reject, B Reject, C Add
- Stage 4 (premise refresh): partial — original three-way pick dead, "protocol
  only" survives as the answer; C already absorbed the shift, Stage A not rerun
- Stage 5 (output): brief saved to
  `docs/briefs/2026-07-30-scheduling-ownership-boundary.md`

## OPEN_QUESTIONS

- Does G-A's "≥5 fired by a scheduler" number still mean anything once the
  scheduler is host-native and Verbs only supplies the ticket contract? The
  number was delegated and provisional at charting; it may need to become a
  different measurement rather than a smaller count.
- Which host satisfies G-A in practice. Cloud routines lose all hook
  enforcement; GitHub Actions has a documented plugin-install path that has
  never been run. Entry 7 needs one of these established before its mechanism
  decision can be tested.
