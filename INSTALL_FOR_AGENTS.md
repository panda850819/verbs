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

## Portable: hook-free skills

```bash
npx skills@latest add panda850819/verbs -a claude-code codex -g -y
```

The portable surface installs the same self-contained 14-skill payload. It does
not install marketplace metadata or any hooks. Do not install both surfaces in
one host profile; duplicate discovery makes the active skill and hook contract
ambiguous.

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
python3 scripts/verbs doctor --host codex --strict
bash scripts/conformance-smoke.sh codex
```

The Marketplace Plugin is the recommended Codex surface. For a hook-free
skill-only install, use the portable command above. A bare skill-directory
symlink is not a substitute for either documented surface.

## Migrate from v4.0.0-rc.1

`v0.5.0` started a new version epoch; the current `v0.6.0` still sorts below
`v4.0.0-rc.1`. Host package managers cannot express migration from that RC as
an upgrade. Keep an immutable RC rollback checkout and reinstall one host at a
time.

```bash
git worktree add --detach ../verbs-v4-rollback v4.0.0-rc.1
```

Claude Code:

```bash
claude plugin validate "/absolute/path/to/verbs"
claude plugin uninstall verbs@verbs --scope user --keep-data
claude plugin marketplace remove verbs --scope user
claude plugin marketplace add "/absolute/path/to/verbs" --scope user
claude plugin install verbs@verbs --scope user
```

Run `/reload-plugins`, then the Claude verification block. If verification
fails, restore the pinned RC:

```bash
claude plugin uninstall verbs@verbs --scope user --keep-data
claude plugin marketplace remove verbs --scope user
claude plugin marketplace add ../verbs-v4-rollback --scope user
claude plugin install verbs@verbs --scope user
```

Codex:

```bash
codex plugin remove verbs@verbs --json
codex plugin marketplace remove verbs
codex plugin marketplace add "/absolute/path/to/verbs" --json
codex plugin add verbs@verbs --json
```

Restart Codex, then run the Codex verification block. The same pinned checkout
is the rollback source:

```bash
codex plugin remove verbs@verbs --json
codex plugin marketplace remove verbs
codex plugin marketplace add ../verbs-v4-rollback --json
codex plugin add verbs@verbs --json
```

Remove the rollback checkout only after both hosts have passed strict parity
and a cold-start invocation.

## Migrate from v3

Do one host at a time. First pin an immutable v3.4.2 rollback checkout; the old
marketplace often points at the same moving checkout and stops being a v3 source
after it advances to Verbs.

```bash
git worktree add --detach ../pandastack-v3-rollback \
  8d9a382b74d5b3e0ef0b6e91375fab3a172a916f
```

Keep that worktree through the migration window. Add and validate the new
marketplace, then remove the v3 plugin immediately before installing Verbs.
Never enable both plugins at once.

Claude Code:

```bash
claude plugin validate "/absolute/path/to/verbs"
claude plugin marketplace add "/absolute/path/to/verbs" --scope user
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

Keep Verbs disabled while you diagnose it. Then migrate Codex.

Codex:

```bash
codex plugin marketplace add "/absolute/path/to/verbs" --json
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

Keep Verbs disabled while you diagnose it. Remove the rollback worktree only
after both hosts pass verification.

The namespace is `/verbs:*`; `/pandastack:*` has no alias. The old GitHub
repository URL redirects after the repository rename. Compatibility is limited
to the `scripts/pandastack` CLI shim and documented legacy environment-variable
reads through the 0.x release line.
Existing `~/.pandastack` lifecycle data is left untouched; Verbs does not read,
move, or delete it.

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

Maintainers prove the real installer in a disposable profile with:

```bash
bash scripts/installer-smoke.sh claude "$PWD" vX.Y.Z
bash scripts/installer-smoke.sh codex "$PWD" vX.Y.Z
```

After creating the local v0.6.0 tag, the release gate also proves upgrade and
rollback in one disposable host profile. Keep an exact v0.5.0 checkout, then
run both hosts:

```bash
git worktree add --detach ../verbs-v0.5.0 v0.5.0
bash scripts/installer-smoke.sh claude --upgrade ../verbs-v0.5.0 "$PWD"
bash scripts/installer-smoke.sh codex --upgrade ../verbs-v0.5.0 "$PWD"
```

The script uses official host installers, requires enabled inventory plus
strict parity, and performs one namespaced skill invocation. It does not copy
caches or synthesize registry/config receipts. Authentication is reused only
for the invocation: Claude loads the exact disposable installed artifact in a
fresh authenticated process; Codex uses a disposable API-key login when
`OPENAI_API_KEY` is available, otherwise it copies only `auth.json` with mode
0600. The temporary credential is removed on exit. Upgrade mode keeps one
disposable HOME across `v0.5.0 → v0.6.0 → v0.5.0`, and executes the installed
v0.6 hook contracts before rollback.
