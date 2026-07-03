---
type: skill-eval
skill: ship
bucket: engineering
evaluated_skill_hash: 534ad29cc828ce9894a075a8a63dbca8d4a6cb00
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — ship

**Verdict: SOLID.** Strong leading-word anchors, a clean hot/cold split, Step 8 closure evidence, and a Step 10 pointer to review's guard-escalation SSOT; held back by existing line-level duplication, an un-named native-parity delta, and a git-mode body still past the ~80-line guide.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L41 — mode-dispatch table then numbered Steps 0–11 (L63–169) run the same ordered process every git-mode invocation; the new Step 8.4 (L143) is a deterministic presence/absence check, not a model-discretion fork. |
| Description / invocation | pass | L4 — front-loads "Multi-mode ship verb. Closes work", branch-per-trigger table, explicit `/handover` disambiguation (L8); unaffected by this edit. |
| Completion criteria | pass | L143 — new: "Closure evidence before claiming done: print ticket/PR URL and the state transition performed; if either is missing, say what evidence is missing and do not claim done" is checkable (evidence present or named-absent) and closes the exact premature-completion gap ("I shipped" with no PR link) the audit flagged; strictly stronger than the step it sits in. |
| Information hierarchy | pass | L181 — git mode still inline as the hot path, knowledge mode and reference detail (rationalizations, project-state, quote-gate) behind pointers; the guard-escalation change is a one-line pointer to review Step 7 (L159), not a copied rule block. |
| Leading words | pass | L107 — step headers ("Pre-flight", "Load Learnings", "Scope Check", "Review Gate", "Commit", "Branch", "Push + PR") remain pretrained anchors; "closure evidence" (L143) is itself a compact leading phrase the model can act on without further unpacking. |
| Pruning | weak | L142-143 — the closure gate restates "Return the PR URL" one line after it: item 3 already says "Return the PR URL", item 4 says "print ticket/PR URL" again before adding its real new content (the state-transition + missing-evidence branch). Separately, L161's propose-only flaw-routing prose is still triplicated against `lib/trigger-first-skill-evolution.md` and the review skill's matching rule — the prior eval's fix was never applied. |
| Native parity | weak | L143 — the delta is real (raw `gh pr create` + a human eyeballing the terminal vs. a gate that refuses to claim done without printed evidence) but the skill never names it: no line in the body says "vs. running git/gh by hand, ship adds X" the way the axis asks. Same gap as the sibling meta evals — the axis is new to this skill's scoring, not yet answered in the text. |
| Granularity | pass | L159 — guard escalation folds into existing Step 10 as a pointer to review Step 7 rather than spawning a new ship stage or duplicating the full clause. |
| pandastack conformance | weak | L181 — frontmatter valid, all pointers resolve (`@./modes/knowledge.md`, three `skills/engineering/ship/lib/*.md`, repo-root `lib/trigger-first-skill-evolution.md`); but the git-mode body still runs ~120 lines (Steps 0-11 + dispatch), past the ~<80 guideline the prior eval already flagged. |

## Why it's good
The hot/cold dispatch is still done right: the knowledge mode and three reference chunks (rationalizations, project-state mechanics, quote-gate) all sit behind resolvable pointers, so SKILL.md carries only the git-mode hot path. Step 8.4 converts "return the PR URL" from a soft instruction into a real completion criterion (evidence printed, or the gap named). Step 10's guard-escalation pointer strengthens close-out without copying review's full rule.

## Top fixes
1. L142-143 — collapse the duplication the new gate introduced: fold "Return the PR URL" into item 4 (e.g. "Print the PR URL, then closure evidence: ... print the state transition performed; if either is missing, say what's missing and do not claim done") instead of stating "print the PR URL" twice in adjacent lines.
2. L143 — name the native-parity delta explicitly since the axis now scores every skill on it: one clause noting that raw `gh pr create` leaves evidence-checking to whoever reads the terminal, and this gate is the earned override.
3. L161 — still unresolved from the prior eval: collapse the inlined propose-only flaw-routing prose to a single cite of `lib/trigger-first-skill-evolution.md`; it remains triplicated (here + the lib SSOT + review's matching rule).

## Behavioral cases
- trigger `/ship` -> expected process: git mode — read config, pre-flight (pull/test/diff/log/branch), load learnings, scope check, review gate, commit, branch, tag, push + PR (print URL, then closure evidence or named gap), release, write learnings with review Step 7 guard-escalation pointer, project-state.
- trigger `/ship knowledge knowledge/foo.md` -> expected process: dispatch to `@./modes/knowledge.md` (Close + Extract + Backflow), vault-only, never touches external systems.
- trigger `gh pr create` succeeds but the linked Linear/GitHub issue was never transitioned -> expected process: Step 8.4 fires — report the missing state transition explicitly, do not claim the ship is done.
- anti-trigger `hand this unfinished build unit to Codex` -> should NOT fire (routes to `/handover`; ship closes finished work, handover delegates unfinished — disambiguated at L8).
