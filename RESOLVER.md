# RESOLVER.md

> Map of every active skill in Verbs. Use this as the index when something looks like overlap or you cannot tell which skill to invoke.
>
> Companion to PHILOSOPHY.md (the why) and the per-skill SKILL.md files (the how). The active tier list lives in `manifest.toml`.

## Why this file exists

Verbs ships the skills cataloged in `manifest.toml` (core + ext tiers). Each skill owns its own contract; users and hosts compose them as needed.

This is the pattern used by gstack and alirezarezvani: monorepo + RESOLVER.md beats multi-repo split, because the categorization lives next to the content.

---

## Skill catalog

### Dev workflow

| Skill | Purpose | Trigger |
|---|---|---|
| `verbs:grill` | Adversarial requirement discovery, atomic 5-10 min, surfaces unknown unknowns. Use `grill --brief` for structured-brief output. | grill me, stress test, draft a brief, structured intake |
| `verbs:codebase-design` | Deep-module design vocabulary: interface / seam / adapter / depth-as-leverage, deletion test, testable through the interface. Reference core other skills cite. | design this module, where does the seam go, interface feels too wide |
| `verbs:careful` | Confirmation gates for production / shared infra / destructive commands. | working on prod |
| `verbs:ui` | Build/fix UI with a point of view: lock direction, verify render, build past happy path, decompose cited products. NOT browser-test (`qa`) or render-bug (`debug`). | design, 做頁面, 不好看, 很醜, 排版 |
| `verbs:prototype` | Throwaway prototype answering ONE design question: logic → terminal state driver; UI → N structurally different variants behind `?variant=`. Verdict recorded, code lands on a prototype branch. NOT production UI (`ui`). | prototype this, try a few variants, does this state model feel right |
| `verbs:qa` | Browser-based UI QA. | test this UI |
| `verbs:review` | Risk-adaptive diff review with scoped evidence and cold-context escalation. | review PR |
| `verbs:debug` | Systematic root-cause debugging: root-cause gate, hypothesis-explains-every-symptom, instrument-first by bug class, bisect, scope-blast. NOT diff review (`review`) or UI taste (`ui`). | bug, crash, regression, 報錯, 跑不通, used to work |
| `verbs:ship` | Test + commit + PR in git mode. CLOSES finished work. | code done, ship it |
| `verbs:handover` | Hand unfinished work to Codex to DO: sync (spawn `codex exec` now) or `--async` (write an anchored file payload). Not `ship`, which closes finished work. | hand this to codex, let codex finish, 丟給 codex |
| `verbs:advisor` | Pull a decorrelated second opinion from a different model into the current session. `--panel` = blind cross-model critics on a prepared plan. The inbound half of the cross-runtime pair; `handover` is the outbound half. | second opinion, red-team this, 多角度審, am I sure about this |
| `verbs:sprint` | Acceptance-driven focused execution with bounded review and delivery evidence. | small focused task |

For multi-step sequential work, run multiple sprints in sequence.

Scope greenfield design (DB schema, service topology, ADRs) with `grill --brief`, then build in a sprint.

### Trust evaluation

| Skill | Purpose |
|---|---|
| `verbs:gatekeeper` | Pre-adoption trust check for external skills / MCP / repos / packages / software services. NOT a code review skill. STRIDE classification at Step 0. |

## Disambiguation

### Four review surfaces

| Surface | What it reviews |
|---|---|
| Built-in `/review` | Generic PR review |
| Built-in `/security-review` | Branch code for security issues |
| `verbs:review` | YOUR code via risk-adaptive passes, grounded findings, and earned cold review |
| `verbs:gatekeeper` | EXTERNAL agents / MCP / repos BEFORE you adopt them |

If you are reviewing your own PR -> `verbs:review`. If you are deciding whether to install someone else's MCP server or clone their skill repo -> `verbs:gatekeeper`.

### Requirement discovery

- `verbs:grill` — adversarial, one-question-at-a-time, surfaces unknown unknowns. Atomic 5-10 min, no brief output.
- `verbs:grill --brief` — the same drilling, then a structured close that writes a brief + executable plan.

## Version

This RESOLVER.md is for Verbs v0.7.3. Update it when adding, removing, or renaming skills.

---

## Aliases

Only aliases still declared by an active SKILL.md appear here. They do not alias
the retired v3 plugin namespace.

| Old name (alias) | New name | Renamed in | Grace until |
|---|---|---|---|
| `slowmist-agent-security` | `gatekeeper` | v1.1 | 2026-08-04 |
