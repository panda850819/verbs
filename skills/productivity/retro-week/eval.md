---
type: skill-eval
skill: retro-week
bucket: productivity
evaluated_skill_hash: 7b6457186eaf2a9a8fa3c40a0f1279e644344246
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — retro-week

**Verdict: SOLID.** Leading virtue is a discipline-spine: propose-only GC, a hard `count >= 2` recurrence gate, and a per-phase wait gate make the five-phase flow deterministic and hard to short-circuit.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L13 — five-phase flow (scan → synthesis → GC → interview → write), each boundary ending on an explicit wait-for-user; write target stays one path (L18 overview + L261 step both say `brain/reflections/weekly/`), no Phase-1/Phase-3 contradiction. |
| Description / invocation | pass | L3 — front-loads the leading phrase "Five-phase weekly retro," states what it does, and carries the minimal trigger set (one slash command + one NL form collapsed to "weekly retro/review"); no body-identity restated. |
| Completion criteria | pass | L148 — GC proposal gated on a checkable `count >= 2`; every phase ends on a concrete print + wait gate (L56, L97, L178, L210), so no step invites premature completion. |
| Information hierarchy | pass | L145 — the #106 win: GC classify catalogs (keyword→mechanism, reason→propose) now sit behind a `lib/gc-inputs.md` pointer instead of hot in the body; verbatim layouts live in `lib/output-formats.md` (L93, L176, L261), scan detail in `lib/scan-blocks.md` (L33). |
| Leading words | pass | L108 — "Garbage Collection" borrows Lopopolo's pretrained anchor to compress the convert-slop-to-mechanism sub-protocol; "forcing function," "hotspot," "salience proxy" (L73) anchor compactly. |
| Pruning | weak | L70 — the Phase 1.5 synthesis shell probes (~20 commented lines, L70-89) are still hot and overlap with what L33 says the engine "already covers (gbrain synthesis)"; SSOT itself is clean (recurrence gate defined once at L148, back-referenced at L174/L176/L183), but residual command detail remains prunable. |
| Granularity | pass | L60 / L106 — Phase 1.5 (synthesis) and Phase 1.6 (GC) are distinct processes with distinct inputs/outputs and their own skip conditions (L62 gbrain-absent skip; L185 empty-week block); each split earns its load. |
| pandastack conformance | weak | L284 — frontmatter valid, all three `lib/` refs resolve, hot/cold dispatch honoured (catalogs cold), but the body is 284 lines, well over the ~<80 guideline; the five-phase gated flow earns much of it, not all. |

## Why it's good
The #106 slim landed cleanly: the GC keyword→mechanism and reason→propose catalogs moved out of the body into `lib/gc-inputs.md`, so the body shrank from ~309 to 284 lines while the recurrence gate keeps a single canonical definition (L148) that downstream steps back-reference rather than re-state. The spine is discipline — propose-only GC (L110, L182), a hard `count >= 2` gate, and an explicit user wait at every phase boundary make the process reproducible and resistant to short-circuiting.

## Top fixes
1. L70-89 — move the Phase 1.5 synthesis shell probes (git-log hotspots + `gbrain query`, with their THESIS / CONTRADICTIONS / GAP comments) into `lib/scan-blocks.md`; keep only the process gate + skip condition hot. This is the largest remaining hot block and was the prior eval's Top fix #3, still not landed.
2. L33 vs L66 — resolve the ambiguity: L33 says the engine "already covers… gbrain synthesis," yet L66-89 has the agent re-derive synthesis inputs as if always run. State whether step 1e reads engine output or is a standalone fallback (mirror the explicit "only when running standalone" guard already used for GC inputs at L114).
3. L154 — the awk quote-stripping minutiae (`gsub(/^[ ]*"|"[ ]*$/, "", question)`) is implementation detail; push it to `lib/gc-inputs.md` and keep only the "strip surrounding quotes before grouping" instruction hot.

## Behavioral cases
- trigger `/retro-week` → expected process: run `retro-scan.sh week`, print the compressed scan block, Phase 1.5 synthesis (on a user gate), Phase 1.6 GC sweep (on a user gate), one-question-at-a-time interview, then write `brain/reflections/weekly/$YEAR-W$WEEK_NUM.md`.
- trigger `weekly review` → expected process: same five-phase flow (NL branch); if a Hermes cron pre-generated the brief, read it from `brain/inbox/retros/` instead of re-scanning (L27).
- anti-trigger `monthly review` → should NOT fire (routes to retro-month).
- anti-trigger `ship this note` → should NOT fire (routes to ship; retro-week writes only the retro page and never git-commits, L273).
