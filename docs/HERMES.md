# Verbs on Hermes

Hermes supports selective manual import only. Verbs does not ship a
Hermes manifest, hooks adapter, or packaged parity.

Import only the skills you have checked against Hermes' tool vocabulary:

```bash
mkdir -p "$HOME/.hermes/skills"
ln -sfn /absolute/path/to/verbs/skills/productivity/grill \
  "$HOME/.hermes/skills/grill"
ln -sfn /absolute/path/to/verbs/skills/engineering/review \
  "$HOME/.hermes/skills/review"
```

Repeat per selected skill. Then start a fresh Hermes session and verify that the
skill name and its required tools resolve.

Hermes owns its own orchestration, scheduling, memory, messages, session policy,
and tool translation. Imported skills do not receive Verbs reference
adapters automatically.
Skills that require unavailable tools remain unsupported on that host.

Update the checkout with `git pull`; the symlinked skill content updates in
place. Re-run the same real invocation after any skill or Hermes upgrade.
