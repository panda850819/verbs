---
name: wayfinder
type: skill
description: |
  Chart or work a decision map across sessions until the route to its
  destination is clear. Use when the request itself names a map, resumes one,
  or an `ask-boss` handoff identifies multi-session decision fog. With no map
  yet, run the interview and write the map here, then stop. With an existing
  map, take ONE unblocked entry, resolve it by type (research / grilling /
  prototype / task), write the decision back, and graduate the fog. A request
  without a named map that only needs one-session requirement discovery goes to
  `grill`. NOT executing a locked plan; execution entry points remain human-selected.
reads:
  - repo: docs/briefs/**
  - skill: lib/interview.md
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
user-invocable: true
---
# Wayfinder

Wayfinder has two modes: chart a new Decision Map, or resolve one existing
frontier entry per session. It does not execute a locked plan.

## Handoff from `ask-boss`

Carry the destination, known context, source references, authority, and
contradictions from `ask-boss`. **Do not re-run orientation or ask for facts
already present in the packet.** `wayfinder` owns the map, one-entry close, and
map artifact; it may interview only for decisions the map still needs.

If a caller already started an unfinished interview, follow the shared switch
rule and carry answers forward rather than restarting.

## Chart a new map

Use this mode when a map is named, `ask-boss` hands over multi-session fog, or
`grill` hands over a large unclear effort.

1. **Name the destination.** Ask for it if absent; do not invent the effort.
2. **Interview.** Run **`@lib/interview.md`** here: dependency-aware frontier
   rounds, facts first, delete first, and its stopping rule. **If the interview
   already ran this session, do not run it again.** **If an interview is still unfinished
   when the user switches skills, say so before the next question.** Carry the
   answers forward; the shared protocol owns the exact announcement.
3. **Write the map.** Create `docs/briefs/{YYYY-MM-DD}-{slug}-map.md` with one
   typed entry (`research` / `prototype` / `grilling` / `task`) per visible
   decision and blocking links. Hidden fog stays under Not yet specified.
4. **Stop after creation.** Leave entries unresolved and report the map path.

If the interview shows the work fits one session, write no map; route to `grill`
for its structured close.

## Map contract

The map carries Destination, Notes, Decisions so far, typed entries with blockers,
Not yet specified, and Out of scope. **This skill owns that format.** The map is
the index; entries hold detail and the frontier is open entries whose blockers are
closed.

## Work an existing map

1. Read only the map index and linked notes required by the chosen entry.
2. **Choose and claim.** If the user named an entry, take that one; otherwise
   take the first frontier entry. Mark it `status: in-progress ({date})` before
   work only when `{date}` comes from trustworthy host context or a tool. When
   no current date is available, write `status: in-progress` without a date;
   never infer or guess one. Apply the same rule to the final closed status.
3. **Resolve by type.** Research writes cited facts. `grilling` and `prototype`
   are HITL: run the respective skill and wait for human input; never answer the
   human's side yourself, and leave the entry open when no human is available.
   The prototype reaction is the decision input. A `task` unblocks the decision
   or produces a precise checklist.
4. Write the full answer to `docs/briefs/{map-slug}/{NN}-{entry-slug}.md`, close
   the entry, and append one gist to Decisions so far.
5. Graduate newly precise fog into typed entries, or move past-destination work
   to Out of scope. Stop after one entry.

When the frontier and fog are empty, re-enter `grill` for the build brief. If
the plan is already executable, report that state and stop; a human selects the
execution entry point.

## Completion

Charting ends after the map is created. Working ends after one entry is resolved
and recorded; it never silently builds the destination.
