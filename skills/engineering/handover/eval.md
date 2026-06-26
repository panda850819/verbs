---
type: skill-eval
skill: handover
bucket: engineering
evaluated_skill_hash: 9a55cf0e6e756f5c02960cbe7bf7bb6d83866c06
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — handover

**Verdict: SOLID.** Fail-closed 5-gate preflight plus exemplary hot/cold split keep the body a pure orchestration layer; costs one point for repeating the Codex-quota economics across three sections.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L60 — the five-check "Gate (both modes)", each ending in a hard `stop`, runs before either mode, so every invocation takes the same derive→payload→spawn→classify path; state is derived from acceptance/git (L74), not model whim. |
| Description / invocation | pass | L4 — front-loads "Explicit Codex handover workflow", lists one trigger per branch (`/handover [slug]`, `--async`), and the NOT-clause (L7) fences plan-writing / ship / subagent loops. |
| Completion criteria | pass | L94 — state-emission now has a checkable, exhaustive done-condition: "Done when EITHER the `delegated` event is appended OR `scripts/pandastack-state` is confirmed absent" with the `[ -x ]` test specified and "never skip silently". |
| Information hierarchy | pass | L70 — XML payload, result schema, sandbox-escape gate, and status→action table are pushed to `references/codex-invocation.md`, pulled only when sync mode fires; the body keeps only the orchestration sequence. |
| Leading words | pass | L58 — "session occupancy, not cost" anchors the async/sync axis in one pretrained concept; L62 "this skill is a no-op (delegation would recurse)" anchors the platform gate. |
| Pruning | weak | L42 — the "separate Codex quota / not double-paying" economic point is restated at L46 ("rather spend Codex quota") and L58 ("not cost…same subscription either way"); one meaning, three touches, a single anchor could collapse it. |
| Granularity | pass | L70 — the cold split earns its load: the reference's own header (its L3) shows both `/handover` and `/sprint --delegate codex` reach it, so the cut serves independent reach, not a single-use push. |
| pandastack conformance | pass | L2 — `name: handover` equals the folder; `references/codex-invocation.md` resolves (~1K tokens, under the 5K hot/cold threshold so reading it hot is correct); `reads`/`writes`/`forbids`/`domain` are spec-sanctioned advisory metadata. |

## Why it's good
The Gate (L60-66) is genuinely exhaustive — platform, sandbox-escape, availability, repo-root, plan-precondition — and each check fails closed with a named stop reason, so the skill cannot half-run and both modes share one preflight. Reference extraction is disciplined: every brittle `codex exec` mechanic lives behind one shared pointer the body reaches twice, keeping the hot body as pure routing. The state-emission step (L89-98), a silent best-effort skip in the prior revision, is now a checkable non-silent completion criterion.

## Top fixes
1. L42 / L46 / L58 — collapse the three restatements of the Codex-quota economics into one anchored sentence; keep the L58 "session occupancy, not cost" framing and drop the repeats in the Routing Boundary (L42) and When-to-use (L46).
2. L106-108 — the "this reduces to `status: in_progress, owner: codex`" gloss is explanatory sediment the appended event already implies; trim it so the State-emission section earns its ~20 lines.

## Behavioral cases
- trigger `/handover pro-31` (plan with ≥3 rote build units) -> expected process: run the L60 gate, derive non-passing U-IDs from acceptance checks (L74), build the XML payload, spawn `codex exec` in background, poll in foreground, classify the single result per the reference table, Claude commits a `completed` batch and keeps review/ship, then append the `delegated` state event.
- anti-trigger `ship this finished work / open the PR` -> should NOT fire; routes to `ship` (L37 excludes closing finished work, PR, publishing).
- anti-trigger `write the plan for the refactor` -> should NOT fire; routes to `plan` / `writing-plans` (L33).
