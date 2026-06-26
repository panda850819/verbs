---
type: skill-eval
skill: retro-month
bucket: productivity
evaluated_skill_hash: d58a1009f8dc2fa9f162a2e7854ffd3777bdd74c
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — retro-month

**Verdict: SOLID.** Leading virtue is a hard-anchored interview process (one-question-at-a-time, verbatim capture, no-invent rule) that makes the strategic conversation reproducible. The earlier engine-section mismatch and scan-only completion hole are repaired; remaining cost is a 126-line body and some residual monthly-specific memory-update complexity.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L61 — "Walk through layers ONE QUESTION AT A TIME" plus the fixed 3-phase spine (L14-16) pins the same process every run regardless of output. |
| Description / invocation | pass | L3 — front-loads "Interactive monthly retro", user-invocable, one trigger per branch ("/retro-month", "monthly retro", "monthly review"), no body-identity restated. |
| Completion criteria | pass | L57 — either branch must wait for the user's interview start, and L61 makes 2b-i goal-alignment the completion floor for every branch including scan-only and short mode. |
| Information hierarchy | pass | L31 — engine block details and weekly-retro reference commands are pushed behind `skills/productivity/retro-month/lib/scan-blocks.md`; the Phase-3 template is behind `skills/productivity/retro-month/lib/retro-template.md` (L107). |
| Leading words | pass | L70 "Drift candidates" / L89 "commodity check" / L123 "append + supersede" anchor behaviour in compact reusable concepts. |
| Pruning | pass | L47 — Phase 2 now prints the engine's real sections instead of re-describing obsolete scan subsections; the output template and scan-block details are cold pointers. |
| Granularity | pass | L61 — the 2b-i-through-2b-v split is justified by anti-premature-completion (short-version still forces goal-alignment), each layer earns its load. |
| pandastack conformance | weak | L107 — all internal refs resolve and the engine-section mismatch is gone; weak only because the body is 126 lines, above the ~80 guideline, with project-memory and feedback-log update branches still hot. |

## Why it's good
The interview engine is the load-bearing strength: one-question-at-a-time (L61), verbatim capture including "想不到/沒有" (L93), and a hard never-invent rule (L124) make a genuinely stochastic strategic conversation reproducible. The runtime-agnostic scan engine (L18-23) guarantees Claude/Codex/Hermes produce the same brief, and the append+supersede memory discipline (L123) protects project memory from lossy rewrites.

## Top fixes
1. L83-87 — `feedback-log.md` is still named directly; align it with the newer weekly retro pattern of deriving from active feedback files, or document where the file lives.
2. L76-80 — project memory edits are powerful side effects; add a brief "draft-and-confirm before edit" gate if this skill is run outside a fully interactive monthly retro.
3. L107-115 — push the mechanical update checklist behind `skills/productivity/retro-month/lib/retro-template.md` or a sibling reference if trimming toward ~80 lines becomes a priority.

## Behavioral cases
- trigger `/retro-month` -> expected process: run retro-scan.sh month, print compressed scan block, ask "掃完了。要開始月度 interview 嗎？", then one-question-at-a-time interview, then write brain/reflections/monthly/$YEAR-$MONTH.md.
- trigger `monthly review` -> expected process: same 3-phase flow; if a Hermes cron already wrote the prep, locate it via ls -t inbox/retros and read instead of re-scanning.
- anti-trigger `weekly retro` -> should NOT fire (routes to retro-week; 30-day vs 7-day window and monthly output dir differ).
- anti-trigger `stress test this idea` -> should NOT fire (routes to grill/office-hours; that is fuzzy-idea intake, not a periodic retro).
