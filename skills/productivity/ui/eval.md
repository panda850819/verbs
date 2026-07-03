---
type: skill-eval
skill: ui
bucket: productivity
evaluated_skill_hash: 8b805e79bdee0c90bfa307286fa04b82b1ba75fe
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — ui

**Verdict: SOLID.** A lean UI override spine over a dense craft reference: it names the AI-default aesthetic, forces render verification, and routes visual taste separately from bugs and browser QA.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L18 — the three fixed overrides run every UI task: fight defaults, verify render, and build past happy path. |
| Description / invocation | pass | L4 — front-loads UI surfaces and trigger terms, while L7-9 cleanly excludes backend logic, browser-test QA, and root-cause debugging. |
| Completion criteria | pass | L21 — screenshot verification at 375px and 1280px before "done" gives the skill an observable finish condition, not source-level confidence. |
| Information hierarchy | pass | L26 — fonts, CJK type, OKLCH, CSS bans, motion, spacing, and content rules are all cold in `references/craft.md`; the hot body stays a 27-line spine. |
| Leading words | pass | L18 — "Fight your defaults" plus "AI-default" names the main override in a phrase the model can keep active while editing. |
| Pruning | pass | L14 — the body says the agent already knows design and only lacks craft numbers plus override discipline; it avoids restating generic design advice. |
| Native parity | pass | L18 — names the native/default competitor directly: Inter, purple-blue gradient, centered hero, two CTAs, identical cards. The delta is a forced named direction plus default-trap scan. |
| Granularity | pass | L26 — one craft reference is the right split for this size; the skill does not split typography, color, and layout into separate skills before repeated evidence demands it. |
| pandastack conformance | pass | L2 — `name: ui` matches the folder, the reference path resolves, and the 27-line hot body stays well under the soft cap. |

## Why it's good
The skill's delta is practical UI discipline the base model routinely misses: named visual direction, real screenshot verification, non-happy states, and CJK taste routing. The craft detail stays out of the hot body until needed.

## Top fixes
1. `references/craft.md` is dense; split only if it grows past the current single-reference shape and repeated use shows separate surfaces fire independently.

## Behavioral cases
- trigger `這個頁面很醜，幫我改` → expected process: keep it in UI taste, read craft, choose direction, edit, screenshot at mobile and desktop.
- anti-trigger `button click throws an exception` → should NOT fire (routes to `debug`).
