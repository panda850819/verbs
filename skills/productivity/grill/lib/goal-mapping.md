# Goal Mapping

Pre-step before requirement clarification. Identify which stated project goals
the task serves, weight them, and use the dominant layer to shape downstream
questions and alternatives.

Verbs does not discover personal goals from identity or memory stores.
Use goals already in the conversation or explicitly present in the current
project. Missing context stays missing.

## Step 1: Read project goal evidence

Read in order and stop when enough signal exists:

1. Goals and constraints stated in the current conversation.
2. The matching brief, plan, issue, or decision record.
3. Project-local `ROADMAP.md`, `TODOS.md`, or documented goals when present.
4. Current branch, recent commits, and session notes for the immediate target.

Surface up to three layers:

- **L1 (long horizon)**: product or program commitments that this project states.
- **L2 (current initiative)**: the active project, milestone, or in-flight bet.
- **L3 (current delivery)**: this branch, sprint, or shipping target.

If one or more layers are absent, record the gap. Never infer a role, identity,
or life goal from unrelated files.

## Step 2: Map the task

For each visible layer, classify the task as:

- directly serves;
- indirectly enables;
- unrelated;
- works against.

Pick the most directly served layer as dominant. If every visible layer is
unrelated, flag the task framing before proposing a solution.

## Step 3: Shape downstream questions

- **L1 dominant**: protect long-horizon constraints such as portability,
  durability, and public compatibility.
- **L2 dominant**: ask about integration with the named initiative and its
  current dependencies.
- **L3 dominant**: ask about time pressure, acceptance, edge cases, and failure
  modes.

An option that serves the dominant layer while violating a documented higher
constraint must be flagged, not silently recommended.

## Step 4: Output

```text
GOAL MAPPING
- L1 (long horizon): {goal or "no project evidence"}
    -> directly | indirectly | unrelated | works against
- L2 (current initiative): {goal or "no project evidence"}
    -> directly | indirectly | unrelated | works against
- L3 (current delivery): {goal or "no project evidence"}
    -> directly | indirectly | unrelated | works against

DOMINANT LAYER: {L1 | L2 | L3 | UNCLEAR}
RATIONALE: {one evidence-backed sentence}
```

If `UNCLEAR`, ask one question that would change the mapping. Otherwise pass the
mapping into the brief's Gate Log and continue under the caller's gate rules.

## Skip

Skip for a typo, one-line config edit, or clear bug where every layer yields the
same action; when the user explicitly says skip; or when a parent flow already
produced a current mapping.
