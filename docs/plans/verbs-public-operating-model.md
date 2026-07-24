---
slug: verbs-public-operating-model
date: 2026-07-24
type: plan
source: grill
brief: docs/briefs/2026-07-24-verbs-public-operating-model.md
execution: code
status: todo
---

# Verbs public operating model — executable plan

> WHAT only. WHY is in the brief (`brief:` above). Agents read this file;
> per-task `status:` is derived from git at execute time, never hand-edited
> mid-sprint.

## Tasks

### verbs-public-operating-model-T01 — Generate the README skill catalog

- scope: `scripts/verbs`, `README.md`, `tests/verbs-sync.sh`
- acceptance: `python3 scripts/verbs sync --check && bash tests/verbs-sync.sh`
- depends-on: none
- status: todo

### verbs-public-operating-model-T02 — Rewrite the first-visit README

- scope: `README.md`
- acceptance: `rg -q '^## Why Verbs exists$' README.md && rg -q '^## How work flows$' README.md && rg -q '^## Enforcement boundaries$' README.md && rg -q 'RESOLVER\\.md' README.md`
- depends-on: verbs-public-operating-model-T01
- status: todo

### verbs-public-operating-model-T03 — Expand the RESOLVER operating model

- scope: `RESOLVER.md`, `PHILOSOPHY.md`, `DISPATCH.md`
- acceptance: `python3 tests/resolver-routes-test.py && rg -q '^## Operating model$' RESOLVER.md && rg -q 'README.*first-visit' RESOLVER.md && rg -q 'DISPATCH.*machine routing' RESOLVER.md && rg -q 'manifest.*skill catalog' RESOLVER.md`
- depends-on: none
- status: todo

### verbs-public-operating-model-T04 — Lock drift checks and verify

- scope: `scripts/lint-manifest-sync.sh`, `tests/verbs-sync.sh`, `tests/resolver-routes-test.py`, documentation files changed by T01-T03
- acceptance: `bash tests/run-all.sh && git diff --check`
- depends-on: verbs-public-operating-model-T01, verbs-public-operating-model-T02, verbs-public-operating-model-T03
- status: todo
