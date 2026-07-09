# pandastack (plugin internal)

Personal AI operator OS for Claude Code, with Codex CLI compatibility. Skills tiered core / ext (see `manifest.toml`) in engineering / productivity / writing / meta buckets, plus 3 documented lifecycle compositions. Skill-only: no agent dispatch, no persona sub-agents.

This file is the plugin-internal contract read by skill content. The user-facing README lives at the repo root.

## Skills (top-level surface)

Full catalog in `RESOLVER.md` at the repo root. Dev-workflow primitives:

- `/pandastack:grill` — adversarial requirement discovery, atomic, no brief output
- `/pandastack:grill --brief` — structured close that produces a brief + executable plan
- `/pandastack:advisor --panel` — blind cross-model critique of a prepared plan
- `/pandastack:review` — parallel 3-pass review + Codex cross-check + learnings
- `/pandastack:qa` — browser-based QA with structured assertions
- `/pandastack:ship` — multi-mode (git / knowledge); default git mode = test + commit + PR
- `/pandastack:careful` — confirm before destructive actions (safety)

Lifecycle skills: knowledge (`/ship knowledge`) and writing (`/write`), cataloged in `RESOLVER.md`. work / research / decision are documented as variants, not first-class flows; retro moved to the personal overlay (2026-06-30).

## Scenario flows (single-skill, internally chained)

- `/sprint` — focused 1-2h execution: scope → grill-lite → execute → review → ship
- `/grill --brief` — adversarial intake followed by a written brief + executable plan
- `/advisor --panel` — blind cross-model critique of a prepared plan, deduped + ranked findings, per-finding apply gate

## Learnings

Stored at the path configured in the project's `CLAUDE.md` or `AGENTS.md` under `## pandastack > learnings`. Default: `docs/learnings/`. Format: see `lib/learning-format.md`.

Compound logic (extract a debugging pattern / pitfall / architecture decision) is part of `/ship knowledge <path>` Stage 3 Backflow — it routes to `docs/learnings/<category>/<slug>.md` after Panda confirms. The decision-note variant of `/ship knowledge` (when path matches `decisions/`) replaces the v2.1 `/work-ship`.

## Goal mapping

`grill --brief` can use the Goal Mapping helper in `lib/goal-mapping.md` when a brief needs to map the current task to L1 (long horizon) / L2 (this season) / L3 (this week) layers.

## pandastack

test: bash tests/run-all.sh
main: main
tag: none
release: false
deploy: null
learnings: docs/learnings
