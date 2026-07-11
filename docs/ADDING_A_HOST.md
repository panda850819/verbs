# Adding a Host to Panda Verbs

A host adapter makes the existing skill pack discoverable in one runtime. It
does not add orchestration, memory, scheduling, identity, or project state to
Panda Verbs.

## Sources of truth

- `manifest.toml` owns product identity, version, and the active skill set.
- `scripts/verbs sync` generates the Claude, Codex, and Agents loader metadata.
- `DISPATCH.md` owns public routing.
- `hooks/` contains reference adapters. No hook is registered automatically.
- Each `SKILL.md` owns its workflow and tool assumptions.

Do not fork skill content merely to rename tools. Keep any translation in the
adapter and state the unsupported cases.

## Adapter contract

Before claiming support, define:

| Field | Required answer |
|---|---|
| Install | Reproducible add, update, and remove commands |
| Discovery | How the host exposes exactly the manifest skill set |
| Namespace | Whether the host displays `verbs:<name>` or plain names |
| Tools | Explicit mapping for read, edit, shell, browser, and delegation |
| Hooks | Which reference adapters, if any, the host enables explicitly |
| Boundary | Native, degraded, selective, experimental, or unsupported |

The adapter may support a subset, but it must not imply parity for skills or
adapters it does not enable.

## Verification gate

A host becomes supported only after all of these pass:

1. A clean profile installs through the documented host command.
2. The discovered names equal `manifest.toml` with no missing or extra skill.
3. The namespace is the documented `verbs` identity; any opt-in adapter is named explicitly.
4. One real skill invocation completes through the host's normal tool path.
5. Update and removal are reproducible without editing registries by hand.

Record the host and CLI versions with the evidence. Synthetic cache fixtures
test the scanner; they do not prove the real installer.

## Current support

| Host | Status | Install surface |
|---|---|---|
| Claude Code | Verified | Local plugin marketplace |
| Codex | Verified | Local plugin marketplace |
| Hermes | Selective manual import | Individual skill directories |
| OpenClaw | Unsupported / experimental | None |

Keep runtime-specific coordination on the host side. A new adapter should add
the smallest install and translation layer that can pass the verification gate.
