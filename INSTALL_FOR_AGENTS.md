# Install Verbs

This is the install source of truth for Claude Code and Codex. Choose exactly
one install surface per host profile. The recommended Marketplace Plugin uses
the plugin id `verbs`, marketplace `verbs`, and selector `verbs@verbs`.

## Recommended: Marketplace Plugin

Claude Code:

```bash
claude plugin marketplace add panda850819/verbs --scope user
claude plugin install verbs@verbs --scope user
```

Codex:

```bash
codex plugin marketplace add panda850819/verbs --json
codex plugin add verbs@verbs --json
```

These remote marketplace commands were verified in disposable profiles. The
Marketplace Plugin registers the SessionStart dispatch adapter, Bash PreToolUse
destructive guard, and Stop verification gate.

## Clone and inspect source

```bash
git clone https://github.com/panda850819/verbs.git
cd verbs
python3 scripts/verbs doctor --json
bash scripts/bootstrap.sh
```

`doctor` checks the manifest, host registrations, enabled install receipts, and
packaged source/cache parity. `bootstrap` reports the core and extension skills
plus their optional CLI requirements. Neither command changes host configuration.

## Install the Marketplace Plugin in Claude Code

```bash
cd /absolute/path/to/verbs
claude plugin validate .
claude plugin marketplace add "$PWD" --scope user
claude plugin install verbs@verbs --scope user
```

Run `/reload-plugins` in Claude Code, then verify:

```bash
claude plugin list --json
python3 scripts/verbs doctor --host claude --strict
bash scripts/conformance-smoke.sh claude
```

The strict check includes plugin version, skill set, `DISPATCH.md`, and the
registered hook tree.

## Install the Marketplace Plugin in Codex

```bash
cd /absolute/path/to/verbs
codex plugin marketplace add "$PWD" --json
codex plugin add verbs@verbs --json
```

Restart Codex, then verify:

```bash
codex plugin list --json
python3 scripts/verbs doctor --host codex --strict --live-hooks
bash scripts/conformance-smoke.sh codex
```

The Marketplace Plugin is the recommended Codex surface. A bare skill-directory
symlink is not a substitute for it.

## Migrations

The v3 (`pandastack@pandastack`) and `v4.0.0-rc.1` migrations are complete.
Their step-by-step uninstall/reinstall paths live in git history and
`CHANGELOG.md`. The namespace is `/verbs:*`; `/pandastack:*` has no alias.
Compatibility is limited to the `scripts/pandastack` CLI shim and documented
legacy environment-variable reads through the 0.x release line. Existing
`~/.pandastack` lifecycle data is left untouched; Verbs does not read, move,
or delete it.

## Verify a checkout

```bash
python3 scripts/verbs sync --check
claude plugin validate .
bash tests/run-all.sh
```

The full suite is deterministic and offline. Failed test output is written to
`/tmp/verbs-test-<name>.log`. On a slower machine:

```bash
VERBS_TEST_TIMEOUT=300 bash tests/run-all.sh
```

Use `python3 scripts/verbs init --host <claude|codex|hermes> --dry-run` to print
the local install commands without changing the host.
