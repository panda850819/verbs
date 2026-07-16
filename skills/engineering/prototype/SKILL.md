---
name: prototype
description: |
  Throwaway prototype that answers ONE design question. Logic branch ("does
  this state model / data shape feel right?") → tiny interactive terminal
  driver. UI branch ("what should this look like?") → several structurally
  different variants behind a ?variant= param. Use when a design question is
  answerable by building cheap and reacting: sanity-check a state model,
  explore what a surface should look like, make a grill open question
  concrete. NOT committed production UI work (use `ui`) and NOT the feature
  itself (use `sprint`).
reads:
  - repo: "**"
writes:
  - repo: "**"
  - cli: stdout
domain: shared
classification: exec
user-invocable: true
---
# Prototype

A prototype is **throwaway code that answers a question**. The question decides
the shape; the verdict outlives the code.

## Pick the branch

Identify the question from the prompt and the surrounding code. If genuinely
ambiguous, ask when the user is present; otherwise match the surrounding code
(backend module → logic; page or component → UI) and state the assumption at
the top of the prototype. Getting the branch wrong wastes the whole prototype.

- **"Does this logic / state model feel right?"** → [LOGIC.md](LOGIC.md): a
  tiny interactive terminal app that pushes the state model through cases that
  are hard to reason about on paper.
- **"What should this look like?"** → [UI.md](UI.md): several structurally
  different variants on one route, switchable via `?variant=` and a floating
  bottom bar. Single round by default; UI.md's converge mode runs repeated
  rounds down the visual design tree when the user (or a wayfinder entry)
  asks for it.

## Rules (both branches)

1. **Throwaway from day one, clearly marked.** Locate it next to the module or
   page it prototypes so context is obvious; name it so a casual reader sees
   prototype, not production. Obey the project's existing routing and task
   conventions — invent no new top-level structure.
2. **One command to run**, via the project's existing task runner. The user
   starts it without thinking.
3. **No persistence by default.** State lives in memory. If the question is
   explicitly about persistence, hit a scratch store named "PROTOTYPE — wipe
   me".
4. **Skip the polish.** No tests, no error handling beyond what makes it
   runnable, no abstractions. The point is to learn fast.
5. **Surface the state.** After every action (logic) or variant switch (UI),
   show the full relevant state so the user sees what changed.

## Capture when done

Done means the question is answered AND captured:

- Fold the validated decision into the real code, or into the brief/plan
  driving the work.
- Record the verdict — the question and its answer — on the tracking issue or
  brief that spawned the prototype.
- Commit the prototype itself to a throwaway `prototype/<slug>` branch as the
  primary source, never the default branch. The default branch keeps only the
  validated decision.

## Relationship to other skills

- `prototype` diverges cheap to choose a direction; `ui` then converges and
  builds the committed direction for production.
- A grill open question of the shape "how should it look / behave" is often
  fastest resolved here; feed the verdict back into the brief.
