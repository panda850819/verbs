---
type: skill-eval
skill: retro-week
bucket: productivity
evaluated_skill_hash: 5e59891e3b7be47ef9f768b387a73c972dcec371
evaluated_at: 2026-06-30
rubric: writing-great-skills@1.0.0
---

# Eval — retro-week

**Verdict: SOLID.** One deterministic shared engine drives identical cross-runtime prep, and every phase ends on a hard wait gate.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L20 — "All Phase 1 / 1.5 / 1.6 raw-data gathering is done by the shared, runtime-agnostic engine so Claude / Codex / Hermes all produce the same brief" — same process every run, across runtimes. |
| Description / invocation | weak | L3 — "writes the final retro to brain/reflections/weekly/" names a single fixed destination, but the de-personalized body (L273) falls back to `docs/retros/weekly/` on a brain-less install; the description overstates the path. |
| Completion criteria | pass | L153 — "A mechanism proposal … may ONLY be emitted to the table when `count >= 2`" is checkable and exhaustive; each phase boundary also ends on a concrete wait-for-user gate (L61, L102, L183, L216). |
| Information hierarchy | pass | L150 — the keyword→mechanism classification catalog is pushed behind a context pointer to `lib/gc-inputs.md` (the #106 move); SKILL.md keeps the classify steps + recurrence gate hot, the lookup table loads cold. |
| Leading words | pass | L113 — borrows Lopopolo's "categorically eliminate" / forcing-function anchor to compact the convert-slop-to-mechanism sub-protocol; "hotspot"/"salience proxy" (L78) anchor compactly too. |
| Pruning | weak | L188 — the 1j "what NOT to do" block restates the recurrence gate already canonical at L153 (and the proposes-only rule at L115); a recap that fails the no-op test, curable with a cross-reference. |
| Granularity | pass | L7 — `related_skills: [retro-month, ship]` shows the by-sequence split (week vs month) drawn cleanly; Phase 1.5 / 1.6 are gated sub-processes with their own skip conditions, no independent trigger warranting their own skill. |
| pandastack conformance | weak | L42 — frontmatter valid, all three `lib/` refs resolve, and the `${PANDASTACK_BRAIN}` / `$CLAUDE_PLUGIN_ROOT` indirection + write guards are correct robustness; the one residual miss is length: the Phase-1 raw-scan format is still inlined (L44-59) while its Phase-1.5/1.6/3 siblings live in `lib/output-formats.md`, leaving the body ~293 lines over the ~<80 bar. |

## Why it's good
The spine is a single shared engine (`retro-scan.sh`, resolved via `$CLAUDE_PLUGIN_ROOT` with a checkout fallback at L25) so Claude, Codex, and Hermes generate the same prep brief, and every phase transition is a hard "wait for user" gate that keeps the run deterministic without freezing the conversation. The de-personalization is a real conformance win: `${PANDASTACK_BRAIN}` plus the brain-present write guard (L273) make a brain-less install degrade to a local `docs/retros/weekly/` fallback instead of fabricating the author's tree. The GC sweep's `count >= 2` recurrence gate (L153) is a genuinely checkable criterion that stops one-off corrections from becoming mechanisms.

## Top fixes
1. L185–190 — collapse the 1j discipline recap into a cross-reference to L115 / L153; as written it re-states rules already canonical elsewhere (no-op / sediment).
2. L42 — move the Phase-1 raw-scan format (L44-59) into `lib/output-formats.md` to match its siblings; this both fixes the hot/cold inconsistency and trims the body toward the ~<80 bar.
3. L3 — align the description's destination with the de-personalized fallback (e.g. "writes the retro to the brain, local `docs/retros/weekly/` fallback") so it no longer overstates a brain-only path.

## Behavioral cases
- trigger `/retro-week` → expected process: run the shared engine scan (Phase 1) and print the compressed scan block, gate; auto-generate brain synthesis (1.5) and the GC sweep (1.6) as propose-only blocks, each on a user gate; conduct a one-question-at-a-time interview; write the final retro to `brain/reflections/weekly/` (local `docs/retros/weekly/` fallback if no brain).
- trigger `weekly review` → expected process: same five-phase flow; if a Hermes cron pre-generated the brief, read it from `$BRAIN/inbox/retros/` instead of re-scanning (L32).
- anti-trigger `monthly retro` → should NOT fire (routes to `retro-month`).
- anti-trigger `ship this note` → should NOT fire (routes to `ship`; retro-week writes only the retro page and never git-commits, L281).
