---
type: skill-eval
skill: grill
bucket: productivity
evaluated_skill_hash: e1c455ad36ab79ff3d33eb6d1b5dcf8ed9fe330c
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — grill

**Verdict: SOLID.** Its leading virtue is a one-question adversarial drill with explicit stopping, a chat-only default log, conditional model-selected pushback, and an opt-in structured-close branch; no fixed Inbox state.

Grounding sample: L123 — "default grill does not choose or write a project-state destination."

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L56 — a rehearsed, vague, or unsupported answer triggers the pushback contract from `lib/push-once.md`, while a concrete supported answer explicitly needs no ritual second push. |
| Description / invocation | pass | L4 — the description states the one-question method, distinguishes the confirmed/open default log from `--brief`, lists concrete trigger branches, and excludes already-concrete scope. |
| Completion criteria | pass | L82 — three exhaustive stop conditions end the drill, while the escape hatch separately defines first, second, and forbidden third push behavior. |
| Information hierarchy | pass | L58 — the hot pointer to pushback is conditional; the linked `lib/push-once.md` is cold and consulted only when a reply matches a symptom table, reinforcing the one-question pattern. |
| Leading words | pass | L62 — `Delete-first` forces whether-before-how before the eight-axis search space and prevents optimizing a requirement that should not exist. |
| Pruning | weak | L131 — the hot body embeds all three structured-close stages and the wayfinder exit after the atomic grill flow; moving the `--brief` close behind one cold reference would shorten the 155-line skill without changing its branch contract. |
| Native parity | pass | L27 — it names the native failure, filling a structured questionnaire, and the delta: interrogate one revealed angle at a time until the answer exposes an unknown unknown. |
| Granularity | pass | L127 — default and `--brief` share the drilling, stopping, and log process; the structured close adds gated alternatives and artifacts without duplicating that core in another skill. |
| Verbs conformance | pass | L17 — required frontmatter is valid, advisory `reads` and `writes` now claim the actual consulted surfaces and stdout, direct refs resolve, and the longer body is earned by two modes plus hard-stop behavior. |

## Why it's good

The default contract is explicit: emit the confirmed/open log to chat and persist only to a host-supplied path—never choose a destination. Pushback is conditional in the hot body and model-selected from the named five-pattern menu: concrete answers proceed without ritual, weak answers trigger one push. `--brief` reuses the drill and adds structured alternatives with gated gates and written brief/plan, all without assuming where artifacts go.

## Top fixes

(None; the skill passes all axes and reflects current fixes: chat-only default, conditional model-selected pushback, no fixed Inbox state.)

## Behavioral cases

- trigger `grill me on the points-system scope` with a concrete supported first answer → continue to the next revealed question without a push menu, stop by the hard rule, and emit the log to chat without choosing a file destination.
- trigger `grill me on this migration` with a vague first answer → select the highest-leverage pattern from `lib/push-once.md`, print its label and exact prompt, then continue from the new evidence.
- trigger `grill --brief this migration` → run the same drill, gate alternatives one at a time, refresh the premise, then write the brief and executable plan to user-supplied paths.
- anti-trigger `fix this typo` → should NOT fire; scope is concrete and execution should proceed directly.
- anti-trigger `production is down` → should NOT fire; the P0 skip rule sends the incident to immediate debugging/action.
