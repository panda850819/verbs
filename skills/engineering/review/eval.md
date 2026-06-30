---
type: skill-eval
skill: review
bucket: engineering
evaluated_skill_hash: 7c9b95dd5db56d34d055472bc9f00f1f70310138
evaluated_at: 2026-06-30
rubric: writing-great-skills@1.0.0
---

# Eval — review

**Verdict: SOLID.** A fixed, decorrelated review pipeline (Step 0 audit → parallel lenses → cold review → cross-model Codex) where every gate is forced into a checkable completion box; the #106 slim inlined the single-consumer confidence rule and demoted the rationalizations prose, so only Pruning (length + one soft step) still trails.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L27 — "Run these 5 commands. **Do not skip.**" pins the opener; Steps 0→8 run the same shape every time and `{main}`/`{learnings_dir}` are bound explicitly at L50, so no placeholder drifts and conditional passes gate on deterministic `SCOPE_*` signals, not model whim. |
| Description / invocation | pass | L4 — front-loads the "review" trigger and reciprocates boundaries: "NOT UI/browser (qa), plan critique (boardroom), or correctness-bug hunting (code-review)." The #106 edit closed the bare-one-liner gap; only the `verify` (runtime-behavior) edge is still unstated. |
| Completion criteria | pass | L240 — "Before exiting, print a single ASCII box" forces a per-step accounting (audit ran/skipped, P0–P3 counts, COLD/CODEX catches, OPEN_QUESTIONS, CRITICAL_GAPS); abort still prints the box with unrun steps marked `skipped (user)` (L263). Each "skip silently" is gated on a checkable condition. |
| Information hierarchy | pass | L128 — Pass 4–8 checklists sit cold behind `lib/conditional-passes.md` ("Skip the file entirely when no scope signal fired"); the confidence-decay rule is now one inline line at its step (L70, the single-consumer `lib/confidence.md` correctly deleted), while rationalizations (L267), gate-contract, learning-format, and flaw-routing stay behind pointers. Steps hot, catalogs cold. |
| Leading words | pass | L120 — strong pretrained/coined anchors carry the behaviour: "Grounding requirement (anti-hallucination)", "AUTO-FIX \| ASK", "COLD-CATCH", "CROSS-MODEL CONFIRMED", "needs-trace"; restatements collapse into merge tags rather than re-prose. |
| Pruning | weak | L103 — "Model routing" stays soft ("the orchestrator judges which model fits", "decide by task nature at dispatch time") with no concrete anchor, the one near-no-op the prune left in. Confidence inlining (L70) and the rationalizations demotion are real wins, but the body still runs 267 lines (~3× the ~80 guideline), so the axis is improved, not resolved. |
| Granularity | pass | L168 — the Step 6 / Step 6.5 split earns its load: cold-context (same model, zero intent) and cross-model (GPT, different reasoning) are distinct decorrelation axes, and the `.5` numbering signals run-in-parallel-with-6, not a gratuitous sequence split. |
| pandastack conformance | pass | L70 — the deleted `lib/confidence.md` left no dangling ref (rule now inline); the remaining five `lib/` pointers all resolve (`conditional-passes`/`rationalizations` skill-local, `gate-contract`/`learning-format`/`trigger-first-skill-evolution` repo-root), name=folder (`review`), and hot/cold honoured via `context: fork` (L101) / `isolation: "worktree"` (L146) dispatch. |

## Why it's good
The decorrelation architecture is the asset: in-session passes, a zero-context cold reviewer, and a cross-model Codex pass each attack a different blind-spot class, and the merge tags (COLD-CATCH / CROSS-MODEL CONFIRMED / needs-trace) keep their signals separable instead of mushed. The anti-hallucination grounding requirement (L120) is unusually disciplined: it demands a named, traced exploit path and adds the third `needs-trace` outcome so a real-but-untraced vuln is never silently dropped. The Completion Summary box (L240) turns "did I finish?" from vibe into a checkable artifact, abort included.

## Top fixes
1. L103 — give model-routing one concrete anchor (mechanical pattern pass → cheaper model, architectural-reasoning pass → reasoning model) so the line stops reading as "use judgment"; this is the softest line in the body and the only real no-op the slim missed.
2. L4 — add the missing `verify` edge to the anti-trigger list ("NOT runtime-behavior verification (use `verify`)"); `qa` already draws the review/verify/qa triangle, so review should reciprocate the third edge it omits.
3. L267 — `lib/rationalizations.md` still carries rows that merely restate inline gates (row 1 vs L27 "Do not skip", the Codex row vs L189); trim those to keep only rationalizations with no inline enforcement, so the lib file stops re-arguing the body.

## Behavioral cases
- trigger `review my branch before I open the PR` → expected process: Step 0 system audit (5 cmds, no skip) → Step 1 scope/diff (binds `{main}`/`{learnings_dir}`) → Step 2 learnings + confidence decay → Step 3 brief drift+coverage → Step 4 detect `SCOPE_*` → Step 5 parallel correctness/security/architecture + conditional passes → Step 6 cold review → Step 6.5 Codex (or mark unavailable) → Step 7/7.5 learnings + flaw routing → Step 8 completion box; stops without pushing (`git push` / `gh pr create` forbidden, L17–18).
- anti-trigger `QA this page / check the UI flow` → should NOT fire (routes to `qa`, browser-based UI testing; review is code-diff only — stated at L4).
- anti-trigger `poke holes in this plan / red-team this approach` → should NOT fire (routes to `boardroom`, plan critique; review needs a diff, not a plan — stated at L4).
