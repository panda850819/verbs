# RESOLVER.md

> Map of every active skill in pandastack. Use this as the index when something looks like overlap or you cannot tell which skill to invoke.
>
> Companion to PHILOSOPHY.md (the why) and the per-skill SKILL.md files (the how). The active tier list lives in `manifest.toml`.

## Why this file exists

pandastack ships the skills cataloged in `manifest.toml` (core + ext tiers). Lifecycle flows are no longer first-class constructs. What used to live in `flows/*.md` is now either documented inline in the relevant skill (sprint covers dev, ship knowledge covers knowledge close) or demoted because it was not really a flow.

This is the pattern used by gstack and alirezarezvani: monorepo + RESOLVER.md beats multi-repo split, because the categorization lives next to the content.

---

## Skill catalog

### Knowledge

| Skill | Purpose | Trigger |
|---|---|---|
| `pandastack:ship knowledge <path>` | Close + Extract + Backflow on a knowledge note, including the decision-note variant for work-topic close. | ship this note, close out this decision |

Vault hygiene (orphans / stale / superseded / dead redirects) is a direct file scan (`rg` / `find`) or, when `gbrain` is connected, a brain query. It is not a dedicated pandastack skill.

### Writing

| Skill | Purpose | Trigger |
|---|---|---|
| `pandastack:write` | Voice-aware drafting + slop detection. | help me write |

Daily cadence writing skills require private CLIs and live outside the public package.

### Dev workflow

| Skill | Purpose | Trigger |
|---|---|---|
| `pandastack:grill` | Adversarial requirement discovery, atomic 5-10 min, surfaces unknown unknowns. Use `grill --brief` for structured-brief output. | grill me, stress test, draft a brief, structured intake |
| `pandastack:careful` | Confirmation gates for production / shared infra / destructive commands. | working on prod |
| `pandastack:ui` | Build/fix UI with a point of view: lock direction, verify render, build past happy path, decompose cited products. NOT browser-test (`qa`) or render-bug (`debug`). | design, 做頁面, 不好看, 很醜, 排版 |
| `pandastack:qa` | Browser-based UI QA. | test this UI |
| `pandastack:review` | Parallel 3-pass review + Codex cross-check. | review PR |
| `pandastack:debug` | Systematic root-cause debugging: root-cause gate, hypothesis-explains-every-symptom, instrument-first by bug class, bisect, scope-blast. NOT diff review (`review`) or UI taste (`ui`). | bug, crash, regression, 報錯, 跑不通, used to work |
| `pandastack:ship` | Test + commit + PR in git mode. CLOSES finished work. | code done, ship it |
| `pandastack:handover` | Hand unfinished work to Codex to DO: sync (spawn `codex exec` now) or `--async` (write payload for Hermes). Not `ship`, which closes finished work. | hand this to codex, let codex finish, 丟給 codex |
| `pandastack:advisor` | Pull a decorrelated second opinion from a different model into the current session. `--panel` = blind cross-model critics on a prepared plan. The inbound half of the cross-runtime pair; `handover` is the outbound half. | second opinion, red-team this, 多角度審, am I sure about this |
| `pandastack:sprint` | Single-track 1-2h focused execution: scope -> grill-lite -> execute -> review -> ship. `--delegate codex` delegates a >=3-unit batch via `handover`. | small focused task |

For multi-step sequential work, run multiple sprints in sequence.

Greenfield design (DB schema / service topology / ADRs) is rare for Panda's maintenance-heavy work. Scope it with `grill --brief`, then build in a sprint.

### Trust evaluation

| Skill | Purpose |
|---|---|
| `pandastack:gatekeeper` | Pre-adoption trust check for external agents / MCP / repos / on-chain. NOT a code review skill. STRIDE classification at Step 0. |

### Meta / skill authoring

| Skill | Purpose | Trigger |
|---|---|---|
| `pandastack:skill-creator` | Create new pandastack skills. MECE-checks RESOLVER, enforces hot/cold dispatch, applies trigger-first skill evolution, and `--eval` scores existing skills. | create a skill, new pandastack skill, improve this skill, eval this skill, score this skill |
| `pandastack:writing-great-skills` | Reference + scorecard for well-constructed skills. The construction-quality SSOT (scores the SKILL.md, not its artifact). `skill-creator --eval` binds it. | how do I write a skill, what makes a skill good |

Project setup is manual now: add the project `AGENTS.md` / `CLAUDE.md` contract directly when a repo needs one.

---

## Private supplement

Some lifecycles (work alert triage, on-chain trading research, cadence skills, and owned-account readers) are not in this public index because they need private CLIs. The public index above stays self-contained: anything you can read here, you can install from this repo alone.

---

## Disambiguation

### Four review surfaces

| Surface | What it reviews |
|---|---|
| Built-in `/review` | Generic PR review |
| Built-in `/security-review` | Branch code for security issues |
| `pandastack:review` | YOUR code via parallel 3-pass + Codex cross-check |
| `pandastack:gatekeeper` | EXTERNAL agents / MCP / repos BEFORE you adopt them |

If you are reviewing your own PR -> `pandastack:review`. If you are deciding whether to install someone else's MCP server or clone their skill repo -> `pandastack:gatekeeper`.

### Requirement discovery

- `pandastack:grill` — adversarial, one-question-at-a-time, surfaces unknown unknowns. Atomic 5-10 min, no brief output.
- `pandastack:grill --brief` — the same drilling, then a structured close that writes a brief + executable plan.

### Two ship modes

`/ship` is one skill with two modes:

| Mode | Trigger | What it does |
|---|---|---|
| git (default) | `/ship` (no args) or `/ship <branch-flag>` | test + commit + push + PR |
| knowledge | `/ship knowledge <path>` or `/ship knowledge/...` or `/ship decisions/...` | Close + Extract + Backflow on a knowledge note. Decision-note variant handles work-topic close and writes `Inbox/ship-proposals/` markdown for manual external push. |

---

## Lifecycle map

3 documented compositions, no separate flow specs:

| Composition | Driver / chain | Where the lifecycle is documented |
|---|---|---|
| dev | `/sprint` (1-2h) or manual `/grill --brief` -> `/careful` -> build -> `/qa` -> `/review` -> `/ship` | `skills/engineering/sprint/SKILL.md` + README "Lifecycle map" |
| writing | `/write` -> manual publish | `skills/writing/write/SKILL.md` + README "Lifecycle map" |
| knowledge | direct write to vault -> `/ship knowledge <path>` | `skills/engineering/ship/modes/knowledge.md` + README "Lifecycle map" |

What used to be `flows/<name>.md` is gone. Reasons:
- dev: `/sprint` is the executable spec; the long-form flow spec was duplicate.
- writing, knowledge: their lifecycles are short enough to fit inside their respective skill / mode files.
- research: not a real flow; it is a knowledge variant.
- work: not a real flow; it is a dev variant + decision-note variant of `/ship knowledge`.
- decision: not a flow; it is an async autonomy contract.
- retro: moved to the personal overlay on 2026-06-30.

---

## Version

This RESOLVER.md is for pandastack v3.4.0. Update when adding, removing, or renaming skills.

---

## Aliases

The following old names still matter in user-facing compatibility text. Remove hardcoded references in cron jobs, launchd plists, or Hermes manifests before grace dates.

| Old name (alias) | New name | Renamed in | Grace until |
|---|---|---|---|
| `work-ship` | `ship knowledge <decisions/path>` | v2.2.0 (2026-05-09) | 2026-08-07 |
| `knowledge-ship` | `ship knowledge` | v2.0.0 (2026-05-07) | 2026-08-05 |
| `write-ship` | n/a (`ship write` mode retired 2026-06-12, Blog tree gone post-rebuild) | v2.0.0 (2026-05-07) | retired 2026-06-12 |
| `tool-bird` | `bird` (now in private overlay) | v1.4.0 | 2026-08-05 |
| `tool-browser` | n/a (`agent-browser` archived 2026-06-08) | v1.4.0 | n/a after archive |
| `tool-slack` / `tool-notion` / `tool-summarize` | n/a (skills cut in v2.2.0) | v1.4.0 | n/a after cut |
| `agent-browser` | `tool-browser` | v1.1 (then reverted in v1.4.0) | n/a |
| `content-write` | `write` | v1.1 | expired 2026-08-04 |
| `feed-curator` | `curate-feeds` (now in private overlay) | v1.1 | expired 2026-08-04 |
| `harness-survey` | `scout` (cut v2.2.0) | v1.1 | expired 2026-08-04 |
| `morning-briefing` | `brief-morning` (now in private overlay) | v1.1 | expired 2026-08-04 |
| `slowmist-agent-security` | `gatekeeper` | v1.1 | expired 2026-08-04 |
| `weekly-retro-prep` | n/a | v1.1 -> cut v2.0.0 | n/a |
