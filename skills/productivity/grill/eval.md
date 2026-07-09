---
type: skill-eval
skill: grill
bucket: productivity
evaluated_skill_hash: acc138c5ea0777721e989c9ffe54c394a152a6f7
evaluated_at: 2026-07-09
rubric: writing-great-skills@1.1.0
---

# Eval — grill

> 2026-07-09 re-validation (#170): grill absorbed the retired `office-hours` as a new `--brief` mode (Stage A alternatives / B premise / C brief to docs/briefs/ / C+ plan to docs/plans/). Re-anchored every citation to the current SKILL.md and replaced all office-hours routing references with grill's own `--brief` close. Verdict unchanged.

**Verdict: SOLID.** Tight, process-stable adversarial-drill tool with a clean model/user invocation split and a hard-capped stopping rule; loses points on a restated identity line (leading words / pruning) and an unnamed native baseline (native parity).

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L52 — "ONE question at a time. Wait for the answer. Then pick the next question based on what the answer revealed" pins one invariant process every run; the recommended goal-map pre-step (L34) is a soft branch and `--brief` (L122) is an opt-in mode, but the drill core is firm across both. |
| Description / invocation | pass | L4 — front-loads "Adversarial requirement discovery"; carries explicit user trigger phrases (L7-8), a skip condition (L43), and now the structured-brief path as grill's own `--brief` mode rather than a pointer to a separate skill. Model-vs-user split is right; one-trigger-per-branch is clean. |
| Completion criteria | pass | L78 — stopping rule is checkable and exhaustive (3 consecutive no-new-unknowns OR 7+ questions OR escape hatch), with exact log lines (L91) on the hard cap defending against premature continuation. |
| Information hierarchy | pass | L56 — push-once is correctly deferred to lib/push-once.md (body keeps the trigger, lib holds the 5-pattern menu); progressive disclosure holds and the `--brief` stages likewise defer scaffolds to lib/output-templates.md (L130, L132). |
| Leading words | weak | L28 — "Adversarial requirement discovery" is restated verbatim from the description (L4) at the body opener (L28) and the purpose is re-framed again at L30; the restatements should collapse to one canonical statement. |
| Pruning | weak | L28 — "Adversarial requirement discovery" is repeated from the description and then re-framed at L30; the relationship notes are clean, but this identity echo still costs hot body space. |
| Native parity | weak | L30 — nearest native feature is a generic checklist or direct implementation after a fuzzy prompt; the delta is one-angle-at-a-time unknown-unknown discovery, but the skill does not name that native baseline directly. |
| Granularity | pass | L11 — the two lib splits (goal-mapping L11, push-once L12) each earn their load: push-once is genuinely reached by grill's own `--brief` close and by `/sprint`, so the cut buys cross-skill reach, not just length. |
| pandastack conformance | pass | L2 — name=grill matches folder; frontmatter valid; all five repo lib pointers (goal-mapping, push-once, stop-rule, output-templates, skill-decision-tree) resolve at repo root; 149 lines is earned reference (axis list, output template, `--brief` stages, anti-patterns co-located with the tool body while shared mechanics live behind resolving lib/ pointers). |

## Why it's good
The skill commits to a single interrogation process — one question, push once via a named menu, drill 8 anchored axes framed as a search space rather than a checklist — so every run looks the same and stays adversarial instead of degrading into a questionnaire. The model/user boundary is handled correctly: the description carries user trigger phrases, a skip condition, and now the structured-brief output as grill's own `--brief` mode (Stage A/B/C/C+ at L126-132), so invocation routing is unambiguous and no longer hands off to a sibling skill. The remaining reference (axis list, output template, `--brief` stages, anti-patterns) is appropriately co-located with the tool body while the shared mechanics live behind resolving lib/ pointers.

## Top fixes
1. L28/L30 — collapse the "Adversarial requirement discovery" identity statement to one place; the description (L4) already owns it, so the body opener is a restatement that adds no process.
2. L34 — if this pre-step keeps paying for itself, split the L1/L2/L3 identification instructions out of the brief-oriented `goal-mapping.md` so grill can point at a smaller, purpose-fit reference.

## Behavioral cases
- trigger `grill me on the points-system scope` -> expected process: optional goal-map pre-step (L34), then ONE question at a time (L52), push-once via the lib menu on a rehearsed reply (L56), drill the 8 axes as a search space (L60), stop per the stopping rule (L78), emit a confirmed/open grill log to Inbox/grill-*.md (L119).
- trigger `draft me a brief on X` / `grill --brief on the migration` -> expected process: same drilling, then the `--brief` structured close (L122) runs Stage A forced alternatives (L126), Stage B premise refresh (L128), Stage C brief to docs/briefs/ (L130), and Stage C+ executable plan to docs/plans/ only when the next step is execution (L132).
- anti-trigger `fix this typo in the README` -> should NOT fire; scope is already concrete, so grill skips per L45 (bug fix or typo) and the work just proceeds.
