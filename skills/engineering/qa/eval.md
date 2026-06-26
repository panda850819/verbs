---
type: skill-eval
skill: qa
bucket: engineering
evaluated_skill_hash: d8a50cfdab93681e1ca04561a759f54d67e1d5aa
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — qa

**Verdict: SOLID.** A deterministic 5-step browser-QA pipeline with a clean model/user trigger split and a now-checkable close criterion; loses points only where Step 4's mechanical-bug example list duplicates the extracted bug-template routing.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L18 — same 3-round plan (Functional -> Adversarial -> Coverage) then Merge runs every time; `{learnings_dir}` is now bound once at L14 ("resolve... default `docs/learnings`") and reused at L98, so both intake and close are reproducible per project. |
| Description / invocation | pass | L4 — front-loads "Browser-based QA"; model signal ("UI has changed") split from user phrasings ("test this", "QA", "check the page"); two anti-triggers route to `verify` / `review`; no body-identity restatement left. |
| Completion criteria | pass | L98 — repaired Step 5 terminates only when a `type: pitfall` learning is written OR an explicit "no learning warranted" is recorded ("done only once one of the two is recorded"); Step 3 closes on the summary line (L86) plus STEP_PASS/FAIL/SKIP markers. |
| Information hierarchy | pass | L79 — bug `[BUG]` template + screenshot path extracted to `skills/engineering/qa/lib/test-output-format.md`; the verification rigor ladder (L72-75) stays inline because it fires every run; progressive disclosure honored. |
| Leading words | pass | L26 — pretrained anchors carry each branch (Functional / Adversarial / Coverage; Deterministic / Snapshot / Screenshot); no restatement sediment. |
| Pruning | weak | L91 — the AUTO-FIX mechanical-bug example list ("CSS, missing null check, wrong URL") is duplicated verbatim inside `lib/test-output-format.md`'s `Action` routing line; the same enumeration lives in two places, so neither is the single source. |
| Granularity | pass | L40 — Step 3's sub-sections (Parallel Execution, Assertion Protocol, Verification, Failure Output, Summary) are distinct mechanics, each earning its load; 5 steps map to a real pipeline with no over-split. |
| pandastack conformance | pass | L79 — `name: qa` = folder; repo-root `lib/learning-format.md` is intentionally distinct from the explicit skill-local `skills/engineering/qa/lib/test-output-format.md`; all refs resolve, and the 102-line body is earned by browser-QA orchestration plus extracted failure-output detail. |

## Why it's good
The trigger is textbook: leading phrase first, a model-detectable signal ("UI has changed") separated from the literal user phrasings, and two anti-triggers that name the skills they hand off to. The 3-round test-planning protocol (Functional, then an adversarial re-read, then coverage gaps for big changes) makes the *process* identical every run rather than depending on whatever the agent happens to think of, and the assertion-marker + verification-rigor ladder turns "I tested it" into structured, gradeable evidence. The Step 5 repair closed the prior premature-completion bait, and binding `{learnings_dir}` fixed the prior intake/close unpredictability.

## Top fixes
1. L91 — drop the inline "CSS, missing null check, wrong URL" example list from Step 4 and let `lib/test-output-format.md` (which already carries the identical `Action: AUTO-FIX | ASK` enumeration) be the single source; Step 4 then just says "route per the `Action` field."
2. L51 — the step budgets ("~25 / ~40 / ~75") are the only soft, non-checkable knob in an otherwise crisp Step 3; tie them to the test-group size class or mark them advisory so they read as guidance, not a completion criterion.

## Behavioral cases
- trigger `the checkout page changed, QA it` -> expected process: Step 1 load config + UI pitfalls + brief, Step 2 run the 3-round plan and merge a numbered list, Step 3 assert with STEP_PASS/FAIL/SKIP plus the verification ladder (parallel sub-agents if 3+ groups), Step 4 AUTO-FIX mechanical bugs / ASK on design, Step 5 record a `type: pitfall` learning or "no learning warranted".
- anti-trigger `verify this PR's fix actually works` -> should NOT fire (routes to `verify` per L6 — non-UI verification); `review my diff before I push` -> should NOT fire (routes to `review` — code-diff review, not a live browser flow).
