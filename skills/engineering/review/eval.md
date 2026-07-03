---
type: skill-eval
skill: review
bucket: engineering
evaluated_skill_hash: f2882685647b2416fc92bd1948dd659503de0219
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — review

**Verdict: SOLID.** A fixed, decorrelated review pipeline (Step 0 audit -> parallel lenses -> cold review -> cross-model Codex) now front-loaded by mandatory learning recall and closed with propose-only guard escalation for recurring/checkable bug classes; only Pruning (length + one soft step) still trails.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L69 — the once-dead recall step ("measured: 0 fires across 375 sessions") is now "mandatory and must **change the review, not just list titles**"; with the L32 "Do not skip" opener and `{main}`/`{learnings_dir}` bound at L55, every run takes the same shape and conditional passes gate on deterministic `SCOPE_*` signals, not model whim. |
| Description / invocation | pass | L4 — front-loads the "review"/"check my code"/"before creating a PR" triggers and reciprocates boundaries: NOT UI/browser (`qa`), plan critique (`boardroom`), or lightweight single-pass diff checks. |
| Completion criteria | pass | L241 — "Before exiting, print a single ASCII box" forces per-step accounting (audit ran/skipped, P0-P3 counts, COLD/CODEX catches, OPEN_QUESTIONS, CRITICAL_GAPS); abort still prints the box with unrun steps marked `skipped (user)` (L264), and Step 2 now ends on a checkable criterion (`(no relevant prior learning)` vs a per-learning bearing line). |
| Information hierarchy | pass | L62 — the recall mechanics are pushed behind the `lib/learning-recall.md` context pointer and resolved store-agnostically (gbrain filtered to `learnings/`, else ranked grep over `{learnings_dir}`), while Pass 4-8 catalogs stay cold behind `lib/conditional-passes.md` (L127, "Skip the file entirely when no scope signal fired") and rationalizations behind a pointer (L268). Steps hot, mechanics/catalogs cold. |
| Leading words | pass | L119 — strong pretrained/coined anchors carry the behaviour: "Grounding requirement (anti-hallucination)", plus "AUTO-FIX \| ASK" (L133), "COLD-CATCH", "CROSS-MODEL CONFIRMED", "needs-trace", and now "Guard escalation (propose-only)" (L225); restatements collapse into merge tags instead of re-prose. |
| Pruning | weak | L102 — "Model routing" stays soft ("the orchestrator judges which model fits", "decide by task nature at dispatch time") with no concrete anchor, the one near-no-op the prune left in; the body also runs 268 lines (~3x the ~80 guideline), so the axis is improved (recall mechanics moved to lib), not resolved. |
| Native parity | weak | L169 — nearest native feature is a single in-context review pass or platform review command; the delta is cold-context plus cross-model decorrelation, but the skill does not name that native competitor directly. |
| Granularity | pass | L167 — the Step 6 / Step 6.5 split earns its load: cold-context (same model, zero intent) and cross-model (GPT, different reasoning) are distinct decorrelation axes, and the `.5` numbering signals run-in-parallel-with-6, not a gratuitous sequence split. |
| pandastack conformance | pass | L62 — the `../../../lib/learning-recall.md` pointer resolves (worktree-root `lib/`), as do the other refs (`conditional-passes`/`rationalizations` skill-local; `gate-contract`/`learning-format`/`trigger-first-skill-evolution` repo-root `lib/`); name=folder (`review`) and hot/cold honoured via `context: fork` (L100) / `isolation: "worktree"` (L145) dispatch. |

## Why it's good
The decorrelation architecture is the asset: in-session passes, a zero-context cold reviewer, and a cross-model Codex pass each attack a different blind-spot class, and the merge tags (COLD-CATCH / CROSS-MODEL CONFIRMED / needs-trace) keep their signals separable instead of mushed. The Step 2 rewire is a real strengthening, not a defect: a step measured dead (0 fires / 375 sessions) is now a mandatory, store-agnostic recall that must change the plan or be explicitly dismissed, with confidence decay applied inline (L69). The Completion Summary box (L241), guard escalation clause (L225), and anti-hallucination grounding requirement (L119, named-and-traced exploit path plus the third `needs-trace` outcome) turn close-out from prose into checkable artifacts.

## Top fixes
1. L102 — give model-routing one concrete anchor (mechanical pattern pass -> cheaper model, architectural-reasoning pass -> reasoning model) so the line stops reading as "use judgment"; it is the softest line in the body and the only real no-op the slim missed.
2. L4 — add the missing `verify` edge to the anti-trigger list ("NOT runtime-behavior verification (use `verify`)"); `qa` already draws the review/verify/qa triangle, so review should reciprocate the third edge it omits.
3. L44/L89 — body still ~3x the 80-line guideline; the next prune candidates are the inline report-bullet prose (L44-49) and per-step log lines that the L241 completion box already accounts for.

## Behavioral cases
- trigger `review my branch before I open the PR` -> expected process: Step 0 system audit (5 cmds, no skip) -> Step 1 scope/diff (binds `{main}`/`{learnings_dir}`) -> Step 2 mandatory store-agnostic learnings recall that changes the review (or `(no relevant prior learning)`) -> Step 3 brief drift+coverage -> Step 4 detect `SCOPE_*` -> Step 5 parallel correctness/security/architecture + conditional passes -> Step 6 cold review -> Step 6.5 Codex (or mark unavailable) -> Step 7 learnings + guard proposal when recurring/checkable -> Step 7.5 flaw routing -> Step 8 completion box; stops without pushing (`git push` / `gh pr create` forbidden, L16-18).
- anti-trigger `QA this page / check the UI flow` -> should NOT fire (routes to `qa`, browser-based UI testing; review is code-diff only — stated at L4).
- anti-trigger `poke holes in this plan / red-team this approach` -> should NOT fire (routes to `boardroom`, plan critique; review needs a diff, not a plan — stated at L4).
