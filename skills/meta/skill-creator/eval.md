---
type: skill-eval
skill: skill-creator
bucket: meta
evaluated_skill_hash: 697a20e4aedea3feffe7a32bca8b06b3fd66d9b0
evaluated_at: 2026-07-02
rubric: writing-great-skills@1.0.0
---

# Eval — skill-creator

**Verdict: SOLID.** Same checkable process every run: refuse-to-build gated upfront, hot/cold made mandatory, scorecard bound at the generation moment. The new subtract-first gate is a real completion-criteria win for Phase 2 — but it restates L35 rather than replacing it, and now that Native parity is scored for the first time, the skill still doesn't name its own delta against the model's default skill-authoring reflex.

_2026-06-29 re-stamp: SKILL.md L35 synced the MECE category walk to RESOLVER's current headings (dropped the removed "Personas" / "Multi-lens review" categories). Content-preserving edit — verdict and axis citations unchanged; hash refreshed._

_2026-07-02 re-stamp (a): v3.4.0 removed `team-orchestrate` from the disambiguation examples. Content-preserving edit — verdict and axis citations unchanged; hash refreshed._

_2026-07-02 re-stamp (b): added the subtract-first gate to Phase 2 (L37) and scored Native parity for the first time (axis added to the scorecard by #139, missed on this skill's prior pass). Net movement: Completion criteria stays pass but is now better-evidenced (Phase 2 finally has a checkable exit condition); Leading words drops to weak (the gate coins an unestablished term); Pruning's weak carries over with new evidence (the gate restates L35 instead of merging with it); Native parity enters as weak (never assessed before, and not fixed by this edit)._

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L14 — fixed spine (1 gap → 2 MECE, now incl. the subtract-first gate → 3 hot/cold → 3.5 inline/extract → 4 write → 5 resolver → 6 verify → 7 self-check); the new gate slots into the existing Phase 2 without reordering anything. |
| Description / invocation | pass | L4 — leading verb "Create new pandastack skills" still front-loaded, one-trigger-per-branch list unchanged by this edit. |
| Completion criteria | pass | L37 — Phase 2 previously had no checkable exit condition ("ask… if yes, extend" isn't falsifiable); the gate makes one: name the absorbed/replaced skill or the rejection reason, else halt — checkable and exhaustive, exactly what the scorecard asks of a step. |
| Information hierarchy | pass | L107 — the heavy verify+route procedure still sits behind the `lib/verify-and-route-check.md` pointer; the new 2-line gate stays inline at L37 rather than extracted, correctly, since every Phase-2 run needs it. |
| Leading words | weak | L37 — "subtract-first gate" is coined for this edit only (repo-wide grep finds it nowhere else: not in `GLOSSARY.md`, not reused by another skill); contrast L130's "MECE violation," which anchors an already-shared term. A leading word should compress a concept the model or repo already carries, not mint a private label in the same breath it's used. |
| Pruning | weak | L37 — restates L35's "extend that skill instead of adding new" three lines later as "why extending… was rejected… do not create": same defer-to-existing-skill meaning in two adjacent paragraphs under one heading. A single paragraph (walk → ask → name-or-halt) would read as one gate instead of two. Pre-existing weakness also still open: `lib/trigger-first-skill-evolution.md` cited three times (L18, L68, L131). |
| Native parity | weak | L12 — nearest native feature is the model's default reflex to hand-write a SKILL.md ad hoc from a prompt; the delta is the Q0/MECE/hot-cold/subtract-first gate stack this skill forces — but the skill never states that native competitor or delta explicitly (mirrors the same gap the axis's own home skill, `writing-great-skills`, still owes itself). |
| Granularity | pass | L30 — the new gate follows the same bolded-inline-label pattern already used by the Q0 refuse-to-build check (L30-33) rather than claiming a numbered sub-step; 3.5 and 6.5 still reserve numbered splits for decisions with their own branching logic, so folding the gate into Phase 2's prose costs nothing extra. |
| pandastack conformance | weak | L4 — frontmatter/manifest/RESOLVER/`lib/` refs all resolve, but the file is now 140 lines end-to-end (was 138 pre-edit), still well past the ~80-line guidance this skill would flag in someone else's SKILL.md. |

## Why it's good
The skill still enforces its own thesis in order: Q0 refuse-to-build (L30) runs upstream of the overlap walk, hot/cold stays a mandatory diagrammed binary (L43-62), and Phase 7 (L111) binds the writing-great-skills scorecard at the generation moment. The subtract-first gate (L37) is a genuine upgrade to Phase 2: it turns a soft "ask and use judgment" instruction into a checkable, exhaustive completion criterion — the exact move the scorecard's own Information Hierarchy section asks for — closing a gap the skill has carried since its first eval.

## Top fixes
1. L35/L37 — merge into one paragraph: walk RESOLVER → ask overlap → name-the-skill-or-halt. Right now the same "defer to an existing skill" instruction is stated once as guidance and again three lines later as a gate; one co-located paragraph reads as a single check instead of two.
2. L37 — either drop the "subtract-first gate" label and let the instruction stand on its own, or, if the term is meant to stick as shared vocabulary, use it again elsewhere (RESOLVER.md's Disambiguation section, or a `writing-great-skills` GLOSSARY entry) so it earns leading-word status instead of being coined once and never reinforced.
3. L12 — name skill-creator's own native-parity delta (default model reflex to hand-write a SKILL.md vs. the Q0/MECE/hot-cold/subtract-first gate stack), matching the self-example the axis's home skill (`writing-great-skills`) still owes itself.

## Behavioral cases
- trigger `create a skill for auditing stale brain pages` -> expected process: Q0 refuse-to-build first (is this a brain page or one-line script?), then MECE-walk RESOLVER against `maintain`, then the subtract-first gate — name `maintain` as the skill this would extend or state why extending it was rejected, else stop; hot/cold-decide, write to the frontmatter contract, add RESOLVER/manifest rows, verify, scorecard self-check + `/skill-eval`.
- anti-trigger `score whether this skill is well-written` -> should NOT fire (routes to `skill-eval`, the evaluator counterpart that writes the co-located `eval.md`; skill-creator builds and gates creation, it does not produce the verdict).
