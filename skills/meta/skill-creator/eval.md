---
type: skill-eval
skill: skill-creator
bucket: meta
evaluated_skill_hash: 97f2ccb381df9feb8dcd1bd25651cab95ceb2f3b
evaluated_at: 2026-07-09
rubric: writing-great-skills@1.1.0
---

# Eval — skill-creator

> 2026-07-09 re-validation (#170): skill-creator absorbed the retired `skill-eval` as an `--eval <name>` mode (evaluator half; scoring steps + eval.md template moved to `lib/skill-eval.md`, referenced by the new `## --eval mode` section at L14-16). Description (L4) now advertises `--eval`; Phase 7 self-check (L120) now runs `--eval` instead of `/skill-eval`. Verdict unchanged (SOLID); all axis citations re-anchored to current lines.

**Verdict: SOLID.** Same checkable process every run: refuse-to-build gated upfront, hot/cold made mandatory, scorecard bound at the generation moment. The new subtract-first gate is a real completion-criteria win for Phase 2 — but it restates L42 rather than replacing it, and now that Native parity is scored, the skill still doesn't name its own delta against the model's default skill-authoring reflex. Folding the evaluator in as `--eval` strengthens Native parity (build + eval are now one verb) without disturbing the build spine.

_2026-06-29 re-stamp: SKILL.md L42 synced the MECE category walk to RESOLVER's current headings (dropped the removed "Personas" / "Multi-lens review" categories). Content-preserving edit — verdict and axis citations unchanged; hash refreshed._

_2026-07-02 re-stamp (a): v3.4.0 removed `team-orchestrate` from the disambiguation examples. Content-preserving edit — verdict and axis citations unchanged; hash refreshed._

_2026-07-02 re-stamp (b): added the subtract-first gate to Phase 2 (L44) and scored Native parity for the first time (axis added to the scorecard by #139, missed on this skill's prior pass). Net movement: Completion criteria stays pass but is now better-evidenced (Phase 2 finally has a checkable exit condition); Leading words drops to weak (the gate coins an unestablished term); Pruning's weak carries over with new evidence (the gate restates L42 instead of merging with it); Native parity enters as weak (never assessed before, and not fixed by this edit)._

_2026-07-03 re-stamp: added the `docs/out-of-scope/` precedent check to Phase 2 (L39). Net movement: Completion criteria stays pass with an earlier stop condition; Pruning stays weak because Phase 2 now has three adjacent anti-sprawl gates that still need one tighter paragraph._

_2026-07-09 re-stamp (#170): absorbed the retired `skill-eval` as an `--eval` mode (L14-16, L120). Net movement: Native parity's weak now has a concrete direction (generator + evaluator under one verb), and Granularity stays pass because `--eval` is a mode flag, not a claimed numbered sub-step; build spine and all other axes unchanged._

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L20 — fixed spine (1 gap → 2 MECE, now incl. out-of-scope + subtract-first gates → 3 hot/cold → 3.5 inline/extract → 4 write → 5 resolver → 6 verify → 7 self-check); `--eval` (L14) slots in as a parallel mode without reordering the build phases. |
| Description / invocation | pass | L4 — leading verb "Create new pandastack skills" still front-loaded; one-trigger-per-branch list now also carries the `--eval`/"eval/score this skill" trigger folded in from the retired skill-eval. |
| Completion criteria | pass | L39 — Phase 2 has a concrete early exit: consult the precedent directory, and if a match exists, surface it and stop. |
| Information hierarchy | pass | L114 — the heavy verify+route procedure sits behind the `lib/verify-and-route-check.md` pointer, and the eval scoring steps sit behind the `lib/skill-eval.md` pointer (L16); the 2-line precedent gate stays inline at L39, correctly, since every Phase-2 run needs it. |
| Leading words | weak | L44 — "subtract-first gate" is coined for this edit only (repo-wide grep finds it nowhere else: not in `GLOSSARY.md`, not reused by another skill); contrast L137's "MECE violation," which anchors an already-shared term. A leading word should compress a concept the model or repo already carries, not mint a private label in the same breath it's used. |
| Pruning | weak | L44 — restates L42's "extend that skill instead of adding new" two lines later as "why extending… was rejected… do not create"; with L39 added, Phase 2 now has three adjacent anti-sprawl gates that could be one ordered paragraph. |
| Native parity | weak | L12 — nearest native feature is the model's default reflex to hand-write (and ad-hoc score) a SKILL.md from a prompt; the delta is the Q0/MECE/hot-cold/subtract-first gate stack plus the now-absorbed `--eval` scorer (L14, one verb for build + eval) — but the skill never states that native competitor or delta explicitly (mirrors the same gap the axis's own home skill, `writing-great-skills`, still owes itself). |
| Granularity | pass | L34 — the precedent gate follows the same inline Phase-2 pattern already used by the Q0 refuse-to-build check (L34-37) rather than claiming a numbered sub-step; the absorbed evaluator ships as a `--eval` mode (L14), not a split skill, and 3.5 / 6.5 still reserve numbered splits for decisions with their own branching logic. |
| pandastack conformance | weak | L4 — frontmatter/manifest/RESOLVER/`lib/` refs all resolve, but the file is now 147 lines end-to-end, still well past the ~80-line guidance this skill would flag in someone else's SKILL.md. |

## Why it's good
The skill still enforces its own thesis in order: Q0 refuse-to-build (L34) runs upstream of the precedent and overlap checks, hot/cold stays a mandatory diagrammed binary (L50-69), and Phase 7 (L118) binds the writing-great-skills scorecard at the generation moment. The out-of-scope gate (L39) is a real upgrade to Phase 2: rejected directions become a checkable stop condition before the agent spends tokens proposing a known-bad skill or abstraction. Folding the evaluator in as `--eval` (L14) means the generator and its scorecard-scorer bind the same SSOT — build and eval are one verb.

## Top fixes
1. L39-L44 — merge the Phase 2 anti-sprawl checks into one paragraph: Q0 -> out-of-scope precedent -> RESOLVER overlap -> name-the-skill-or-halt. The behavior is good; the shape is starting to accrete.
2. L44 — either drop the "subtract-first gate" label and let the instruction stand on its own, or, if the term is meant to stick as shared vocabulary, use it again elsewhere (RESOLVER.md's Disambiguation section, or a `writing-great-skills` GLOSSARY entry) so it earns leading-word status instead of being coined once and never reinforced.
3. L12 — name skill-creator's own native-parity delta (default model reflex to hand-write and ad-hoc score a SKILL.md vs. the Q0/MECE/hot-cold/subtract-first gate stack plus the built-in `--eval` scorer), matching the self-example the axis's home skill (`writing-great-skills`) still owes itself.

## Behavioral cases
- trigger `create a skill for auditing stale brain pages` -> expected process: Q0 refuse-to-build first (is this a brain page or one-line script?), consult `docs/out-of-scope/`, then MECE-walk RESOLVER against `maintain`, then the subtract-first gate — name `maintain` as the skill this would extend or state why extending it was rejected, else stop; hot/cold-decide, write to the frontmatter contract, add RESOLVER/manifest rows, verify, scorecard self-check + run `--eval` to write the co-located `eval.md`.
- trigger `score whether this skill is well-written` -> SHOULD fire: skill-creator now owns eval-scoring via `--eval <name>` (L14-16), the evaluator half folded in when `skill-eval` retired. It reads the writing-great-skills scorecard, scores all 9 axes with cited `L<n>` evidence, and writes the co-located `eval.md` with the SKILL.md hash stamped.
