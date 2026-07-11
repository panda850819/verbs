# Install Panda Verbs

This is the install source of truth for Claude Code and Codex. Both hosts use
the plugin id `verbs`, marketplace `verbs`, and selector `verbs@verbs`.

## Clone and inspect

```bash
git clone https://github.com/panda850819/panda-verbs.git
cd panda-verbs
python3 scripts/verbs doctor --json
bash scripts/bootstrap.sh
```

`doctor` checks the manifest, host registrations, enabled install receipts, and
packaged source/cache parity. `bootstrap` reports the core and extension skills
plus their optional CLI requirements. Neither command changes host configuration.

## Install in Claude Code

```bash
cd /absolute/path/to/panda-verbs
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

## Install in Codex

```bash
cd /absolute/path/to/panda-verbs
codex plugin marketplace add "$PWD" --json
codex plugin add verbs@verbs --json
```

Restart Codex, then verify:

```bash
codex plugin list --json
python3 scripts/verbs doctor --host codex --strict
bash scripts/conformance-smoke.sh codex
```

Codex plugin install is the supported path. A bare skill-directory symlink does
not install marketplace metadata or the complete packaged surface.

## Migrate from v3

Do one host at a time. First pin an immutable v3.4.2 rollback checkout; the old
marketplace often points at the same moving checkout and stops being a v3 source
after it advances to v4.

```bash
git worktree add --detach ../pandastack-v3-rollback \
  8d9a382b74d5b3e0ef0b6e91375fab3a172a916f
```

Keep that worktree through the RC dogfood window. Add and validate the new
marketplace, then remove the v3 plugin immediately before installing v4. Never
enable both plugins at once.

Claude Code:

```bash
claude plugin validate "/absolute/path/to/panda-verbs"
claude plugin marketplace add "/absolute/path/to/panda-verbs" --scope user
claude plugin uninstall pandastack@pandastack --scope user --keep-data
claude plugin install verbs@verbs --scope user
```

Run `/reload-plugins` and the Claude verification block. Only after it passes:

```bash
claude plugin marketplace remove pandastack --scope user
```

If install or verification fails, repoint the old marketplace to the pinned
checkout and reinstall v3:

```bash
claude plugin marketplace remove pandastack --scope user
claude plugin marketplace add ../pandastack-v3-rollback --scope user
claude plugin install pandastack@pandastack --scope user
```

Keep v4 disabled while you diagnose it. Then migrate Codex.

Codex:

```bash
codex plugin marketplace add "/absolute/path/to/panda-verbs" --json
codex plugin remove pandastack@pandastack --json
codex plugin add verbs@verbs --json
```

Restart Codex and run the Codex verification block. Only after it passes:

```bash
codex plugin marketplace remove pandastack
```

If install or verification fails, repoint the old marketplace and reinstall:

```bash
codex plugin marketplace remove pandastack
codex plugin marketplace add ../pandastack-v3-rollback --json
codex plugin add pandastack@pandastack --json
```

Keep v4 disabled while you diagnose it. Remove the rollback worktree only after
the RC dogfood window succeeds.

The v4 namespace is `/verbs:*`; `/pandastack:*` has no alias. The old GitHub
repository URL redirects after the repository rename. RC compatibility is
limited to the `scripts/pandastack` CLI shim and the documented verify-gate env
fallback. Existing `~/.pandastack` lifecycle data is left untouched; v4 does
not read, move, or delete it.

## Verify a checkout

```bash
python3 scripts/verbs sync --check
claude plugin validate .
bash tests/run-all.sh
```

The full suite is deterministic and offline. Failed test output is written to
`/tmp/panda-verbs-test-<name>.log`. On a slower machine:

```bash
PANDA_VERBS_TEST_TIMEOUT=300 bash tests/run-all.sh
```

Use `python3 scripts/verbs init --host <claude|codex|hermes> --dry-run` to print
the local install commands without changing the host.

Maintainers prove the real installer in a disposable profile with:

```bash
bash scripts/installer-smoke.sh claude "$PWD" vX.Y.Z
bash scripts/installer-smoke.sh codex "$PWD" vX.Y.Z
```

The script uses official host installers, requires enabled inventory plus
strict parity, and performs one namespaced skill invocation. It does not copy
caches or synthesize registry/config receipts. Authentication is reused only
for the invocation: Claude loads the exact disposable installed artifact in a
fresh authenticated process; Codex copies only `auth.json` into the temporary
profile with mode 0600 and removes it on exit.
