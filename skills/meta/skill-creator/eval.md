---
type: skill-eval
skill: skill-creator
bucket: meta
evaluated_skill_hash: 74521fb8f5b89dd6612702b262499fd996398d07
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — skill-creator

**Verdict: SOLID.** A refuse-to-build-first authoring workflow whose phases fix one process per run and whose hot/cold gate is genuinely load-bearing — held back from STRONG by a 188-line body, two `.5` accretion phases, and an evidence pointer that does not resolve.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L12 — "Sized to fit between office-hours and sprint"; the seven numbered phases fix one process every run, not one output |
| Description / invocation | weak | L4 — front-loads "Create new pandastack skills" well and keeps the load-bearing "NOT the brain filing-tree RESOLVER.md" disambiguator, but double-names the index ("the pandastack RESOLVER.md (RESOLVER.md at the repo root …)") and restates body identity (MECE / hot-cold) instead of pruning to triggers + reach |
| Completion criteria | pass | L160 — done-gate is checkable and closed: score against the scorecard, revise any weak axis, run `/skill-eval`, `lint-eval-fresh.sh` enforces |
| Information hierarchy | weak | L136 — Phase 6.5 is a multi-step reference *procedure* (pick 6 confusable pairs → write ~6 prompts → re-check → tighten) kept hot inline; this belongs behind a `lib/` pointer, not the SKILL.md top tier |
| Leading words | pass | L62 — "non-negotiable" (and L26 "smallest durable change") are crisp pretrained anchors that fix behaviour in few tokens |
| Pruning | weak | L155 — "the cheap, solo-durable version of yao-meta-skill's route-confusion guard … steal the mechanism, refuse its harness shape" is no-op meta-narration; the body is 188 lines, well over the ~<80 guideline |
| Granularity | weak | L64 — Phase 3.5 (and L136 Phase 6.5) are bolted-on `.5` sub-phases: accretion / sediment, not splits that earn a load |
| pandastack conformance | weak | L62 — `learnings/patterns/long-session-evals` does not resolve (no `learnings/` dir in this layout); cited 3× (L62, L179, L188). Frontmatter is clean and `RESOLVER.md` / `SKILL-FRONTMATTER.md` resolve at repo root, so this is a broken evidence pointer, not a structural fail |

## Why it's good
The Q0 refuse-to-build gate (L30) plus the trigger-first evolution load (L18) put the cheapest non-skill outcome upstream of every other phase, which is exactly the sprawl defence the rubric asks for. The hot/cold decision (L39-62) is mandatory, diagrammed, and tied to long-session-eval evidence, so the single most consequential authoring choice cannot be silently skipped. Completion is honestly closed: L160 forces a scorecard self-check and a written `eval.md`, binding construction quality at the generation moment rather than as an afterthought.

## Top fixes
1. **L62 / L179 / L188** — the `learnings/patterns/long-session-evals` pointer is dead (no `learnings/` dir in this layout). Repoint it to where the long-session evidence actually lives, or drop the path and keep the prose claim. A skill that cites missing evidence for its single "non-negotiable" rule erodes that rule's authority every time the pointer is followed.
2. **L136-156** — move Phase 6.5's near-neighbor route-check procedure into a `lib/` reference reached by a context pointer, and delete the L155-156 yao-meta-skill meta-narration (no-op). This pulls the 188-line body toward the ~<80 budget and lifts pruning and information-hierarchy at once.
3. **L4** — prune the description: drop the self-restating "(RESOLVER.md at the repo root — the skill-overlap index …)" aside and the MECE / hot-cold identity that the body already owns; keep triggers + the "NOT the brain filing-tree RESOLVER.md" reach clause. Fold the two `.5` phases (3.5 → 3, 6.5 → 6/lib) so the phase list reads as clean splits, not sediment.

## Behavioral cases
- trigger `create a new pandastack skill for X` → expected process: Phase 1 gap identification, then Q0 refuse-to-build (L30), MECE-walk `RESOLVER.md` (L35), decide hot/cold (L39), write SKILL.md to the frontmatter contract (L72), update RESOLVER + manifest, self-check against writing-great-skills (L158), then `/skill-eval`.
- anti-trigger `score this skill / is this skill well-written` → should NOT fire; that is evaluation, routes to `skill-eval` (the generator's evaluator counterpart, not the generator).
