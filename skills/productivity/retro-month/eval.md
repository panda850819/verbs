---
type: skill-eval
skill: retro-month
bucket: productivity
evaluated_skill_hash: 44e705a2f44a811e6b088b8c2c772f10c55829c7
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — retro-month

**Verdict: SOLID.** A tightly-gated three-phase interview flow whose predictability is enforced by explicit human wait-points and verbatim-capture rules, weakened by sprawl and a script reference that does not resolve.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L113 — "Walk through layers ONE QUESTION AT A TIME" plus per-phase wait-gates (L86, L109) pin the same process every run |
| Description / invocation | weak | L3 — "monthly retro", "monthly review" are two phrasings of one branch (near-synonym duplication); `version` absent from frontmatter |
| Completion criteria | pass | L86 — Phase 1 ends on a checkable gate ("掃完了。要開始月度 interview 嗎？" — wait for user) and Phase 3 lands on a concrete write target (L159) |
| Information hierarchy | weak | L31 — "The sub-sections below document what it gathers" frames 1a–1d as docs, yet L39–47/L53–56 ship full executable bash that re-runs what the engine already covers — duplication/sediment |
| Leading words | pass | L236 — "prefer **append + supersede** over **delete + rewrite**" anchors the edit discipline in a compact, pretrained contrast |
| Pruning | weak | L21 — the body is 239 lines (vs the ~<80 pandastack norm); much is the Phase-3 output template (L161–220), legitimate scaffold but still sprawl, and 1a–1d duplicate engine behaviour |
| Granularity | pass | L7 — split from `retro-week` by sequence/cadence (`related_skills: [retro-week]`); the monthly cut earns its own leading word and strategic-layer steps |
| pandastack conformance | weak | L21 — `~/site/skills/pandastack/scripts/retro-scan.sh` does NOT resolve; canonical install path is `plugins/pandastack/scripts/retro-scan.sh`, so the engine call breaks at the documented path |

## Why it's good
The phase gates and "ONE QUESTION AT A TIME" rule (L113) make this a genuinely deterministic interview, not a free-form chat — the agent stops and waits at L86 and L109, capturing user verdicts verbatim (L119, L146). The append+supersede discipline (L236) and the load-bearing-questions carve-out for short mode (L238: still run 2b-i goal-alignment) protect the irreducible core. Output is a single fixed brain template (L161–220), so two runs produce comparably-shaped retros.

## Top fixes
1. L21 — fix the broken engine path: the documented `~/site/skills/pandastack/scripts/retro-scan.sh` does not exist; canonical is `plugins/pandastack/scripts/retro-scan.sh`. A hardcoded path that breaks at install is a real conformance failure.
2. L31 + L39–47/L53–56 — resolve the duplication: either delete the inline bash for 1a–1d (the engine runs it) or relabel them as "the engine does X" reference, not re-runnable steps. As written the agent may double-run the scan.
3. L3 — collapse "monthly retro"/"monthly review" to one trigger and add `version:` to frontmatter for drift tracking.

## Behavioral cases
- trigger `/retro-month` (or "monthly retro") → expected process: run retro-scan engine → print compressed scan block → wait → strategic interview one question at a time → write `reflections/monthly/$YEAR-$MONTH.md`
- anti-trigger `weekly retro` / `/retro-week` → should NOT fire (routes to sibling `retro-week`; this skill is the monthly strategic cadence only)
