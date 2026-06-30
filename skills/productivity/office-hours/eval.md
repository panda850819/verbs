---
type: skill-eval
skill: office-hours
bucket: productivity
evaluated_skill_hash: fd0d5bf01b68b66dd97b3a4f28ae901235b5a5b4
evaluated_at: 2026-06-30
rubric: writing-great-skills@1.0.0
---

# Eval — office-hours

**Verdict: SOLID.** Gate-enforced predictability — every stage closes on a printed STOP/gate so the same gated *process* runs each run, not the same output — is the leading virtue; the soft spots are the verbose Stage-2 skip-guard and an over-~80 body.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L99 — "ONE question at a time. Wait for answer." plus named stop conditions (L103) and a hard per-approach STOP (L141) lock the same process every run. |
| Description / invocation | pass | L5 — front-loads the leading word "Bring a fuzzy idea to office hours" and lists distinct branches (/office-hours, "stress test this", "draft a brief"→`--quick`); identity sits in the body, not the description. |
| Completion criteria | pass | L170 — "`acceptance:` MUST be a concrete check (a grep, a test/lint command, a file-exists assertion) … write checks, not vibes" makes every emitted task done-checkable, defeating premature completion. |
| Information hierarchy | pass | L68 — capability-probe is an explicit cold pointer ("Cold pointer, not a hot import — `--quick` runs never pay its tokens"); push-once / escape-hatch / stop-rule / bad-good are `@`-pointers and both output scaffolds live in `lib/output-templates.md` (L158, L168). |
| Leading words | pass | L32 — "30-minute structured pressure cooker" anchors the whole behaviour in one pretrained concept; reinforced by "mid-flight weapon" (L60) and one-way/two-way door (L95). |
| Pruning | weak | L85 — the Stage-2 skip-guard re-argues the four-condition print (L80-83) in prose ("self-confirming … the evidence print is the guard … do NOT skip"); the Differs-from-grill block (L57-58) also restates the mode-timing already at L50-51. |
| Granularity | pass | L162 — splitting Stage 5b (executable plan) off Stage 5 (brief) is earned by-sequence: reached only when the brief routes to /sprint or /team-orchestrate, and it guards the WHY/WHAT separation. The 5 numbered stages are a clean single-skill sequence. |
| pandastack conformance | weak | L178 — file ends at 178 lines (~98 non-blank body lines), past the ~80 discipline and not all earned (skip-guard prose L85, Differs-from-grill dup L57-58). Frontmatter valid (`type: skill`, L3), hot/cold dispatch honoured (L68), all 7 `lib/` refs + output-templates.md resolve — the only ding is length. |

## Why it's good

The gate discipline is load-bearing: adversarial drilling is one question at a time with named stop conditions (L99, L103), alternatives are gated per-approach with an explicit non-batching STOP (L141), and the run only ends on a brief whose plan tasks carry greppable `acceptance:` checks (L170). Information hierarchy is exemplary — the heavy capability probe is a cold pointer (L68) and both output scaffolds are extracted to `lib/output-templates.md`, so the body stays gates-only. The brief/plan WHY-vs-WHAT split (L166) keeps each fact in exactly one file, and the Stage numbering reads clean (Stage 1-5 + optional 5b).

## Top fixes

1. L85 — compress the Stage-2 skip-guard: the four-condition print (L80-83) already *is* the guard; the trailing "self-confirming → do NOT skip" prose says it three ways. Cut to one why-line.
2. L57-58 — the "Differs from `/grill`" block duplicates the mode-timing from Modes (L50-51); collapse to the single load-bearing line (`/grill` = mid-flight, no brief; `/office-hours` = ends with a brief), which L60 already states.
3. Path-style normalize — `lib/` refs mix styles (L68 `../../../lib/`, L72 `lib/`, L158 full `skills/productivity/office-hours/lib/`); pick one form so the cold-pointer convention reads uniformly.

## Behavioral cases

- trigger `I think I want to build a brief-router but I'm not sure` → expected process: full mode — Stage 1 capability-probe + vault scan + goal-mapping, Stage 2 one-question-at-a-time premise drill (push-once menu on rehearsed replies), Stage 3 2-3 named alternatives with per-approach Apply gate + STOP, Stage 4 premise refresh, Stage 5 brief to `docs/briefs/`, Stage 5b plan to `docs/plans/` if it routes to /sprint.
- trigger `draft a brief, context is already loaded` → expected process: `/office-hours --quick`, Stage 1 skipped with the one-line context-summary print (L66), straight to Stage 2 premise challenge.
- anti-trigger `critique this prepared plan / red-team this` → should NOT fire (routes to `/boardroom` — a prepared plan, not a fuzzy idea).
- anti-trigger `grill me on this scope for 5 min, no brief needed` → should NOT fire (routes to `/grill` — atomic mid-session pressure, confirmed/open log, no brief output per L57).
