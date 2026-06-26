---
type: skill-eval
skill: review
bucket: engineering
evaluated_skill_hash: 6a0b0e81b0a96c57efedd3b31635012cccac03a8
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — review

**Verdict: SOLID.** A rigorously-sequenced multi-pass review with hard completion criteria (the Step 8 ASCII box) and genuine anti-rubber-stamp guardrails (cold review, Codex cross-model, grounding rule), undercut by sprawl and a few unresolved template variables.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | weak | L59 — `{learnings_dir}` is used as a path but never resolved or sourced anywhere in the skill; the agent has no defined process to bind it, so the same step runs differently across projects |
| Description / invocation | pass | L4 — front-loads "review"/"check my code"/"before a PR" as distinct trigger branches; model-invoked correctly for an agent-reachable verb |
| Completion criteria | pass | L297 — "still print the box. Mark unrun steps as `skipped (user)`" gives a hard, checkable done-state that defeats premature completion even on abort |
| Information hierarchy | weak | L114 — a full inline finding-format spec plus the Mnilax Rule 9 narrative sits hot in SKILL.md where a `lib/` pointer (the pattern already used for confidence/gate-contract) would keep the top legible |
| Leading words | pass | L176 — "Cold Review (Uncorrelated Context)" anchors decorrelation in a pretrained concept; "adversarial cross-check", "fog"-style framing recur and do real anchoring work |
| Pruning | weak | L299 — the "Common Rationalizations" table (L299-309, 11 lines) is motivational prose; useful but it pushes an already-286-line body further past the ~80-line bar and several rows restate completion criteria already stated |
| Granularity | pass | L101 — Step 5 Parallel Review is split by sequence from the cold/Codex passes that follow, each an independent gate; the splits earn their keep rather than fragmenting one action |
| pandastack conformance | weak | L25 — body runs 286 lines (3.5x the ~<80 guideline) with no stated earn; lib refs all resolve and forbids/reads frontmatter is valid, but the length bar is plainly broken |

## Why it's good
The skill's spine is its decorrelation machinery: Step 6 cold review, Step 6.5 Codex cross-model, and the L122 anti-hallucination grounding rule together force a review that cannot quietly rubber-stamp itself, which is exactly the failure mode review skills die on. Completion is genuinely checkable — the Step 8 box is printed even on user abort (L297), so "did I finish?" is never ambiguous. Frontmatter is disciplined: explicit `forbids: git push / gh pr create` (L19-20) keeps the verb read-only and on the right side of the ship boundary.

## Top fixes
1. L59 / L54 — define `{learnings_dir}` and `{main}` once at Step 1 (e.g. "resolve `{main}` and `{learnings_dir}` from the pstack config read above; default to `main` / `docs/learnings`"). Right now they are dangling placeholders that break per-run predictability.
2. L114 — push the inline finding-format spec + Mnilax Rule 9 exposition behind a `lib/review-pass-format.md` pointer, matching the progressive-disclosure pattern the skill already uses for confidence.md / gate-contract.md.
3. L25 — the 286-line body needs a stated earn or a cut. The conditional passes (L132-160) and the rationalizations table (L299) are the obvious candidates to externalize.

## Behavioral cases
- trigger `review my code before I open the PR` → expected process: Step 0 system audit (5 cmds) → scope the diff → load learnings → brief-alignment → parallel passes → cold review + Codex → write learnings → print completion box. Stops without pushing (forbids git push).
- anti-trigger `ship this and open the PR` → should NOT fire; `git push` / `gh pr create` are forbidden here — routes to `pandastack:ship`.
