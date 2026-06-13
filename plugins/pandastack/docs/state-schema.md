# pandastack lifecycle state schema

Machine-readable state that makes loop-in-agent possible: a scheduler (Hermes /
cron) reads where each work-item stands and decides the next step against
`DISPATCH.md`, instead of a human firing every phase by hand.

Implemented by `scripts/pandastack-state` (zero-dependency Python 3).

## Design contract (grilled 2026-06-13)

| Decision | Choice | Why |
|---|---|---|
| Granularity | one log per **project**, `item` field separates work | scheduler reads all in-flight items of a repo in one pass (gstack `projects/<slug>/` model) |
| Event grain | **phase boundaries + terminal states** only | enough to resume ("where, what status"); not a per-action activity log that bloats and can't be reduced cheaply |
| Phase vocabulary | full **7-phase** lifecycle | scheduler can map the exact next phase to a skill via DISPATCH.md |
| Storage model | **event-sourced, append-only** | multi-runtime writers (Claude/Codex/Hermes) never race on a shared file; active state is COMPUTED, never overwritten |
| ts + run_id origin | produced by the **writer**, not the model | the model decides WHAT happened; the program records WHEN — resume breaks if a model invents timestamps |

## Location

```
~/.pandastack/projects/<slug>/state.jsonl     # override root via PANDASTACK_STATE_HOME
```

`<slug>` = the repo / vault basename. Append-only; never edited in place.

## Event shape (one JSON object per line)

```json
{
  "ts": "2026-06-13T02:13:37Z",      // ISO8601 UTC, writer-produced
  "run_id": "a1b2c3d4e5f6",          // one skill invocation, writer-produced
  "skill": "sprint",                 // which skill emitted it
  "runtime": "claude-code",          // claude-code | codex | hermes | other
  "item": "feed-curator",            // work-item slug (required)
  "event": "phase_enter",            // see enum below
  "phase": "BUILD",                  // 7-phase enum; required for phase_enter
  "ref": "docs/sessions/...md",      // artifact pointer (brief / session / PR) | null
  "note": "EOD"                      // freetext | null
}
```

### `event` enum

| event | meaning | reduced status |
|---|---|---|
| `phase_enter` | entered a lifecycle phase (requires `--phase`) | `in_progress` |
| `resumed` | picked back up after a pause | `in_progress` |
| `delegated` | handed to Codex (sets `owner: codex`) | `in_progress` |
| `paused` | parked mid-phase (keeps last phase) | `paused` |
| `shipped` | reached SHIP, closed | `shipped` (terminal) |
| `failed` | gave up / blocked | `failed` (terminal) |
| `aborted` | explicitly killed | `aborted` (terminal) |

### `phase` enum (7-phase lifecycle)

`DEFINE → PLAN → GATE → BUILD → VERIFY → REVIEW → SHIP` (README "Lifecycle map").

## Reducer

`reduce` folds the log per item, last event wins for status; `phase` tracks the
last phase entered (terminal/paused keep it). `next` lists non-terminal items
with the advisory next phase. The phase→skill mapping itself lives in
`DISPATCH.md`, not in this script — the store reports state, the dispatch table
decides action.

```bash
pandastack-state reduce --slug myrepo            # table of every item's active state
pandastack-state reduce --slug myrepo --json     # same, machine-readable
pandastack-state next   --slug myrepo            # only active items + advisory next phase
```

## Who writes (phase-boundary + terminal points only)

| Skill | Emits |
|---|---|
| `office-hours` | `phase_enter DEFINE` (brief written) |
| `sprint` | `phase_enter BUILD/VERIFY/REVIEW`, terminal `shipped`/`failed`/`aborted`, `paused` on PAUSE |
| `review` | `phase_enter REVIEW` |
| `ship` | `phase_enter SHIP` then `shipped` |
| `handover` | `delegated` |
| `checkpoint` | `paused` (and `resumed` on --resume) |

Skills emit at boundaries, not for every unit. A skill that can't reach the
writer (degraded runtime) just skips emission and says so — the log stays
append-only and gap-tolerant.

## Scheduler usage (loop-in-agent)

```
for item in `pandastack-state next --slug <repo> --json`:
    look up item.phase in DISPATCH.md  ->  spawn the skill for the NEXT phase
```

State in the file, decision in DISPATCH.md, execution in the runtime — three
concerns, three places, no model memory in the loop.
