---
type: skill-eval
skill: skill-creator
bucket: meta
evaluated_skill_hash: 3ca72338fd616f81d665f631e9815e9e3f140e4f
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — skill-creator

**Verdict: SOLID.** Same checkable process every run: refuse-to-build gated upfront, hot/cold made mandatory, scorecard bound at the generation moment. The new subtract-first gate is a real completion-criteria win for Phase 2 — but it restates L35 rather than replacing it, and now that Native parity is scored for the first time, the skill still doesn't name its own delta against the model's default skill-authoring reflex.

_2026-06-29 re-stamp: SKILL.md L35 synced the MECE category walk to RESOLVER's current headings (dropped the removed "Personas" / "Multi-lens review" categories). Content-preserving edit — verdict and axis citations unchanged; hash refreshed._

_2026-07-02 re-stamp (a): v3.4.0 removed `team-orchestrate` from the disambiguation examples. Content-preserving edit — verdict and axis citations unchanged; hash refreshed._

_2026-07-02 re-stamp (b): added the subtract-first gate to Phase 2 (L37) and scored Native parity for the first time (axis added to the scorecard by #139, missed on this skill's prior pass). Net movement: Completion criteria stays pass but is now better-evidenced (Phase 2 finally has a checkable exit condition); Leading words drops to weak (the gate coins an unestablished term); Pruning's weak carries over with new evidence (the gate restates L35 instead of merging with it); Native parity enters as weak (never assessed before, and not fixed by this edit)._

_2026-07-03 re-stamp: added the `docs/out-of-scope/` precedent check to Phase 2 (L35). Net movement: Completion criteria stays pass with an earlier stop condition; Pruning stays weak because Phase 2 now has three adjacent anti-sprawl gates that still need one tighter paragraph._

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L14 — fixed spine (1 gap → 2 MECE, now incl. out-of-scope + subtract-first gates → 3 hot/cold → 3.5 inline/extract → 4 write → 5 resolver → 6 verify → 7 self-check); the new gate slots into the existing Phase 2 without reordering anything. |
| Description / invocation | pass | L4 — leading verb "Create new pandastack skills" still front-loaded, one-trigger-per-branch list unchanged by this edit. |
| Completion criteria | pass | L35 — Phase 2 now has a concrete early exit: consult the precedent directory, and if a match exists, surface it and stop. |
| Information hierarchy | pass | L110 — the heavy verify+route procedure still sits behind the `lib/verify-and-route-check.md` pointer; the new 2-line precedent gate stays inline at L35, correctly, since every Phase-2 run needs it. |
| Leading words | weak | L40 — "subtract-first gate" is coined for this edit only (repo-wide grep finds it nowhere else: not in `GLOSSARY.md`, not reused by another skill); contrast L133's "MECE violation," which anchors an already-shared term. A leading word should compress a concept the model or repo already carries, not mint a private label in the same breath it's used. |
| Pruning | weak | L40 — restates L38's "extend that skill instead of adding new" two lines later as "why extending… was rejected… do not create"; with L35 added, Phase 2 now has three adjacent anti-sprawl gates that could be one ordered paragraph. |
| Native parity | weak | L12 — nearest native feature is the model's default reflex to hand-write a SKILL.md ad hoc from a prompt; the delta is the Q0/MECE/hot-cold/subtract-first gate stack this skill forces — but the skill never states that native competitor or delta explicitly (mirrors the same gap the axis's own home skill, `writing-great-skills`, still owes itself). |
| Granularity | pass | L30 — the precedent gate follows the same inline Phase-2 pattern already used by the Q0 refuse-to-build check (L30-33) rather than claiming a numbered sub-step; 3.5 and 6.5 still reserve numbered splits for decisions with their own branching logic. |
| pandastack conformance | weak | L4 — frontmatter/manifest/RESOLVER/`lib/` refs all resolve, but the file is now 143 lines end-to-end (was 138 pre-edit), still well past the ~80-line guidance this skill would flag in someone else's SKILL.md. |

## Why it's good
The skill still enforces its own thesis in order: Q0 refuse-to-build (L30) runs upstream of the precedent and overlap checks, hot/cold stays a mandatory diagrammed binary (L46-65), and Phase 7 (L114) binds the writing-great-skills scorecard at the generation moment. The out-of-scope gate (L35) is a real upgrade to Phase 2: rejected directions become a checkable stop condition before the agent spends tokens proposing a known-bad skill or abstraction.

## Top fixes
1. L35-L40 — merge the Phase 2 anti-sprawl checks into one paragraph: Q0 -> out-of-scope precedent -> RESOLVER overlap -> name-the-skill-or-halt. The behavior is good; the shape is starting to accrete.
2. L40 — either drop the "subtract-first gate" label and let the instruction stand on its own, or, if the term is meant to stick as shared vocabulary, use it again elsewhere (RESOLVER.md's Disambiguation section, or a `writing-great-skills` GLOSSARY entry) so it earns leading-word status instead of being coined once and never reinforced.
3. L12 — name skill-creator's own native-parity delta (default model reflex to hand-write a SKILL.md vs. the Q0/MECE/hot-cold/subtract-first gate stack), matching the self-example the axis's home skill (`writing-great-skills`) still owes itself.

## Behavioral cases
- trigger `create a skill for auditing stale brain pages` -> expected process: Q0 refuse-to-build first (is this a brain page or one-line script?), consult `docs/out-of-scope/`, then MECE-walk RESOLVER against `maintain`, then the subtract-first gate — name `maintain` as the skill this would extend or state why extending it was rejected, else stop; hot/cold-decide, write to the frontmatter contract, add RESOLVER/manifest rows, verify, scorecard self-check + `/skill-eval`.
- anti-trigger `score whether this skill is well-written` -> should NOT fire (routes to `skill-eval`, the evaluator counterpart that writes the co-located `eval.md`; skill-creator builds and gates creation, it does not produce the verdict).
