---
name: debug
description: |
  Root-cause route for an observed error, crash, regression, failing test, or
  intermittent behavior whose cause is still unknown. Reproduce it, name the
  evidence-backed cause before editing, verify the fix with a red-capable check,
  and scan for siblings. Use `review` for diff review and `ui` for taste complaints.
user-invocable: true
---
# Debug

You already know how to debug. This skill is not the method. It overrides the
momentum reflexes you get wrong and points you to lore you cannot derive.

## Override

- **Name the root cause before you edit.** At `file:function:line`, with the evidence. "A state issue"
  is not a root cause; "stale cache in `useUser` at `user.ts:42`, dep array missing `userId`" is.
  Editing before you can say that sentence is the failure mode.
- **Diagnosis ends only on a red-capable command.** Name one already-run deterministic, fast,
  agent-runnable command that can fail, and say you saw its output. "I understand the bug" is not done.
- **Do not claim fixed until you ran it and looked.** "Should work" is not evidence. Compile-only is
  not enough for UI / native / generated-artifact bugs: open it, and for generated output read the
  contents, not the source diff. Cannot run it here → say so and hand off the exact check.
- **Before "fixed", grep the signature for siblings.** One fix that ignores siblings leaves N-1 in the
  tree; the same shape usually hides elsewhere.

## Lore (consult when the cause is not obvious)

`lib/diagnosis.md` — known bug classes (listener-owns-lifetime, O(N²)
accumulators, schema category-leak, and CLI archetypes: PATH drift, stdout/stderr contract, pipe
backpressure, cold-start), instrument-first-by-bug-class, bisect with worktree safety, and the
3-failed-hypotheses handoff template.

Recall first per [`@lib/learning-recall.md`](lib/learning-recall.md):
pull from the repo learning path configured by the host project, matching the symptom / bug class before
hypothesizing. A new reusable bug class emits a candidate using
`lib/learning-format.md`; a match emits a one-line `seen again` candidate. Never
write or update the learning store here. Persistence belongs to the host/project.
