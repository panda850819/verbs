---
type: skill-eval
skill: handover
bucket: engineering
evaluated_skill_hash: 5c6dcff8ed377402a5bb7842e2566a5e70abdcc5
evaluated_at: 2026-07-10
rubric: writing-great-skills@1.1.0
---

# Eval — handover

> 2026-07-09 re-validation (#170): the Boundary list shed its dead Hermes-era routing refs (`plan` / `writing-plans` / `subagent-driven-development` / `claude-code` / `opencode`), kept the raw-`codex exec` native competitor, and gained an `advisor` cross-reference (judgment IN vs build OUT). Axis evidence re-anchored; scores and verdict unchanged.
>
> 2026-07-10 re-validation (#172): both sync and async paths now select a shared, transport-tested model anchor before mode dispatch and forbid inherited model, effort, and permission defaults. Async payloads carry a `<runtime>` block; direct-headless rechecks its minimum CLI on the execution machine, while Hermes fails loud unless its adapter proves it honored the whole block. The invocation reference was re-verified against Codex CLI 0.144.1.

**Verdict: SOLID.** Fail-closed 7-gate preflight plus a clean hot/cold split keep the body a pure orchestration layer; costs one point for restating the Codex-quota economics across three sections.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L59 — the seven-check "Gate (both modes)" runs before either mode; version and model anchor are explicit gates (L64-71) before the existing derive→payload→spawn→classify path. |
| Description / invocation | pass | L4 — front-loads "Explicit Codex handover workflow", lists one trigger per branch (`/handover [slug]` L5, `--async` L6), and the NOT-clause (L7) fences plan-writing / ship / judgment-heavy work, cross-referencing `advisor` for the last. |
| Completion criteria | pass | L112 — state-emission carries a checkable, exhaustive done-condition: "Done when EITHER the `delegated` event is appended OR `scripts/pandastack-state` is confirmed absent" with the `[ -x ]` test named and "never skip silently". |
| Information hierarchy | pass | L69 — volatile model/effort/version/guard values live in `lib/model-anchors.md`; the XML payload, schema, sandbox gate, and classification table remain in `references/codex-invocation.md`. The body keeps selection and orchestration. |
| Leading words | pass | L56 — "session occupancy, not cost" anchors the async/sync axis in one pretrained concept; L61 "already inside a sandbox… (delegation would recurse)" anchors the env/platform gate. |
| Pruning | weak | L40 — the "separate Codex quota / not double-paying" economic point recurs at L44 ("rather spend Codex quota") and L56 ("session occupancy… same subscription either way"); one meaning, three touches, collapsible to a single anchor. |
| Native parity | pass | L34 — names direct `codex exec` as the native competitor, while L59-103 gives the delta: version-gated anchor selection, verified payload, result schema, sandbox gate, and async fail-loud behavior. |
| Granularity | pass | L68 — the cold split earns its load: the reference's own header shows both `/handover` (sync) and `/sprint --delegate codex` (batch loop) reach it, so the cut serves independent reach, not a single-use push. |
| pandastack conformance | pass | L30 — de-personalized: "an explicit pandastack `/handover`", description "you" (L7), Boundaries "the orchestrator" (L112) are generic/redistributable; `name: handover` (L2) matches the folder and `references/codex-invocation.md` (~1K tokens, under the 5K hot threshold) resolves. |

## Why it's good
The Gate (L59-71) is exhaustive — platform, recursion, availability, version, repo-root, plan, and model anchor — and each check fails closed. Anchor selection happens before mode dispatch, preventing sync and async runs from inheriting defaults. The async artifact carries the same role/model/effort in `<runtime>` and refuses an unproven Hermes adapter (L92-103). Reference extraction stays disciplined: volatile values live in `lib/model-anchors.md`, while brittle `codex exec` mechanics remain in the invocation reference.

## Top fixes
1. L40 / L44 / L56 — collapse the three restatements of the Codex-quota economics into one anchored sentence; keep the L56 "session occupancy, not cost" framing and drop the repeats in Routing Boundary (L40) and When-to-use (L44).
2. `references/codex-invocation.md:50` — the de-personalization missed the reference: it still reads "explicit one-time confirmation from Panda this session", contradicting SKILL.md L112's "the orchestrator". Same SSOT, one voice — sync the reference.
3. L104-106 — the "this reduces to `status: in_progress, owner: codex`" gloss is explanatory sediment the appended event already implies; trim it so the State-emission section earns its ~20 lines.

## Behavioral cases
- trigger `/handover pro-31` (plan with ≥3 rote, file-scoped build units) -> expected process: run the L59 gate, select and version-check the model anchor, derive non-passing U-IDs from acceptance checks (L83), build the XML payload, spawn the pinned `codex exec` call, classify the result, keep review/ship on Claude, then append the `delegated` state event (L107).
- anti-trigger `ship this finished work / open the PR` -> should NOT fire; routes to `ship` (L34 excludes closing finished work, PR, publishing).
- anti-trigger `give me a second opinion on this design fork` -> should NOT fire; routes to `advisor` (L35), which pulls judgment IN — handover sends build work OUT to Codex and never reasons on your behalf.
