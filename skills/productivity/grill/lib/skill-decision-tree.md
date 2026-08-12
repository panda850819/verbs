# lib/skill-decision-tree.md — Workflow shape → execution surface

> Shared module. Loaded by `grill` and any skill that recommends the next execution step.
>
> Origin: 2026-05-05. Updated after Verbs retired its delegated-execution
> transport in favor of Herdr and host-native workers.

## The sharp distinction: execution ownership

Default to `/sprint`: the active session owns one finish line through acceptance,
review, Git, and delivery. Delegation changes who performs a bounded unit, not
who owns completion.

For multi-step sequential work, run multiple sprints in sequence. There is no
separate orchestrator skill.

## Q0: Should this even be a skill? (refuse-to-build escape hatch)

Before routing a workflow to execution, ask whether the thing should be a skill
at all. Refusing to build is a valid outcome and the cheapest place to stop
skill sprawl.

- **Knowledge → note.** A fact, decision, reference, or read-once checklist
  belongs in the owner's configured knowledge store.
- **One deterministic step → script or `lib/` helper.** A single command with no
  judgment does not earn frontmatter, routing, and an index slot.
- Continue only for a multi-step workflow needing in-context judgment.

## 2-question decision test

### Q1: Is there one concrete finish line?

If yes → **`/sprint`**. It retains acceptance, review, Git, and delivery
ownership even when a bounded unit is delegated.

If no → split the work into independently verifiable finish lines, or return to
`grill` when the decomposition still depends on unsettled decisions.

### Q2: Did the human explicitly request delegated execution?

If yes, use Herdr inside a managed Herdr pane or the host's native worker
surface. Give the worker one bounded unit and runnable acceptance checks. Treat
its output as evidence, not completion, then return to the active Sprint.

If no, execute in the foreground session.

## Brief shape → execution mapping

| Brief shape | Execution |
|---|---|
| One independently verifiable outcome | `/sprint` |
| Several independent outcomes | One `/sprint` per outcome |
| Explicit delegated mechanical unit | Herdr or host-native worker inside the owning Sprint |
| Fuzzy scope or unresolved product decision | `/grill` first |

## Anti-patterns

- Delegating because task count alone is high.
- Sending judgment-heavy or exploratory work to a worker.
- Treating worker output as accepted, reviewed, committed, or delivered work.
- Adding another Verbs transport wrapper around host-native delegation.

## When this lib is loaded

- `grill` — recommend the next execution surface in the brief.
- Any skill that must distinguish foreground execution from explicit delegation.
