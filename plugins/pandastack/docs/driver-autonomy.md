# Driver autonomy standard — what auto-runs vs what needs Panda

The single contract for `pandastack-drive`. It decides, for each active work-item,
whether the next step runs unattended or stops for Panda. This is Panda's
AGENTS.md four-mode routing made executable: **auto = auto-resolve; gate =
draft-and-ask / escalate.**

## Auto-runs (no decision needed) — ALL must hold

1. **Reversible** — produces a plan / report / test-result; no commit-to-main, no
   push, PR, deploy, publish, delete, overwrite, or force-push.
2. **Local-only** — no message / DM / post / email / external API write.
3. **Within budget** — no metered-API or subscription-quota fan-out (a swarm = 8
   agents is NOT auto); under the per-run token cap.
4. **Own files** — the project's own repo/files; NOT shared infra
   (`~/.agents`, `~/.claude`, `~/.codex`, `launchd`, `~/.hermes`, secrets).
5. **Unambiguous** — one clear next step, not a choice between valid paths.
6. **Phase ∈ {PLAN, VERIFY, REVIEW}** — analysis phases (plan / run-checks / read-only review).

## Gates to Panda (stops, asks) — ANY triggers

| # | Trigger | Example |
|---|---|---|
| 1 | **Decision** (GATE phase) | kill / pivot / scope / priority / approach (pandastack v2 start) |
| 2 | **Mutation that lands** (BUILD→commit) | edits that touch main / prod |
| 3 | **Publish / external** (SHIP) | push, PR, deploy, send, post, DM |
| 4 | **Spend** | swarm / metered API / quota fan-out / over budget |
| 5 | **Irreversible** | delete, overwrite, force-push, DROP |
| 6 | **Ambiguity** | multiple valid paths, unclear signal, conflicting evidence |
| 7 | **Shared infra / harness / secrets** | `~/.agents`, `~/.claude`, `~/.codex`, launchd, `~/.hermes`, `.env` |

## Two enforcement layers

- **Classification (Stage 1, live):** by phase. `GATE / BUILD / SHIP` and `paused`
  never auto-run. `pandastack-drive` surfaces them with a reason.
- **Execution (Stage 2):** before spawning an AUTO item's skill, re-check the live
  triggers (#3–#7) against what the skill will actually do. Any hit → gate, do not
  run. A skill that *starts* AUTO but mid-run needs to mutate/publish/spend must
  stop and surface, not push through.

## Execution runtime — Codex, not `claude -p`

The driver delegates an AUTO step to **Codex** (`codex exec -s read-only -C <repo>`),
never `claude -p`:

- `claude` print-mode retires **2026-06-15** — anything built on it breaks.
- Codex runs on Panda's **subscription** (no per-call $). Throttle by `--max`, not a $ budget.
- `-s read-only` enforces no-mutation **at the sandbox layer** — a third wall on top
  of the phase classifier (BUILD/SHIP never reach here) and the read-only prompt.

General rule: for development / delegated execution, prefer spawning **Codex** over
metered or soon-retired paths.

## Notify cadence

- **New gate appears** → ping Panda now (telegram, async nudge).
- **Daily digest** → the full queue into the dashboard once a morning (floor).
- **Unchanged queue** → stay quiet. Re-sending the same queue is noise.

[Source: Panda 2026-06-14 — "要有標準什麼東西需要我決定"]
