---
slug: pro-15-pandastack-cli-doctor
date: 2026-06-18
type: plan
source: linear
linear: PRO-15
linear_url: https://linear.app/pdzeng/issue/PRO-15/pandastack-cli-installdoctor-interface
execution: code
status: planned
---

# PRO-15 — pandastack CLI install/doctor interface

> WHAT only. WHY lives in Linear PRO-15 and the brain decision `decisions/2026-06-15-pandastack-cli-orchestration-worker-protocol`.
> Per-task status is derived from git/checks at execute time. Do not mark a task done in this file unless the referenced check has run green.

## Goal

Create the repo-local front-door CLI a fresh user runs before using pandastack. It detects installed runtimes, checks prerequisites, and recommends a usable setup path without requiring Bun or Node to start.

## Non-goals

- Do not implement the full PRO-17 capability map yet (`pandastack.toml`, `.pandastack/local/capabilities.json`, `~/.pandastack/runtimes.json`). PRO-15 may print runtime facts, but persistent capability state belongs to PRO-17.
- Do not migrate orchestration skills to the worker protocol. That is PRO-18.
- Do not rewrite the public docs end-to-end. PRO-19 owns the new-user install docs. PRO-15 should only add CLI-facing help and minimal README pointers.
- Do not add Bun / Node / third-party Python dependencies to the bootstrap path.

## Current context

Existing relevant files:

- `scripts/bootstrap.sh` — Bash report-only fresh install probe. It checks `~/.agents/AGENTS.md`, manifest core/ext skill readiness, private overlay, and host install hints. It does not expose a stable `pandastack doctor` command.
- `plugins/pandastack/manifest.toml` — SSOT for skill tiers and public CLI dependencies.
- `scripts/agent-worker` + `plugins/pandastack/docs/agent-worker.md` — existing worker-protocol adapter. CLI orchestration must keep runtime invocation behind this adapter boundary.
- `scripts/pslib.py` — shared Python helper module for scheduler/Linear logic. PRO-15 can add a small CLI helper module here only if it stays generic and stdlib-only; prefer a new `scripts/psdoctor.py` if doctor logic grows.
- Existing test style is Bash harness over Python stdlib scripts: `tests/agent-worker.sh`, `tests/drive-build.sh`, `tests/linear-reduce.sh`, `scripts/conformance-smoke.sh`.

## Runtime model to expose

`pandastack doctor` output must distinguish these roles:

- **Host runtime**: where the user invokes pandastack skills. Current known hosts: Claude Code, Codex CLI, Hermes, OpenClaw planned.
- **Worker runtime**: backend that executes bounded jobs through `scripts/agent-worker`. Current production backend: Codex. Test backend: `test`.
- **Operator runtime**: scheduler/orchestrator layer. Current examples: shell/manual, launchd, Hermes cron, Claude foreground session.

Do not hardcode Panda's personal paths as required dependencies. It is fine to detect them as optional / local-profile facts.

## Proposed CLI shape

Create a single repo-local executable:

```bash
scripts/pandastack doctor [--json] [--host claude|codex|hermes|auto]
scripts/pandastack init [--host claude|codex|hermes] [--dry-run]
scripts/pandastack help
```

Public contract:

- `doctor` is read-only. It prints detected status and exact next actions. Exit 0 when it can produce a report, even if dependencies are missing. Exit nonzero only for internal errors such as unreadable manifest.
- `doctor --json` emits deterministic JSON for tests and future PRO-17 consumption.
- `init --dry-run` prints the commands it would run, without mutation.
- `init` may remain conservative in PRO-15: it can print host-specific install commands and refuse mutation unless the implementation can do it safely. The acceptance criterion is install-flow/front-door, not full dotdir management.
- The command must run with Python stdlib only: `python3 scripts/pandastack doctor --json` path or an executable Python wrapper is acceptable.

## Tasks

### pro-15-T01 — Add `scripts/pandastack` CLI skeleton

- scope: `scripts/pandastack` new executable Python script, stdlib only.
- behavior:
  - argparse subcommands: `doctor`, `init`, `help`.
  - `doctor --json` returns a top-level object with `schema_version`, `repo`, `host`, `roles`, `checks`, `recommendation`, `next_actions`.
  - `doctor` text output prints the same data in a readable table/list.
  - unsupported command exits 2 with argparse help.
- acceptance:
  - `scripts/pandastack doctor --json | python3 -m json.tool >/dev/null`
  - `scripts/pandastack help` exits 0.
- depends-on: none
- status: planned

### pro-15-T02 — Manifest and substrate checks

- scope: `scripts/pandastack` and optional helper module `scripts/psdoctor.py`.
- behavior:
  - locate repo root from script path, not cwd.
  - read `plugins/pandastack/manifest.toml` without external TOML packages. Python 3.11+ has `tomllib`; for older Python, implement only the small parser needed for `[skill.<name>]`, `tier`, `requires`, and `description`.
  - check substrate files without assuming Panda's home: `~/.agents/AGENTS.md`, repo `plugins/pandastack/manifest.toml`, repo `plugins/pandastack/DISPATCH.md`, repo `plugins/pandastack/skills/`.
  - count core/ext skills from manifest and compare with disk folders enough to flag obvious drift.
- acceptance:
  - `scripts/pandastack doctor --json` reports `manifest.ok=true`, `skill_counts.core=24`, `skill_counts.ext=2` on current repo unless manifest changes intentionally.
  - If manifest path is temporarily moved in a test fixture, command exits nonzero with a clear error and no traceback.
- depends-on: pro-15-T01
- status: planned

### pro-15-T03 — Runtime detection for host / worker / operator roles

- scope: `scripts/pandastack` or `scripts/psdoctor.py`.
- behavior:
  - detect commands with `shutil.which`: `claude`, `codex`, `git`, `python3`, `bash`, `agent-browser`, `curl`, `jq`, optional `pdctx`, optional `hermes` if present.
  - derive host readiness:
    - Claude host ready if `claude` exists and plugin install command can be printed.
    - Codex host ready if `codex` exists and symlink command can be printed.
    - Hermes host status is supported-as-scheduler/host via pdctx, not first-class packaged runtime. If `pdctx` is missing, mark degraded with README pointer.
  - derive worker readiness:
    - `scripts/agent-worker` exists.
    - `codex` exists for production backend.
    - test backend always available for offline checks.
  - derive operator readiness:
    - shell/manual always available.
    - launchd only detect on Darwin by `launchctl` presence.
    - Hermes cron only informational unless a stable public CLI is available.
- acceptance:
  - JSON contains separate `roles.host`, `roles.worker`, `roles.operator` objects.
  - Text output names all three roles explicitly.
  - Missing `codex` is a worker warning, not a fatal doctor failure.
- depends-on: pro-15-T02
- status: planned

### pro-15-T04 — Recommendation engine and next actions

- scope: `scripts/pandastack` or `scripts/psdoctor.py`.
- behavior:
  - choose one `recommendation.profile`: `claude-only`, `codex-only`, `cross-runtime`, `hermes-operator`, or `bootstrap-only`.
  - rules:
    - Claude + Codex present → `cross-runtime`.
    - Claude present, Codex missing → `claude-only` with worker install suggestion.
    - Codex present, Claude missing → `codex-only`.
    - Neither present → `bootstrap-only`.
    - Hermes/pdctx present may add `operator_notes`, but should not override host profile unless no host is present.
  - next actions must be exact shell or host commands, reusing existing README/bootstrap commands:
    - Claude: `/plugin marketplace add <repo>`, `/plugin install pandastack@pandastack`, `/reload-plugins`.
    - Codex: `mkdir -p ~/.codex/skills` and `ln -sfn <repo>/plugins/pandastack/skills ~/.codex/skills/pandastack`.
    - Missing substrate: create/read `~/.agents/AGENTS.md` pointer.
- acceptance:
  - fixture tests can simulate PATH with temporary fake executables and assert expected recommendation profiles.
  - Output never requires Bun or Node as the first step.
- depends-on: pro-15-T03
- status: planned

### pro-15-T05 — `init --dry-run` and conservative install flow

- scope: `scripts/pandastack`.
- behavior:
  - `scripts/pandastack init --host claude --dry-run` prints Claude install commands and exits 0.
  - `scripts/pandastack init --host codex --dry-run` prints Codex symlink commands and exits 0.
  - `scripts/pandastack init --host hermes --dry-run` prints the current supported path and docs pointer, with degraded warning if `pdctx` is missing.
  - Non-dry-run may either execute only safe local symlink creation for Codex or refuse with a message to re-run with a future explicit flag. Pick the smaller safe implementation. Do not mutate Claude/Hermes configs in PRO-15.
- acceptance:
  - dry-run commands are deterministic and include the absolute repo path.
  - non-dry-run never touches `~/.claude`, `~/.hermes`, or shared infra without a clear explicit flag and tests.
- depends-on: pro-15-T04
- status: planned

### pro-15-T06 — Test harness

- scope: `tests/pandastack-cli.sh` new Bash test.
- behavior:
  - no network, no real Claude/Codex invocation.
  - use temporary PATH dirs with fake `claude` / `codex` executables to test recommendation profiles.
  - use temporary HOME to test substrate present/missing behavior.
  - validate JSON with `python3 -m json.tool`.
  - assert `doctor` text output contains `Host runtime`, `Worker runtime`, `Operator runtime`.
  - assert `init --dry-run` prints expected commands.
- acceptance:
  - `bash tests/pandastack-cli.sh` green.
- depends-on: pro-15-T01..T05
- status: planned

### pro-15-T07 — Wire docs and existing bootstrap pointer

- scope: `README.md`, `scripts/bootstrap.sh` only if needed.
- behavior:
  - README Quick start should mention `scripts/pandastack doctor` as the front-door command before or alongside `scripts/bootstrap.sh`.
  - Keep `scripts/bootstrap.sh` working. It may delegate messaging to `scripts/pandastack doctor` only if tests prove no regression; otherwise leave bootstrap untouched and add a pointer.
  - Do not expand PRO-19-level install docs here.
- acceptance:
  - `grep -n "scripts/pandastack doctor" README.md` finds the new command.
  - `bash scripts/bootstrap.sh` still exits 0.
- depends-on: pro-15-T06
- status: planned

### pro-15-T08 — Verification gate and Linear linkback

- scope: checks only, plus Linear comment via existing script.
- behavior:
  - run local checks:
    - `bash tests/pandastack-cli.sh`
    - `bash scripts/lint-manifest-sync.sh`
    - `bash scripts/bootstrap.sh`
    - `bash tests/agent-worker.sh`
  - review `git diff --stat` and ensure no unrelated files changed.
  - append a Linear comment to PRO-15 with branch, commit, checks, and verdict using `scripts/pandastack-linear-comment` if available.
- acceptance:
  - all commands above exit 0.
  - Linear PRO-15 has an append-only comment with the final commit/check summary.
- depends-on: pro-15-T07
- status: planned

## Implementation constraints

- Python stdlib only for `scripts/pandastack` and tests.
- Do not print env vars or secrets.
- Do not call external AI runtimes during tests.
- Do not hide missing runtime states. Missing commands should be warnings with exact next actions.
- Keep direct `codex exec` / `claude -p` usage out of flow code. Runtime calls belong in `scripts/agent-worker`; PRO-15 should only detect and recommend.

## Verification commands for the executor

```bash
bash tests/pandastack-cli.sh
bash scripts/lint-manifest-sync.sh
bash scripts/bootstrap.sh
bash tests/agent-worker.sh
```

Optional conformance smoke after the main tests, if token budget and installed hosts allow it:

```bash
bash scripts/conformance-smoke.sh hook
```

## Suggested branch and commit

```bash
git checkout -b feat/pro-15-pandastack-cli-doctor
git add scripts/pandastack tests/pandastack-cli.sh README.md scripts/bootstrap.sh docs/plans/pro-15-pandastack-cli-doctor.md
git commit -m "feat(cli): add pandastack doctor front door"
```

Do not push or open a PR without Panda's explicit approval.
