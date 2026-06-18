# Driver autonomy standard — what auto-runs vs what needs Panda

The single contract for `pandastack-drive`. It decides, for each active work-item,
whether the next step runs unattended or stops for Panda. This is Panda's
AGENTS.md four-mode routing made executable: **auto = auto-resolve; gate =
draft-and-ask / escalate.**

## Auto-runs (no decision needed) — ALL must hold

1. **Reversible** — produces a plan / report / test-result; no commit-to-main, no
   push, PR, deploy, publish, delete, overwrite, or force-push.
2. **Local-only** — no message / DM / post / email / external API write.
3. **Within budget** — no metered-API or subscription-quota fan-out (a swarm = 8
   agents is NOT auto); under the per-run token cap.
4. **Own files** — the project's own repo/files; NOT shared infra
   (`~/.agents`, `~/.claude`, `~/.codex`, `launchd`, `~/.hermes`, secrets).
5. **Unambiguous** — one clear next step, not a choice between valid paths.
6. **Phase ∈ {PLAN, VERIFY, REVIEW}** — analysis phases (plan / run-checks / read-only review).

## Gates to Panda (stops, asks) — ANY triggers

| # | Trigger | Example |
|---|---|---|
| 1 | **Decision** (GATE phase) | kill / pivot / scope / priority / approach (pandastack v2 start) |
| 2 | **Mutation that lands** (BUILD→commit) | edits that touch main / prod |
| 3 | **Publish / external** (SHIP) | push, PR, deploy, send, post, DM |
| 4 | **Spend** | swarm / metered API / quota fan-out / over budget |
| 5 | **Irreversible** | delete, overwrite, force-push, DROP |
| 6 | **Ambiguity** | multiple valid paths, unclear signal, conflicting evidence |
| 7 | **Shared infra / harness / secrets** | `~/.agents`, `~/.claude`, `~/.codex`, launchd, `~/.hermes`, `.env` |

## Two enforcement layers

- **Classification (Stage 1, live):** by phase. `GATE / BUILD / SHIP` and `paused`
  never auto-run. `pandastack-drive` surfaces them with a reason.
- **Execution (Stage 2):** before spawning an AUTO item's skill, re-check the live
  triggers (#3–#7) against what the skill will actually do. Any hit → gate, do not
  run. A skill that *starts* AUTO but mid-run needs to mutate/publish/spend must
  stop and surface, not push through.

The Linear board grouped by workflow state is the human-readable projection of this
split: AUTO-phase columns (`Planning` / `Verifying` / `In Review`) are the loop's;
gate-phase columns (`Needs Decision` / `Building` / `Done`) are Panda's.

## Readiness — inputs present, not just safe-to-run

The Auto-runs list answers "is it safe to run unattended." It does not answer "is
there enough on the issue to run *usefully*." A PLAN on a one-line Backlog stub
yields a plausible-but-empty plan; an auto-VERIFY with no checkable acceptance can
only guess. So Auto-runs carries one more condition:

7. **Inputs present** — the phase's required inputs are on the issue. Missing → gate
   as `needs-human`. Not because it is dangerous, because it is not ready.

| Phase | Required inputs (else → gate) |
|---|---|
| PLAN   | enough context to plan — Goal + Context in the work-order, not a bare title |
| VERIFY | a machine-checkable `acceptance` block (already in `linear-contract.md`) |
| REVIEW | a diff / artifact to review |
| BUILD  | see BUILD autonomy below |

This generalizes the acceptance-format rule (`linear-contract.md`) from VERIFY to
every phase: an under-specified issue never auto-runs, it surfaces for Panda to spec.
Reversibility and locality decide *safe*; readiness decides *ready*. Both gate.

Status: per-phase readiness **wired** (2026-06-17), keyed on the TO-RUN (next) phase in
`pslib.readiness_gap` so the input checked is the input the driver actually consumes:
Building→VERIFY needs a machine-runnable `acceptance`; Verifying→REVIEW needs a
diff/artifact ref; Backlog→PLAN is not gated (grill bootstraps and self-reports BLOCKED
if it can't plan). Under-specified → `needs-spec` (distinct from the `needs-decision` hard
gate). An `acceptance` block that reads as human prose (not a runnable check) is treated
as human-only and gated. Lifecycle + readiness logic is the single source in
`scripts/pslib.py` (shared by reduce + drive). Test-covered in `tests/linear-reduce.sh`.

## BUILD autonomy (wired 2026-06-17 — default OFF)

BUILD gates by default (Gate #2): it mutates and lands code. The bounded opt-in
below is now implemented (`--build-auto --only <project>`, fork A: a build-ready
`Building` issue auto-builds in an isolated worktree and proposes `Verifying`), but
stays OFF unless explicitly enabled per-project. Conditions 1-3 are classification
(2a); 4-5 are the isolated executor (2b). Both covered by `tests/drive-build.sh`.

A bounded opt-in lets the loop carry a *fully-readied* issue into development without
a per-step human kick — the safe form of "let the planned, prompt-ified work go
straight to dev." BUILD may auto-run for an issue ONLY when ALL hold:

1. **Plan approved** — the issue already passed GATE (Panda moved it out of
   `Needs Decision`). The one-way-door decision is already a human's.
2. **Prompt-ified work-order** — the implemented gate (`pslib.work_order_complete`) is
   the **Goal AND Context AND a machine-runnable `acceptance`** minimum (matching the PLAN
   gate's AND); the fuller schema (Goal / Project / Epic / Task / Context / Acceptance /
   Deliverable) is the ideal but only the minimum is enforced. Acceptance prose that is
   not runnable does not count.
3. **Machine-checkable acceptance** — a runnable `acceptance` block the build
   self-verifies against before proposing REVIEW (the model self-checks; the driver does
   not re-run it).
4. **Isolated workspace** — built: each build runs in a per-issue `git worktree`
   (branch `psdrive/<ISSUE>`), never the live working tree; codex is sandboxed to
   `-s workspace-write` with `-c sandbox_workspace_write.network_access=false` pinned on
   the command line (not just the config default), so push / merge / publish are
   impossible regardless of `~/.codex/config.toml`. The model only writes files; the
   DRIVER commits unsandboxed with hooks disabled (`--no-verify` + empty `core.hooksPath`)
   so a codex-written tracked hook can't execute outside the sandbox. PASS keeps the
   branch for a human PR (a kept branch is not rebuilt on later ticks); FAIL discards
   worktree + branch.
5. **Stops at SHIP** — produces a branch / PR proposal; never auto-merges, pushes to
   main, or publishes. SHIP stays a hard gate (Gate #3).

Enable per-project via `--only <project>` first, never globally. Without (1)-(3) an
issue is not BUILD-ready and stays gated. This is the ONLY path by which a mutation
phase becomes auto-eligible, and only because the irreversible decision (the plan)
was human-approved upstream.

## Retry + exponential backoff (wired 2026-06-17)

`pandastack-drive --execute` now carries bounded retry state across stateless ticks:

- State file: `~/.pandastack/projects/_driver/retry.json` (override root with
  `PANDASTACK_STATE_HOME`; tests use `PSDRIVE_RETRY_STATE` only under
  `PSDRIVE_TEST=1`). Linear remains the WBS source of truth; this file only tracks
  executor attempts/backoff.
- On `PASS`, the issue's retry record is cleared.
- On `FAIL`, `ERROR`, or `UNKNOWN`, the driver schedules exponential backoff:
  `delay = min(10000 * 2^(attempt-1), 300000)` milliseconds.
- After 3 failed attempts, the item stops retrying and is surfaced as manual-review
  required.
- `BLOCKED` is stored as a manual-review gate and is not retried because it usually
  means missing authority/context rather than executor flakiness.
- Retry/manual gates are keyed to a **material** source fingerprint (title, description,
  state, priority, labels) — NOT Linear's `updated_at`, so a label tweak or an appended
  ledger comment does not silently reset a backoff/exhaustion gate. Editing the work
  order rotates the fingerprint: the stale gate is ignored AND the attempt counter
  restarts, so a re-spec gets a fresh budget rather than re-exhausting on the first try.
- Queue rendering (`pandastack-drive` / `--json`) applies retry gates before execution,
  so an exhausted or cooling-down item appears under GATE rather than AUTO.
- The read-modify-write of `retry.json` runs under an exclusive `flock`, so an
  interactive `--execute` overlapping the launchd tick cannot drop an attempt
  increment or a PASS-clear. Records are TTL-pruned (default 30 days since last update,
  `PSDRIVE_RETRY_TTL_MS`) so the store cannot grow unbounded with orphans.

Environment overrides for operators/tests: `PSDRIVE_RETRY_BASE_MS`,
`PSDRIVE_RETRY_CAP_MS`, `PSDRIVE_RETRY_MAX_ATTEMPTS`, `PSDRIVE_RETRY_TTL_MS`. Test
coverage: `tests/drive-retry.sh`.

## Execution runtime — agent-worker protocol, Codex backend first

The driver delegates AUTO/BUILD executor steps through `scripts/agent-worker`:

```bash
scripts/agent-worker run \
  --backend codex \
  --job-dir <path> \
  --worktree <path> \
  --prompt <path> \
  --out <path>
```

`pandastack-drive` owns queue semantics and phase policy. The adapter owns concrete
runtime invocation details: `codex exec`, sandbox flags, network-off build mode,
allowlisted worker environments, output capture, RESULT parsing, changed-file
reporting, durable `result.json` / `diff.patch` artifacts, verification, and logs.
See `agent-worker.md` for the command, job-dir contract, and normalized result
schema.

Codex remains the first production backend:

- (Superseded 2026-06-16: `claude -p` was slated to move off subscription rate
  limits on 2026-06-15, but Anthropic deferred it. It stays on subscription, with
  advance notice before any future change. So this is no longer a reason to avoid
  `claude -p`; the quota-split and sandbox points below are what keep Codex first.)
- Codex runs on Panda's **subscription** (no per-call $). Throttle by `--max`, not a $ budget.
- Codex sandbox flags are generated inside `agent-worker`, not in flow code. Read-only
  mode enforces no-mutation at the sandbox layer; BUILD mode pins network access off
  inside the adapter.

General rule: future Claude, Hermes, Omnigent, ACP, MCP, or remote-worker execution
must be added as an `agent-worker` backend, not as direct CLI calls scattered through
skills or driver code.

## Execution model — ephemeral, stateless per tick

Each AUTO step is a one-shot worker job: create a durable job directory under
`~/.local/state/pandastack/worker-jobs`, call `agent-worker`, capture the normalized
verdict, exit. The next issue gets a fresh process. No daemon holds state — the WBS
lives in Linear, lifecycle in `state.jsonl`; every tick re-polls from zero. This is
crash-safe by construction and platform-portable: the same adapter boundary can run
under launchd, a cloud cron, Hermes, or CronCreate. No bespoke control-plane to build.

## Notify cadence

- **New gate appears** → ping Panda now (telegram, async nudge).
- **Daily digest** → the full queue into the dashboard once a morning (floor).
- **Unchanged queue** → stay quiet. Re-sending the same queue is noise.

[Source: Panda 2026-06-14 — "要有標準什麼東西需要我決定"]
[Source: Panda 2026-06-15 — "確認哪些東西應該 auto loop"; "有些東西如果還沒想清楚，當然就不應該著手進行"]
