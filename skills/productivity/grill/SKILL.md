---
name: grill
description: |
  Adversarial requirement discovery. Ask ONE question at a time, hunting for hidden
  requirements / unknown unknowns. Its structured close routes spec-sized work to
  `to-spec`, large foggy work to `wayfinder`, and smaller work to a local brief plus
  executable plan. Say "quick" or "don't write files" for a chat-only log. Use for
  "grill me", "stress test this scope", "what am I missing", "draft a brief",
  structured intake, or a feature/refactor expected to touch 3+ files or add an
  abstraction. Skip when scope is already concrete.
reads:
  - skill: lib/interview.md
  - skill: lib/push-once.md
  - skill: lib/stop-rule.md
  - skill: lib/output-templates.md
  - skill: lib/skill-decision-tree.md
  - skill: to-spec
  - repo: knowledge/**
writes:
  - repo: docs/briefs/*.md
  - repo: docs/plans/*.md
  - cli: stdout
domain: shared
classification: tool
user-invocable: true
---
# Grill

The point is NOT to fill a structured questionnaire. The point is to surface
**unknown unknowns** by interrogating one angle at a time until the answer
surprises you. By default the drilling ends in a structured close that writes a
canonical Spec Issue for spec-sized work or a local brief and plan for smaller
work. A chat-only opt-out ("quick", "just talk", "don't write files") leaves
only the confirmed/open log instead.

## When to use

- Feature scope is fuzzy ("I want a points system" → backfill? retroactive? UI placement? streak rules?)
- Before requirements become a Spec or local implementation brief
- When you suspect hidden constraints (compliance, migration, downstream consumers)
- User explicitly says "grill me", "stress test this", "what am I missing"

## When to skip

- Bug fix or typo
- Scope already documented (existing PRD, ticket with AC)
- User has given clear acceptance criteria
- Time-sensitive (P0 incident — just do it)

## Protocol

**The interview protocol is @lib/interview.md.** Run it: one question at a
time, pushback via `lib/push-once.md`, facts looked up rather than asked,
delete-first before any axis, the eight-axis search space, and its stopping
rule and escape hatch. Do not restate or fork it here.

**If the interview already ran this session, do not run it again.** A caller
that hands work over mid-flow — `wayfinder` deciding the effort fits one session
after all — arrives with the drilling done. Carry that result forward and start
at the structured close. Re-asking answered questions is the failure this
primitive exists to prevent.

**If an interview is still unfinished when the user switches skills, say so
before the next question.** In either direction — arriving here mid-interview,
or leaving here for another caller — the answers carry forward and the new
caller's close replaces the old one. `@lib/interview.md` owns the rule and the
exact line to print; a silent switch drops an artifact with nothing said.

Grill's own contract is what happens around that interview: the chat-only
opt-out below, and the structured close further down.

## Chat-only opt-out

Distinct from the escape hatch. The escape hatch stops the DRILLING early; the
chat-only opt-out keeps the drilling but skips the structured close. When the
user signals they want no written artifact — "quick", "just talk it through",
"don't write files", "不用寫檔", "grill 一下就好" — end at the Output log below
and do NOT run the structured close. Absent that signal, the close is the
default: most Grill uses need a durable next-stage artifact.

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
- The structured close routes to `to-spec`, a local brief/plan, or a decision map
- Park as memo (if not ready to act)
```

Emit this log to chat. It is the complete output ONLY when the chat-only opt-out
fired; otherwise it is the running record and the structured close below follows.

## Structured close (default)

Unless the chat-only opt-out fired, the drilling ends here: a structured close
with a canonical Spec Issue or local brief and plan, layered on top of the log above.
After the `@lib/interview.md` stopping rule fires, run Stage A, Stage B, then
exactly one route from the routing gate; do not skip or reorder them.

**Stage A — Alternatives (forced).** @lib/stop-rule.md Generate 2-3 named approaches: one minimal-viable (fewest files, ships fastest), one ideal-architecture (best long-term trajectory), optional lateral. Each carries Summary / Effort {S/M/L} / Pros / Cons. Print a **RECOMMENDATION**: {A/B/C} because {one-line reason}. Then a per-approach gate, one at a time, never batched — `APPROACH {X}: Carry forward? [Add / Defer / Reject]` — STOP and wait on each.

**Stage B — Premise refresh.** Original premise / surfaced premises (from the drilling) / revised premise / still-load-bearing [Y/N/partial]. If the revised premise differs significantly from the original, surface it — the user may want to redo Stage A with the new framing.

### Route after premise refresh

Apply these branches in order:

1. **Large and foggy -> `wayfinder`.** If the effort is both too big for one
   session and the route is still unclear, hand off to `wayfinder` and stop.
   It owns charting: it runs the interview itself and writes
   `docs/briefs/{YYYY-MM-DD}-{slug}-map.md`. Do not write a map here — one
   skill writes maps, and it is not this one. Pass the drilling so far so the
   charting session does not re-ask what is already answered. Once the route is
   clear, re-enter Stage A or this routing gate.
2. **Spec-sized -> `to-spec`.** Route here when the chosen work is expected to
   require two or more implementation Issues, or when even one PR changes a
   public contract, schema or migration, or security boundary. Give `to-spec`
   the Grill log, approved alternatives, refreshed premise, and repository
   evidence. Once it publishes the GitHub Spec Issue, that Issue is canonical.
   Do not write a competing repository brief, executable plan, PRD, local Spec
   copy, or tracking Issue. Stop after reporting the Spec URL; `to-tickets`
   owns later decomposition.
3. **Smaller work -> local close.** Continue to Stage C and C+ below.

**Stage C — Write the local brief (smaller work only).** Write `docs/briefs/{YYYY-MM-DD}-{slug}.md` using the brief scaffold in `lib/output-templates.md`: Problem, original + revised premise, alternatives (with each Add/Defer/Reject), chosen approach + rationale, Scope (in/out), Seams (which existing test seams the work passes through; new seams named and placed as high as possible — skip for pure-decision briefs), the "Next skill (recommended)" routing block (`lib/skill-decision-tree.md` 2-question test), Gotchas, OPEN_QUESTIONS. Print the path and surface the "Next skill" block verbatim. Do NOT close with "want me to start it?" — name the next skill directly. If the chosen approach routes to build work and the repo has a GitHub remote, offer once to mint the tracking issue from the brief (`gh issue create`, title = the proposed slug, body links the brief) — the ticket-gated flow starts there.

**Stage C+ — Executable plan (only when the next step is execution).** If the chosen approach routes to `/sprint` or `/handover` (there is build work, not a pure decision), ALSO write `docs/plans/{slug}.md` (NO date prefix — `/sprint --plan {slug}` and `/handover {slug}` resolve by bare slug, so write and read must match) using the plan scaffold in `lib/output-templates.md`: frontmatter + `## Tasks`, each task carrying scope / acceptance / depends-on / status. The brief is the WHY, the plan is the WHAT — keep them strictly separate, each fact in one file. `acceptance:` MUST be a concrete check (a grep, a test/lint command, a file-exists assertion) — `/sprint --plan` derives per-task done/skip from it; vibes force sprint back to the iteration counter. This one plan file is the sprint input, the cross-session resume checkpoint, and the Codex handover payload. Add one pointer to the brief under `## Chosen approach`: `Executable plan: docs/plans/{slug}.md`.

**Granularity confirm (before writing the plan file).** Print the proposed task list — title / depends-on / what it delivers — and confirm granularity and edges once: too coarse, too fine, does each task depend only on what genuinely gates it. One confirm, not a loop.

**Wide-refactor exception.** When one mechanical change (a rename, a retype) has a blast radius no vertical slice can keep green, shape the tasks as expand → migrate → contract: expand adds the new form beside the old; migrate tasks convert call sites in batches sized by blast radius, each `depends-on` expand; contract deletes the old form, `depends-on` every batch. Vertical slices stay the default — reach for this only when a single edit breaks callers everywhere at once.

## Anti-patterns

Interview anti-patterns live with the protocol in `lib/interview.md`. Grill's
own:

- ❌ Skipping the structured close because the drilling felt conclusive
- ❌ Writing a local brief for spec-sized work instead of routing to `to-spec`
- ❌ Writing both a Spec Issue and a competing repository brief
- ❌ Batching the per-approach gates in Stage A
- ❌ Closing with "want me to start it?" instead of naming the next skill

## Relationship to other skills

- **Structured close is the default** — Spec-sized work routes to `to-spec`;
  smaller work writes a local brief and executable plan; large foggy work hands
  off to `wayfinder`, which charts the map itself.
- **Before a host closes a decision record** — if you're closing a work topic and realize scope was never grilled.
