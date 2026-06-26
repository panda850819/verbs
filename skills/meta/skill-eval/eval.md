---
type: skill-eval
skill: skill-eval
bucket: meta
evaluated_skill_hash: 25e7ef05320a1a1ac1995961905ed25432e3110b
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — skill-eval

**Verdict: SOLID.** A tight, self-referential evaluator: it binds writing-great-skills as its single criteria source, forces one cited line per axis, and closes on a machine-checkable completion criterion (eval.md exists + hash stamped + lint passes).

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L19 — `## Steps` is a fixed 4-step ordered process; every run takes the same path (load criteria → score → optional second opinion → write verdict). |
| Description / invocation | weak | L4 — model-invoked is right, but the trigger list piles five near-synonyms ("eval this skill" / "score this skill" / "is this skill well-written" / "why is this skill good" / "(re)generate a skill's eval") that all name one branch "evaluate a skill" — synonym duplication that should collapse (§ Writing the description). |
| Completion criteria | pass | L35 — closes checkable and exhaustive: `eval.md` exists + every axis has a cited line + `lint-eval-fresh.sh` passes; no premature-completion bait. |
| Information hierarchy | pass | L11 — criteria pushed out to the writing-great-skills scorecard via a context pointer ("load its **scorecard** section"); the template kept inline where it is read every run. |
| Leading words | pass | L17 — "fans out" + "hot/cold rule — never score the whole corpus in one hot context" anchor the dispatch behaviour in pretrained concepts instead of restating it. |
| Pruning | weak | L29 — Step 3 "Second opinion (optional, for first-class skills)" is the softest tier: "optional" + the fuzzy gate "heavily-used skill" lets the agent skip by default, so the step pays load while changing little behaviour (near no-op). |
| Granularity | pass | L17 — the `all` fan-out splits by sequence correctly: one sub-agent per skill, honouring the hot/cold rule rather than scoring every skill in one hot context. |
| pandastack conformance | pass | L23 — frontmatter valid, body 50 non-blank lines (<80), hot/cold honoured (L17), and `lib/quality-rubric.md` / `SKILL-FRONTMATTER.md` / `scripts/lint-eval-fresh.sh` all resolve in-repo. |

## Why it's good
The scope note (L13) and the SSOT pointer (L11) keep this skill from re-inventing axes — it judges construction only and defers all criteria to writing-great-skills, so the two stay in sync by reference, not by copy. The completion criterion (L35) is genuinely exhaustive (file + per-axis citation + lint), and the Anti-patterns section (L76-81) names the exact failures this evaluator is most prone to (rubber-stamping, scoring-the-artifact, uncited verdicts) — a self-aware guard most skills lack.

## Top fixes
1. L4 — collapse the five synonym triggers to one branch phrase + the re-gen case (e.g. "eval/score a skill, or regenerate its eval after editing"); the renamed-synonym pile is description duplication that pays context load every turn.
2. L29 — either give Step 3 a hard gate (a named threshold for "first-class"/"heavily-used") or demote it from a numbered Step to an in-skill reference note; an "optional" numbered step invites skip-by-default and reads as a no-op.
3. L31 — "Disagreement on an axis → downgrade to weak" is a reconciliation rule buried inside the optional Step 3; if that step is skipped the rule is lost. Surface it where scoring happens (L27), not only inside the skippable tier.

## Behavioral cases
- trigger `/skill-eval ingest` → expected process: read the writing-great-skills scorecard (8 axes), read `skills/<bucket>/ingest/SKILL.md` whole + its sibling refs, score each axis pass/weak/fail with one `L<n>`, write `skills/<bucket>/ingest/eval.md` from the template, stamp `git hash-object`, verify `lint-eval-fresh.sh ingest` passes.
- anti-trigger `score the brief this skill produced` → should NOT fire (scoring the artifact, not the SKILL.md construction — routes to `lib/quality-rubric.md`, per the scope note at L13).
