# RESOLVER.md

> Map of every active skill in Verbs. Use this as the index when something looks like overlap or you cannot tell which skill to invoke.
>
> Companion to PHILOSOPHY.md (the why) and the per-skill SKILL.md files (the how). The active tier list lives in `manifest.toml`.

## Why this file exists

Verbs ships the skills cataloged in `manifest.toml` (core + ext tiers). Each skill owns its own contract; users and hosts compose them as needed.

This is the pattern used by gstack and alirezarezvani: monorepo + RESOLVER.md beats multi-repo split, because the categorization lives next to the content.

---

## Skill catalog

### Writing

| Skill | Purpose | Trigger |
|---|---|---|
| `verbs:write` | Voice-aware drafting + slop detection. | help me write |

Cadence automation and private-CLI workflows are outside this package.

### Dev workflow

| Skill | Purpose | Trigger |
|---|---|---|
| `verbs:grill` | Adversarial requirement discovery, atomic 5-10 min, surfaces unknown unknowns. Use `grill --brief` for structured-brief output. | grill me, stress test, draft a brief, structured intake |
| `verbs:careful` | Confirmation gates for production / shared infra / destructive commands. | working on prod |
| `verbs:ui` | Build/fix UI with a point of view: lock direction, verify render, build past happy path, decompose cited products. NOT browser-test (`qa`) or render-bug (`debug`). | design, 做頁面, 不好看, 很醜, 排版 |
| `verbs:qa` | Browser-based UI QA. | test this UI |
| `verbs:review` | Parallel 3-pass review + cross-model adversarial check. | review PR |
| `verbs:debug` | Systematic root-cause debugging: root-cause gate, hypothesis-explains-every-symptom, instrument-first by bug class, bisect, scope-blast. NOT diff review (`review`) or UI taste (`ui`). | bug, crash, regression, 報錯, 跑不通, used to work |
| `verbs:ship` | Test + commit + PR in git mode. CLOSES finished work. | code done, ship it |
| `verbs:handover` | Hand unfinished work to Codex to DO: sync (spawn `codex exec` now) or `--async` (write an anchored file payload). Not `ship`, which closes finished work. | hand this to codex, let codex finish, 丟給 codex |
| `verbs:advisor` | Pull a decorrelated second opinion from a different model into the current session. `--panel` = blind cross-model critics on a prepared plan. The inbound half of the cross-runtime pair; `handover` is the outbound half. | second opinion, red-team this, 多角度審, am I sure about this |
| `verbs:sprint` | Single-track 1-2h focused execution: scope -> grill-lite -> execute -> review -> ship. `--delegate codex` delegates a >=3-unit batch via `handover`. | small focused task |

For multi-step sequential work, run multiple sprints in sequence.

Scope greenfield design (DB schema, service topology, ADRs) with `grill --brief`, then build in a sprint.

### Trust evaluation

| Skill | Purpose |
|---|---|
| `verbs:gatekeeper` | Pre-adoption trust check for external skills / MCP / repos / packages / software services. NOT a code review skill. STRIDE classification at Step 0. |

### Meta / skill authoring

| Skill | Purpose | Trigger |
|---|---|---|
| `verbs:skill-creator` | Create new Verbs skills. MECE-checks RESOLVER, enforces hot/cold dispatch, applies trigger-first skill evolution, and `--eval` scores existing skills. | create a skill, new Verbs skill, improve this skill, eval this skill, score this skill |
| `verbs:writing-great-skills` | Reference + scorecard for well-constructed skills. The construction-quality SSOT (scores the SKILL.md, not its artifact). `skill-creator --eval` binds it. | how do I write a skill, what makes a skill good |

## Disambiguation

### Four review surfaces

| Surface | What it reviews |
|---|---|
| Built-in `/review` | Generic PR review |
| Built-in `/security-review` | Branch code for security issues |
| `verbs:review` | YOUR code via parallel 3-pass + cross-model adversarial check |
| `verbs:gatekeeper` | EXTERNAL agents / MCP / repos BEFORE you adopt them |

If you are reviewing your own PR -> `verbs:review`. If you are deciding whether to install someone else's MCP server or clone their skill repo -> `verbs:gatekeeper`.

### Requirement discovery

- `verbs:grill` — adversarial, one-question-at-a-time, surfaces unknown unknowns. Atomic 5-10 min, no brief output.
- `verbs:grill --brief` — the same drilling, then a structured close that writes a brief + executable plan.

## Version

This RESOLVER.md is for Verbs v0.5.0. Update it when adding, removing, or renaming skills.

---

## Aliases

Only aliases still declared by an active SKILL.md appear here. They do not alias
the retired v3 plugin namespace.

| Old name (alias) | New name | Renamed in | Grace until |
|---|---|---|---|
| `content-write` | `write` | v1.1 | 2026-08-04 |
| `slowmist-agent-security` | `gatekeeper` | v1.1 | 2026-08-04 |
