---
type: skill-eval
skill: deepwiki
bucket: engineering
evaluated_skill_hash: ee13e512aac719fe1418bde03a7ee923f392035c
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — deepwiki

**Verdict: WEAK.** Leading virtue is a genuinely falsifiable quality gate: Phase 5 forbids self-reporting, the repo-root source-grounding lint resolves, and the skill-local output template now resolves through an explicit repo-relative path. It remains WEAK because the body is still ~205 lines, routing/grounding rules repeat across phases, and Phase 4 is thin.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L42 — the workflow graph pins the same 5-phase process every run (clone → analyze → read source → generate → gate → route), independent of which repo is fed in. |
| Description / invocation | pass | L5 — front-loads "GitHub repo docs + Mermaid diagrams"; `Trigger on` / `Skip when` (L7-8) are one-trigger-per-branch; model-invocable, no body identity restated. |
| Completion criteria | pass | L176 — "passes only when its command exits clean or its grep finds the evidence — producing the checklist is not passing it" makes each gate item done-vs-not checkable, killing the premature-completion bait. |
| Information hierarchy | weak | L124 — the Mandatory-Output table plus the tech-stack/key-files tables sit hot in the body while only the fill-in template was pushed to lib/; reference-grade material is split across both tiers rather than fully behind the pointer. |
| Leading words | pass | L162 — "code gate, not honor system" and "the lint is the backstop" are compact anchors that carry the grounding discipline in few tokens. |
| Pruning | weak | L178 — the source-grounding rule lives in Phase 3 (L158), the Source Reading Rule (L138), and Phase 5 check 1; the gate self-defends "does not restate them" (L184) yet check 1 still re-describes the edged-diagram fix, and routing repeats across L142 and L170. |
| Native parity | weak | L16 — nearest native feature is ad hoc `gh clone` plus manual source reading; the skill's delta is the fixed clone→analyze→grounded-diagram pipeline, but the body does not explicitly name that native baseline. |
| Granularity | weak | L168 — Phase 4 "Output" is a thin section that mostly re-points to the Output Routing Rule already defined in Phase 2; the split does not clearly earn its load. |
| pandastack conformance | weak | L152 — the skill-local template is now an explicit repo-relative path (`skills/engineering/deepwiki/lib/output-and-diagrams.md`) and the code gate uses the repo-root `lib/lint-mermaid-grounding.sh` (L162), so refs resolve under `lint-refs-resolve.py`. Residual: body ~205 lines exceeds the ~<80 reference and still carries duplicated routing/grounding prose. |

## Why it's good
The skill converts the core failure mode of repo documentation — hallucinated architecture diagrams — into a falsifiable, command-checked gate: Phase 5 forbids self-reporting (L176) and the source-grounding lint catches directional edges lacking a source citation (L162). The description is tight and correctly model-invoked, and the workflow graph plus fixed Phase 1→5 ordering make the process deterministic across runs. The fill-in template and per-type diagram syntax were extracted to `skills/engineering/deepwiki/lib/output-and-diagrams.md`, and all internal refs now resolve.

## Top fixes
1. L158 / L178 — collapse the source-grounding rule to one home. Phase 5 check 1 should cite Phase 3 by reference only ("run the Phase 3 grounding lint; exit 0 required") instead of re-describing the edged-diagram fix already given at L158-160.
2. L168 — fold Phase 4 into the Output Routing Rule or drop it; it restates Phase 2's rule and only adds the Notion `/tmp` write detail, which can live beside that rule.
3. L124 / L150 — move the mandatory-output table and routing examples behind the same skill-local lib pointer if the body needs to move closer to the ~80-line target.

## Behavioral cases
- trigger `/deepwiki vercel/next.js --output notion` -> expected process: gh-auth check (L65), shallow clone, tree + tech-stack detection, read ≥2 source files (L138), generate 5 mandatory sections + grounded Mermaid, run Phase 5 gate to exit 0 (L176), ask for Notion page ID, write via `notion page update` (L170).
- anti-trigger `where is the auth middleware defined in this repo` -> should NOT fire (code grep/lookup routes to `gh` CLI or grep per the Skip clause L8), not a full wiki-generation run.
