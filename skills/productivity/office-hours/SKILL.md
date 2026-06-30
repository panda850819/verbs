---
name: office-hours
type: skill
description: |
  Bring a fuzzy idea to office hours: model challenges, drills, surfaces unknowns, ends with a written brief. Default 30 min; --quick mode skips context-load when already loaded. Triggers on /office-hours, "office hours", "stress test this", "draft a brief".
reads:
  - repo: lib/capability-probe.md
  - repo: lib/push-once.md
  - repo: lib/escape-hatch.md
  - repo: lib/stop-rule.md
  - repo: lib/bad-good-calibration.md
  - repo: lib/goal-mapping.md
  - vault: knowledge/**
  - vault: docs/sessions/**
writes:
  - vault: Inbox/office-hours-*.md
  - vault: docs/briefs/*.md
  - vault: docs/plans/*.md
  - cli: stdout
domain: shared
classification: lifecycle-flow
capability_required:
  - agents.md
  - vault
  - lib/push-once.md
  - lib/escape-hatch.md
  - lib/stop-rule.md
---

# Office Hours — bring a problem, leave with a brief

> 30-minute structured pressure cooker. You walk in with a fuzzy idea or a stuck decision. Model challenges premises, drills unknowns, forces alternatives, and writes the brief that captures what you actually decided.

## When to invoke

- Fuzzy idea you want to stress-test before committing
- Decision you've been circling — need pressure to ground it
- Pre-PRD scoping where structured grill would be too narrow
- "I think I want X but I'm not sure" → office-hours
- Replacement for `/brainstorm` (deprecated)

## When to skip

- Bug fix or typo (just do it)
- Decision already made and clear (use `/sprint` to execute)
- Pure technical execution question (use `/grill`)

## Modes

- **Default** (full): all 5 stages, ~30 min. Use for fuzzy ideas where context, goal mapping, and premise challenge all matter.
- **`--quick`**: skip Stage 1 (capability probe + vault scan + goal mapping). Jump straight to Stage 2 premise challenge with user-provided context. ~10-15 min. Use when context is already loaded in-session and you only need premise challenge → alternatives → brief.

`--quick` is the structured-brief replacement for the deprecated `grill --mode structured`. When user says "draft a brief" / "structured intake" and goal context is already established this session, run `/office-hours --quick`.

## Differs from `/grill`

- `/grill` is the atomic 5-10 min adversarial pressure tool used mid-session, surfaces unknown unknowns, outputs a confirmed/open log to `Inbox/grill-*.md`
- `/office-hours` is the structured flow that ends with a written brief in `docs/briefs/`. Default takes 30 min with full context load; `--quick` takes 10-15 min when context is pre-loaded.

`/grill` is a mid-flight weapon (no brief output). `/office-hours` is a complete session that produces a brief.

## Stages

### Stage 1: Capability probe + load context

**Skip this stage entirely if `--quick`** — assumes context + goals already established in-session. Print one line: `Stage 1 skipped (--quick). Using session context: {1-line summary of what's already loaded}.` Then proceed to Stage 2.

When you reach this stage (full mode only), read `../../../lib/capability-probe.md` and run the probe. Cold pointer, not a hot import — `--quick` runs never pay its tokens.

Then:
1. Scan vault for the topic (filename + content match across `docs/sessions/`, `docs/learnings/`, `knowledge/`) — surface 3-5 prior hits
2. Read `lib/goal-mapping.md` Step 1: identify L1 / L2 / L3 goals from memory
3. State: "Today's office hours topic is: {topic}. Prior context: {summary}. Active goals: {L1/L2/L3}."
4. Print: `Stage 1 done. Proceeding to Stage 2 — premise challenge. [press any key or write 'skip' to jump to Stage 3]`

### Stage 2: Premise challenge (adversarial)

**Skip guard (check BEFORE drilling)** — mirrors `/grill`'s "skip when scope is already concrete". Before declining to grill, print the concrete evidence for each of the four conditions:

1. Deliverable = what exactly
2. Tested = which artifact/run
3. Reversible = why (two-way door)
4. Unknowns = why none

Only when all four are evidenced, print `Stage 2 skipped — scope already concrete. Routing to ship.` and jump to Stage 5 brief (or recommend `/sprint` / `/ship`). The "no unknowns" judgment is self-confirming, so the evidence print is the guard: if you cannot name the test artifact and the deliverable, the scope is NOT concrete — do NOT skip.

The point is to surface **unknown unknowns** by interrogating one angle at a time. Inspired by gstack `/office-hours` rehearsed-answer pattern.

Drill across these axes (search space, not checklist):

1. **Existence** — does this already exist? what's the status quo?
2. **Premise** — what assumption are you making that you haven't tested?
3. **Counterfactual** — what happens if you don't do this?
4. **Stakeholders** — who's affected? do they know?
5. **Reversibility** — two-way door or one-way door?

Protocol:

- ONE question at a time. Wait for answer.
- @../../../lib/push-once.md — when first reply is rehearsed, print 5-pattern menu, user picks, model uses literal prompt as next message.
- @../../../lib/escape-hatch.md — if user signals enough, 2-strike protocol kicks in.
- After each answer, pick next question based on what answer revealed (not from checklist).
- Stop conditions: 7+ questions OR 3 consecutive non-revealing answers OR escape-hatch.

@../../../lib/bad-good-calibration.md — apply 4 BAD/GOOD pairs to your pushback prompts.

### Stage 3: Alternatives (forced)

@../../../lib/stop-rule.md

Generate **2-3 named approaches**:

- One **minimal viable** (fewest files, ships fastest)
- One **ideal architecture** (best long-term trajectory)
- Optional **creative / lateral** (unexpected framing)

```
APPROACH A: {name}
  Summary: {1-2 sentences}
  Effort: {S/M/L}
  Pros: {bullets}
  Cons: {bullets}

APPROACH B: {name}
  ...

APPROACH C: {name}  [optional]
  ...
```

**RECOMMENDATION**: {A/B/C} because {one-line reason mapped to dominant goal layer}.

**Per-approach gate** (do not batch):

```
APPROACH A: Apply to brief? [Add / Defer / Reject]
APPROACH B: Apply to brief? [Add / Defer / Reject]
APPROACH C: Apply to brief? [Add / Defer / Reject]
```

STOP. Wait for user response on each. No silent continuation.

### Stage 4: Premise refresh

After alternatives picked, refresh the premise:

```
Original premise: {what was assumed at Stage 1}
Surfaced premises (from Stage 2): {what got discovered}
Revised premise: {what holds after grilling}
Premise still load-bearing: [Y/N/partial]
```

If revised premise is significantly different from original, surface this — user may want to redo Stage 3 with the new framing.

### Stage 5: Output brief

Write to `docs/briefs/{YYYY-MM-DD}-{slug}.md` using the brief scaffold in `skills/productivity/office-hours/lib/output-templates.md`. The brief carries: Problem, original + revised premise, alternatives considered (with each approach's Add/Defer/Reject), chosen approach + rationale, Scope (in/out), the "Next skill (recommended)" routing block (`lib/skill-decision-tree.md` 2-question test), Gotchas, a per-stage Gate Log, and OPEN_QUESTIONS.

Print path. Surface the "Next skill (recommended)" block from the brief verbatim — that's the routing decision per `lib/skill-decision-tree.md`. Do NOT close with "want me to start it for you?" — operator says next skill name directly.

### Stage 5b: Emit executable plan (when the next step is execution)

If the chosen approach routes to `/sprint` or `/team-orchestrate` (there is build work to do, not a pure decision), ALSO write an executable plan to `docs/plans/{slug}.md` (NO date prefix — the date lives in frontmatter; readers `/sprint --plan {slug}` / `--continue {slug}` / `/handover {slug}` resolve by bare slug, so write and read must match). One active plan per slug; re-planning the same topic overwrites it. Skip this stage for pure-decision briefs with no execution.

The brief is the **WHY** (problem, premise, rationale). The plan is the **WHAT** (tasks, acceptance, deps). Keep them strictly separate — do NOT copy the brief's rationale into the plan, do NOT put task IDs in the brief. Each fact lives in exactly one file (else the two drift).

Write the plan using the plan scaffold in `skills/productivity/office-hours/lib/output-templates.md` (frontmatter + `## Tasks`, each task carrying scope / acceptance / depends-on / status). Then add ONE pointer line to the brief under `## Chosen approach`: `Executable plan: docs/plans/{slug}.md`. Print both paths.

`acceptance:` MUST be a concrete check (a grep, a test/lint command, a file-exists assertion) — `/sprint --plan` derives per-task done/skip from it. A task with no checkable acceptance forces sprint back to the iteration counter, so write checks, not vibes. This plan file is also the cross-session resume checkpoint and the Codex handover payload — one artifact, three jobs.

## Anti-patterns

- ❌ Skipping Stage 1 ("I know the context, let's drill") — past-case lookup catches duplicate work
- ❌ Generating alternatives in Stage 2 (mixed mode) — keep adversarial pure, alternatives in Stage 3
- ❌ Writing brief in Stage 3 — brief comes after alternatives chosen, not before
- ❌ Re-running office-hours on a topic just office-hours'd — user is procrastinating, push to /sprint
- ❌ Letting Stage 2 run beyond 7 questions — escape-hatch enforces breadth ceiling
