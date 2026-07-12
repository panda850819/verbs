# Logic Prototype

A tiny interactive terminal app that lets the user drive a state model by
hand. Right when the question is business logic, state transitions, or data
shape — the kind of thing that looks reasonable on paper but only feels wrong
once pushed through real cases. If the question is "what should this look
like", wrong branch: [UI.md](UI.md).

## Process

### 1. State the question

One paragraph at the top of the prototype (or its README): the state model and
the question being answered. A logic prototype answering the wrong question is
pure waste — make the question explicit so it can be checked later.

### 2. Pick the language

Whatever the host project uses; no obvious runtime → ask. Don't add a new
package manager or runtime just for a prototype.

### 3. Isolate the logic in a portable module

Put the logic that answers the question behind a small, pure interface that
could be lifted into the real codebase later. The shape follows the question:

- **Pure reducer** `(state, action) => state` — discrete events, single value.
- **State machine** — when "which actions are even legal right now" is part of
  the question.
- **Small set of pure functions** over a plain data type — no implicit current
  state, just transformations.
- **Class or module with a clear method surface** — when the logic genuinely
  owns ongoing internal state.

Pick the shape that fits the question, not the one easiest to wire to a TUI.
Keep it pure: no I/O, no terminal code. The TUI imports it; nothing flows the
other direction. This purity is what outlives the prototype.

### 4. Build the smallest TUI that exposes the state

On every tick, clear the screen and re-render the whole frame — one stable
view, not an ever-growing scrollback. Each frame, in order: (1) current state,
pretty-printed and diff-friendly (one field per line; bold names, dim
context); (2) keyboard shortcuts at the bottom (`[a] add  [d] delete  [q]
quit`). Behaviour: initialise state → read one keystroke → dispatch to a
handler → re-render the full frame → loop until quit. The whole frame fits on
one screen.

### 5. One command

Register it in the project's existing task runner (`package.json` scripts,
Makefile, justfile, pyproject). No task runner → put the command at the top of
the prototype's README.

### 6. Hand it over

Give the user the run command; they drive it themselves. "Wait, that shouldn't
be possible" and "huh, I assumed X" are the payoff — bugs in the idea. Add new
actions on request; prototypes evolve.

### 7. Capture

Per [SKILL.md](SKILL.md): the validated reducer / machine / function set lifts
into the real module; the TUI shell rides along to the throwaway branch that
keeps the prototype as a primary source.

## Anti-patterns

- **Tests on a prototype.** A prototype that needs tests is no longer a
  prototype.
- **Wiring the real database.** In-memory unless persistence IS the question.
- **Generalising.** No "what if we later want X". One question.
- **Blurring logic and TUI.** A reducer that references console, prompts, or
  escape codes is no longer portable.
- **Shipping the TUI shell to production.** The logic module behind it is the
  bit worth keeping.
