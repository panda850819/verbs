# Goal Mapping

Pre-step before requirement clarification. Identify which of the user's
goals this task serves, weight them, and use the dominant goal layer to
shape downstream questions and alternatives.

## Why this exists

Without goal mapping, brief / grill default to generic forcing questions
(demand reality / status quo / narrowest wedge) that don't adapt to the
user's actual goal hierarchy. Result: solutions get scoped in a goal
vacuum and often produce over-scaffolded answers that serve no specific
layer. Goal mapping forces the agent to find what the user is actually
trying to accomplish before solutioning.

## Step 1: Read goal hierarchy

Read these sources in order. Stop early if enough signal:

1. `<memory-dir>/MEMORY.md` — index of project / user / feedback memories
2. `<memory-dir>/project_*.md` — active initiatives, output strategy,
   season-level goals
3. `<memory-dir>/user_*.md` — role, work modes, long-horizon identity goals
4. Active session context — daily note, recent commits, branch name,
   recent session docs

Surface up to three goal layers:

- **L1 (long horizon, 6-18mo)** — output strategy, role/identity goals,
  vision-level commitments. Often documented in a `project_output_*.md`
  or similar memory entry.
- **L2 (this season / quarter)** — active initiatives, named projects,
  in-flight bets. Usually in `project_<name>.md` files.
- **L3 (this week / today)** — current branch / sprint / shipping target.
  Read from daily note + recent session docs + git status.

If only one or two layers surface, that is fine. Note the gap rather
than inventing.

## Step 2: Map current task to each layer

For each layer, ask:

- Does this task **directly serve** a goal at this layer?
- Does it **indirectly serve** (enabler / scaffolding for the goal)?
- Is it **unrelated** at this layer?
- Does it **work against** any goal at this layer? (rare but worth checking)

Pick the **dominant layer** — the one the task most directly serves. If
all three layers say "unrelated", the task framing is likely wrong.
Flag and reframe before proceeding.

## Step 3: Use dominant layer to shape downstream

Dominant layer changes which questions matter:

- **L1 dominant**: scope-completeness questions matter most. Task must
  respect long-horizon constraints (publishability, portability,
  durability). Skip "narrowest wedge" — wedge framing usually wrong for
  L1 work.
- **L2 dominant**: status-quo + integration questions matter most. Task
  fits inside a named initiative; ask how it integrates with that
  initiative's other moving parts. Wedge questions useful here.
- **L3 dominant**: time-pressure + edge-case questions matter most.
  Demand-reality usually answered (it's the user, today). Status-quo
  usually obvious. Drill into edge cases / failure modes.

If the dominant layer is L1 but Alternatives propose L3-style wedge
options, that is a sign the framing collapsed back to short-term and
should be rebuilt with L1 constraints in front.

## Step 4: Output mapping to user

State the mapping in one block:

```
GOAL MAPPING
- L1 (long horizon): {goal or "no clear L1 goal found"}
    → task serves this: directly | indirectly | not | works against
- L2 (this season): {goal or gap note}
    → task serves this: directly | indirectly | not | works against
- L3 (this week): {goal or gap note}
    → task serves this: directly | indirectly | not | works against

DOMINANT LAYER: {L1 | L2 | L3 | UNCLEAR}
RATIONALE: {one sentence — why this is dominant}
```

If `UNCLEAR` or no layer matches, also output:

```
TASK FRAMING APPEARS WRONG. Reframing options:
- Could this actually be {alternative framing}?
- Is this a different lifecycle (e.g. maintenance, hygiene, retro)?
- Should the question be {reframed question} instead?
```

Ask: "Confirming this mapping, or correct me?" — use the four-option
gate (approve / edit / reject / skip — see `lib/gate-contract.md`).

## Step 5: Pass result to downstream

Record outcome in the brief's `## Gate Log`:

```
Goal Mapping (Step 1.5): L1={...} L2={...} L3={...} → dominant={...}
  approve | edit: {what changed} | reject | skip
```

Downstream skills read this and adapt:

- **Clarify (Step 2)**: skip forcing questions whose answers are
  derivable from the goal mapping output.
- **Alternatives (Step 4)**: filter to options that serve the dominant
  layer; flag any option that violates a non-dominant layer's
  constraints (e.g. dominant=L3 but option breaks L1 portability).
- **Premise Challenge (Step 3)**: include "is the dominant goal layer
  framing correct?" as one of the premises.

## When to skip goal mapping

- Task is a typo / one-line config / clear bug fix where any goal layer
  would yield the same answer
- User says "skip" or "just do it" — record in Gate Log as `skip`, do
  not silently bypass
- Goal mapping has already been done in a parent flow (e.g. sprint did
  brief which already ran goal mapping — grill can sit on the result)

The cost of running goal mapping is one extra round trip with the user.
The cost of skipping when it would have helped is over-scaffolded work
that serves no goal layer. Default to running it.
