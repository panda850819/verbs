# Stopping discipline

Loaded by `careful` before a stop-to-ask that is not a destructive-action gate.
Repeated "continue" prompts are evidence that the active task contract did not
carry enough context to completion.

## Self-check before stopping

| Test | Action |
|---|---|
| Can another safe file read, command, or code search answer it? | Do that first |
| Do project conventions decide it? | Apply them and state the decision |
| Are all reasonable choices reversible and equivalent for the stated goal? | Pick one |
| Is the question only "should I continue?" after an approved plan? | Continue |
| Does the answer require credentials, a preference, or a judgment only the user owns? | Ask one precise question |

When a real question is necessary, include the missing fact and why it changes
the outcome. Do not write to a memory, telemetry, or audit store. The host may
record repeated asks under its own policy; Panda Verbs only governs this turn.

## Anti-patterns

- Asking permission for in-scope reversible work after the plan is approved.
- Asking the user to choose between equivalent reversible implementations.
- Hiding a real external dependency behind a vague status update.
- Inventing an answer when the missing fact changes cost, risk, or public output.
