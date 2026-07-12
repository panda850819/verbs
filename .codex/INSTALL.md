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
python3 scripts/verbs doctor --host codex --strict --live-hooks
bash scripts/conformance-smoke.sh codex
```

Do not use a bare skill-directory symlink as a substitute for the documented
surface. Historical v3/RC migration paths live in the root guide's git history.
