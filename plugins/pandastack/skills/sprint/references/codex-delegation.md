# Sprint — Codex delegation (sync, in-loop)

> Hand a batch of mechanical build units to Codex via `codex exec` from inside the sprint, collect the structured result, keep planning + review + git on Claude. SYNCHRONOUS: it occupies the Claude turn polling for the result. For ASYNC fire-and-forget, use `/ship codex` instead. Ported from EveryInc Compound Engineering `ce-work-beta`; the invocation is verified against codex-cli 0.130.0 on this machine.

## Gate — default OFF

Default: execute with FREE Claude subagents (per the prefer-cc-subagents rule). Turn delegation ON only when BOTH hold:

1. The batch is **≥5 mechanical units** (CE crossover is 5-7; below it the per-batch orchestration overhead ~4-5k tokens + 1.7-2.2x wall-clock dominate), OR the user passed `--delegate codex` explicitly.
2. The input is a **plan file** (`docs/plans/{slug}.md`). NO plan → NO delegation: "Codex delegation needs a plan file — using standard mode." The plan's U-IDs + acceptance ARE the delegation payload.

Cost note: codex runs on the ChatGPT subscription here (`~/.codex/auth.json`, no API key), so delegation is ~free at the margin. The reason to use it is conserving the Claude session and batch economics, NOT cost.

## Pre-delegation checks (run once, before the first batch)

0. **Platform gate** — only when the orchestrator is Claude Code. Under Codex / Gemini / other, disable and run standard mode.
1. **Env guard** — `[ -n "$CODEX_SANDBOX" ] || [ -n "$CODEX_SESSION_ID" ]` → already inside a sandbox, disable (delegation would recurse).
2. **Availability** — `command -v codex` must print an absolute path, else disable: "Codex CLI not found — standard mode."
3. **Repo-root precondition** — run from `git rev-parse --show-toplevel`. `codex exec` refuses non-git dirs; if the work dir is not a git repo, pass `--skip-git-repo-check` or disable.

## Batching

Delegate all units in one batch. If >5, split at the plan's phase boundaries or groups of ~5 — never split U-IDs that share files. Skip delegation entirely if every unit is trivial.

## Invocation (verified on codex 0.130.0)

Per batch: write the XML prompt + the result schema into a `mktemp -d` scratch dir (capture its absolute path), then:

```bash
SD="$(mktemp -d -t sprint-codex-XXXXXX)"   # use the echoed absolute path everywhere below
codex exec \
  -s workspace-write \
  --output-schema "$SD/result-schema.json" \
  -o "$SD/result-batch-N.json" \
  - < "$SD/prompt-batch-N.md"
```

- Launch as a Bash tool call with `run_in_background: true` (the tool PARAMETER, not a shell `&`) to clear the 2-minute timeout ceiling.
- Risky batch (auth / payments / migrations): insert `-c 'model_reasoning_effort="high"'` before `-s`. Default defers to `~/.codex/config.toml`.
- Needs network / dep install: swap `-s workspace-write` for `--dangerously-bypass-approvals-and-sandbox` (0.130.0 has no `--yolo` alias).

Prompt XML sections: `<task>` (U-ID goals), `<files>` (combined scope), `<constraints>` (Codex must NOT git commit/push — the orchestrator owns git; stay in repo root; keep scoped), `<verify>` (the U-IDs' acceptance as ONE combined test command; "do not report completed unless tests pass"), `<output_contract>` (fill the schema).

Result schema: `{status: completed|partial|failed, files_modified[], issues[], summary, verification_summary}` — all required, `additionalProperties: false`.

## Collect + classify

Poll for the result file in SEPARATE foreground Bash calls (keeps the turn active so the working tree isn't touched mid-run). Classify each batch:

| Signal | Classification | Action |
|---|---|---|
| exit ≠ 0 | CLI failure | rollback, fall back to standard mode for ALL remaining work |
| exit 0, result JSON missing/malformed | task failure | rollback, `consecutive_failures++` |
| exit 0, status `failed` | task failure | rollback, `consecutive_failures++` |
| exit 0, status `partial` | partial | keep diff, finish remaining locally, `consecutive_failures++` |
| exit 0, status `completed` | success | `git add {scope} && git commit`, reset `consecutive_failures = 0` |

Rollback = `git checkout -- . && git clean -fd -- {scope paths}` (never bare `git clean -fd`). Codex runs + fixes its own tests; the orchestrator does NOT re-run them per batch (doubles cost). Safety net = the self-reported result + the circuit breaker + Stage 4 review on the whole diff.

## Circuit breaker

After 3 consecutive failures: set delegation off, finish remaining units in standard Claude mode. "Codex delegation disabled after 3 consecutive failures."

## Git ownership

Codex never commits/pushes (enforced in `<constraints>`). Clean-baseline preflight before the first batch: `git diff --quiet HEAD`. All git stays with the Claude orchestrator; Stage 4 review and Stage 5 ship always run on Claude, never delegated.
