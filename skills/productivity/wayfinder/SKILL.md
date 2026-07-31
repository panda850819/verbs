---
name: wayfinder
type: skill
description: |
  Chart or work a decision map across sessions until the route to its
  destination is clear. Use when the request itself names a map: charting one,
  or resuming an existing one. With no map yet, run the interview and write the
  map here, then stop. With an existing map, take ONE unblocked entry, resolve
  it by type (research / grilling / prototype / task), write the decision back,
  and graduate the fog. A large effort that names no map goes to `grill`, which
  hands off here once the drilling shows the route is unclear. NOT executing a
  locked plan (sprint).
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

Wayfinder has two modes. Charting establishes the map; working advances one
existing map entry per session.

## Chart a new map

Use this mode when a map is asked for and none exists yet — the user names one
directly, or `grill` hands the effort over as large and foggy.

1. **Name the destination.** If the user has not supplied a topic, ask for the
   destination before charting. Do not invent the effort the map should cover.
   What reaching the end looks like — a spec, a locked decision, a change made
   in place — shapes every entry, so settle it first.
2. **Run the interview.** Follow `@lib/interview.md` here, in this session: one
   question at a time, facts looked up rather than asked, delete-first before
   any axis, and its stopping rule. Do not hand this to another skill and stop —
   charting the map is this skill's own work.

   **If the interview already ran this session, do not run it again.** A caller
   that hands work over mid-flow — `grill` routing a large and foggy effort
   here — arrives with the drilling done. Carry that result forward and start
   at step 3. The skip needs a prior interview; without one, run it here rather
   than delegating it away.
3. **Write the map.** Create `docs/briefs/{YYYY-MM-DD}-{slug}-map.md` in the
   format below. Chart one typed entry per decision the interview made visible
   (`research` / `prototype` / `grilling` / `task`) with its blocking links.
   Do not chart decisions still hidden by fog; those stay under Not yet
   specified until an entry graduates them.
4. **Stop after creation.** Report the map path and leave its entries
   unresolved. Charting and working the first entry are separate sessions.

If the interview shows the effort fits one session after all, write no map. Say
so and route to `grill` for its structured close, which owns the spec-sized and
smaller-work paths.

## The map

When a map already exists, load it as the index and work its frontier. If no map
exists, use Chart a new map when a topic is present; otherwise ask for the
destination.

The **map is the index** — entries hold the detail. The **frontier** is the set
of open entries whose blockers are all closed. Work one entry per session; the
fog retreats one decision at a time until the route to the destination is clear
and no entries remain.

`docs/briefs/{YYYY-MM-DD}-{slug}-map.md` carries: Destination, Notes, Decisions
so far, typed investigation entries with blocking links, Not yet specified (the
fog), and Out of scope. This skill owns that format — it writes maps when
charting and reads them when working, and nothing else in Verbs writes one.

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
     reaction to the artifact is the decision input. When the entry's text
     names UI.md's converge mode (typical for a novel frontend surface), run
     that mode instead of re-deciding; this is plain entry wording, not a new
     map field.
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
   `grill` Stage A for the build brief, or go straight to `sprint` when
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
