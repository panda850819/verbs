# lib/skill-decision-tree.md — Workflow shape → execution skill

> Shared module. Loaded by `office-hours` (Stage 5 next-skill recommendation), `sprint` (Stage 3 persona-routing reference), `boardroom` (post-critique handoff), and any other Layer 1 flow skill that needs to recommend the next execution step.
>
> Origin: 2026-05-05 — office-hours produced briefs but did not point to the next skill. v2.0.0 simplified the picture: `execute-plan` was cut (its sequential-subagent role overlapped sprint Phase 3); the only execution-locus axis left is sprint vs team-orchestrate.

## The sharp distinction: execution locus

Pick by **who executes**:

| Skill | Main session role | Executor | Context isolation | Time ordering |
|---|---|---|---|---|
| `/sprint` | **Executor itself** | Main session (you + the AI in same context) | None — same context throughout, persona is a cognitive lens | N/A (single track) |
| `/team-orchestrate` | **Conductor** | N subagents at once | Fresh context per branch + worktree isolation | Parallel, gate per branch as it returns |

For multi-step sequential work without parallelism, run multiple sprints in sequence. There is no dedicated "sequential subagent coordinator" skill — that ceremony cost more than it saved.

## Q0: Should this even be a skill? (refuse-to-build escape hatch)

Before routing a workflow to an execution skill — and before `skill-creator` runs
its MECE check — ask whether the thing should be a skill **at all**. Refusing to
build is a valid, non-failure outcome; it is the cheapest place to stop skill
sprawl, upstream of the MECE check.

- **It's knowledge, not a workflow → a brain page, not a skill.** A fact, a
  decision, a reference, a checklist someone reads once — file it under the brain
  (`gbrain` / RESOLVER tree). Skills are *executed*; pages are *read*.
- **It's one deterministic step → a one-line script / alias, not a skill.** If the
  whole capability is `grep`/`jq`/a single CLI invocation with no judgment, a
  script (or a `lib/` helper) beats a SKILL.md. A skill's overhead (frontmatter,
  trigger surface, index slot, resolver row) only pays off when there is real
  routing + judgment to host.
- **Only if it survives both** — a multi-step workflow needing in-context judgment
  or dispatch — continue to the 2-question test below.

This is an outcome, not an error: "this should be a brain page / one-line script,
not a skill" is a correct answer that keeps the corpus lean.

## 2-question decision test

Ask in order. First Yes wins.

### Q1: 「我要不要邊做邊 iterate / debug / 改方向？」OR 「這只是一件事？」

If yes → **`/sprint`**. Reason: iteration is cheap when the executor is in-session. For multi-step sequential work, run multiple sprints in sequence — each sprint owns one task end-to-end.

If no, the work is N truly independent branches that benefit from wall-clock parallelism → continue to Q2.

### Q2: 「N 個元件互相獨立，wall-clock 平行有意義嗎？」

If yes → **`/team-orchestrate`**. Single message dispatches N subagents in parallel, each in its own worktree; conductor (main session) gates each branch as it returns.

If no → reconsider. The work likely fits Q1 better, or the framing is wrong.

## Brief shape → skill mapping

Use this when reading an office-hours brief or boardroom synthesis:

| Brief shape | Skill |
|---|---|
| "Ship X in 1-2 hr; iteration expected" | `/sprint` |
| "These N steps in order" | N × `/sprint` (run sequentially) |
| "These N branches can advance independently" | `/team-orchestrate` |
| "I need a brief / I have a fuzzy idea" | (you're earlier in the flow — `/office-hours` first) |
| "Plan critique needed" | `/boardroom` (read brief, return findings, then route per Q1-Q2) |

## Persona dispatch is orthogonal

Persona (eng-lead / design-lead / ops-lead / product-lead / ceo) is **not the same axis** as execution locus. Personas can be used in either execution mode:

| Skill | Persona usage |
|---|---|
| `/sprint` | Stage 3 detects task shape, loads ONE persona's SKILL.md as in-session lens (main session reads + applies the iron laws as cognitive frame). No subagent. |
| `/team-orchestrate` | Per-branch persona via inline-from-skill pattern (read SKILL.md → inline contract into subagent prompt → dispatch as `general-purpose`). See `lib/persona-frame.md` § "Inline-from-skill dispatch pattern". |

Persona routing table:

| Task signal | Persona skill |
|---|---|
| Code edit / refactor / debug / fix / feature impl / ship / tech stack 選型 / DB schema / API contract | `pandastack:eng-lead` |
| UX / layout / accessibility / visual hierarchy / interaction design | `pandastack:design-lead` |
| Multi-team coord / process design / SLA / runbook / handoff / on-call | `pandastack:ops-lead` |
| Feature scoping / metric / PMF / pricing / user research | `pandastack:product-lead` |
| Kill / pivot / scope cut / strategic frame / cross-axis prioritization | `pandastack:ceo` |
| Default (no clear signal) | `pandastack:eng-lead` |

(In v1.x there was a separate `architect` persona for greenfield design; folded into `eng-lead` in v2.0.0 because Panda's day-to-day is maintenance, not greenfield.)

## Anti-patterns

- ❌ Picking skill by time-box alone (1-2 hr → sprint regardless) — execution locus matters more than duration
- ❌ Picking skill by task count alone (3+ tasks → team-orchestrate regardless) — N sequential sprints beats forced parallelism for dependent work
- ❌ Pick `/sprint` then spawn multi-agent inside Stage 3 — defeats single-track discipline; that's `/team-orchestrate`
- ❌ Mixing personas in a single `/sprint` topic — sprint is single-track single-persona; if scope spans personas, split topic and run multiple sprints
- ❌ Defaulting to team-orchestrate for parallelism feel — true parallelism requires independent branches AND worktree isolation that's been smoke-tested; default to sequential sprints if unsure

## When this lib is loaded

- `office-hours` Stage 5 — read this lib to recommend next skill in the brief
- `sprint` Stage 3 — read this lib for persona routing table (single-persona in-session lens)
- `team-orchestrate` Phase 0.5 — same routing table, but for per-branch subagent dispatch
- `boardroom` Stage 4 — recommend follow-up skill after critique synthesis

## See also

- `lib/persona-frame.md` § "Inline-from-skill dispatch pattern" — operational details for subagent dispatch
- `lib/capability-probe.md` — substrate availability check, runs at start of every flow skill
