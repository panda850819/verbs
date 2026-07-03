# Install for Agents

Execute this from a fresh clone of pandastack. Do not invent a second install
path: `scripts/bootstrap.sh`, `scripts/pandastack`, and `manifest.toml` are the
current sources of truth.

## 1. Preconditions Probe

Run these commands from anywhere inside the clone:

```bash
cd "$(git rev-parse --show-toplevel)"
command -v git
python3 scripts/pandastack doctor --host auto
bash scripts/bootstrap.sh
```

Interpret the output:

- `git rev-parse` prints the repo root. If it fails, you are not in a git clone.
- `command -v git` prints a path. If it fails, install Git first.
- `python3 scripts/pandastack doctor --host auto` detects Claude Code, Codex CLI,
  Hermes, the shell/manual operator, and manifest drift.
- `bash scripts/bootstrap.sh` reads `manifest.toml`, lists core skills that run
  from the clone, lists ext skills with public CLI dependencies, and prints the
  host-specific next step.

The manifest tier model is:

- `core`: markdown-only skills. A fresh clone plus host install should load them.
- `ext`: public CLI-backed skills. `bootstrap.sh` prints the missing public
  install command for each dependency.

## 2. Install Path Per Runtime

Run exactly one dry-run for the runtime you are installing. Then paste the
printed runtime lines into that runtime or shell.

Claude Code:

```bash
python3 scripts/pandastack init --host claude --dry-run
```

The dry-run prints the Claude plugin marketplace path, including
`/plugin install pandastack@pandastack`, followed by `/reload-plugins`.

Codex CLI:

```bash
python3 scripts/pandastack init --host codex --dry-run
```

The dry-run prints the Codex skill-dir install. Today this is clone plus symlink
into `~/.codex/skills/pandastack`, then restart Codex CLI.

Hermes or another host:

```bash
python3 scripts/pandastack init --host hermes --dry-run
```

Hermes is direct skill import. For an unsupported host, use
`docs/ADDING_A_HOST.md` and keep the shared content canonical in this repo.

## 3. Verification

Run the deterministic offline gates:

```bash
bash tests/lint-suite.sh && bash tests/run-all.sh
```

Interpret the output:

- Success means `lint-suite: all offline linters passed` and `run-all.sh` ends
  with `0 failed`.
- A linter failure is a real structural drift signal. Fix the named file or
  stale eval, then rerun the same command.
- A test failure writes per-test output under `/tmp/pstest-<name>.log`.

For slower machines, rerun the full suite with a longer timeout:

```bash
PSTEST_TIMEOUT=300 bash tests/run-all.sh
```

## 4. Failure Table

| Symptom | Paste-ready fix command |
|---|---|
| You are inside the clone but not at the repo root | `cd "$(git rev-parse --show-toplevel)"` |
| Unsure which host runtime is visible | `python3 scripts/pandastack doctor --host auto` |
| Need Claude Code install lines again | `python3 scripts/pandastack init --host claude --dry-run` |
| Need Codex CLI install lines again | `python3 scripts/pandastack init --host codex --dry-run` |
| Need Hermes import lines again | `python3 scripts/pandastack init --host hermes --dry-run` |
| Need to re-check core/ext dependency state | `bash scripts/bootstrap.sh` |
| Offline structural lint failed | `bash tests/lint-suite.sh` |
| Full deterministic suite failed | `bash tests/run-all.sh` |
| Full deterministic suite timed out | `PSTEST_TIMEOUT=300 bash tests/run-all.sh` |
