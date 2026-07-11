# Install Verbs in Codex

See [`INSTALL_FOR_AGENTS.md`](../INSTALL_FOR_AGENTS.md) for the install and
migration source of truth.

Local checkout:

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

To migrate from `v4.0.0-rc.1`, follow the root guide's explicit
uninstall/reinstall path. `0.5.0` sorts below the RC and cannot be installed as
an ordinary upgrade. Do not use a skill-directory symlink as a plugin
substitute; it omits marketplace metadata.
Verbs registers no automatic hooks. Reference adapters under `hooks/` run only
when a host wires them explicitly.
