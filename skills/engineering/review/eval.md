---
type: skill-eval
skill: review
bucket: engineering
evaluated_skill_hash: 3b37f4fccb9589cb4f64a0e8aa707cd3f607cf94
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — review

**Verdict: SOLID.** Strongest virtue is a fixed, decorrelated review pipeline (Step 0 audit -> parallel lenses -> cold review -> cross-model Codex) with every gate forced into a verifiable completion box; loses points on a bare description with no anti-trigger and a "Rationalizations" table that re-argues gates already enforced inline.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L27 — "Run these 5 commands. **Do not skip.**" fixes the opener; Step 0->8 runs the same shape every run, and `{main}`/`{learnings_dir}` are now bound explicitly at Step 1 (L50: "Bind the path variables used below from it"), so no dangling placeholder drifts per project. Conditional passes gate on detected `SCOPE_*` (deterministic), not model whim. |
| Description / invocation | weak | L4 — "Use when asked to 'review', 'check my code', or before creating a PR." Front-loads the leading word but is a bare one-liner: no anti-trigger, no model-vs-user split, and does not reciprocate the boundary `qa` draws against it ("NOT for code-diff review (use review)"), despite live collision with qa / verify / `/code-review`. |
| Completion criteria | pass | L238 — Step 8 ASCII box forces a per-step accounting (audit ran/skipped, P0-P3 counts, COLD/CODEX catches, OPEN_QUESTIONS, CRITICAL_GAPS); even on abort "still print the box. Mark unrun steps as `skipped (user)`." Every "skip silently" is gated on a checkable condition (no brief / no mapping / nothing to record). |
| Information hierarchy | pass | L128 — the Pass 4-8 conditional checklists are now extracted to `lib/conditional-passes.md` ("run the matching pass from `lib/conditional-passes.md`. Skip the file entirely when no scope signal fired"), so reference reached only on a fired signal sits cold behind a pointer; steps stay hot, checks co-located. |
| Leading words | pass | L120 — strong pretrained anchors throughout: "Grounding requirement (anti-hallucination)", "AUTO-FIX | ASK", "COLD-CATCH", "CROSS-MODEL CONFIRMED", "needs-trace"; restatements collapsed into merge tags, not re-prose. |
| Pruning | weak | L265 — "Common Rationalizations" table (7 rows) re-argues content already enforced by inline gates: "Step 0 audit takes too long, skip it" duplicates L27's "Do not skip"; "Codex unavailable, just skip" duplicates L177/L272's mark-unavailable contract. Motivational sediment, not a single source of truth. |
| Granularity | pass | L168 — the Step 6 / Step 6.5 split earns its load: cold-context (same model, no intent) and cross-model (GPT, different reasoning) are distinct decorrelation axes; the `.5` numbering signals run-in-parallel-with-6, not a gratuitous sequence split. |
| pandastack conformance | pass | L101 — name=folder (`review`); all 5 `lib/` refs resolve (`conditional-passes.md` skill-local; `confidence`/`gate-contract`/`learning-format`/`trigger-first-skill-evolution` to repo-root `lib/`, the convention peers eng-lead/qa use); hot/cold honoured via `context: fork` / `isolation: "worktree"` subagent dispatch. Body 275 lines is heavy but is a flow-class orchestrator with reference correctly extracted, so length is earned not bloat. |

## Why it's good
The decorrelation architecture is the real asset: in-session passes, a zero-context cold reviewer, and a cross-model Codex pass each attack a different blind-spot class, and the merge rules (COLD-CATCH / CROSS-MODEL CONFIRMED / needs-trace) keep their signals separable instead of mushed. The anti-hallucination grounding requirement (L120) is unusually disciplined — it demands a named, traced exploit path and adds the third `needs-trace` outcome so a real-but-untraced vuln is never silently dropped. The Completion Summary box turns "did I finish?" from vibe into a checkable artifact, abort included.

## Top fixes
1. L4 — add anti-triggers and a model/user line to the description: "NOT for UI/browser QA (use `qa`), runtime behavior verification (use `verify`), or the live working diff in Claude (use `/code-review`)." Mirror the boundary qa already draws back at review.
2. L265 — cut or fold the Rationalizations table. Each row mapping to an existing gate (Step 0 skip, Codex skip, cold-review skip) is redundant with the inline "Do not skip" / mark-unavailable enforcement; keep at most the 2-3 rows with no inline gate behind them.
3. L103 — "Model routing" defers model choice to per-dispatch judgment with no examples; one concrete anchor (mechanical pass -> cheaper model, architecture pass -> reasoning model) would make the routing's predictability visible without reintroducing a fixed table.

## Behavioral cases
- trigger `review my branch before I open the PR` -> expected process: Step 0 system audit (5 cmds, no skip) -> Step 1 scope/diff (binds {main}/{learnings_dir}) -> Step 2 load learnings w/ confidence decay -> Step 3 brief drift+coverage -> Step 4 detect SCOPE_* -> Step 5 parallel correctness/security/architecture + conditional passes -> Step 6 cold review -> Step 6.5 Codex (or mark unavailable) -> Step 7/7.5 learnings + flaw routing -> Step 8 completion box; stops without pushing (forbids git push / gh pr create).
- anti-trigger `QA this page / check the UI flow` -> should NOT fire (routes to `qa`, browser-based UI testing; review is code-diff only).
- anti-trigger `ship this / create the PR and push` -> should NOT fire as review (routes to `ship`; `git push` / `gh pr create` forbidden here, L17-18).
