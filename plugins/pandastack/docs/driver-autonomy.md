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

The Linear board grouped by workflow state is the human-readable projection of this
split: AUTO-phase columns (`Planning` / `Verifying` / `In Review`) are the loop's;
gate-phase columns (`Needs Decision` / `Building` / `Done`) are Panda's.

## Readiness — inputs present, not just safe-to-run

The Auto-runs list answers "is it safe to run unattended." It does not answer "is
there enough on the issue to run *usefully*." A PLAN on a one-line Backlog stub
yields a plausible-but-empty plan; an auto-VERIFY with no checkable acceptance can
only guess. So Auto-runs carries one more condition:

7. **Inputs present** — the phase's required inputs are on the issue. Missing → gate
   as `needs-human`. Not because it is dangerous, because it is not ready.

| Phase | Required inputs (else → gate) |
|---|---|
| PLAN   | enough context to plan — Goal + Context in the work-order, not a bare title |
| VERIFY | a machine-checkable `acceptance` block (already in `linear-contract.md`) |
| REVIEW | a diff / artifact to review |
| BUILD  | see BUILD autonomy below |

This generalizes the acceptance-format rule (`linear-contract.md`) from VERIFY to
every phase: an under-specified issue never auto-runs, it surfaces for Panda to spec.
Reversibility and locality decide *safe*; readiness decides *ready*. Both gate.

Status: VERIFY-acceptance readiness **wired** (2026-06-17). `pandastack-linear-reduce`
now gates a VERIFY-phase issue with no machine-checkable `acceptance` block as
`needs-spec` (distinct from the `needs-decision` hard gate), test-covered in
`tests/linear-reduce.sh`. Still pending: PLAN (Goal+Context) and REVIEW (diff/artifact)
readiness, and BUILD autonomy below.

## BUILD autonomy (proposed — default OFF)

Today BUILD always gates (Gate #2): it mutates and lands code. That is the shipped
default; keep it until the conditions below are built and verified.

A bounded opt-in lets the loop carry a *fully-readied* issue into development without
a per-step human kick — the safe form of "let the planned, prompt-ified work go
straight to dev." BUILD may auto-run for an issue ONLY when ALL hold:

1. **Plan approved** — the issue already passed GATE (Panda moved it out of
   `Needs Decision`). The one-way-door decision is already a human's.
2. **Prompt-ified work-order** — the description is a complete work-order
   (Goal / Project / Epic / Task / Context / Acceptance / Deliverable) that renders
   straight into the executor prompt; no missing field.
3. **Machine-checkable acceptance** — a runnable `acceptance` block the build
   self-verifies against before proposing REVIEW.
4. **Isolated workspace** — runs in a per-issue workspace, not the live repo, so a
   bad run cannot corrupt working state. <!-- upgrade: port symphony workspace isolation + backoff -->
5. **Stops at SHIP** — produces a branch / PR proposal; never auto-merges, pushes to
   main, or publishes. SHIP stays a hard gate (Gate #3).

Enable per-project via `--only <project>` first, never globally. Without (1)-(3) an
issue is not BUILD-ready and stays gated. This is the ONLY path by which a mutation
phase becomes auto-eligible, and only because the irreversible decision (the plan)
was human-approved upstream.

## Execution runtime — Codex, not `claude -p`

The driver delegates an AUTO step to **Codex** (`codex exec -s read-only -C <repo>`),
never `claude -p`:

- (Superseded 2026-06-16: `claude -p` was slated to move off subscription rate
  limits on 2026-06-15, but Anthropic deferred it. It stays on subscription, with
  advance notice before any future change. So this is no longer a reason to avoid
  `claude -p`; the quota-split and sandbox points below are what keep Codex the runtime.)
- Codex runs on Panda's **subscription** (no per-call $). Throttle by `--max`, not a $ budget.
- `-s read-only` enforces no-mutation **at the sandbox layer** — a third wall on top
  of the phase classifier (BUILD/SHIP never reach here) and the read-only prompt.

General rule: for development / delegated execution, prefer spawning **Codex** over
metered or soon-retired paths.

## Execution model — ephemeral, stateless per tick

Each AUTO step is a one-shot CLI process: open `codex exec`, run one prompt, capture
the verdict, exit. The next issue gets a fresh process. No daemon holds state — the
WBS lives in Linear, lifecycle in `state.jsonl`; every tick re-polls from zero. This
is crash-safe by construction and platform-portable: the same CLI call runs under
launchd, a cloud cron, Hermes, or CronCreate. No bespoke control-plane to build.

## Notify cadence

- **New gate appears** → ping Panda now (telegram, async nudge).
- **Daily digest** → the full queue into the dashboard once a morning (floor).
- **Unchanged queue** → stay quiet. Re-sending the same queue is noise.

[Source: Panda 2026-06-14 — "要有標準什麼東西需要我決定"]
[Source: Panda 2026-06-15 — "確認哪些東西應該 auto loop"; "有些東西如果還沒想清楚，當然就不應該著手進行"]
