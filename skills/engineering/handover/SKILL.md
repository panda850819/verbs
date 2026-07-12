---
name: handover
description: |
  Explicit Codex handover workflow for unfinished mechanical build units from an existing plan.
  Runs only from a Claude Code orchestrator; Codex/Gemini seats no-op to avoid recursive delegation.
  - /handover [slug]: sync handoff, spawn `codex exec`, poll, collect structured result.
  - /handover --async [slug]: write a self-contained payload to docs/handoffs/ only; does not spawn Codex or touch git.
  Use when a plan has several rote, file-scoped build units and you explicitly want a bounded Codex execution. NOT for plan writing, closing finished work, PR/ship flow, or exploratory judgment-heavy work (pull a cross-model take with advisor instead).
reads:
  - repo: docs/plans/**
  - skill: lib/model-anchors.md
  - skill: references/codex-invocation.md
  - cli: git
  - cli: codex
writes:
  - repo: docs/handoffs/**
  - cli: codex exec
  - cli: git commit
  - cli: stdout
forbids:
  - cli: git push
  - cli: git push --force
  - cli: git push origin main
domain: shared
classification: exec
user-invocable: false
---
# Handover

## Routing Boundary

Use this skill only for an explicit Verbs `/handover`: unfinished mechanical build units from an existing plan are delegated to Codex, while the orchestrator keeps planning, review, and git ownership.

Do not use it for:
- Direct `codex exec` outside the handover protocol — raw CLI use skips the payload contract, the preflight gate, and the result classification this skill adds.
- Native read-only Agent Worker fan-out — follow the shared `DISPATCH.md` protocol; handover remains the bounded path for mechanical write delegation from Claude Code to Codex.
- Closing finished work, PR creation, publishing, or shipping — use `ship`.
- Exploratory or judgment-heavy work where a model should reason, not execute — pull a cross-model take with `advisor`; do not hand the thinking to Codex.
- Multi-step sequential plan-and-build in one runtime — use `sprint`.

This is an explicit cross-runtime invocation contract. Verbs defines the payload, safety gate, and result classification; the host owns runtime availability, authentication, model choice outside the pinned invocation, and cost policy.

## When to use

- A plan has **≥3 mechanical build units** (rote, well-specified, file-scoped) that benefit from one bounded fresh execution context.
- You planned + partially built and want the rest done by Codex while you review / move on.

Skip a single trivial edit — it stays on Claude. (Judgment-heavy / exploratory work is already out of scope per Routing Boundary.)

## Mode dispatch

| Invocation | Mode | Session | Git |
|---|---|---|---|
| `/handover [slug]` (default) | sync — spawn codex now, poll, collect | occupies this turn | source host commits the completed diff |
| `/handover --async [slug]` | async — write payload only | frees this session | nobody touches git until the human runs it |

The async-vs-sync axis is **session occupancy**: sync keeps this turn busy polling; async writes a runnable artifact and stops.

## Gate (both modes)

1. **Platform** — orchestrator must be Claude Code. Under Codex / Gemini, this skill is a no-op (delegation would recurse).
2. **Env guard** — `[ -n "$CODEX_SANDBOX" ] || [ -n "$CODEX_SESSION_ID" ]` → already inside a sandbox, stop ("already inside Codex").
3. **Availability** — `command -v codex` must print an absolute path. Missing → stop ("Codex CLI not found").
4. **Version** — read the minimum Codex version from `lib/model-anchors.md`, parse
   `codex --version`, and stop with the installed and required versions when it
   is unparseable or older.
5. **Repo-root** — run from `git rev-parse --show-toplevel`. A git repo is required: sync mode commits the result, and both modes resolve the plan + write handoffs under the repo's `docs/`. Not a git repo → stop ("handover needs a git repo").
6. **Plan precondition** — resolve the slug (arg, else current branch, else latest `docs/plans/*.md`). The plan's U-IDs + acceptance criteria ARE the payload. No plan → stop ("handover needs a plan file — its U-IDs/acceptance are the payload").
7. **Model anchor** — select `handover.mechanical` by default and
   `handover.risky` only for the risk classes in `lib/model-anchors.md`. This
   selection happens before mode dispatch and applies to sync and async.

## Sync mode (default)

Claude spawns Codex, waits for the structured result, keeps git + review. Read
`references/codex-invocation.md` for the verified `codex exec` invocation, the
`<task>/<files>/<constraints>/<non_goals>/<stop_conditions>/<budget>/<judgment>/<verify>/<output_contract>`
XML payload, the result schema, the sandbox-escape gate, and the single-result
classification table.

Flow:

1. Require `git status --porcelain=v1 --untracked-files=all` to be empty. Stop
   and ask the source host to commit or isolate existing work before delegation;
   scoped rollback is safe only from a fully clean baseline.
2. Derive remaining work: for each U-ID in the plan, run its `acceptance:` check and include ONLY the U-IDs that do NOT already pass (do not trust the plan's `status:` field — it is always `todo`; state is derived from git). Fall back to all U-IDs if acceptance can't be run here.
3. Build the XML payload + result schema into a `mktemp -d` scratch dir.
4. Spawn `codex exec` with the selected model anchor per
   `references/codex-invocation.md` (background Bash to clear the 2-min ceiling).
5. Poll for the result file in separate foreground Bash calls, then classify
   and act only through the status→action table in
   `references/codex-invocation.md`. Stop when that one-shot table returns its
   terminal `success`, `partial`, or `failed` result.
6. Git, review (`/review`), and ship stay in the source host — never delegated.

## Async mode (`--async`)

Write ONE self-contained handoff to `docs/handoffs/{YYYY-MM-DD}-{slug}-codex.md`
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
- Codex never commits, pushes, or opens PRs. The source host owns git (enforced in the payload's `<constraints>`). In sync mode the source host commits a completed batch; in async mode the human owns git entirely.
- Escalating Codex past `-s workspace-write` (e.g. `--dangerously-bypass-approvals-and-sandbox` for network / dep-install) is NEVER auto-selected from plan/task content — it needs an explicit one-time confirmation from the orchestrator this session. See `references/codex-invocation.md`.
