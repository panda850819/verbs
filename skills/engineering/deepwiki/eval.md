---
type: skill-eval
skill: deepwiki
bucket: engineering
evaluated_skill_hash: 87314838758260e991a1b8d496c849d199d71b6c
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — deepwiki

**Verdict: SOLID.** Its load-bearing virtue is anti-hallucination discipline: the Phase 3 source-grounding guard plus a real lint backstop make "don't draw edges you didn't read in source" a checkable gate, not a wish — rare and genuinely well-engineered.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L77 — fixed Phase 1→5 ordering with per-phase sub-steps gives the same process every run; clone → analyze → generate → mermaid → gate is deterministic. |
| Description / invocation | pass | L7 — front-loads "GitHub repo docs + Mermaid diagrams", explicit `Trigger on` / `Skip when` branches, correctly user-invocable; `aliases: [tool-deepwiki]` (L3) is undocumented in SKILL-FRONTMATTER.md (no `aliases` key in its field table) but harmless. |
| Completion criteria | weak | L289 — the Phase 5 gate runs "in your thinking" (honor-system checklist), which is premature-completion bait: the agent can self-report pass without a code check, exactly the failure the L228 lint was built to avoid. The strong gate (L228) is not generalized to the rest of the gate. |
| Information hierarchy | weak | L222 — Phase 3 inlines a ~5-line grounding essay hot; sibling files exist (`agents/system.md`, `agents/wiki-gen.md`, `agents/mermaid.md`, verified present and 0 references in SKILL.md) but the body never points at them via a context pointer, so progressive disclosure is unused while the body sits at 316 lines. |
| Leading words | weak | L224 — "Source-grounding guard" is a coined phrase, not a pretrained anchor; the rule leans on restated imperatives ("MUST", "hard rule", "grounded in source you actually read") repeated across L156/L224/L226 instead of one leading word that collapses them. |
| Pruning | weak | L291 — the Phase 5 Quality Gate restates the Mandatory Output Requirements (L149–152) and the Source Reading Rule (L156) almost verbatim; combined with 316 lines (second-longest meta skill, ~4× the qualitative ~<80 reference) this is duplication plus sprawl. |
| Granularity | pass | L77 — one coherent skill, no over-split; the only granularity miss is that the `agents/` units are present but unwired (a hierarchy fault, scored above), not a bad cut. |
| pandastack conformance | weak | L228 — `lib/lint-mermaid-grounding.sh` is a repo-root-relative `lib/` ref and the script exists there, so the rubric's "`lib/` refs resolve" criterion is MET — same convention as skill-creator's `lib/skill-decision-tree.md` and using-pandastack's `lib/verify-the-test-loop.md`. What is not clean: 316 lines vs the rubric's "~<80 unless earned". SKILL-FRONTMATTER.md L85–87 disavows hard line numbers ("discipline is qualitative, not a magic number"), so this is a real length-discipline weakness, not a hard fail; the unwired `agents/` siblings are the obvious place to disclose the overage. |

## Why it's good
The Phase 3 source-grounding guard (L224–228) is the rare case of a skill turning "don't hallucinate architecture" into a falsifiable, code-backed gate — directional mermaid edges must trace to read imports/calls, a directory tree is explicitly declared not-source, and a lint exits 2 on violation. The Phase 1 abort-early discipline (L83 gh-auth check, L93–96 clone-failure stop, L136 no-hallucinate-on-empty) keeps the skill from producing confident docs over missing source. Together these make the predictable process trustworthy, not just repeatable.

## Top fixes
1. L222 — wire the existing `agents/system.md`, `agents/wiki-gen.md`, `agents/mermaid.md` via context pointers and move the hot Phase 3 grounding essay + Phase 5 detail behind them; this is the lever that pulls 316 lines back toward the qualitative budget instead of padding the hot body.
2. L291 — cut the Phase 5 duplication: the Quality Gate re-states L149–152 (Mandatory Output Requirements) and L156 (Source Reading Rule). Collapse to one source of truth.
3. L289 — make the gate a code check, not a thinking-only checklist; generalize the L228 lint model (mermaid syntax via `mmdc`, tree cross-check) so "I produced the checklist" can't substitute for "the check passed".

## Behavioral cases
- trigger `document this repo <github.com/org/name>` → expected process: gh-auth check → shallow clone → tree analysis → read ≥2 real source files (L156) → generate the 5 mandatory sections → grounded mermaid + lint (L228) → Phase 5 gate → route per `--output`.
- anti-trigger `where is the retry logic in this repo` → should NOT fire (a code grep/lookup; routes to gh CLI / grep per L8 `Skip when`), not a full doc-generation run.
