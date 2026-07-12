# lib/skill-decision-tree.md — Workflow shape → execution skill

> Shared module. Loaded by `grill --brief` and any skill that recommends the next execution step.
>
> Origin: 2026-05-05 — structured briefs did not point to the next skill. The current split is foreground judgment (`sprint`) versus a planned mechanical batch (`handover`).

## The sharp distinction: execution locus

Pick by **who executes**:

| Skill | Main session role | Executor | Context isolation | Time ordering |
|---|---|---|---|---|
| `/sprint` | **Executor itself** | Main session (you + the AI in same context) | None — same context throughout | N/A (single track) |
| `/handover` | **Orchestrator** | One bounded Codex batch | Fresh delegated context | Returns one structured result |

For multi-step sequential work without parallelism, run multiple sprints in sequence. There is no dedicated "sequential subagent coordinator" skill — that ceremony cost more than it saved.

## Q0: Should this even be a skill? (refuse-to-build escape hatch)

Before routing a workflow to an execution skill — and before proposing any new
skill — ask whether the thing should be a skill **at all**. Refusing to
build is a valid, non-failure outcome; it is the cheapest place to stop skill
sprawl, upstream of the MECE check.

- **It's knowledge, not a workflow → a knowledge note, not a skill.** A fact, a
  decision, a reference, or a checklist someone reads once belongs in the
  owner's configured knowledge store. Skills are *executed*; notes are *read*.
- **It's one deterministic step → a one-line script / alias, not a skill.** If the
  whole capability is `grep`/`jq`/a single CLI invocation with no judgment, a
  script (or a `lib/` helper) beats a SKILL.md. A skill's overhead (frontmatter,
  trigger surface, index slot, resolver row) only pays off when there is real
  routing + judgment to host.
- **Only if it survives both** — a multi-step workflow needing in-context judgment
  or dispatch — continue to the 2-question test below.

This is an outcome, not an error: "this should be a knowledge note / one-line script,
not a skill" is a correct answer that keeps the corpus lean.

## 2-question decision test

Ask in order. First Yes wins.

### Q1: 「我要不要邊做邊 iterate / debug / 改方向？」OR 「這只是一件事？」

If yes → **`/sprint`**. Reason: iteration is cheap when the executor is in-session. For multi-step sequential work, run multiple sprints in sequence — each sprint owns one task end-to-end.

If no, continue to Q2.

### Q2: 「已有可驗收的 plan，且至少三個 unit 都是 file-scoped mechanical work 嗎？」

If yes → **`/handover`**. The foreground session keeps planning, review, and git ownership while Codex executes the bounded batch.

If no → reconsider. The work likely fits Q1 better, or the framing is wrong.

## Brief shape → skill mapping

Use this when reading a `grill --brief` brief:

| Brief shape | Skill |
|---|---|
| "Ship X in 1-2 hr; iteration expected" | `/sprint` |
| "These N steps in order" | N × `/sprint` (run sequentially) |
| "These ≥3 planned units are mechanical and file-scoped" | `/handover` |
| "I need a brief / I have a fuzzy idea" | (you're earlier in the flow — `/grill --brief` first) |

## Anti-patterns

- ❌ Picking skill by time-box alone (1-2 hr → sprint regardless) — execution locus matters more than duration
- ❌ Picking by task count alone — handover also requires a prepared plan, mechanical scope, and runnable acceptance checks
- ❌ Handing judgment-heavy or exploratory work to `/handover` — keep it in `/sprint`
- ❌ Using `/handover` as a generic parallelism layer — host-native subagent policy stays outside this pack

## When this lib is loaded

- `grill --brief` — read this lib to recommend next skill in the brief
- Any skill that must recommend foreground execution versus bounded delegation
