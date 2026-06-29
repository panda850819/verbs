---
name: sprint
mode: skill
description: |
  Focused execution session: from "I want to do X" to shipped or explicitly paused/failed/aborted. Internal flow: dojo, grill (lite), execute, review, ship; only SHIPPED triggers backflow. Triggers on /sprint, "sprint on this", "let's ship X", "focused session". Routes UI work to `ui`, bugs to `debug`.
reads:
  - repo: lib/capability-probe.md
  - repo: lib/escape-hatch.md
  - repo: lib/push-once.md
  - repo: lib/gate-contract.md
  - repo: skills/productivity/dojo/SKILL.md
  - repo: skills/productivity/grill/SKILL.md
  - repo: skills/productivity/ui/SKILL.md
  - repo: skills/engineering/debug/SKILL.md
  - repo: skills/engineering/review/SKILL.md
  - repo: skills/engineering/ship/SKILL.md
  - repo: lib/verify-the-test-loop.md
  - repo: skills/engineering/sprint/references/codex-delegation.md
  - vault: knowledge/**
  - vault: docs/learnings/**
  - vault: docs/plans/**
writes:
  - vault: Inbox/sprint-*.md
  - vault: docs/sessions/*.md
  - cli: stdout
  - git: commits via /ship
domain: shared
classification: lifecycle-flow
capability_required:
  - agents.md
  - vault
  - lib/capability-probe.md
  - lib/escape-hatch.md
  - skills/productivity/dojo
  - skills/productivity/grill
  - skills/engineering/review
  - skills/engineering/ship
---

# Sprint — focused 1-2 hour execution

> A sprint has a whistle and a finish line. You walk in with a topic. You walk out with one of four states: SHIPPED, PAUSED, FAILED, or ABORTED_BY_USER. Only SHIPPED triggers ship/extract/backflow. The other three write a checkpoint and stop cleanly.

## When to invoke

- 1-2 hour focused work on a specific topic
- "Let's ship X today" / "sprint on this"
- Coming out of `/office-hours` with an approved brief
- Bug fix that needs review + ship discipline (was `commands/fix.md`)
- Quick ship on a small change with `--quick` flag (was `commands/quick.md`)

## When to skip

- Trivial 1-line change (just edit + commit)
- Multi-day project (use `/office-hours` first, then sprint per session)
- Pure planning / scoping (use `/office-hours`, not sprint)

## Modes

- Default: full sprint (dojo → grill lite → execute → review → ship)
- `--quick`: skip dojo + grill, go execute → review → ship
- `--design`: auto-invoke `ui` skill at execute stage (replaces `commands/design.md`)
- `--plan {path|slug}`: execute against a durable plan at `docs/plans/{slug}.md` (the artifact `/office-hours` Stage 5b emits). Sprint reads it READ-ONLY and derives per-task progress from git — see Stage 3 plan-driven execution. Auto-detect rule: slugify the topic the same way office-hours does and check for `docs/plans/{that-slug}.md` (exact slug, no fuzzy match); if the sprint began from an office-hours brief, use the plan path office-hours printed. If none found, run conversationally.
- `--continue {slug}`: resume a PAUSED sprint. Skips dojo + grill; loads the PAUSED checkpoint + `docs/plans/{slug}.md`, recomputes which U-IDs are already done (git + acceptance), and resumes at the first non-done task.
- `--delegate codex`: in Stage 3, hand a batch of mechanical units to Codex (synchronous, in-loop) via the `/handover` invocation. OFF unless you pass this flag — sprint defaults to free Claude subagents and never auto-delegates. A batch of ≥3 mechanical units is the advisory threshold worth surfacing the flag at, NOT an auto-trigger. Requires a plan file. See `references/codex-delegation.md` for the batch loop; the single-invocation mechanics live in `skills/engineering/handover/references/codex-invocation.md`. For ASYNC handover that frees this session, use `/handover --async`.

## Stages

### Stage 0: Capability probe

@../../../lib/capability-probe.md

Abort or degrade per probe rules. Output probe block as opening.

### Stage 1: Dojo (skip if `--quick`)

Invoke `skills/productivity/dojo/SKILL.md` for the topic. Output prep brief, print path. User reads, then continues.

Best-effort: also surface `{brain}/learnings/` pages matching the topic (the auto-sedimented learnings from transcript-ingest) so plan-time context includes past lessons. Skip silently if `{brain}` is absent. (Semantic two-brain `gbrain query` is the private-overlay upgrade; this flat glob is the public, Zero-Dependencies-safe baseline that closes the write→read loop.)

### Stage 2: Grill (lite, skip if `--quick`)

Run `skills/productivity/grill/SKILL.md` in default (adversarial) mode with **3-question cap** (not full 7). Cover:

- Existence (does this exist already? half-built somewhere?)
- Scope boundary (what's IN, what's OUT)
- Reversibility (two-way / one-way door?)

@../../../lib/push-once.md applies. @../../../lib/escape-hatch.md applies. If user signals stop, log and skip to Stage 3.

### Stage 3: Execute

**Plan-driven execution (when `--plan {slug}` or `--continue {slug}`, or `docs/plans/{slug}.md` auto-detected):** If a durable plan exists, read it READ-ONLY. It is a decision artifact, NOT a worklog:

- Do NOT edit the plan body during the sprint. Per-task `status:` is DERIVED, never hand-written. The only writes go to code + git. (This guards the two-runtime drift AGENTS.md warns about — a fresh Claude session or a Codex handoff must re-derive state from git + the plan, never from a mutable progress field.)
- Before executing each `{slug}-T0N` task, run an idempotency check: (1) does the task's `acceptance:` check already pass (grep / run it)? (2) is its scope already present in the git diff/tree? If yes → mark that U-ID done and SKIP it, no silent reimplementation. Respect `depends-on:` ordering.
- For `--continue`: load `Inbox/sprint-{slug}-*.md` (PAUSED checkpoint) + the plan, run the idempotency check across all U-IDs, resume at the first non-done task. Skip Stage 1 (dojo) and Stage 2 (grill).
- If a task has no checkable `acceptance:`, fall back to the `iteration` counter for that task and flag it in the narrate line.

When no plan file is present, execute conversationally. Done-condition for the conversational path: each build unit's acceptance condition (Execution mode step 1) is re-verified by the architect — subagent-reported green is never trusted. Execute is not complete until every unit's acceptance re-verifies, matching the plan-driven path's idempotency check.

**Execution mode (default: architect + subagent build — Panda directive 2026-06-12):** the main session is the ARCHITECT, not the typist. For each non-trivial build unit:

1. Main session writes a tight spec: files in scope, seams/interfaces, hard constraints, style anchor (which existing file to imitate), and a checkable acceptance condition per unit.
2. Dispatch the unit to a runtime-native subagent (Claude Code: `Agent` tool; one unit = one agent; parallel dispatch ONLY when units are file-disjoint). The subagent gets the spec, not the architect's full context. The architect judges which model/agent fits each unit by its nature — a deep-reasoning seam vs a mechanical edit — and passes `model:` accordingly. Decide per task at dispatch time; do not hardcode a fixed tier mapping. Codex delegation still targets the Codex runtime.
3. Main session reviews the returned diff against the spec, re-verifies acceptance itself (build/test — subagent-reported green is never trusted), fixes integration seams, and owns all git operations.

Carve-outs:
- **Trivial unit** (single-file, mechanical, ~20 lines or less): main session edits directly — dispatch overhead exceeds the work.
- **Interface-discovery work** (the seam itself is unknown until you write it): main session may execute the seam-defining unit, then dispatch the rest against the now-fixed interface.
- **Runtime without a subagent mechanism** (e.g. plain `codex exec`): degrade to main-session execution and say so in the narrate line.

Rationale: the architect's context window and judgment are the scarce resource; spend them on spec, review, and integration, not keystrokes. "Faster if I just write it myself" is the failure mode this default exists to prevent — it was true for the single unit and false for the sprint.

**Codex delegation:** when `--delegate codex` is set (the rule lives in Modes, above), Stage 3 hands the batch of mechanical units to Codex via `/handover` instead of dispatching to free subagents — planning / review / git stay on Claude. It is SYNCHRONOUS (occupies this turn polling); for ASYNC fire-and-forget that frees the session, use `/handover --async`. Gate, batching, and circuit breaker: `references/codex-delegation.md`.

Stage 3 runs with baseline engineering discipline — root cause before fix, minimal diff, verify before done, 3-strike escalation — from `~/.agents/AGENTS.md` § Coding Discipline plus `careful` and `review`. For a UI build, follow `ui`; for a bug, follow `debug`. There is no separate persona-lens step.

Track `iteration` counter starting at 1.

**Step-level narrate** (Mnilax Rule 10, adopted 2026-05-24): every distinct sub-step within Stage 3 (file edit, command run, validation pass) must end with a one-line narrate:

```
done: {what was completed} | verified: {what was checked} | remaining: {next sub-step}
```

Mirrors background-session protocol (`result:` / `needs input:` / `failed:`) but applied to foreground sprint. Purpose: at 50-min mark, model + user both know where the sprint is even if context drifts. Skip ONLY for trivial 1-line edits (`--quick` mode auto-skips). If you completed something you can't summarize back, stop — you've drifted past the last known-good state.

**Multi-source aggregator dispatch-branch test**: if this sprint adds a new dispatch branch / per-source handler / per-source filter to a multi-source aggregator, the handler-level integration test for the new branch is part of Stage 3 implementation, NOT Stage 4 review iter 2. Read `skills/engineering/sprint/lib/aggregator-test-checklist.md` for the trigger shapes and test shape.

### Stage 4: Review + verify gate (skip if `--quick`)

Invoke `skills/engineering/review/SKILL.md`. Parse output for:

- P0 + P1 findings (excluding entries already AUTO-FIXED by review skill)
- `COVERAGE GAP` entries
- `SCOPE DRIFT` entries

Three branches:

1. **All counts = 0** (clean review) → proceed to Stage 5 (ship gate, state=SHIPPED)
2. **`iteration >= 3` and any non-zero** → terminal state = FAILED, do NOT auto-loop
3. **`iteration < 3` and any non-zero** → present 4-option gate per `lib/gate-contract.md`:

   ```
   Review found:
     {n} P0 / {n} P1 / {n} COVERAGE GAP / {n} SCOPE DRIFT

   [approve] feed findings to execute context, return to Stage 3, iteration++
   [edit]    user supplies modified findings, return to Stage 3, iteration++
   [reject]  log findings as OPEN_QUESTIONS, proceed to Stage 5 with state=PAUSED
   [skip]    log findings as OPEN_QUESTIONS, proceed to Stage 5 (review-clean assumption)
   ```

**Auto-loop semantics**: approve/edit increment iteration counter and loop back to Stage 3. Stage 3 receives findings as additional context, then re-runs execute. Stage 4 fires again at end. Max 3 loops; iteration=3 with non-zero count → FAILED.

**Why bounded**: 3 loops is the empirical "if you can't fix it in 3 review-cycles, the diagnosis itself is the bug" cap (the 3-strike escalation rule). After FAILED, user does manual intervention (no auto-retry).

### Stage 5: Ship gate (terminal state decision)

**Deploy-proof precondition (if the deliverable was validated by a human
manually exercising a build/deploy).** Before `state = SHIPPED` or before
asking the user to do that validation: @../../../lib/verify-the-test-loop.md
— prove the artifact the user tested embeds this change (content marker /
source-not-newer / pinned path / stable identity). If unproven, the bug
is the pipeline: do NOT ask the user to test and do NOT mark SHIPPED —
fix the loop first (Rule 3). Conclusions from an unverified loop are void
(Rule 2). 3 same-shape failures ⇒ Rule 4 (switch abstraction, not a 4th
variant), not auto-FAILED-after-3.

This is the critical gate. Compute terminal state:

```
if review_clean AND deploy_proven AND user_approves_ship:
    state = SHIPPED
elif user_signals_pause ("park this" / "暫停" / "later"):
    state = PAUSED
elif execute_failed OR review_iteration_exceeded:
    state = FAILED
elif user_signals_abort ("stop" / "abort" / "cancel"):
    state = ABORTED_BY_USER
```

Print computed state to user. User can override (e.g. "actually let's pause this even though review is clean").

### Stage 6: Terminal state handling

**State emission (loop-in-agent).** At each terminal state, append one event to
the machine-readable lifecycle store so a scheduler can see where this item
landed (schema: `docs/state-schema.md`). Best-effort: if the
binary is absent or the runtime can't reach it, skip silently — the log is
gap-tolerant. `slug` = repo basename, `item` = sprint slug.

```
scripts/pandastack-state append --slug {repo} --item {slug} \
  --event {shipped|paused|failed|aborted} --phase {last phase} \
  --skill sprint --runtime {claude-code|codex} [--ref {session-note}]
```

Emit AFTER the per-state handling below (so `--ref` can point at the written
checkpoint / session note). SHIPPED emits `shipped`; PAUSED emits `paused` with
the phase it parked in; FAILED/ABORTED emit `failed`/`aborted`.

#### SHIPPED
1. Invoke `skills/engineering/ship/SKILL.md` — runs commit + push + PR if applicable
2. Trigger Extract + Backflow (writes to docs/sessions/, docs/learnings/,
   `{brain}/sessions/` + `gbrain sync` + announce path when a brain runtime
   is present — skip silently when not, possibly Inbox/ship-log/)
3. Route deferred work: append any deferred follow-ups / OPEN_QUESTIONS to the repo's canonical next-work tracker (`ROADMAP.md` or `TODOS.md`) with a date + source PR. Do NOT park deferred work in a CLI's private memory (it is per-runtime — Codex / Gemini / Claude diverge — and drifts), and do NOT leave it only in the dated session note (not discoverable as "what's next"). If the repo has no tracker, say so in the summary rather than defaulting to memory.
4. Output sprint summary: `Stage 1-6 complete, SHIPPED. {commit-hash}, {PR-url if any}, {extract summary}.`

#### PAUSED
1. Write `Inbox/sprint-{slug}-{date}.md` checkpoint:
   ```
   state: PAUSED
   stages_completed: [0, 1, 2, 3]
   stage_3_progress: {what's done, what's pending}
   plan: docs/plans/{slug}.md   # if one exists; --continue re-derives done/todo from it + git
   resume_with: /sprint --continue {slug}
   ```
2. Do NOT run ship. Do NOT run backflow. Do NOT modify docs/learnings.
3. Output: `Sprint PAUSED. Resume with: /sprint --continue {slug}.`

#### FAILED
1. Write checkpoint with state: FAILED, plus failure reason and stuck-point.
2. Append to `docs/learnings/pitfalls/{date}-{slug}-failed.md` IF the failure reveals a pattern (e.g. "review keeps catching same class of bug after 3 iterations" → write the pattern).
3. Do NOT run ship.
4. Output: `Sprint FAILED at {stage}. Failure: {reason}. Checkpoint at {path}. Manual intervention required.`

#### ABORTED_BY_USER
1. Write checkpoint with state: ABORTED_BY_USER, plus abort reason if user provided.
2. Do NOT run ship. Do NOT extract. Do NOT backflow.
3. Output: `Sprint ABORTED. Checkpoint at {path}. No backflow performed.`

## Terminal state contract

**Only SHIPPED runs ship/extract/backflow.** This is non-negotiable. The other three states are first-class outcomes, not failures of the sprint mechanism.

PAUSED is OK. FAILED is OK. ABORTED is OK. The point of explicit terminal states is to make "sprint didn't ship" not equal "sprint broke" — sometimes the right outcome is to pause.

## Output format

```markdown
---
schema_version: 1
date: {YYYY-MM-DD}
type: sprint
state: {SHIPPED | PAUSED | FAILED | ABORTED_BY_USER}
topic: {topic}
mode: {default | --quick | --design}
iteration: {1, 2, 3}
tags: [sprint, {state-lowercase}]
---

# Sprint — {topic} — {date}

## Capability probe

{probe block}

## Stage progression

| Stage | Status | Output |
|---|---|---|
| 0 capability probe | ok / degraded / abort | {summary} |
| 1 dojo | done / skipped | {prep file path} |
| 2 grill (lite) | done / escape-hatch / skipped | {n questions, log path} |
| 3 execute | done / failed | {iteration} |
| 4 review | done / iteration-exceeded / skipped | {findings count, P0/P1 remaining} |
| 5 ship gate | SHIPPED / PAUSED / FAILED / ABORTED | {state rationale} |
| 6 terminal | {handled per state} | {commit/checkpoint path} |

## Findings (review Stage 4)

{review output condensed}

## Gate Log

{4-option gate decisions per stage}

## Terminal state: {state}

{what happened, why, where the artifact lives}

## OPEN_QUESTIONS

{any axes not addressed}
```

Save to `Inbox/sprint-{slug}-{date}.md` regardless of terminal state.

## Common Rationalizations

Anti-bypass table tying each shortcut to the failure it causes: `@skills/engineering/sprint/lib/rationalizations.md`.
