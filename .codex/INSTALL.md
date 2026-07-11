# Install Verbs in Codex

See [`INSTALL_FOR_AGENTS.md`](../INSTALL_FOR_AGENTS.md) for the install and
migration source of truth.

Recommended Marketplace Plugin:

```bash
codex plugin marketplace add panda850819/verbs --json
codex plugin add verbs@verbs --json
```

It registers SessionStart dispatch, the Bash PreToolUse destructive guard, and
the Stop verification gate.

Local checkout for development:

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

Portable, hook-free alternative:

```bash
npx skills@latest add panda850819/verbs -a claude-code codex -g -y
```

The portable surface contains self-contained skills without marketplace
metadata or hooks. Do not install both surfaces in one Codex profile.

To migrate from `v4.0.0-rc.1`, follow the root guide's explicit
uninstall/reinstall path. `0.6.0` sorts below the RC and cannot be installed as
an ordinary upgrade. Do not use a bare skill-directory symlink as a substitute
for either documented surface.
