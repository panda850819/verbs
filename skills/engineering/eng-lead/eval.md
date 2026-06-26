---
type: skill-eval
skill: eng-lead
bucket: engineering
evaluated_skill_hash: 9b2e2724666e7f407a5f8e707115fe3f33102cec
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — eng-lead

**Verdict: SOLID.** A disciplined engineering-lens persona with strong pretrained anchors (boil the lake / trace the data flow / 3-strike escalation) and a tight routing boundary, dragged down by Anti-patterns that re-state the Iron Laws and Cognitive Models verbatim.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L62 — "On Invoke" gives a fixed 4-step ordered process (read learnings → understand → verify → write learning) the agent re-runs every invocation. |
| Description / invocation | pass | L4 — front-loads "Engineering lens", one trigger per branch, strong explicit NOT-clause routing away from ceo/product/design/ops. Model-invoked is correct (boardroom must reach it). |
| Completion criteria | weak | L62 — the On Invoke steps end on actions, not checkable done-conditions; the lens output (the review/critique itself) has no completion criterion, so "engineering review done" is undefined. |
| Information hierarchy | weak | L53 — "Known bug classes" inlines ~7 lines of dense, code-specific reference hot in the body instead of pushing it behind a context pointer like the other lib refs; only matters when actually debugging that class. |
| Leading words | pass | L41 — "Boil the lake" (paired against "minimal diff" at L40) anchors completeness behaviour in a single pretrained concept; reinforced by "Trace the data flow" (L47) and "Harden the harness" (L51). |
| Pruning | weak | L70 — Anti-patterns restate Iron Laws/Cognitive Models: "Likely handled" (Law #7 L43 → L70), 4th-variant "escalation" (Law #2 L38 → L74), "BUILD SUCCEEDED" (Law #3 L39 → L75). Same meaning in 2-3 places. |
| Granularity | pass | L19 — pushing persona-frame + verify-the-test-loop + calibration into shared lib earns the cut: 5 lead skills + boardroom reuse them, so each split buys independent reach. |
| pandastack conformance | pass | L5 — `reads:` frontmatter valid, all 5 `lib/*.md` refs resolve from repo root, body is 53 non-blank lines (well under ~80), follows the 6-section persona-frame contract. |

## Why it's good
The routing boundary (L22-25) is exemplary: a positive trigger list plus a same-altitude NOT-list naming the four sibling personas, which is exactly what keeps a multi-persona pack from collapsing into one fuzzy "thinking" skill. Leading words are load-bearing rather than decorative — "boil the lake" vs "minimal diff" (L40-41) is an asymmetric pair the agent reasons *with*, not a slogan. Progressive disclosure is real: the heavy test-loop and calibration content lives in shared lib reached by `@` pointer, so the hot body stays legible.

## Top fixes
1. **Pruning (L70-78):** collapse the Anti-patterns section. Items that merely negate an Iron Law ("Likely handled" L70 = Law #7 L43; "4th variant" L74 = Law #2 L38; "BUILD SUCCEEDED" L75 = Law #3 L39) pay tokens to say nothing new. Keep only anti-patterns that name a drift NOT already covered by a law, or delete the section and let the laws carry it.
2. **Completion criteria (L62):** add a done-condition to the lens, e.g. "review is complete when every flagged risk has either a root cause named or an explicit `unknown` flag." Right now nothing tells the agent when to stop reviewing.
3. **Information hierarchy (L53-59):** push "Known bug classes" into a `lib/known-bug-classes.md` reached by pointer. It is on-demand reference, not something every eng-lead invocation needs hot; inlining it bloats the body that L43 progressive-disclosure note says should stay legible.

## Behavioral cases
- trigger `/eng-lead is this watcher leaking?` → expected process: read learnings, read the code, trace data flow before any change (Law #1 L37), match against "Listener owns lifetime" bug class (L57), verify by running with a real `--once` smoke, refuse "likely handled" (L43).
- anti-trigger `should we even build this feature this quarter?` → should NOT fire (routes to `ceo` for strategy-only scope, per L25), since no technical decision is on the table.
