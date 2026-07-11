---
name: sprint
type: skill
description: |
  Focused execution session: from "I want to do X" to shipped or explicitly paused/failed/aborted. Internal flow: prep, grill (lite), execute, review, ship. Triggers on /sprint, "sprint on this", "let's ship X", "focused session". Routes UI work to `ui`, bugs to `debug`.
reads:
  - repo: lib/capability-probe.md
  - repo: lib/escape-hatch.md
  - repo: lib/push-once.md
  - repo: lib/gate-contract.md
  - repo: lib/learning-recall.md
  - repo: lib/model-anchors.md
  - repo: skills/productivity/grill/SKILL.md
  - repo: skills/productivity/ui/SKILL.md
  - repo: skills/engineering/debug/SKILL.md
  - repo: skills/engineering/review/SKILL.md
  - repo: skills/engineering/ship/SKILL.md
  - repo: lib/verify-the-test-loop.md
  - repo: skills/engineering/sprint/lib/rationalizations.md
  - repo: skills/engineering/sprint/lib/aggregator-test-checklist.md
  - repo: skills/engineering/sprint/references/codex-delegation.md
  - repo: knowledge/**
  - repo: docs/learnings/**
  - repo: docs/plans/**
writes:
  - cli: stdout
  - git: commits via /ship
domain: shared
classification: lifecycle-flow
capability_required:
  - writable-cwd
  - lib/capability-probe.md
  - lib/escape-hatch.md
  - skills/productivity/grill
  - skills/engineering/review
  - skills/engineering/ship
user-invocable: false
---
# Sprint — focused 1-2 hour execution

> A sprint has a whistle and a finish line. You walk in with a topic. You walk
> out with one of four states: SHIPPED, PAUSED, FAILED, or ABORTED_BY_USER.
> Only a fully approved run attempts `ship`; SHIPPED is recorded only after
> delivery succeeds. Other outcomes emit a checkpoint candidate to the host.

## When to invoke

- 1-2 hour focused work on a specific topic
- "Let's ship X today" / "sprint on this"
- Coming out of `grill --brief` with an approved brief
- Bug fix that needs review + ship discipline (was `commands/fix.md`)
- Quick ship on a small change with `--quick` flag (was `commands/quick.md`)

## When to skip

- Trivial 1-line change (just edit + commit)
- Multi-day project (use `grill --brief` first, then sprint per session)
- Pure planning / scoping (use `grill --brief`, not sprint)

## Modes

- Default: full sprint (prep → grill lite → execute → review → ship)
- `--quick`: skip prep + grill, go execute → review → ship
- `--design`: auto-invoke `ui` skill at execute stage (replaces `commands/design.md`)
- `--plan {path|slug}`: execute against a durable plan at `docs/plans/{slug}.md` (the artifact `grill --brief` Stage C+ emits). Sprint reads it READ-ONLY and derives per-task progress from git — see Stage 3 plan-driven execution. Auto-detect rule: slugify the topic the same way `grill --brief` does and check for `docs/plans/{that-slug}.md` (exact slug, no fuzzy match); if the sprint began from a `grill --brief` brief, use the plan path it printed. If none found, run conversationally.
- `--continue {slug}`: resume a PAUSED sprint. Skips prep + grill, loads
  `docs/plans/{slug}.md`, re-derives completed U-IDs from git + acceptance, and
  resumes at the first non-done task. A host-provided prior checkpoint may add
  context, but the skill does not select or persist a state file.
- `--delegate codex`: in Stage 3, hand a batch of mechanical units to Codex (synchronous, in-loop) via the `/handover` invocation. OFF unless you pass this flag; sprint otherwise uses the host's normal execution mechanism and never auto-delegates across runtimes. A batch of ≥3 mechanical units is the advisory threshold worth surfacing the flag at, NOT an auto-trigger. Requires a plan file. See `references/codex-delegation.md` for the batch loop; the single-invocation mechanics live in `skills/engineering/handover/references/codex-invocation.md`. For ASYNC handover that frees this session, use `/handover --async`.

## Stages

### Stage 0: Capability probe

@../../../lib/capability-probe.md

Abort or degrade per probe rules. Output probe block as opening.

### Stage 1: Prep (skip if `--quick`)

Run a minimal in-session prep pass:

1. Scan local project docs for the topic with `rg` / `find` (`docs/sessions`, `docs/learnings`, `knowledge`, and `docs/plans` when present).
2. Surface only concrete gotchas, half-built attempts, and relevant prior decisions. No fabricated pattern matching.
3. If no useful history exists, say "No relevant prior context found" and continue.

Run the learnings recall per [`@../../../lib/learning-recall.md`](../../../lib/learning-recall.md): surface the top 3-5 learnings relevant to the sprint topic so plan-time context carries past lessons, and use them in the plan, not just list them. Resolve the repo's configured learning directory; if none exists, skip with a note.

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
- For `--continue`: load the plan and any checkpoint the host explicitly
  supplied, run the idempotency check across all U-IDs, and resume at the first
  non-done task. Git + acceptance remain authoritative. Skip Stage 1 and Stage 2.
- If a task has no checkable `acceptance:`, fall back to the `iteration` counter for that task and flag it in the narrate line.

When no plan file is present, execute conversationally. Done-condition for the conversational path: each build unit's acceptance condition (Execution mode step 1) is re-verified by the architect — subagent-reported green is never trusted. Execute is not complete until every unit's acceptance re-verifies, matching the plan-driven path's idempotency check.

**Execution mode (default: architect + delegated build when the host supports it):** the main session owns architecture, review, and integration. For each non-trivial build unit:

1. Main session writes a tight spec: files in scope, seams/interfaces, hard constraints, style anchor (which existing file to imitate), and a checkable acceptance condition per unit.
2. When the host exposes isolated subagents, dispatch one unit per subagent and parallelize ONLY file-disjoint units. The subagent gets the spec, not the architect's full context. Model choice and global dispatch policy remain host concerns; this skill defines the work-unit contract only.
3. Main session reviews the returned diff against the spec, re-verifies acceptance itself (build/test — subagent-reported green is never trusted), fixes integration seams, and owns all git operations.

Carve-outs:
- **Trivial unit** (single-file, mechanical, ~20 lines or less): main session edits directly — dispatch overhead exceeds the work.
- **Interface-discovery work** (the seam itself is unknown until you write it): main session may execute the seam-defining unit, then dispatch the rest against the now-fixed interface.
- **Runtime without a subagent mechanism** (e.g. plain `codex exec`): degrade to main-session execution and say so in the narrate line.

Rationale: the architect's context window and judgment are the scarce resource; spend them on spec, review, and integration, not keystrokes. "Faster if I just write it myself" is the failure mode this default exists to prevent — it was true for the single unit and false for the sprint.

**Codex delegation:** when `--delegate codex` is set (the rule lives in Modes, above), Stage 3 hands the batch of mechanical units to Codex via `/handover`; planning, review, and git stay in the foreground host. It is SYNCHRONOUS (occupies this turn polling); for an artifact-only async handoff, use `/handover --async`. Read `lib/model-anchors.md`; gate, invocation contract, batching, and circuit breaker live in `references/codex-delegation.md`.

Stage 3 runs with the host's active engineering discipline plus `careful` and `review`: root cause before fix, minimal diff, and verify before done. For a UI build, follow `ui`; for a bug, follow `debug`. There is no separate persona-lens step.

Track `iteration` counter starting at 1.

**Step-level narrate** (Mnilax Rule 10, adopted 2026-05-24): every distinct sub-step within Stage 3 (file edit, command run, validation pass) must end with a one-line narrate:

```
done: {what was completed} | verified: {what was checked} | remaining: {next sub-step}
```

Mirrors background-session protocol (`result:` / `needs input:` / `failed:`) but applied to foreground sprint. Purpose: at 50-min mark, model + user both know where the sprint is even if context drifts. Skip ONLY for trivial 1-line edits (`--quick` mode auto-skips). If you completed something you can't summarize back, stop — you've drifted past the last known-good state.

**Multi-source aggregator dispatch-branch test**: if this sprint adds a new dispatch branch / per-source handler / per-source filter to a multi-source aggregator, the handler-level integration test for the new branch is part of Stage 3 implementation, NOT Stage 4 review iter 2. Read `skills/engineering/sprint/lib/aggregator-test-checklist.md` for the trigger shapes and test shape.

### Stage 4: Review + verify gate

Invoke `skills/engineering/review/SKILL.md`. Parse output for:

- P0 + P1 findings (excluding entries already AUTO-FIXED by review skill)
- `COVERAGE GAP` entries
- `SCOPE DRIFT` entries

Three branches:

1. **All counts = 0** (clean review) → proceed to Stage 5 (ship gate)
2. **`iteration >= 3` and any non-zero** → terminal state = FAILED, do NOT auto-loop
3. **`iteration < 3` and any non-zero** → present 4-option gate per `lib/gate-contract.md`:

   ```
   Review found:
     {n} P0 / {n} P1 / {n} COVERAGE GAP / {n} SCOPE DRIFT

   [approve] feed findings to execute context, return to Stage 3, iteration++
   [edit]    user supplies modified findings, return to Stage 3, iteration++
   [reject]  log findings as OPEN_QUESTIONS, proceed to Stage 5 with state=PAUSED
   [skip]    log findings as OPEN_QUESTIONS, proceed to Stage 5 with state=PAUSED
   ```

**Auto-loop semantics**: approve/edit increment iteration counter and loop back to Stage 3. Stage 3 receives findings as additional context, then re-runs execute. Stage 4 fires again at end. Max 3 loops; iteration=3 with non-zero count → FAILED.

**Why bounded**: 3 loops is the empirical "if you can't fix it in 3 review-cycles, the diagnosis itself is the bug" cap (the 3-strike escalation rule). After FAILED, user does manual intervention (no auto-retry).

### Stage 5: Ship gate (terminal state decision)

**Deploy-proof precondition (if the deliverable was validated by a human
manually exercising a build/deploy).** Before `state = READY_TO_SHIP` or before
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
    state = READY_TO_SHIP
elif user_signals_pause ("park this" / "暫停" / "later"):
    state = PAUSED
elif execute_failed OR review_iteration_exceeded:
    state = FAILED
elif user_signals_abort ("stop" / "abort" / "cancel"):
    state = ABORTED_BY_USER
else:
    state = PAUSED  # name the unmet ship precondition
```

Print the computed gate state. `READY_TO_SHIP` is intermediate, not a terminal
result. The user can override it before delivery.

### Stage 6: Terminal state handling

#### READY_TO_SHIP → SHIPPED or PAUSED
1. Invoke `skills/engineering/ship/SKILL.md` — runs commit + push + PR if applicable.
2. If ship succeeds and returns its required PR + pushed commit/branch evidence,
   set terminal state to SHIPPED. If ship fails or evidence is missing, set
   terminal state to PAUSED, name the blocker, and continue with the PAUSED
   handler. Never report SHIPPED before delivery evidence exists.
3. Emit a compact evidence summary, any learning candidates, and a `DEFERRED`
   list. Do not persist them or mutate a project tracker; the host/project owns
   those destinations.
4. Output sprint summary only after success: `Stage 1-6 complete, SHIPPED.
   {commit-hash}, {PR-url}, {evidence summary}.`

#### PAUSED
1. Emit this checkpoint candidate to stdout for the host/project to persist if
   desired:
   ```
   state: PAUSED
   stages_completed: [0, 1, 2, 3]
   stage_3_progress: {what's done, what's pending}
   plan: docs/plans/{slug}.md   # if one exists; --continue re-derives done/todo from it + git
   resume_with: /sprint --continue {slug}
   ```
2. Do NOT retry ship or persist learning candidates.
3. Output: `Sprint PAUSED. Resume with: /sprint --continue {slug}.`

#### FAILED
1. Emit a checkpoint candidate with state: FAILED, failure reason, and stuck-point.
2. Emit a pitfall candidate IF the failure reveals a reusable pattern. Do not persist it.
3. Do NOT run ship.
4. Output: `Sprint FAILED at {stage}. Failure: {reason}. Checkpoint candidate emitted. Manual intervention required.`

#### ABORTED_BY_USER
1. Emit a checkpoint candidate with state: ABORTED_BY_USER and any supplied reason.
2. Do NOT run ship or persist learning candidates.
3. Output: `Sprint ABORTED. Checkpoint candidate emitted.`

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
| 1 prep | done / skipped | {prior context summary} |
| 2 grill (lite) | done / escape-hatch / skipped | {n questions, log path} |
| 3 execute | done / failed | {iteration} |
| 4 review | done / iteration-exceeded / skipped | {findings count, P0/P1 remaining} |
| 5 ship gate | READY_TO_SHIP / PAUSED / FAILED / ABORTED | {state rationale} |
| 6 terminal | {handled per state} | {commit evidence / checkpoint candidate} |

## Findings (review Stage 4)

{review output condensed}

## Gate Log

{4-option gate decisions per stage}

## Terminal state: {state}

{what happened, why, where the artifact lives}

## OPEN_QUESTIONS

{any axes not addressed}
```

Emit this block to stdout. The host/project may persist it; Verbs does not
select or write a project-state path.

## Common Rationalizations

Anti-bypass table tying each shortcut to the failure it causes: `@skills/engineering/sprint/lib/rationalizations.md`.
