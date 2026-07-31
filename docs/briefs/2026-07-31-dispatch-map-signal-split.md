---
date: 2026-07-31
type: brief
source: grill
topic: Dispatch rows 7 and 8 both match a large fuzzy idea (#290)
tags: [brief, grill]
---

# Dispatch map-signal split

## Problem

`DISPATCH.md` rows 7 and 8 both match the same input — a large, fuzzy topic
typed without a slash command — and nothing states which wins. Before v0.19.0
the overlap was harmless because `grill` wrote the map either way. Now row 7
produces a map and row 8 produces a brief, a Spec Issue, or a hand-off, so the
same input yields a different artifact depending on a coin flip the model makes
silently.

## Original premise

The rows can be separated by whether the effort spans sessions, and the fix is
to write that distinction down.

## Revised premise (after grill)

The distinction cannot live at the dispatch layer at all. "Spans sessions" and
"is it big" are the same judgment, and it is exactly what the user has not made
yet at the moment they type. Two grill answers confirmed the destination —
not-big goes to `grill`, big needs a map — while both declined to supply an
input string that would let a rule see "big" from the outside. So the routing
table must key on something visible in the input, and the size judgment must
happen one layer in, after `grill` has drilled.

Two facts make that safe now, and neither held when #290 was filed:

- #288 (merged, v0.19.2) guarantees `wayfinder` carries a finished interview
  forward, so escalating from `grill` costs one hop and no repeated questions.
- Entering the wrong door is asymmetric. A wrong `grill` costs a hop. A wrong
  `wayfinder` reaches step 3 and can leave an unwanted map file in
  `docs/briefs/`. The cheaper wrong answer belongs in the default row.

`RESOLVER.md:54-61` already encodes this: rule 1 is `grill`, rule 2 says
**add** `wayfinder` when the uncertainty spans decisions. Only `DISPATCH.md`
presents them as peers.

## Alternatives considered

- A: State precedence — keep both rows, add a tiebreak sentence — [Reject]
- B: Split the signals — row 7 catches only visible map language, row 8 catches
  every other fuzzy input — [Add]
- C: Collapse to one row — `wayfinder` leaves model-routed dispatch entirely —
  [Reject]

## Chosen approach

B — it swaps an unobservable judgment ("how big is this?") for one visible in
the input ("does it name a map?"), and the destination is unchanged because
`grill` route 1 still escalates large foggy work to `wayfinder`.

Rejected A because a precedence sentence is prose the model must re-weigh every
session, and the route test could only assert that the sentence exists, not that
routing follows it. Rejected C because it also drops "resume that map", a
frequent and unambiguous signal that deserves automatic routing.

## Scope

In: `DISPATCH.md` rows 7 and 8; the `RESOLVER.md` selection guidance and
catalog rows that must agree; a route assertion in
`tests/resolver-routes-test.py`; version bump, sync, CHANGELOG.

Out: #289 (mid-interview skill switch). Adding a third dispatch row. Changing
what either skill does once entered — only which one is entered first.

## Seams

`tests/resolver-routes-test.py` is the existing seam: it already parses
`DISPATCH.md` and `RESOLVER.md` as text and appends to a `failures` list, and
it already carries a seeded-mutation self-check. The new assertion lands there
rather than in a new test file.

## Next skill (recommended)

```
Shape: single-target-iterative
Reasoning: four coupled prose and test edits in one repo, each verified by the
existing suite; judgment stays in the foreground session.

Recommended skill:
  → /sprint dispatch-map-signal-split
```

## Gotchas surfaced

- The route assertion must fail when row 7 regains generic fuzzy language, not
  merely when the row goes missing. A presence-only check reproduces #276's
  failure shape: green regardless of what the model loads.
- `RESOLVER.md` rule 2's "Add `wayfinder` when the uncertainty itself spans
  multiple decisions or sessions" is now the one place that still keys on size.
  It must be rewritten to key on the map, or the two sources disagree again.

## Gate Log

- Stage 1 (load context): read DISPATCH rows 7-8, RESOLVER 20-70, both SKILL
  bodies, resolver-routes-test.py, dispatch-miss.log
- Stage 2 (premise challenge): 3 questions, 1 push via push-once `[1] 具體一點`,
  escape-hatch fired? N. Push answered with a restatement; accepted after the
  second consistent reply rather than pushing a third time.
- Stage 3 (alternatives): chose B
- Stage 4 (premise refresh): original premise NOT load-bearing — replaced, see
  Revised premise
- Stage 5 (output): brief saved to
  docs/briefs/2026-07-31-dispatch-map-signal-split.md

## OPEN_QUESTIONS

- None blocking. #289 stays open and its answer may reference this decision.
