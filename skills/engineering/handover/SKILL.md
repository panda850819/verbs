---
name: handover
description: |
  Explicit Codex handover workflow for unfinished mechanical build units from an existing plan.
  - /handover [slug]: sync handoff, spawn `codex exec`, poll, collect structured result.
  - /handover --async [slug]: write a self-contained payload to docs/handoffs/ only; does not spawn Codex or touch git.
  Use when a plan has several rote, file-scoped build units and you deliberately want Codex subscription quota used. NOT for plan writing, generic engine invocation, subagent-driven-development loops, closing finished work, PR/ship flow, or exploratory judgment-heavy work.
reads:
  - repo: docs/plans/**
  - repo: skills/engineering/handover/references/codex-invocation.md
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

Use this skill only for an explicit pandastack `/handover`: unfinished mechanical build units from an existing plan are delegated to Codex, while the orchestrator keeps planning, review, and git ownership.

Do not use it for:
- Writing plans — use `plan` or `writing-plans`.
- General Hermes subagent execution — use `subagent-driven-development`.
- Direct Codex CLI usage outside the handover protocol — use `codex`.
- Claude Code or OpenCode engine usage — use `claude-code` or `opencode`.
- Closing finished work, PR creation, publishing, or shipping.
- Exploratory or judgment-heavy work where Codex should not be the executor.

`/handover` gives a unit of work to **Codex** to execute. The distinction from `/ship`: ship *closes* work that is already done (commit, PR, file a note); handover *delegates* work that is not done yet to a second runtime.

Codex runs on the ChatGPT subscription (`~/.codex/auth.json`, no API key) — a **separate quota** from Claude, so delegating a batch conserves the Claude session rather than double-paying. The `prefer-cc-subagents` rule targets gbrain skills that spin up a *metered Anthropic API* runtime; Codex is not that, so it is a legitimate opt-in here.

## When to use

- A plan has **≥3 mechanical build units** (rote, well-specified, file-scoped) and you would rather spend Codex quota than the Claude session on them.
- You planned + partially built and want the rest done by Codex while you review / move on.

Skip a single trivial edit — it stays on Claude. (Judgment-heavy / exploratory work is already out of scope per Routing Boundary.)

## Mode dispatch

| Invocation | Mode | Session | Git |
|---|---|---|---|
| `/handover [slug]` (default) | sync — spawn codex now, poll, collect | occupies this turn | Claude commits the completed diff |
| `/handover --async [slug]` | async — write payload for Hermes / offline | frees this session | nobody touches git until the human runs it |

The async-vs-sync axis is **session occupancy**, not cost (codex runs on the same subscription either way): sync keeps this turn busy polling; async drops an artifact and lets Hermes run it on subscription quota while you do something else.

## Gate (both modes)

1. **Platform** — orchestrator must be Claude Code. Under Codex / Gemini, this skill is a no-op (delegation would recurse).
2. **Env guard** — `[ -n "$CODEX_SANDBOX" ] || [ -n "$CODEX_SESSION_ID" ]` → already inside a sandbox, stop ("already inside Codex").
3. **Availability** — `command -v codex` must print an absolute path. Missing → stop ("Codex CLI not found").
4. **Repo-root** — run from `git rev-parse --show-toplevel`. A git repo is required: sync mode commits the result, and both modes resolve the plan + write handoffs under the repo's `docs/`. Not a git repo → stop ("handover needs a git repo").
5. **Plan precondition** — resolve the slug (arg, else current branch, else latest `docs/plans/*.md`). The plan's U-IDs + acceptance criteria ARE the payload. No plan → stop ("handover needs a plan file — its U-IDs/acceptance are the payload").

## Sync mode (default)

Claude spawns Codex, waits for the structured result, keeps git + review. Read `references/codex-invocation.md` for the verified `codex exec` invocation, the `<task>/<files>/<constraints>/<non_goals>/<stop_conditions>/<budget>/<judgment>/<verify>/<output_contract>` XML payload, the result schema, the sandbox-escape gate, and the single-result classification table.

Flow:

1. Derive remaining work: for each U-ID in the plan, run its `acceptance:` check and include ONLY the U-IDs that do NOT already pass (do not trust the plan's `status:` field — it is always `todo`; state is derived from git). Fall back to all U-IDs if acceptance can't be run here.
2. Build the XML payload + result schema into a `mktemp -d` scratch dir.
3. Spawn `codex exec` per `references/codex-invocation.md` (background Bash to clear the 2-min ceiling).
4. Poll for the result file in separate foreground Bash calls, then classify + act per the status→action table in `references/codex-invocation.md` (the SSOT — do not restate divergent actions here): `completed` → `git add {scope} && git commit`; `partial` → KEEP the diff, finish the remaining units locally; `failed` / CLI-failure → scoped rollback, finish locally.
5. Git, review (`/review`), and ship stay on Claude — never delegated.

## Async mode (`--async`)

Write ONE self-contained handoff to `docs/handoffs/{YYYY-MM-DD}-{slug}-codex.md` using the same XML contract (so the same payload drives either path — they differ only in async-vs-sync). Then print:

- the handoff path;
- the dispatch one-liner — **Hermes (default):** hand the file to Hermes, it runs on `provider: openai-codex` (`~/.hermes/config.yaml`); **direct headless:** `codex exec -s workspace-write - < docs/handoffs/{...}-codex.md` (must run at repo root).

Async mode NEVER spawns codex and NEVER touches git — it only emits the artifact (vault-only, like ship's knowledge mode).

## State emission (loop-in-agent)

After the delegation actually happens — sync: once the codex result is collected
(any status); async: once the handoff file is written — append one `delegated`
event to the lifecycle store so a scheduler can see this item is being executed
by Codex (schema: `docs/state-schema.md`). Done when EITHER the `delegated`
event is appended OR `scripts/pandastack-state` is confirmed absent (test
`[ -x scripts/pandastack-state ]` first; if it fails, report "state binary
absent, event skipped" — never skip silently). `slug` = repo basename,
`item` = handover slug.

```
scripts/pandastack-state append --slug {repo} --item {slug} \
  --event delegated --skill handover --runtime codex \
  --ref {commit-or-handoff-path}
```

This reduces to `status: in_progress, owner: codex` — the loop's Claude-orchestrates /
Codex-executes split becomes visible in the state file. A later `/review` or
`/ship` event (if the work continues on Claude) supersedes it.

## Boundaries

- `docs/plans/{slug}.md` stays the source of truth for WHAT. The handoff is a derived snapshot — do not copy the brief's rationale into it.
- Codex never commits / pushes / opens PRs — the Claude orchestrator owns git (enforced in the payload's `<constraints>`). In sync mode Claude commits on a completed batch; in async mode the human owns git entirely.
- Escalating Codex past `-s workspace-write` (e.g. `--dangerously-bypass-approvals-and-sandbox` for network / dep-install) is NEVER auto-selected from plan/task content — it needs an explicit one-time confirmation from the orchestrator this session. See `references/codex-invocation.md`.
