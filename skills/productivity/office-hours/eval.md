---
type: skill-eval
skill: office-hours
bucket: productivity
evaluated_skill_hash: d05e045c64b07989dbc7c17d23a5536fe82dde17
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — office-hours

**Verdict: WEAK.** Leading virtue is gate-enforced predictability: every stage ends on a printed STOP/gate so the same gated process runs each time. It remains WEAK because the body is still 179 lines, the Stage-2 skip guard is verbose, and the description trigger list still packs several near-synonyms into one branch.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L100 — "ONE question at a time. Wait for answer." plus named stop conditions (L104) and STOP-and-wait gates (L142) lock the same process every run, not the same output. |
| Description / invocation | weak | L5 — leading phrase "Bring a fuzzy idea" front-loads well, but the trigger list packs near-synonyms ("I have an idea" / "let me think out loud" / "office hours" / "structured intake") that rename one branch; one-trigger-per-branch is violated |
| Completion criteria | pass | L171 — `acceptance:` MUST be a concrete grep/test/file-exists check, "write checks, not vibes" — every emitted task is done-checkable, defeating premature-completion bait. |
| Information hierarchy | pass | L69 — capability-probe is a cold pointer read only when Stage 1 runs; the brief and plan scaffolds are extracted to `skills/productivity/office-hours/lib/output-templates.md` (L159, L169); reusable rules live behind `@`-pointers. |
| Leading words | pass | L32 — "30-minute structured pressure cooker" anchors the whole behaviour in one pretrained concept; reinforced by "mid-flight weapon" (L61) and one-way/two-way door (L89) |
| Pruning | weak | L79 — the Stage 2 skip-guard is one ~180-word paragraph that re-argues "don't skip a fuzzy scope" three ways ("self-confirming", "evidence print is what exposes", "do NOT skip") and ends with a redundant Chinese gloss; tighten to the four-condition gate + one why-line |
| Granularity | pass | L163 — splitting Stage 5b (executable plan) off Stage 5 (brief) is earned: it is reached only when the brief routes to /sprint or /team-orchestrate, an independent-reach branch that also defends WHY/WHAT separation. |
| pandastack conformance | weak | L69/L101/L102/L106/L110 — frontmatter valid and all lib refs resolve; the heaviest output templates are now extracted, but the 179-line body is still over the ~80 discipline and the Stage-2 skip guard remains verbose. |

## Why it's good

The gate discipline is the load-bearing strength: adversarial drilling is gated to one question at a time with named stop conditions (L100, L104), alternatives are gated per-approach with an explicit non-batching STOP (L134-142), and the run only ends on a brief whose executable plan tasks carry greppable acceptance checks (L171). The Stage 2 skip-guard (L79-86) is a strong defence against the self-confirming "no unknowns" judgment. The brief/plan WHY-vs-WHAT separation (L167) keeps each fact in exactly one file.

## Top fixes

1. L77-88 — compress the Stage 2 skip-guard to the four-condition checklist + a single why-line; it still re-argues "do not skip a fuzzy scope" after the checklist.
2. L5 — collapse the trigger list to one phrase per branch ("office hours" / "stress test this" / "draft a brief"); drop "I have an idea" and "let me think out loud" as synonyms that inflate context load every turn.
3. L173-179 — anti-patterns are compact, but moving mode-comparison detail into the `/grill` section could pull the body closer to ~80 without losing gates.

## Behavioral cases

- trigger `I think I want to build a brief-router but I'm not sure` -> expected process: Stage 1 capability-probe + vault scan + goal-mapping, Stage 2 one-question-at-a-time premise drill (push-once menu on rehearsed replies), Stage 3 2-3 named alternatives with per-approach Apply gate, Stage 4 premise refresh, Stage 5 brief to `docs/briefs/`, Stage 5b plan to `docs/plans/` if it routes to /sprint.
- trigger `draft a brief, context is already loaded` -> expected process: `/office-hours --quick`, Stage 1 skipped with the one-line context-summary print (L67), straight to Stage 2.
- anti-trigger `grill me on this scope for 5 min, no brief needed` -> should NOT fire (routes to `/grill` — atomic mid-session pressure, confirmed/open log, no brief output per L58).
- anti-trigger `I already wrote the brief, critique the plan` -> should NOT fire (routes to `/boardroom` per L47).
