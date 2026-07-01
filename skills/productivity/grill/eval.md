---
type: skill-eval
skill: grill
bucket: productivity
evaluated_skill_hash: e607c87e4fc5889cd99ea5b60caaeccd9c107861
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — grill

**Verdict: SOLID.** Tight, process-stable adversarial-drill tool with a clean model/user invocation split and a hard-capped stopping rule; loses points on a triple-restated identity line (leading words) and version-archaeology sediment in the relationship section (pruning).

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L47 — "ONE question at a time. Wait for the answer. Then pick the next question based on what the answer revealed" pins one invariant process every run; the recommended goal-map pre-step (L29) is a soft branch but the drill core is firm. |
| Description / invocation | pass | L4 — front-loads "Adversarial requirement discovery"; carries explicit user trigger phrases, a skip condition, and a disambiguation pointer to /office-hours. Model-vs-user split is right; one-trigger-per-branch is clean. |
| Completion criteria | pass | L71 — stopping rule is checkable and exhaustive (3 consecutive no-new-unknowns OR 7+ questions OR escape hatch), with exact log lines (L84) on the hard cap defending against premature continuation. |
| Information hierarchy | pass | L51 — push-once is correctly deferred to lib/push-once.md (body keeps the trigger, lib holds the 5-pattern menu); the menu re-inlining from the prior version is gone, so progressive disclosure now holds. |
| Leading words | weak | L23 — "Adversarial requirement discovery" is restated verbatim from the description (L4) at the body opener (L23) and echoed again at L25; the restatements should collapse to one canonical statement. |
| Pruning | weak | L128 — "(replaces v2.1 /work-ship reference)" and L127 "Replaces the deprecated grill --mode structured" are migration archaeology that change no run behaviour and belong in a changelog, not the load-bearing body. |
| Granularity | pass | L11 — the two lib splits (goal-mapping, push-once) each earn their load: push-once is genuinely reached by office-hours too, so the cut buys cross-skill reach, not just length. |
| pandastack conformance | pass | L2 — name=grill matches folder; frontmatter valid; both lib/ pointers (and the transitively-referenced lib/gate-contract.md) resolve at repo root; lib reads ~2.1K tokens stay under the 5K hot/cold dispatch line, so inline loading is correct and 127 lines is earned reference. |

## Why it's good
The skill commits to a single interrogation process — one question, push once via a named menu, drill 8 anchored axes framed as a search space rather than a checklist — so every run looks the same and stays adversarial instead of degrading into a questionnaire. The model/user boundary is handled correctly: the description carries user trigger phrases, a skip condition, and a pointer to the structured-brief sibling, so invocation routing is unambiguous. The repair landed: the previously re-inlined pushback menu and the dead `reads:` glob and the Origin changelog block are all gone, and the remaining reference (axis list, output template, anti-patterns) is appropriately co-located with the tool body while the shared mechanics live behind resolving lib/ pointers.

## Top fixes
1. L23/L25 — collapse the "Adversarial requirement discovery" identity statement to one place; the description (L4) already owns it, so the body opener is a restatement that adds no process.
2. L127-128 — strip the "replaces v2.1 /work-ship" and "replaces deprecated grill --mode structured" parentheticals; move migration notes to a changelog so the relationship section states only the current routing.
3. L29 — the recommended goal-mapping pre-step points at a lib written in office-hours shape (it references "Alternatives (Step 4)", the brief's Gate Log, and the four-option gate via lib/gate-contract.md); note or scope the fit so grill's atomic no-brief contract is not silently asked to produce brief-stage artifacts.

## Behavioral cases
- trigger `grill me on the points-system scope` -> expected process: optional goal-map pre-step (L29), then ONE question at a time (L47), push-once via the lib menu on a rehearsed reply (L51), drill the 8 axes as a search space (L53), stop per the stopping rule (L71), emit a confirmed/open grill log to Inbox/grill-*.md (L112).
- anti-trigger `draft me a brief / structured intake on X` -> should NOT fire; routes to /office-hours (default full or --quick) per L8 and L127.
