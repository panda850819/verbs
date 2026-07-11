# Conditional Review Passes (Pass 4-8)

Run a pass ONLY when its scope signal fired in Step 4 (`SCOPE_*`), or — for Pass 8 — when the diff contains writing/design artifacts. Findings use the same `[P0-P3] (confidence: N/10) file:line` format as the always-on passes and merge into the same Step 5 pool.

**Pass 4 — Migration Safety** (only if SCOPE_MIGRATION):
- Backwards-incompatible schema changes without migration path
- Missing rollback strategy (no down migration)
- Data loss risk (column drops, type changes on populated tables)
- Lock duration on large tables (ALTER on millions of rows)

**Pass 5 — API Contract** (only if SCOPE_API):
- Breaking changes to existing endpoints (removed fields, changed types)
- Missing versioning for breaking changes
- Inconsistent error response format
- Missing or wrong HTTP status codes

**Pass 6 — Auth/Permissions** (only if SCOPE_AUTH):
- Privilege escalation paths (user can access admin resources)
- Missing auth checks on new endpoints
- Token/session handling flaws (no expiry, no rotation)
- Secrets logged or exposed in error messages

**Pass 7 — Infra/CI** (only if SCOPE_INFRA):
- Secrets hardcoded in config files
- Missing environment variable validation
- Docker image using latest tag instead of pinned version
- CI steps that can silently fail

**Pass 8 — Quality Rubric** (only when diff contains writing or design artifacts, e.g. `.md` in writing/ media/ briefs/ topics/ paths, or `.html`/`.tsx`/`.css` with visual surface changes):
- Load `lib/quality-rubric.md`. Evaluator-side binding per governance moment #2.
- Score each changed artifact 1-5 on the 4 axes (coherence / originality / craft / functionality).
- Any axis < 3 = fail the gate. Include the specific anti-pattern hit (e.g. "Originality 2 — symmetric bullet structure, LLM diversity collapse").
- Use per-skill weighting table from the rubric when artifact came from `verbs:write` / `verbs:ui` output.
