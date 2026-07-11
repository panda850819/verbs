# Sprint — Codex delegation (the batch loop)

> Hand a sprint's mechanical build units to Codex, batch by batch, keeping planning + review + git in the source host. SYNCHRONOUS: it occupies the foreground turn while polling each result. This file owns the BATCHING LOOP + circuit breaker; the installed skill whose frontmatter `name` is `handover` owns the single-invocation mechanics (XML payload, verified `codex exec`, sandbox gate, result classification), and this loop invokes it per batch. For a one-shot or ASYNC handover, use `/handover` directly. Ported from EveryInc Compound Engineering `ce-work-beta`.

## Gate — explicit opt-in only

Default: execute with the host's normal mechanism. Cross-runtime delegation is **never auto-triggered** — it turns on only when BOTH hold:

1. The user passed `--delegate codex` explicitly. Delegation runs a second runtime in a sandbox and leaves git collection with the source host, so it is opt-in, not inferred. **≥3 mechanical units is an advisory threshold, not a trigger:** below 3 the per-batch orchestration overhead is not worth it, so do not suggest the flag; at 3+ it is worth surfacing "this batch is delegation-sized — pass `--delegate codex` if you want Codex to take it." The switch is always the explicit flag.
2. The input is a **plan file** (`docs/plans/{slug}.md`). NO plan → NO delegation: "Codex delegation needs a plan file — using standard mode." The plan's U-IDs + acceptance ARE the delegation payload.

## Pre-delegation checks (run once, before the first batch)

Run the gate from the installed skill whose frontmatter `name` is `handover`
(platform / env-guard / availability / repo-root), plus:

- **Clean-baseline preflight** before the first batch: require
  `git status --porcelain=v1 --untracked-files=all` to be empty. This proves
  scoped rollback cannot erase pre-existing tracked or untracked work.
- **Model anchor** — read `lib/model-anchors.md`, enforce its minimum Codex
  version, and select `handover.mechanical` by default. Select
  `handover.risky` only for a batch containing one of the shared risk classes.

## Batching

Delegate units in batches of ~3-5. If the plan has more, split at phase boundaries or groups — never split U-IDs that share files. Skip delegation entirely if every unit is trivial.

## Per-batch loop

For each batch, invoke the installed `handover` skill's single-invocation
contract:

1. Build the XML payload + result schema for the batch's non-done U-IDs into a
   `mktemp -d` scratch dir, including the selected role, model, effort, minimum
   CLI, and permission guard in `<runtime>`.
2. Render that anchor into the `codex exec` command (background Bash to clear
   the 2-min ceiling).
3. Poll + classify the one result, then act per the status→action table in `codex-invocation.md` (the SSOT). On `completed`: `git add {scope} && git commit`, reset `consecutive_failures = 0`. On `partial`: KEEP the diff, finish the batch's remaining units locally, `consecutive_failures++`. On `failed` / CLI-failure: scoped rollback, `consecutive_failures++`.

The orchestrator does NOT re-run tests per batch (Codex runs + fixes its own inside the payload; doubles cost otherwise). Safety net = the self-reported result + the circuit breaker + Stage 4 review on the whole diff.

## Circuit breaker

After 3 consecutive failed batches: set delegation off, finish remaining units with the source host's normal mechanism. "Codex delegation disabled after 3 consecutive failures."

## Git ownership

Codex never commits or pushes (enforced in the payload `<constraints>`). All git stays with the source host. Stage 4 review and Stage 5 ship stay in the foreground, never delegated.
