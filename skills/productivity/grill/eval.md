---
type: skill-eval
skill: grill
bucket: productivity
evaluated_skill_hash: 67249cbbdc6d7f54b2d3f7775d30173064244288
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — grill

**Verdict: SOLID.** A tight, predictable adversarial-interrogation loop: one-question-at-a-time discipline plus a checkable, exhaustive stopping rule make the process repeatable across runs; it loses points to a thrice-stated office-hours boundary and a changelog tail that pushes the body past budget.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L48 — `**ONE question at a time.** Wait for the answer.` fixes the core process so every run drives the same loop, not a stochastic Q-dump. |
| Description / invocation | pass | L4 — front-loads the leading phrase "Adversarial requirement discovery" and the description ends with an explicit anti-trigger handing structured output to `/office-hours`. |
| Completion criteria | pass | L86 — stopping rule is checkable AND exhaustive: `3 consecutive answers reveal no new unknowns` / `7+ questions` / escape hatch. No premature-completion bait. |
| Information hierarchy | pass | L52 — the 5-pattern pushback menu is a context pointer to `lib/push-once.md`, not inlined; goal-mapping (L30) is pushed to lib the same way. Progressive disclosure honoured. |
| Leading words | pass | L26 — "surface **unknown unknowns** by interrogating one angle at a time"; reinforced by "Expect rehearsed first answers" (L50). Strong pretrained anchors, not "be thorough" no-ops. |
| Pruning | weak | L147 — the Origin changelog re-narrates the `--mode structured` add-then-remove saga; sediment that no longer changes behaviour. Compounded by the office-hours boundary stated 3x (L8-9, L35, L139). |
| Granularity | pass | L141 — the grill/office-hours/boardroom split is principled (atomic adversarial upstream vs structured brief vs full-plan review); each half has independent reach, so the cut earns its load. |
| pandastack conformance | weak | L143 — frontmatter is valid (name=folder, advisory `reads/writes` resolve), but `## Origin` plus the triple-stated boundary push the body to ~147 lines, well past the ~<80 guidance, and the over-length is sediment, not earned. |

## Why it's good
The process is genuinely deterministic where it matters: ONE question at a time (L48), push-once-minimum-per-axis (L50), a menu-driven pushback that forbids improvised pushes to keep an audit trail (L65), and a stopping rule that is both checkable and exhaustive (L85-88). The escape hatch is wired to the global "enough" protocol with a hard cap and a written unprocessed-axes line (L97-101), so the skill cannot run away from the user. The anti-pattern list (L131-135) and the drill axes as a "search space, not a checklist" (L67) keep it from degrading into the questionnaire it explicitly is not.

## Top fixes
1. L147 — delete the `--mode structured` add/remove changelog from Origin; it is pure sediment and the deprecation is already stated at L139. Keep only the one-line Matt-Pocock attribution.
2. L8-9 / L35 / L139 — collapse the office-hours routing from three statements to one. Keep it in the description (HOT, does invocation work) and the "Relationship to other skills" line; cut the restatement inside "When to use".
3. L143 — trimming fixes 1 and 2 brings the body back toward the ~80-line budget, resolving the conformance ding without losing any load-bearing step.

## Behavioral cases
- trigger `grill me on the points system scope` → expected process: (optional) run goal-mapping (L30), then interrogate ONE axis at a time across Existence/Boundaries/Retroactivity/etc. (L69-76), pushing once per axis via the push-once menu (L52), stopping by the L85 rule, emitting the Grill-log template (L107) to `Inbox/grill-<slug>-<date>.md`.
- anti-trigger `turn these grilled unknowns into a written brief` → should NOT fire; grill produces a confirmed/open log only. Routes to `/office-hours --quick` (L120, L139) for structured-brief output.
