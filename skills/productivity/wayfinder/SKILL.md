---
name: wayfinder
type: skill
description: |
  Chart or work a decision map across sessions until the route to its
  destination is clear. With a large, fuzzy topic and no map, delegate charting
  to grill --brief and stop after the map is created. With an existing map, take
  ONE unblocked entry, resolve it by type (research / grilling / prototype /
  task), write the decision back, and graduate the fog. Use when starting or
  resuming a multi-session effort. NOT executing a locked plan (sprint).
reads:
  - repo: docs/briefs/**
  - skill: grill
  - skill: prototype
writes:
  - repo: docs/briefs/**
  - cli: stdout
domain: shared
classification: lifecycle-flow
capability_required:
  - writable-cwd
  - skill: grill
  - skill: prototype
user-invocable: false
---
# Wayfinder

Wayfinder has two modes. Charting establishes the map for a large, fuzzy
effort; working advances one existing map entry per session.

## Chart a new map

Use this mode when the user gives a large, fuzzy topic and no map exists.

1. **Name the destination.** If the user has not supplied a topic, ask for the
   destination before charting. Do not invent the effort the map should cover.
2. **Delegate charting to `grill --brief`.** Grill runs its structured close and
   its wayfinder exit writes the map at
   `docs/briefs/{YYYY-MM-DD}-{slug}-map.md`.
3. **Stop after creation.** Report the map path and leave its entries unresolved.
   Charting and working the first entry are separate sessions.

If grill concludes that the effort is small enough to proceed without a map,
stop there and follow grill's recommended next skill.

## The map

When a map already exists, load it as the index and work its frontier. If no map
exists, use Chart a new map when a topic is present; otherwise ask for the
destination.

The **map is the index** — entries hold the detail. The **frontier** is the set
of open entries whose blockers are all closed. Work one entry per session; the
fog retreats one decision at a time until the route to the destination is clear
and no entries remain.

`docs/briefs/{YYYY-MM-DD}-{slug}-map.md` is exactly the format that grill's
wayfinder exit writes: Destination, Notes, Decisions so far, typed investigation
entries with blocking links, Not yet specified (the fog), and Out of scope. This
skill consumes that format and never forks it.

## Work an existing map

1. **Orient.** Read the map only — Destination, Decisions so far, open
   entries. Zoom into a linked decision note only when the entry you take
   depends on it.
2. **Choose and claim.** The user named an entry → that one. Otherwise the
   first frontier entry. Mark it `status: in-progress ({date})` in the map
   before any work.
3. **Resolve by type.**
   - `research` (AFK) — read the code / docs / knowledge base and write a
     cited finding. Facts are legwork, never questions to the human.
   - `grilling` (HITL) — run `grill` on that one question, with the human.
     Never answer the human's side yourself; no human available → leave the
     entry open and say so.
   - `prototype` (HITL) — make it concrete via `prototype`; the human's
     reaction to the artifact is the decision input.
   - `task` (HITL or AFK) — work that unblocks a decision (provision access,
     move data so its shape is visible). Do it, or hand the human a precise
     checklist; record the resulting facts later entries depend on.
4. **Record.** Full answer goes to a decision note at
   `docs/briefs/{map-slug}/{NN}-{entry-slug}.md`. In the map: close the entry
   and append one line to Decisions so far —
   `[{entry title}]({note path}) — {one-line gist}`. The map gists and links;
   it never restates the detail.
5. **Graduate the fog.** Anything under Not yet specified that the answer made
   precise enough to phrase becomes a typed entry with blocking links. Anything
   revealed to sit past the Destination moves to Out of scope with a one-line
   why — closed, never resolved on route. A decision that invalidates other
   entries updates or removes them.
6. **Stop.** One entry resolved is the session's work; continue only on an
   explicit ask. Frontier empty AND fog empty → the map is done: re-enter
   `grill --brief` Stage A for the build brief, or go straight to `sprint` when
   the way is already an executable plan.

## Disciplines

- **Fog or entry:** make it an entry when the question can be phrased precisely
  NOW, even if blocked; otherwise it stays fog. Don't pre-slice fog into
  entry-sized pieces — one patch may graduate into several entries, or none.
- **Decisions, not deliverables.** Every entry's output is a decision note.
  The pull to just build the thing marks the map's edge — hand off to `sprint`
  rather than coding inside the map.
- **Refer by name.** In everything the human reads, an entry goes by its title
  with the link riding inside the name — never a bare number.
