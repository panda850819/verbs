# pandastack ↔ Linear contract

How the pandastack scheduler reads a personal Linear workspace as the WBS store.
The scheduler is headless (Linear personal API key, `~/.config/pandastack/secrets.env`),
separate from the claude.ai Linear OAuth connector (company workspace).

Design lineage: symphony `SPEC.md` (poll tracker → reduce → dispatch). The one
thing symphony/multica both lack and we add: the human-gap stop is a **hard**
state the scheduler refuses to advance past, not a prompt convention.

## lifecycle-map (pandastack 7-phase ↔ Linear workflow states)

Linear lets each team define its own workflow states. Configure the Murmur team
with these states so the 7-phase lifecycle maps 1:1:

| pandastack phase | Linear workflow state | type |
|---|---|---|
| DEFINE | `Backlog` | unstarted |
| PLAN | `Planning` | started |
| GATE | `Needs Decision` | started (← the hard human gate, see below) |
| BUILD | `Building` | started |
| VERIFY | `Verifying` | started |
| REVIEW | `In Review` | started |
| SHIP | `Done` | completed |
| (killed) | `Canceled` | canceled |

The scheduler maps a Linear issue's current state → phase via this table. If a
team uses Linear's stock states (`Backlog/Todo/In Progress/In Review/Done`), the
scheduler falls back to: Backlog=DEFINE, Todo=PLAN, In Progress=BUILD,
In Review=REVIEW, Done=SHIP — and there is then NO hard gate state (degraded).

## needs-human (the hard gap gate)

`Needs Decision` is the hard stop. When an issue is in this state, the scheduler
**excludes it from dispatch** — it never auto-advances a `Needs Decision` issue;
it surfaces it as a proposal for Panda and waits. Panda's decision = moving the
issue out of `Needs Decision` (to `Building`, `Canceled`, etc.). That state
transition is the only thing that re-makes the issue dispatchable.

Equivalent fallback when custom states aren't set up: a label `needs-human` on
the issue. The scheduler treats EITHER signal (state `Needs Decision` OR label
`needs-human`) as the hard gate. This is the machine-enforced gate symphony
(approval=never) and multica (soft prompt) both omit.

## acceptance-format

The full issue description follows the **work-order schema** (Goal / Project /
Epic / Task / Context / Owner / Priority / Blocked-by / Acceptance / Needs-human /
Deliverable) — canonical definition in brain
`principles/goal-project-epic-task-ai-workflow.md`. The `Acceptance` field is a
machine-checkable success condition, written as a fenced block the scheduler can parse:

````
```acceptance
<a concrete greppable / runnable check, e.g. `bun test transcribe` green>
```
````

Rules:
- If the block is present and the check is machine-runnable → the scheduler may
  let an executor self-verify before proposing REVIEW.
- If the block is ABSENT, or the check is inherently human (e.g. "語音聽起來自然"),
  the issue's VERIFY phase is automatically a `needs-human` gate — the scheduler
  will not claim it as auto-verifiable.

## active-terminal-states

For the reduce pipeline (symphony §8.2 analogue):

- **active** (scheduler fetches as candidates): `Backlog`, `Planning`,
  `Building`, `Verifying`, `In Review`.
- **gated** (active but NEVER dispatched, surfaced as proposal): `Needs Decision`
  (or any issue carrying the `needs-human` label).
- **terminal** (skipped entirely): `Done`, `Canceled`.

Eligibility predicate (ALL must hold) before an issue is dispatchable:
state ∈ active · state ∉ gated · no `blocked_by` issue is still non-terminal ·
not already claimed/running. Sort survivors by `priority` then age (see
`scripts/pandastack-linear-reduce`).
