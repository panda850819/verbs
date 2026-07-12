---
name: grill
description: |
  Adversarial requirement discovery. Ask ONE question at a time, hunting for hidden
  requirements / unknown unknowns. Atomic 5-10 min by default (a confirmed/open log);
  `--brief` mode adds a structured close that writes a brief (+ executable plan) to
  docs/. Use when the user says "grill me on X", "interrogate this idea", "stress test
  this scope", "what am I missing", "draft a brief", "structured intake". Skip for
  tasks where scope is already concrete.
reads:
  - skill: lib/push-once.md
  - skill: lib/stop-rule.md
  - skill: lib/output-templates.md
  - skill: lib/skill-decision-tree.md
  - repo: knowledge/**
writes:
  - repo: docs/briefs/*.md
  - repo: docs/plans/*.md
  - cli: stdout
domain: shared
classification: tool
user-invocable: false
---
# Grill

The point is NOT to fill a structured questionnaire. The point is to surface
**unknown unknowns** by interrogating one angle at a time until the answer
surprises you. Default grill emits a confirmed/open log to chat; `--brief` adds
a structured close that writes a brief and executable plan.

## When to use

- Feature scope is fuzzy ("I want a points system" → backfill? retroactive? UI placement? streak rules?)
- Before writing a PRD, or run `--brief` (below) to leave with a written brief + executable plan
- When you suspect hidden constraints (compliance, migration, downstream consumers)
- User explicitly says "grill me", "stress test this", "what am I missing"

## When to skip

- Bug fix or typo
- Scope already documented (existing PRD, ticket with AC)
- User has given clear acceptance criteria
- Time-sensitive (P0 incident — just do it)

## Protocol

**ONE question at a time.** Wait for the answer. Then pick the next question based on what the answer revealed, not from a pre-baked list.

**Expect rehearsed first answers.** A polished first reply is not evidence. When
an answer is rehearsed, vague, or unsupported, use the pushback contract below;
a concrete supported answer needs no ritual second push.

**Pushback uses the 5-pattern catalog in `lib/push-once.md`.** When a reply is
rehearsed, vague, or unsupported, select the highest-leverage matching pattern,
print its label, and ask its exact prompt. Do not add a pattern-selection turn.

**Facts vs decisions.** Before asking, classify the question: an answer
derivable from the codebase, knowledge base, or docs is a **fact** — look it
up and state the finding with its source. The human gets only **decisions**:
tradeoffs, preferences, intent no source can settle. A question the agent
could have answered itself is a wasted push.

**Delete-first — drill whether before how.** Before drilling scope or edges, try to delete the whole requirement: can it be removed entirely? Who owns it, and can that person waive it? Requirements from smart or senior people are the most dangerous, because you question them least; optimizing something that should not exist is the most expensive mistake. Only what survives deletion is worth the axes below.

Drill across these axes (not as a checklist — as a search space):

1. **Existence** — does this already exist partially? What's the status quo?
2. **Boundaries** — what's IN scope vs OUT? Where's the line?
3. **Retroactivity** — does this apply to existing data / users / state? Backfill?
4. **Edge cases** — what happens at zero / max / null / concurrent / offline?
5. **Stakeholders** — who else's workflow does this touch? Do they know?
6. **Failure modes** — what's the worst that can happen if this is wrong?
7. **Reversal** — how do we undo this if it turns out bad?
8. **Success signal** — how do you know it worked? What metric / observation?

For each answer:
- If the answer reveals a NEW unknown, drill into that next.
- If the answer is "I haven't thought about that", flag it and move on (don't force decisions in real time).
- If the user gives a confident answer that contradicts something earlier, surface the contradiction explicitly.

## Stopping rule

Stop when one of:
- 3 consecutive answers reveal no new unknowns
- 7+ questions answered (avoid bike-shedding)
- User triggers escape hatch (see below)

### Escape hatch (hard cap)

User signals impatience ("夠了" / "ship it" / "skip the questions" / "just do it"):

**First push-back:** acknowledge once, ask the 2 most critical remaining axes, then stop.
> "聽到。剩兩題收。"

**Second push-back (same session):** stop immediately. Write a line to the grill log:
> `Stopped at user request after Q{N}. Unprocessed axes: {list}.`
Proceed to Output. Flag unprocessed axes as OPEN_QUESTIONS in the log.

**Do NOT ask a third time.** No "are you sure?", no "one more thing". Respect the second stop.

## Output

After grilling ends, produce:

```markdown
## Grill log — <topic> — <date>

### Confirmed
- [point with answer]

### Open / deferred
- [question with "haven't thought" or "decide later" tag]

### Surfaced contradictions
- [if any]

### Recommended next step
- Re-run in `--brief` mode (below) to produce a brief + executable plan (if implementation track)
- Feed into PRD draft (if planning track)
- Park as memo (if not ready to act)
```

Emit the log to chat. Persist only when the host/user supplied an output path;
default grill does not choose or write a project-state destination.

## `--brief` mode (structured close)

Default grill is atomic and leaves only the log above. `--brief` runs the same
drilling, then adds a structured close with a written brief and executable plan.
After the stopping rule fires, run three stages in order; do not skip or reorder.

**Stage A — Alternatives (forced).** @lib/stop-rule.md Generate 2-3 named approaches: one minimal-viable (fewest files, ships fastest), one ideal-architecture (best long-term trajectory), optional lateral. Each carries Summary / Effort {S/M/L} / Pros / Cons. Print a **RECOMMENDATION**: {A/B/C} because {one-line reason}. Then a per-approach gate, one at a time, never batched — `APPROACH {X}: Apply to brief? [Add / Defer / Reject]` — STOP and wait on each.

**Stage B — Premise refresh.** Original premise / surfaced premises (from the drilling) / revised premise / still-load-bearing [Y/N/partial]. If the revised premise differs significantly from the original, surface it — the user may want to redo Stage A with the new framing.

**Stage C — Write the brief.** Write `docs/briefs/{YYYY-MM-DD}-{slug}.md` using the brief scaffold in `lib/output-templates.md`: Problem, original + revised premise, alternatives (with each Add/Defer/Reject), chosen approach + rationale, Scope (in/out), Seams (which existing test seams the work passes through; new seams named and placed as high as possible — skip for pure-decision briefs), the "Next skill (recommended)" routing block (`lib/skill-decision-tree.md` 2-question test), Gotchas, OPEN_QUESTIONS. Print the path and surface the "Next skill" block verbatim. Do NOT close with "want me to start it?" — name the next skill directly. If the chosen approach routes to build work and the repo has a GitHub remote, offer once to mint the tracking issue from the brief (`gh issue create`, title = the proposed slug, body links the brief) — the ticket-gated flow starts there.

**Stage C+ — Executable plan (only when the next step is execution).** If the chosen approach routes to `/sprint` or `/handover` (there is build work, not a pure decision), ALSO write `docs/plans/{slug}.md` (NO date prefix — `/sprint --plan {slug}` and `/handover {slug}` resolve by bare slug, so write and read must match) using the plan scaffold in `lib/output-templates.md`: frontmatter + `## Tasks`, each task carrying scope / acceptance / depends-on / status. The brief is the WHY, the plan is the WHAT — keep them strictly separate, each fact in one file. `acceptance:` MUST be a concrete check (a grep, a test/lint command, a file-exists assertion) — `/sprint --plan` derives per-task done/skip from it; vibes force sprint back to the iteration counter. This one plan file is the sprint input, the cross-session resume checkpoint, and the Codex handover payload. Add one pointer to the brief under `## Chosen approach`: `Executable plan: docs/plans/{slug}.md`.

**Granularity confirm (before writing the plan file).** Print the proposed task list — title / depends-on / what it delivers — and confirm granularity and edges once: too coarse, too fine, does each task depend only on what genuinely gates it. One confirm, not a loop.

**Wide-refactor exception.** When one mechanical change (a rename, a retype) has a blast radius no vertical slice can keep green, shape the tasks as expand → migrate → contract: expand adds the new form beside the old; migrate tasks convert call sites in batches sized by blast radius, each `depends-on` expand; contract deletes the old form, `depends-on` every batch. Vertical slices stay the default — reach for this only when a single edit breaks callers everywhere at once.

### Wayfinder exit (effort too big for one session)

If the drilling reveals the effort is BOTH too big for one session AND still foggy — the way to the destination isn't visible, scope keeps expanding, decisions hang on decisions not yet made — do NOT force a single brief. Write a local **decision map** at `docs/briefs/{YYYY-MM-DD}-{slug}-map.md`: one typed investigation entry per visible open decision (`research` / `prototype` / `grilling` / `task`), with explicit blocking links. Three disciplines: **don't chart what you can't yet see** (fog-of-war — leave it as "not yet specified", not a fake task); **one investigation per session**; **each investigation's deliverable is a decision note, not code**. External tracker creation and knowledge-store filing remain host actions. Work the map with `wayfinder` — one entry per session. Once the route is clear, re-enter at Stage A `--brief` or go straight to `/sprint`.

## Anti-patterns

- ❌ Asking 5 questions in one message ("also, and what about, also")
- ❌ Reading off a checklist regardless of context
- ❌ Forcing the user to decide on the spot when they say "I haven't thought about that"
- ❌ Continuing after the user signals enough
- ❌ Pretending to grill when scope is already concrete (just acknowledge and proceed)

## Relationship to other skills

- **For structured-brief output** — run `grill --brief`: writes a brief and
  executable plan to `docs/`.
- **Before a host closes a decision record** — if you're closing a work topic and realize scope was never grilled.
