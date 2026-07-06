---
type: skill-eval
skill: handover
bucket: engineering
evaluated_skill_hash: ac147a23c99faecfbbdae30da07c39c1b15fb541
evaluated_at: 2026-07-05
rubric: writing-great-skills@1.1.0
---

# Eval — handover

> 2026-07-05 re-validation (#165): SKILL.md delta since the 2026-07-03 scoring is one additive enumeration line (payload block list gained non_goals / stop_conditions / judgment). All axis evidence re-grounded via lint-eval-quotes; scores and verdict unchanged.

**Verdict: SOLID.** Fail-closed 5-gate preflight plus a clean hot/cold split keep the body a pure orchestration layer; costs one point for restating the Codex-quota economics across three sections.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L60 — the five-check "Gate (both modes)", each ending in a hard `stop`, runs before either mode, so every invocation takes the same derive→payload→spawn→classify path; state is derived from acceptance/git (L74), not model whim. |
| Description / invocation | pass | L4 — front-loads "Explicit Codex handover workflow", lists one trigger per branch (`/handover [slug]` L5, `--async` L6), and the NOT-clause (L7) fences plan-writing / ship / subagent loops. |
| Completion criteria | pass | L94 — state-emission carries a checkable, exhaustive done-condition: "Done when EITHER the `delegated` event is appended OR `scripts/pandastack-state` is confirmed absent" with the `[ -x ]` test named and "never skip silently". |
| Information hierarchy | pass | L70 — the XML payload, result schema, sandbox-escape gate, and status→action table are pushed to `references/codex-invocation.md`, pulled only when sync mode fires; the body keeps just the orchestration sequence. |
| Leading words | pass | L58 — "session occupancy, not cost" anchors the async/sync axis in one pretrained concept; L62 "already inside a sandbox… (delegation would recurse)" anchors the env/platform gate. |
| Pruning | weak | L42 — the "separate Codex quota / not double-paying" economic point recurs at L46 ("rather spend Codex quota") and L58 ("not cost… same subscription either way"); one meaning, three touches, collapsible to a single anchor. |
| Native parity | pass | L35 — names the native competitor as direct Codex CLI usage outside the protocol, while L70 gives the delta: verified invocation payload, result schema, sandbox gate, and classification table. |
| Granularity | pass | L70 — the cold split earns its load: the reference's own header (its L3) shows both `/handover` (sync) and `/sprint --delegate codex` (batch loop) reach it, so the cut serves independent reach, not a single-use push. |
| pandastack conformance | pass | L30 — #110 de-personalization landed: "an explicit pandastack `/handover`" (was "Panda Stack"), description "you" (L7), Boundaries "the orchestrator" (L114) are now generic/redistributable; `name: handover` (L2) matches the folder and `references/codex-invocation.md` (~1K tokens, under the 5K hot threshold) resolves. |

## Why it's good
The Gate (L60-66) is genuinely exhaustive — platform, env-guard, availability, repo-root, plan-precondition — and each check fails closed with a named stop reason, so the skill cannot half-run and both modes share one preflight. Reference extraction is disciplined: every brittle `codex exec` mechanic lives behind one shared pointer the body reaches twice, keeping the hot body as pure routing. The #110 wording change is correct distribution-fitness — the author-specific "Panda" identity is gone from the SKILL.md without disturbing the routing logic.

## Top fixes
1. L42 / L46 / L58 — collapse the three restatements of the Codex-quota economics into one anchored sentence; keep the L58 "session occupancy, not cost" framing and drop the repeats in Routing Boundary (L42) and When-to-use (L46).
2. `references/codex-invocation.md:50` — the de-personalization missed the reference: it still reads "explicit one-time confirmation from Panda this session", contradicting SKILL.md L114's "the orchestrator". Same SSOT, one voice — sync the reference.
3. L106-108 — the "this reduces to `status: in_progress, owner: codex`" gloss is explanatory sediment the appended event already implies; trim it so the State-emission section earns its ~20 lines.

## Behavioral cases
- trigger `/handover pro-31` (plan with ≥3 rote, file-scoped build units) -> expected process: run the L60 gate, derive non-passing U-IDs from acceptance checks (L74), build the XML payload, spawn `codex exec` in background, poll in foreground, classify the single result per the reference table, Claude commits a `completed` batch and keeps review/ship (L78), then append the `delegated` state event (L94).
- anti-trigger `ship this finished work / open the PR` -> should NOT fire; routes to `ship` (L37 excludes closing finished work, PR, publishing).
- anti-trigger `write the plan for the refactor` -> should NOT fire; routes to `plan` / `writing-plans` (L33).
