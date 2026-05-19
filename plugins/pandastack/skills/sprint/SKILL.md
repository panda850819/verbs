---
name: sprint
mode: skill
description: |
  Focused execution session — 1-2 hours from "I want to do X" to "X is shipped or explicitly paused/failed/aborted". Internal flow: dojo (prep) → grill (lite) → execute → review → ship. Terminal states are explicit (SHIPPED / PAUSED / FAILED / ABORTED_BY_USER), only SHIPPED triggers backflow.
  Triggers on /sprint, "sprint on this", "let's ship X", "focused session". Replaces `commands/sprint.md` (deprecated). Auto-routes to design-lead skill on UI scope detection.
  Skill metaphor: a real sprint with a starting whistle and a finish line, not a vague "let's work on it".
reads:
  - repo: lib/capability-probe.md
  - repo: lib/escape-hatch.md
  - repo: lib/stop-rule.md
  - repo: lib/push-once.md
  - repo: lib/persona-frame.md
  - repo: lib/gate-contract.md
  - repo: skills/dojo/SKILL.md
  - repo: skills/grill/SKILL.md
  - repo: skills/review/SKILL.md
  - repo: skills/ship/SKILL.md
  - repo: skills/design-lead/SKILL.md
  - repo: lib/verify-the-test-loop.md
  - vault: knowledge/**
  - vault: docs/learnings/**
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
  - lib/stop-rule.md
  - skills/dojo
  - skills/grill
  - skills/review
  - skills/ship
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
- Pure planning / scoping (use `/office-hours` or `/boardroom`, not sprint)

## Modes

- Default: full sprint (dojo → grill lite → execute → review → ship)
- `--quick`: skip dojo + grill, go execute → review → ship
- `--design`: auto-invoke design-lead skill at execute stage (replaces `commands/design.md`)

## Stages

### Stage 0: Capability probe

@../../lib/capability-probe.md

Abort or degrade per probe rules. Output probe block as opening.

### Stage 1: Dojo (skip if `--quick`)

Invoke `skills/dojo/SKILL.md` for the topic. Output prep brief, print path. User reads, then continues.

### Stage 2: Grill (lite, skip if `--quick`)

Run `skills/grill/SKILL.md` in default (adversarial) mode with **3-question cap** (not full 7). Cover:

- Existence (does this exist already? half-built somewhere?)
- Scope boundary (what's IN, what's OUT)
- Reversibility (two-way / one-way door?)

@../../lib/push-once.md applies. @../../lib/escape-hatch.md applies. If user signals stop, log and skip to Stage 3.

### Stage 3: Execute

@../../lib/skill-decision-tree.md applies — read the persona routing table.

Detect task shape from grill output (Stage 2) and load the matching persona skill as **in-session cognitive lens** (NOT subagent dispatch — sprint is single-track main-session-executor).

Routing (read `lib/skill-decision-tree.md` § "Persona routing table"):

| Task signal | Load skill |
|---|---|
| Code / refactor / debug / fix / feature impl / tech-stack 選型 / DB schema / API contract (default) | `skills/eng-lead/SKILL.md` |
| UI / interaction / layout / visual hierarchy / accessibility | `skills/design-lead/SKILL.md` |
| Multi-team coord / process design / SLA / runbook / on-call | `skills/ops-lead/SKILL.md` |
| Feature scoping / metric / PMF / pricing / user research | `skills/product-lead/SKILL.md` |
| Kill / pivot / scope cut / strategic frame | `skills/ceo/SKILL.md` |

Apply the loaded persona's Soul / Iron Laws / Cognitive Models / On Invoke / Anti-patterns to all Stage 3 work in this same context. Persona is a lens, not a subagent — main session stays the executor.

**Single-persona discipline**: load ONE persona for the whole sprint. If the topic genuinely spans 2+ personas, split into multiple sequential sprints. Mixing personas mid-sprint dilutes the cognitive frame and produces inconsistent output.

Apply minimal-diff + verify + 3-strike escalation (eng-lead iron laws apply even when another persona is the primary lens — they are baseline coding discipline).

Track `iteration` counter starting at 1.

**When scope detection is ambiguous**: ask user once with the candidate personas listed; pick the highest-confidence single one based on user reply. Do not silently default to eng-lead when signals point elsewhere — that misroutes architecture / ops / product work.

**Multi-source aggregator dispatch-branch test checklist**: if this sprint adds a new dispatch branch / per-source handler / per-source filter to a multi-source aggregator (e.g. `if (source.name === "X")` ladder, per-source `evaluateX` filter, per-source `_setXClientForTest` mock seam), **handler-level integration test for the new branch is part of Stage 3 implementation**, NOT Stage 4 review iter 2. Cold reviewer empirically catches this as P0 every time the branch is added without the test (companyos sprints 3 / 5 / 6 = Notion / Slack / Linear all hit this same gap). Test shape: drive `createCallToolHandler` (or equivalent) with one denied-input case + one allowed-input case, assert audit emit shape + that deny does NOT consume any cross-source state (pivot window / cache eviction).

### Stage 4: Review + verify gate (skip if `--quick`)

Invoke `skills/review/SKILL.md`. Parse output for:

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

**Why bounded**: 3 loops is the empirical "if you can't fix it in 3 review-cycles, the diagnosis itself is the bug" cap (mirrors eng-lead's 3-strike escalation rule). After FAILED, user does manual intervention (no auto-retry).

### Stage 5: Ship gate (terminal state decision)

**Deploy-proof precondition (if the deliverable was validated by a human
manually exercising a build/deploy).** Before `state = SHIPPED` or before
asking the user to do that validation: @../../lib/verify-the-test-loop.md
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

#### SHIPPED
1. Invoke `skills/ship/SKILL.md` — runs commit + push + PR if applicable
2. Trigger Extract + Backflow (writes to docs/sessions/, docs/learnings/, possibly Inbox/ship-log/)
3. Output sprint summary: `Stage 1-6 complete, SHIPPED. {commit-hash}, {PR-url if any}, {extract summary}.`

#### PAUSED
1. Write `Inbox/sprint-{slug}-{date}.md` checkpoint:
   ```
   state: PAUSED
   stages_completed: [0, 1, 2, 3]
   stage_3_progress: {what's done, what's pending}
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
| 3 execute | done / failed | {iteration, design-lead invoked Y/N} |
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

| Rationalization | Reality |
|---|---|
| "I already know this codebase, skip dojo" | The past-you who knew it was a different model context. Cold scans surface the half-built attempt you forgot about. |
| "Topic is clear, skip grill" | If it were clear, you'd be in execute mode, not opening `/sprint`. The 3-question cap costs 2 minutes; ambiguity costs a re-do. |
| "Small change, skip review" | Small changes are where regressions hide because nobody looks. P0 review still runs in 90 seconds on a small diff. |
| "One more iteration will fix it" (iter ≥ 3) | 3-strike rule is empirical: at iteration 4 the diagnosis itself is the bug. State=FAILED, manual intervention. |
| "It's partly UI, partly backend, just mix personas" | Mixed personas dilute the cognitive lens and produce inconsistent output. Split into two sequential sprints. |
| "Sprint within a sprint for the sub-task" | Flatten. Either the sub-task is a Stage 3 step in the current sprint, or it's a separate sprint that fires after this one ends. |
| "Review found P1 but ship anyway" | Terminal state contract is load-bearing. P1 unaddressed = state ≠ SHIPPED. Mark PAUSED with the open finding logged, or fix and re-review. |
| "BUILD SUCCEEDED, so the user is testing my fix" | Success proves the compiler ran, not that the deployed artifact is the one you built. Deploy-proof before human test (`lib/verify-the-test-loop.md` R1). |
| "My instrumentation didn't show in their screenshot, weird — anyway" | That is the pipeline alarm, not a fluke. Stop, verify the loop (R1/R2). The session this rule exists for lost days exactly here. |
| "3 lifecycle variants failed, the 4th is my escalation" | Same-shape failure ×3 ⇒ the abstraction/loop is wrong (R4). A 4th variant of the same approach is strike 4, not escalation. Switch primitive or re-verify the loop. |
| "Re-asking the user to re-test is just one more round" | Each contaminated human round-trip is the expensive unit. If the loop needs repeated round-trips, harden the loop first (R3), then iterate. |

## Anti-patterns

- ❌ Calling sprint with no clear topic ("let's sprint on stuff") — sprint requires a single topic
- ❌ Auto-shipping on FAILED state ("review found P1 but ship anyway") — terminal state contract is load-bearing
- ❌ Skipping Stage 0 capability probe ("substrate's fine, let's go") — probe each run, state changes
- ❌ Running sprint inside another sprint ("sprint within sprint") — flatten or use sub-tasks within stage 3
- ❌ Iteration > 3 — that's a FAILED state, not "let me try once more"
- ❌ Marking SHIPPED on human-validated work without deploy-proof (`lib/verify-the-test-loop.md`) — the user may have tested a stale/ghost artifact
- ❌ 4th variant of the same failing approach billed as "escalation" — switch the abstraction, not the parameters
- ❌ Treating PAUSED as failure — PAUSED is a legitimate outcome, no extract/backflow

## Origin

- `commands/sprint.md` (deleted v1.1) — replaced by this skill
- codex Q4 (2026-05-04 review) — flagged abort UX, added 4-state terminal contract
- codex Q6 (2026-05-04 review) — added Stage 0 capability probe
- pandastack lifecycle template (B-pre design) — sprint is the canonical Stage 0-7 lifecycle implementation
