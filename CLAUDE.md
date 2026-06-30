# pandastack (plugin internal)

Personal AI operator OS for Claude Code, with Codex CLI compatibility. 23 skills (21 core / 2 ext — see `manifest.toml`) in engineering / productivity / writing / meta buckets, plus 3 documented lifecycle compositions. Skill-only: no agent dispatch, no persona sub-agents.

This file is the plugin-internal contract read by skill content. The user-facing README lives at the repo root.

## Skills (top-level surface)

Full catalog in `RESOLVER.md` at the repo root. Dev-workflow primitives:

- `/pandastack:init` — one-time project setup
- `/pandastack:grill` — adversarial requirement discovery, atomic, no brief output
- `/pandastack:office-hours` — structured 5-stage flow that produces a brief (`--quick` for pre-loaded context)
- `/pandastack:review` — parallel 3-pass review + Codex cross-check + learnings
- `/pandastack:qa` — browser-based QA with structured assertions
- `/pandastack:ship` — multi-mode (git / knowledge); default git mode = test + commit + PR
- `/pandastack:freeze` — restrict edits to specific paths (safety)
- `/pandastack:careful` — confirm before destructive actions (safety)
- `/pandastack:checkpoint` — save / resume working state snapshots

Lifecycle skills (knowledge / writing / work / retro / decision / research) listed in `RESOLVER.md`.

## Scenario flows (single-skill, internally chained)

- `/sprint` — focused 1-2h execution: dojo → grill-lite → execute → review → ship
- `/office-hours` — 5-stage intake producing a brief: load context → grill → premise challenge → alternatives → write brief
- `/boardroom` — blind parallel critique of a prepared plan: N mutually-blind critics, deduped + ranked findings, per-finding apply gate
- `/dojo` — pre-action prep (scan past sessions, surface gotchas)

## Learnings

Stored at the path configured in the project's `CLAUDE.md` or `AGENTS.md` under `## pandastack > learnings`. Default: `docs/learnings/`. Format: see `lib/learning-format.md`.

Compound logic (extract a debugging pattern / pitfall / architecture decision) is part of `/ship knowledge <path>` Stage 3 Backflow — it routes to `docs/learnings/<category>/<slug>.md` after Panda confirms. The decision-note variant of `/ship knowledge` (when path matches `decisions/`) replaces the v2.1 `/work-ship`.

## Goal mapping

`office-hours` runs a Stage 1 Goal Mapping pre-step that reads the user's goal hierarchy from memory and maps the current task to L1 (long horizon) / L2 (this season) / L3 (this week) layers. Downstream premise challenge and alternatives stages adapt to the dominant layer. See `lib/goal-mapping.md`. (Skipped under `--quick` when context is already loaded in-session.)
