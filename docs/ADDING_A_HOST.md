# Adding a Host to Verbs

A host integration makes the existing skill pack discoverable in one runtime. It
does not add identity, brain or memory, scheduling, project truth, or global
model routing to Verbs.

## Sources of truth

- `manifest.toml` owns product identity, version, and the active skill set.
- `scripts/verbs sync` generates the Claude, Codex, and Agents loader metadata.
- Each `SKILL.md` description owns machine routing; its body owns the workflow
  and tool assumptions.
- Distribution manifests expose skills only and register no lifecycle hooks.

Do not fork skill content merely to rename tools. Keep any translation in host
documentation and state the unsupported cases.

## Adapter contract

Before claiming support, define:

| Field | Required answer |
|---|---|
| Install | Reproducible add, update, and remove commands |
| Discovery | How the host exposes exactly the manifest skill set |
| Namespace | Whether the host displays `verbs:<name>` or plain names |
| Tools | Explicit mapping for read, edit, shell, browser, and delegation |
| Runtime behavior | Proof that installation registers skills only |
| Boundary | Native, degraded, selective, experimental, or unsupported |

The integration may support a subset, but it must not imply parity for skills
or tools it does not enable.

One host profile uses one install surface.

## Verification gate

A host becomes supported only after all of these pass:

1. A clean profile installs through the documented host command.
2. The discovered names equal `manifest.toml` with no missing or extra skill.
3. The namespace is the documented `verbs` identity and no lifecycle hook is registered.
4. One real skill invocation completes through the host's normal tool path.
5. Update and removal are reproducible without editing registries by hand.

Record the host and CLI versions with the evidence. Synthetic cache fixtures
test the scanner; they do not prove the real installer.

## Current support

| Host | Status | Install surface |
|---|---|---|
| Claude Code | Verified | Skills-only Marketplace Plugin |
| Codex | Verified | Skills-only Marketplace Plugin |
| Pi | Direct loading | `skills/` configured in Pi settings |
| Hermes | Unsupported | None |
| OpenClaw | Unsupported / experimental | None |

Keep runtime-specific coordination on the host side. A new integration should
add the smallest install surface that can pass the verification gate.
