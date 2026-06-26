---
type: skill-eval
skill: boardroom
bucket: productivity
evaluated_skill_hash: 0f64410ea1248758a5cf88a0f550ab3169e2ad23
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — boardroom

**Verdict: SOLID.** A genuinely well-architected two-mode router — the sequential-vs-`--panel` split is principled (revised-plan coherence vs uncorrelated-error independence) and the per-finding `Apply? [Y/N/edit]` gate gives it a checkable, interruptible spine — held back by an over-budget body, soft scope routing, and frontmatter drift.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | weak | L88 — `ops_dominant` is keyed on fuzzy keyword-presence ANDed with a "dominant frame is feature/code/UX" judgment that has no tie-break; the same plan can route to a different voice-set across runs. This is the one place same-process determinism actually breaks. |
| Description / invocation | weak | L5 — the description front-loads "Multi-lens plan critique router" with a clean one-trigger-per-branch list and NOT clause, but the frontmatter is `mode: skill` with no `version` and no `user-invocable: true` despite `/boardroom` being user-invoked; invocation intent is under-declared. |
| Completion criteria | weak | L112 — "Output 3-5 critiques in voice's posture" gates on a count, not a checkable done-condition; an agent can emit 3 shallow critiques and call the voice complete. Stage 0 (L77) and the gate loop (L122) are sharp; this step invites premature completion. |
| Information hierarchy | pass | L75 — the capability probe and the five `lib/*` rules are pushed behind context pointers (`@../../../lib/...`), loaded on demand; persona extraction is delegated to `lib/persona-frame.md` rather than inlined. Progressive disclosure held. |
| Leading words | pass | L64 — "uncorrelated errors across lenses", "mutually-blind" (L36), "cold subagents" (L130), "quorum-aggregate" (L138) anchor the panel mechanism in pretrained concepts in few tokens. |
| Pruning | weak | L210 — the sequential-vs-panel distinction is restated at least six times (L36, L61-67 table, L69, L79, L210, L221); the table is the SSOT and the narrative restatements are duplication, and `capability_required` (L22-31) re-lists deps already in `reads` (L6-16) — sediment that helps push the body to 231 lines, ~2.9× the ~80-line guideline. |
| Granularity | pass | L59 — the two-mode split earns its load: default optimizes coherence, `--panel` optimizes independence (L64), and panel mode dispatches voices as cold subagents (L130) rather than loading five sibling SKILL.md files hot; each cut earns its keep. |
| pandastack conformance | weak | L2 — `mode: skill` instead of the spec key `type: skill`, no `version` field, and the body is 231 lines (L1-231) against the ~<80-line guideline; all `reads`/`lib` refs resolve (verified), so this is style+length drift, not a broken path. |

## Why it's good
The mode table (L61-67) is the load-bearing asset: it turns the sequential/panel choice into a one-glance decision keyed to stakes, with mechanism, optimization target, cost, and failure-cure all in one cell-set. The per-finding `Apply? [Y/N/edit]` gate (L113-122) plus the no-batched-gates stop-rule and escape-hatch make the skill checkable and interruptible. Panel mode's quorum-aggregation (L138-142) with an explicit "never drop single-voice findings" rule (L142) is a sophisticated, correct defence against consensus-washing.

## Top fixes
1. **L1-31** — drop `mode: skill` for the spec's `type: skill`, add `version:` and `user-invocable: true`, and delete `capability_required` (L22-31) since it duplicates `reads` (L6-16) and is advisory-only per SKILL-FRONTMATTER.md; this aligns the frontmatter contract and trims sediment.
2. **L210** — collapse the sequential-vs-panel restatements: let the L61-67 table be the single source and cut the narrative duplicates (L36 intro, L69, the L221 anti-pattern re-explanation, the L208-217 ordering preamble); this is the main lever to pull the 231-line body back toward budget.
3. **L88 / L112** — make `ops_dominant` deterministic (keyword-count threshold, or "if ambiguous, do NOT add ops-lead") and replace the "3-5 critiques" count with a coverage criterion (e.g. "every Iron Law checked against the plan") so both voice-scope and per-voice completion are reproducible.

## Behavioral cases
- trigger `/boardroom plans/q3-launch.md --panel` → expected process: Stage 0 probe + load plan, announce `boardroom mode: panel (independent)`, Stage 1 scope (CEO+product+design+eng; ops only if coordination-dominant), dispatch all voices as cold mutually-blind subagents on the original plan, quorum-tag and gate each finding per `lib/outside-voice-rule.md`, write `Inbox/boardroom-q3-launch-2026-06-26.md`.
- anti-trigger `the login button is misaligned, fix it` → should NOT fire; single-domain tactical execution routes to `/design-lead` or `/eng-lead` directly (L53-54), not the multi-lens plan router.
