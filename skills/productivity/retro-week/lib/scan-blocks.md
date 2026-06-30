# Phase 1 scan blocks — what the engine gathers (manual fallback)

`retro-scan.sh week` produces all of these. This ref documents what each block
holds for transparency, and the manual commands to run if the engine is
unavailable. The skill's Phase 1 reads the engine's brief; only fall back here
if `retro-scan.sh` cannot run.

### 1a. Git activity (past 7 days)

Engine runs `git log` over the brain repo and every repo matched by `PANDASTACK_SCAN_PATHS` (default `~/site/{skills,apps,cli,trading}/*`; unset on a fresh install → scans the brain only). Summarize: total commits across repos, key deliverables by repo name.

### 1b. Learnings health — `brain/learnings/`

Engine counts total / new-this-week / stale(90d+) under `$PANDASTACK_BRAIN/learnings/` (default `~/site/knowledge/brain/learnings/`). If missing, it notes "learnings/ not found — skip".

### 1c. Recent brain activity — past 7 days

Engine lists recently-touched pages under `brain/sessions`, `brain/decisions`, `brain/reflections/daily`, `brain/plans`, `brain/projects`. Capture: key decisions, shipped work, open threads.
