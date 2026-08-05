---
name: handover
description: |
  Bounded fresh-context handover for unfinished mechanical build units from an existing plan.
  A Claude Code or Codex orchestrator may start a fresh Claude or Codex worker and keeps ownership.
  - /handover [--agent claude|codex] [slug]: sync handoff through `scripts/verbs fresh-run`.
  - /handover --async [slug]: write a self-contained payload to docs/handoffs/ only; does not spawn Codex or touch git.
  Also owns explicit native Agent Worker or parallel read-only research with at most two depth-one workers. Use when a locked, file-scoped task benefits from fresh conversation context or when bounded read-only fan-out is requested. NOT for plan writing, closing finished work, PR/ship flow, or exploratory judgment-heavy work (pull a cross-model take with advisor instead).
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
and git ownership. Use `sprint` for sequential plan-and-build, `advisor` for
judgment, and `ship` for closing finished work.

Do not invoke raw `codex exec` or `claude -p`: the handover protocol supplies the
allowlist, recursion guard, preflight, sandbox, result classification, and model
anchor.

## Native read-only workers

For **Explicit Agent Worker or parallel read-only research**, start at most two
depth-one workers, disable nested delegation, and keep every pilot worker read-only.
Each request carries `objective`, `scope`, `deliverable`, `acceptance`,
`permissions`, and `budget`; each WorkerResult returns `status`, `findings`,
`evidence`, and `gaps`. The main agent verifies evidence, deduplicates findings,
and records elapsed time, resolved model, and runtime events. Record token usage only when the runtime reports it, never from worker estimates.

## Modes

| Invocation | Mode | Ownership |
|---|---|---|
| `/handover [--agent ...] [slug]` | sync fresh worker | source host keeps git |
| `/handover --async [slug]` | async Codex payload only | human runs it later |

Use sync when this turn should wait for one bounded result. Use async only when
the handoff artifact should be stored without spawning a worker.

## Gate

Before either mode, require: supported Claude/Codex platform; no
`VERBS_FRESH_WORKER=1`; a git repo root; a resolved plan; explicit target
runtime, model, effort, and sandbox; and no unsupported fallback. Read
`lib/model-anchors.md` for the selected role and `references/fresh-run.md` for
exact flags. Compare the execution machine with `<runtime>.minimum_cli`; never
silently substitute a runtime or model.

## Sync

Require a clean baseline. Derive remaining U-IDs by running their acceptance
checks, build the four-field request (`goal`, `acceptance`, `working_directory`,
`completed_evidence`), invoke `scripts/verbs fresh-run`, and accept only its one
structured result. Verify artifacts locally; keep review and ship in the source
host. A partial result stays in the diff for local completion; failure falls back
to standard execution.

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
