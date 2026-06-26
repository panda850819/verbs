---
type: skill-eval
skill: retro-week
bucket: productivity
evaluated_skill_hash: 4c577c5010c359de1f4cc06980c613ff2dfe7941
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — retro-week

**Verdict: WEAK.** Leading virtue is the gate-and-discipline architecture: five phases, each ending on an explicit wait gate, plus a hard `count >= 2` recurrence gate that the propose-only GC sweep enforces. The prior pruning FAIL is resolved, but the body is still 309 lines and the description still clusters the slash command with its natural-language synonym.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L13 — five-phase flow (scan → synthesis → GC → interview → write), each gated by an explicit wait-for-user; the prior write-target contradiction is gone (L18 overview and L286 step both say `brain/reflections/weekly/`). |
| Description / invocation | weak | L3 — front-loads "Interactive weekly retro," no body-identity, but `"/retro-week"` and `"weekly retro"` are the slash form and its NL synonym for one branch; near-synonyms renaming one branch should collapse. |
| Completion criteria | pass | L163 — GC proposal gated on a checkable `count >= 2`; every phase boundary ends on a concrete wait/print gate (L56, L97, L203, L235), no premature-completion bait. |
| Information hierarchy | pass | L33 / L114 — scan-block detail and GC shell-portability rationale are behind explicit skill-local lib pointers; output layouts are also pushed to `skills/productivity/retro-week/lib/output-formats.md` (L93, L201, L286). |
| Leading words | pass | L108 — "Garbage Collection Day" borrows Lopopolo's pretrained anchor to compact the convert-slop-to-mechanism sub-protocol; "hotspot" / "salience proxy" / "forcing function" anchor compactly. |
| Pruning | pass | L163 — recurrence gate now defined once canonically; downstream mentions point back to that gate instead of redefining it (L199, L201). Orphan `feedback-log.md` and the Phase 1/3 write-target contradiction are removed. |
| Granularity | pass | L60 / L106 — Phase 1.5 (synthesis) and 1.6 (GC) are distinct processes with distinct inputs/outputs and their own skip conditions; each split earns its load. |
| pandastack conformance | weak | L33 — skill-local references are now explicit repo-relative paths and pass `lint-refs-resolve.py`; the body is still 309 lines, well over the ~<80 guideline, though the heaviest output templates moved behind `lib/output-formats.md` pointers. |

## Why it's good
The prior FAIL on pruning is genuinely fixed: the recurrence gate now has one canonical definition (L163) with downstream mentions back-referencing it, the orphan `feedback-log.md` is removed, and the Phase 1/Phase 3 write-target contradiction resolves to a single brain path. The spine is discipline: propose-only GC, a hard `count >= 2` gate, and per-phase user gates make the process deterministic and hard to short-circuit.

## Top fixes
1. L137-199 — move the GC proposal-building mechanics into `skills/productivity/retro-week/lib/gc-inputs.md` or a second GC procedure reference; this is the largest remaining hot block.
2. L3 — collapse the two triggers if they are one branch, or justify why the NL phrase covers phrasing the slash command cannot. As written they read as a synonym pair renaming the same weekly-retro action.
3. L70-89 — move the Brain Synthesis shell probes into `skills/productivity/retro-week/lib/scan-blocks.md`; Phase 1.5 should keep the process gate hot and push command detail cold.

## Behavioral cases
- trigger `/retro-week` -> expected process: run `retro-scan.sh week`, print compressed scan, then Phase 1.5 synthesis, then Phase 1.6 GC sweep (each on a user gate), one-question-at-a-time interview, write `brain/reflections/weekly/$YEAR-W$WEEK_NUM.md`.
- trigger `weekly review` -> expected process: same five-phase flow (covered by the "weekly retro" NL branch); if a Hermes cron pre-generated the brief, read it from brain/inbox/retros/ instead of re-scanning (L27).
- anti-trigger `monthly review` -> should NOT fire (routes to retro-month).
- anti-trigger `ship this note` -> should NOT fire (routes to ship; retro-week writes only the retro page and never git-commits, L298).
