---
name: handover
description: |
  Bounded fresh-context handover for unfinished mechanical build units from an existing plan.
  A Claude Code or Codex orchestrator may start a fresh Claude or Codex worker and keeps ownership.
  - /handover [--agent claude|codex] [slug]: sync handoff through `scripts/verbs fresh-run`.
  - /handover --async [slug]: write a self-contained payload to docs/handoffs/ only; does not spawn Codex or touch git.
  Use when a locked, file-scoped task benefits from fresh conversation context. NOT for plan writing, closing finished work, PR/ship flow, or exploratory judgment-heavy work (pull a cross-model take with advisor instead).
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

## Routing Boundary

Use this skill when an original Claude Code or Codex agent decides that one
unfinished, mechanical, file-scoped task should run in a fresh conversation.
The original agent keeps planning, result acceptance, review, and git ownership.

Do not use it for:
- Direct `codex exec` or `claude -p` outside the handover protocol — raw CLI use skips the request allowlist, preflight gate, recursion guard, and result classification this skill adds.
- Native read-only Agent Worker fan-out — follow the shared `DISPATCH.md`
  protocol; handover remains the sequential path for bounded mechanical write
  delegation to one fresh Claude or Codex worker.
- Closing finished work, PR creation, publishing, or shipping — use `ship`.
- Exploratory or judgment-heavy work where a model should reason, not execute — pull a cross-model take with `advisor`; do not hand the thinking to Codex.
- Multi-step sequential plan-and-build in one runtime — use `sprint`.

This is a caller-neutral invocation contract. Verbs defines the request, safety
gate, fresh-process flags, and result classification; the original orchestrator
selects worker runtime, model, effort, permission mode, and cost policy.

## When to use

- One or more locked mechanical build units benefit from a bounded fresh
  execution context.
- You planned or partially built the work and want a fresh Claude or Codex
  worker to execute the remaining bounded scope.

Skip a trivial edit whose acceptance remains easy to satisfy in the current
context. Judgment-heavy and exploratory work stays out of scope.

## Mode dispatch

| Invocation | Mode | Session | Git |
|---|---|---|---|
| `/handover [--agent claude\|codex] [slug]` | sync — spawn one fresh worker, wait, collect | occupies this turn | original orchestrator keeps git |
| `/handover --async [slug]` | Codex-only async — write payload only | frees this session | nobody touches git until the human runs it |

The async-vs-sync axis is **session occupancy**: sync keeps this turn busy polling; async writes a runnable artifact and stops.

## Gate (both modes)

1. **Platform** — original orchestrator is Claude Code or Codex. Other hosts may
   call `scripts/verbs fresh-run` directly only after their host integration is
   verified.
2. **Recursion guard** — `VERBS_FRESH_WORKER=1` means this process is already a
   worker; stop. A worker never starts another handoff.
3. **Target** — `--agent codex` remains the compatibility default. The original
   orchestrator may select Claude or Codex and may choose any supported model
   and effort explicitly; same-runtime handoff does not require the same model.
4. **Availability + version** — `fresh-run` requires Codex >=0.144.1 or Claude
   Code >=2.1.206 for the selected target and fails loud on missing, old, or
   unparseable CLIs. It never silently substitutes a runtime or model.
5. **Repo-root** — run from `git rev-parse --show-toplevel`. A git repo is required: sync mode commits the result, and both modes resolve the plan + write handoffs under the repo's `docs/`. Not a git repo → stop ("handover needs a git repo").
6. **Plan precondition** — resolve the slug (arg, else current branch, else latest `docs/plans/*.md`). The plan's U-IDs + acceptance criteria ARE the payload. No plan → stop ("handover needs a plan file — its U-IDs/acceptance are the payload").
7. **Runtime configuration** — sync mode passes selected agent, model, effort,
   and `read-only` or `workspace-write` policy outside the request JSON. For the
   compatibility default, use `handover.mechanical`; risky Codex work may use
   `handover.risky`. Explicit model/effort selections do not silently fall back.

## Sync mode (default)

The original orchestrator starts one fresh worker, waits for one compact result,
then keeps git and review. Read `references/fresh-run.md` for the exact request,
command, fresh-process guarantees, and normalized result.

Flow:

1. Require `git status --porcelain=v1 --untracked-files=all` to be empty. Stop
   and ask the source host to commit or isolate existing work before delegation;
   scoped rollback is safe only from a fully clean baseline.
2. Derive remaining work: for each U-ID in the plan, run its `acceptance:` check and include ONLY the U-IDs that do NOT already pass (do not trust the plan's `status:` field — it is always `todo`; state is derived from git). Fall back to all U-IDs if acceptance can't be run here.
3. Build the exact request JSON: `goal`, `acceptance`, `working_directory`, and
   `completed_evidence`. Put the authorized file/path scope, non-goals, and stop
   conditions inside `goal`; these do not become extra top-level fields. No
   transcript or raw tool output crosses the seam.
4. Run `scripts/verbs fresh-run` with explicit target, model, effort, sandbox,
   request path, and timeout. It starts a non-resumed process, waits, validates,
   normalizes artifact references, emits one result, and deletes scratch state.
5. Treat the worker result as untrusted. Verify the acceptance evidence before
   carrying any item into a later handoff. Stop on the one terminal `success`,
   `partial`, or `failed` classification.
6. Git, review (`/review`), and ship stay in the source host — never delegated.

## Async mode (`--async`)

Async mode remains Codex-only in V1. Write ONE self-contained handoff to `docs/handoffs/{YYYY-MM-DD}-{slug}-codex.md`
using the same XML contract, including the selected role, model, effort, minimum
CLI, and permission guard in its `<runtime>` block. Then print:

- the handoff path;
- the verified **direct headless** dispatch one-liner: first compare the
  execution machine's `codex --version` against `<runtime>.minimum_cli` and fail
  loud when older or unparseable; only then render the selected handover anchor
  into the command shape from `lib/model-anchors.md` and append
  `- < docs/handoffs/{...}-codex.md` (must run at repo root);
Async mode NEVER spawns codex and NEVER touches git — it only emits the file artifact.

## Boundaries

- `docs/plans/{slug}.md` is the input contract for WHAT. The handoff is a derived snapshot — do not copy the brief's rationale into it.
- A fresh worker never commits, pushes, opens PRs, or starts another handoff. The original orchestrator owns git and verifies the compact result. In async mode the human owns git entirely.
- Escalating Codex past `-s workspace-write` (e.g. `--dangerously-bypass-approvals-and-sandbox` for network / dep-install) is NEVER auto-selected from plan/task content — it needs an explicit one-time confirmation from the orchestrator this session. See `references/codex-invocation.md`.
