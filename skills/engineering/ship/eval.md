---
type: skill-eval
skill: ship
bucket: engineering
evaluated_skill_hash: 38ad9409a5e101a6676353a173ac49c7f6a12c1a
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — ship

**Verdict: SOLID.** Strong leading-word anchors and a clean hot/cold split (knowledge mode + three reference chunks all behind resolvable pointers); costs points on inline duplication of a lib-owned rule (L154) and a git-mode body still past the ~<80 budget (L168).

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L39 — fixed mode-dispatch table then numbered Steps 0–11 run the same ordered process every git-mode invocation; the path-sniff fallback (L46) is deterministic, no model-discretion forks. |
| Description / invocation | pass | L4 — front-loads "Multi-mode ship verb. Closes work", branch-per-trigger table, explicit `/handover` disambiguation (L8), "Use when asked to ship / create PR / ship this note"; no body-identity leak. |
| Completion criteria | pass | L74 — the prior soft gate is now checkable ("if any matched pitfall touches a changed file, list it and require ack before proceeding; else skip"); L109 adds "Stop if `git diff --cached` is empty after staging"; the L150 judgment gate is bounded, not premature-completion bait. |
| Information hierarchy | pass | L172 — git mode (hot path) inline as ordered steps, knowledge mode and the rationalizations / project-state / quote-gate detail pushed behind explicit pointers; progressive disclosure is real. |
| Leading words | pass | L97 — step headers ("Pre-flight", "Load Learnings", "Scope Check", "Review Gate", "Commit", "Branch", "Push + PR") are pretrained anchors; the model resolves each without restatement. |
| Pruning | weak | L154 — the full propose-only flaw-routing prose is inlined here AND owned by `lib/trigger-first-skill-evolution.md` AND mirrored in the review skill's matching rule; the lib file is the SSOT, so this should collapse to a one-line cite. The prior quote-gate duplication is fixed (now `@skills/engineering/ship/lib/quote-gate.md`, L152), so only this one remains. |
| Granularity | pass | L103 — the 11-step split earns its load: each step is a distinct ship gate (commit / branch / tag / push / release / learnings / state) with its own skip condition; none is a no-op fragment. |
| pandastack conformance | weak | L168 — frontmatter `name: ship` matches the folder; all pointers resolve (`@./modes/knowledge.md`, `@skills/engineering/ship/lib/{quote-gate,project-state,rationalizations}.md`, and repo-root `lib/trigger-first-skill-evolution.md`); but the git-mode body still runs ~115 lines (Steps 0-11 + dispatch), past the ~<80 guideline even after extraction. |

## Why it's good
The hot/cold dispatch is done right: the 258-line knowledge mode and three reference chunks (rationalizations, project-state mechanics, quote-gate) all sit behind resolvable pointers, leaving the SKILL.md to carry only the git-mode hot path. Step headers are strong pretrained anchors and every step now states its own skip/stop condition, so the process is predictable and checkable end to end. The frontmatter `reads`/`writes`/`forbids` contract (L10–L28) is precise, and the `git push --force` / `push origin main` forbids back the body's "never push to main" rule.

## Top fixes
1. L154 — collapse the inlined propose-only flaw-routing prose to a single cite of `lib/trigger-first-skill-evolution.md`; the rule is currently triplicated (here + the lib SSOT + review's matching rule), the one standing pruning defect.
2. L168 — the git-mode body is the standing conformance cost (~115 lines, past ~80); push rarely-hit detail (Step 2 brain-learnings paragraph L76, Step 11 project-state rationale already half-extracted) further behind pointers to pull the hot path toward budget.
3. L76 — the Step 2 "compound loop" explanation is reference rationale, not procedure; keep the do-this in the step and move the why behind a pointer.

## Behavioral cases
- trigger `/ship` -> expected process: git mode — read config, pre-flight (pull/test/diff/log/branch), load learnings, scope check, review gate, commit, branch, tag, push + PR, release, write learnings, project-state.
- trigger `/ship knowledge knowledge/foo.md` -> expected process: dispatch to `@./modes/knowledge.md` (Close + Extract + Backflow), vault-only, never touches external systems.
- anti-trigger `hand this unfinished build unit to Codex` -> should NOT fire (routes to `/handover`; ship closes finished work, handover delegates unfinished — disambiguated at L8).
