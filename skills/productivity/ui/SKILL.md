---
name: ui
description: Build or visually correct production UI with a deliberate direction and rendered evidence; use prototype while the design decision remains open.
user-invocable: true
---
# UI

Use [craft references](references/craft.md) for typography, CJK, layout, motion, and required states relevant to the task. Name the observable visual problem and chosen direction; do not reclassify taste complaints as functional bugs or remove deliberate design choices without evidence.

Implement applicable loading, empty, error, navigation, validation, and accessibility states. Verify the rendered result at 375px and 1280px in every shipped locale, including overflow and text wrapping; source inspection alone cannot prove appearance.

`prototype` resolves an open design question; `qa` owns browser acceptance evidence; `review` owns the code diff. Reuse current rendered evidence across these tasks instead of repeating it. Report only the chosen direction, observed result, and remaining gaps.
