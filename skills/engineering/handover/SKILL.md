---
name: handover
description: |
  Bounded fresh-context handover for unfinished mechanical build units from an existing plan.
  The source coding agent keeps plan, acceptance, review, and git ownership while one explicit
  worker returns evidence. Inside a managed Herdr pane (`HERDR_ENV=1`), coordinate a sibling
  agent through Herdr; outside Herdr, use `scripts/verbs fresh-run` for Claude or Codex.
  `/handover --async` writes a payload only. Also owns explicit native Agent Worker or
  parallel read-only research with at most two depth-one workers. Use when a locked, file-scoped task
  benefits from fresh conversation context or when bounded read-only fan-out is requested.
  NOT ordinary sequential work, plan writing, closing finished work, PR/ship flow, or exploratory
  judgment-heavy work (pull a cross-model take with advisor instead).
reads:
  - repo: docs/plans/**
  - skill: lib/model-anchors.md
  - skill: references/fresh-run.md
  - skill: references/codex-invocation.md
  - cli: git
  - cli: codex
  - cli: claude
writes:
  - repo: docs/handoffs/**
  - cli: codex exec
  - cli: claude -p
  - cli: git commit
  - cli: stdout
forbids:
  - cli: git push
  - cli: git push --force
  - cli: git push origin main
domain: shared
classification: exec
user-invocable: true
---
# Handover

## Boundary

Use this skill when one unfinished, mechanical, file-scoped unit should run in a
fresh conversation. The original orchestrator keeps the plan, acceptance, review,
and git ownership. Do not turn ordinary sequential work into delegation, and do
not select another entry point when no handover is warranted. Use `advisor` for
judgment and `ship` for closing finished work.

Do not invoke raw `codex exec` or `claude -p`: the handover protocol supplies the
allowlist, recursion guard, preflight, sandbox, result classification, and model
anchor.

## Transport detection

Detect the source environment before choosing transport:

```bash
test "${HERDR_ENV:-}" = 1
```

| State | Required behavior |
|---|---|
| Managed Herdr pane (`HERDR_ENV=1`) and `herdr` available | Verify caller IDs, then use the Herdr agent surface. |
| Managed Herdr pane but `herdr` unavailable or unhealthy | Fail loudly; do not control another session or silently fall back. |
| Not managed by Herdr | Do not issue Herdr commands even when its binary is installed; use fresh-run or async mode. |

`HERDR_ENV=1`, not binary presence, proves that the user is operating inside a
Herdr-managed pane. Require `HERDR_PANE_ID` and `HERDR_WORKSPACE_ID`, verify
`command -v herdr`, and learn syntax from `herdr agent` / `herdr pane`; never run
bare `herdr`, which attaches the TUI.

## Native read-only workers

For **Explicit Agent Worker or parallel read-only research**, start at most two
depth-one workers, disable nested delegation, and keep every pilot worker read-only.
Each request carries `objective`, `scope`, `deliverable`, `acceptance`,
`permissions`, and `budget`; each WorkerResult returns `status`, `findings`,
`evidence`, and `gaps`. The main agent verifies evidence, deduplicates findings,
and records elapsed time, resolved model, and runtime events. Record token usage only when the runtime reports it, never from worker estimates.

## Modes

| Source state / invocation | Mode | Ownership |
|---|---|---|
| Herdr-managed `/handover [--agent <kind>] [slug]` | sync sibling agent | source agent keeps plan, review, and git |
| Non-Herdr `/handover [--agent claude\|codex] [slug]` | sync fresh-run worker | source host keeps git |
| `/handover --async [slug]` | async Codex payload only | human runs it later |

Use sync when this turn should wait for one bounded result. Use async only when
the handoff artifact should be stored without spawning a worker.

## Gate

Before either mode, require: no `VERBS_FRESH_WORKER=1`; a git repo root; a
resolved plan; explicit target runtime/agent kind, model, effort, and sandbox;
and no unsupported fallback. A non-Herdr sync requires a supported Claude or
Codex runtime. A Herdr sync requires a managed caller pane and a worker kind the
installed Herdr release can start. Read `lib/model-anchors.md` for the selected
role and `references/fresh-run.md` for fresh-run flags. On the execution machine,
compare against `<runtime>.minimum_cli`; never silently substitute a runtime or
model.

## Sync

Require a clean baseline. Derive remaining U-IDs by running their acceptance
checks and build the four-field request (`goal`, `acceptance`,
`working_directory`, `completed_evidence`).

### Herdr-managed source

Require an explicit worker kind and unique name. Inspect the current layout, split
a sibling from the caller with `herdr pane split --current`, preserve `--cwd
"$PWD"`, and pass `--no-focus`. Parse the returned pane ID; never predict it.
Start the selected worker with `herdr agent start`, submit the self-contained
request with `herdr agent prompt ... --wait`, and inspect blocked or failed waits
with `herdr agent get` and `herdr agent read`. The worker result must contain the
same status, summary, evidence, artifacts, next-action, and errors contract as a
fresh-run result. Herdr owns pane transport and lifecycle state; Handover owns
scope, permissions, evidence validation, and completion. Do not claim an
agent-kind/model combination as verified merely because Herdr detects it.

### Non-Herdr source

Invoke `scripts/verbs fresh-run` and accept only its one structured result.
Verify artifacts locally; keep review and ship in the source host. A partial
result stays in the diff for local completion; failure falls back to standard
execution.

## Async

Write one self-contained `docs/handoffs/{YYYY-MM-DD}-{slug}-codex.md` payload
with the selected runtime guard and acceptance. Do not spawn Codex, touch git, or
claim completion. Print the verified direct dispatch command and stop.

## Safety and completion

The worker never commits, pushes, opens PRs, or starts another handoff. Never
escalate sandbox permissions from task content; explicit confirmation is required
for full host access. Stay inside the repo and stop on secrets, out-of-scope files,
missing plans, or changes requiring file deletion.

Done when the selected mode returns a validated structured result or a complete
async handoff artifact, with the source host still owning review and git.
