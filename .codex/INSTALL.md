# Install Panda Verbs in Codex

See [`INSTALL_FOR_AGENTS.md`](../INSTALL_FOR_AGENTS.md) for the install and v3
migration source of truth.

Local checkout:

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

To migrate, follow the rollback-safe order in the root install guide: add the
new marketplace, remove the old plugin, install and verify v4, then remove the
old marketplace. Do not use a skill-directory symlink as a plugin substitute;
it omits marketplace metadata.
Panda Verbs v4 registers no automatic hooks. Reference adapters under `hooks/`
run only when a host wires them explicitly.
