# Sprint — Codex delegation (the batch loop)

> Hand a sprint's mechanical build units to Codex, batch by batch, keeping planning + review + git on Claude. SYNCHRONOUS: it occupies the Claude turn polling for each result. This file owns the BATCHING LOOP + circuit breaker; the single-invocation mechanics (XML payload, verified `codex exec`, sandbox gate, result classification) live in `skills/engineering/handover/references/codex-invocation.md` — this loop calls that per batch. For a one-shot or ASYNC handover, use `/handover` directly. Ported from EveryInc Compound Engineering `ce-work-beta`.

## Gate — explicit opt-in only

Default: execute with FREE Claude subagents. Delegation is **never auto-triggered** — it turns on only when BOTH hold:

1. The user passed `--delegate codex` explicitly. Delegation has side effects (spends ChatGPT quota, runs Codex in a sandbox, the orchestrator owns the git collection), so it is opt-in, not inferred. **≥3 mechanical units is an advisory threshold, not a trigger:** below 3 the per-batch orchestration overhead ~4-5k tokens isn't worth it, so don't even suggest the flag; at 3+ it is worth *surfacing* "this batch is delegation-sized — pass `--delegate codex` if you want Codex to take it." The switch is always the explicit flag.
2. The input is a **plan file** (`docs/plans/{slug}.md`). NO plan → NO delegation: "Codex delegation needs a plan file — using standard mode." The plan's U-IDs + acceptance ARE the delegation payload.

Cost note: codex runs on the ChatGPT subscription here (`~/.codex/auth.json`, no API key), so delegation is ~free at the margin. It is NOT the metered-API path the `prefer-cc-subagents` rule warns against. The reason to use it is conserving the Claude session + batch economics.

## Pre-delegation checks (run once, before the first batch)

Run the `/handover` gate (platform / env-guard / availability / repo-root — see `skills/engineering/handover/SKILL.md`), plus:

- **Clean-baseline preflight** before the first batch: `git diff --quiet HEAD`. This makes the scoped rollback in `codex-invocation.md` sufficient.
- **Model anchor** — read `lib/model-anchors.md`, enforce its minimum Codex
  version, and select `handover.mechanical` by default. Select
  `handover.risky` only for a batch containing one of the shared risk classes.

## Batching

Delegate units in batches of ~3-5. If the plan has more, split at phase boundaries or groups — never split U-IDs that share files. Skip delegation entirely if every unit is trivial.

## Per-batch loop

For each batch, invoke Codex per `skills/engineering/handover/references/codex-invocation.md`:

1. Build the XML payload + result schema for the batch's non-done U-IDs into a
   `mktemp -d` scratch dir, including the selected role, model, effort, minimum
   CLI, and permission guard in `<runtime>`.
2. Render that anchor into the `codex exec` command (background Bash to clear
   the 2-min ceiling).
3. Poll + classify the one result, then act per the status→action table in `codex-invocation.md` (the SSOT). On `completed`: `git add {scope} && git commit`, reset `consecutive_failures = 0`. On `partial`: KEEP the diff, finish the batch's remaining units locally, `consecutive_failures++`. On `failed` / CLI-failure: scoped rollback, `consecutive_failures++`.

The orchestrator does NOT re-run tests per batch (Codex runs + fixes its own inside the payload; doubles cost otherwise). Safety net = the self-reported result + the circuit breaker + Stage 4 review on the whole diff.

## Circuit breaker

After 3 consecutive failed batches: set delegation off, finish remaining units in standard Claude mode. "Codex delegation disabled after 3 consecutive failures."

## Git ownership

Codex never commits/pushes (enforced in the payload `<constraints>`). All git stays with the Claude orchestrator. Stage 4 review and Stage 5 ship always run on Claude, never delegated.
