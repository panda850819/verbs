# Ship — Codex handover mode

> `/ship codex [slug]` — package the current work into ONE self-contained markdown a fresh Codex session (or Hermes on the ChatGPT-Codex subscription) can pick up and finish. ASYNC handover: this WRITES the payload, it does NOT run Codex and does NOT touch git. For SYNCHRONOUS in-loop delegation during a sprint, use `/sprint --delegate codex` instead.

## When to use

- You planned + partially built, and want to hand the rest to Codex WITHOUT occupying this Claude session.
- Overnight / fire-and-forget: drop the artifact, let Hermes run it on subscription quota while you do something else.

The async-vs-sync axis is session occupancy, not cost (codex runs on your ChatGPT subscription either way): `/ship codex` frees this session; `/sprint --delegate codex` keeps it busy polling.

## What it does

1. Resolve the slug (arg, else current branch, else latest `docs/plans/*.md`).
2. Gather the handover payload:
   - the executable plan `docs/plans/{slug}.md` (the WHAT — U-IDs + acceptance criteria)
   - the current diff: `git diff {base}...HEAD` plus any uncommitted `git diff`
   - the remaining work: derive it the way `/sprint --plan` does — for each U-ID, run its `acceptance:` check and include ONLY the U-IDs that do NOT already pass. Do NOT trust the plan's `status:` field (it is always `todo` in the file — state is derived from git, never written back). Fall back to including all U-IDs if acceptance checks can't be run here. Plus any OPEN_QUESTIONS.
3. Write ONE self-contained handoff to `docs/handoffs/{YYYY-MM-DD}-{slug}-codex.md` using the XML contract Codex acts on (the payload format is compatible with the `/sprint --delegate codex` prompt, so the same plan drives either execution path — they differ only in async-vs-sync, not in payload):

```xml
<task>
{each remaining, non-done U-ID: its Goal + acceptance criterion}
</task>
<files>
{combined scope paths from those U-IDs}
</files>
<constraints>
- Do NOT git commit / push / open PRs — the human orchestrator owns git.
- Stay within the repo root; keep changes scoped to the listed U-IDs only.
- Resolve each task fully; do not stop at the first plausible answer.
</constraints>
<verify>
{the U-IDs' acceptance checks, as ONE combined test/lint command}
Run all tests together in one process; do not report done unless they pass.
</verify>
<output_contract>
Report status (completed | partial | failed), files_modified[], issues[], summary,
verification_summary (what you ran to verify + outcome). This is the same 5-field
schema as `/sprint --delegate codex`, so either path validates the result identically.
</output_contract>
```

4. Print two things — the handoff path, and the dispatch one-liner:
   - **Hermes (async, subscription quota):** hand the file to Hermes; it runs on `provider: openai-codex` (`~/.hermes/config.yaml`). This is the default recommended path — it frees this session.
   - **Direct headless:** `codex exec -s workspace-write - < docs/handoffs/{...}-codex.md` — must run at repo root (`codex exec` refuses non-git dirs without `--skip-git-repo-check`).

## Boundaries

- This mode NEVER runs codex itself and NEVER touches git — it only emits the artifact (vault-only, like knowledge/write modes).
- `docs/plans/{slug}.md` stays the source of truth for WHAT; this handoff is a derived snapshot. Do not copy the brief's rationale into it.
- If no plan file exists for the slug, say so and stop — the handover needs the plan's U-IDs/acceptance as its payload.
