# Model anchors

This file is the single source for role-specific model and effort defaults used by
`advisor`. It is an execution contract, not a catalog of every available model.
Broad workflow fan-out economics stay at the harness layer.

Last verified: 2026-07-10 with Codex CLI 0.144.1 and Claude Code 2.1.206.

| Role key | Transport | Model | Effort | Minimum CLI | Guard | Status |
|---|---|---|---|---|---|---|
| `advisor.openai` | direct `codex exec` | `gpt-5.6-sol` | `high` | `codex >= 0.144.1` | read-only sandbox | verified |
| `advisor.anthropic` | direct `claude -p` | `opus` | `high` | `claude >= 2.1.206` | clear `CLAUDECODE`, tools disabled, no session persistence | verified |
| `advisor.panel.openai.fast` | direct `codex exec` | `gpt-5.6-terra` | `medium` | `codex >= 0.144.1` | read-only sandbox | verified |
| `advisor.panel.fast` | direct `claude -p` | `sonnet` | `medium` | `claude >= 2.1.206` | clear `CLAUDECODE`, tools disabled, no session persistence | verified |
| `advisor.panel.deep` | direct `claude -p` | `opus` | `high` | `claude >= 2.1.206` | clear `CLAUDECODE`, tools disabled, no session persistence | verified |

## Selection contract

1. Select the role key before invoking the target runtime.
2. Check the target CLI against the row's minimum version after `command -v`.
   Missing, unparseable, or older versions fail loud with the required upgrade.
3. Pass model, effort, and guard explicitly. Never inherit
   `~/.codex/config.toml`, Claude defaults, or host permissions for a delegated
   call.
4. If the named model or effort is rejected, fail loud. Do not retry without the
   flags and do not silently substitute another model.
Command shapes:

```bash
# advisor.openai | advisor.panel.openai.fast
codex exec --sandbox read-only -m "{Model}" \
  -c 'model_reasoning_effort="{Effort}"' ...

# advisor.anthropic | advisor.panel.fast | advisor.panel.deep
env -u CLAUDECODE claude -p --model "{Model}" --effort "{Effort}" \
  --tools "" --no-session-persistence ...
```

## Transport evidence

- Direct `codex exec` selected and completed fixed-token probes on
  `gpt-5.6-sol/high` and `gpt-5.6-terra/medium`.
- Direct `claude -p --model opus --effort high` selected
  `claude-opus-4-8` and completed its fixed-token probe with tools disabled and
  session persistence off.
- Direct `claude -p --model sonnet --effort medium` selected `claude-sonnet-5`
  and completed its fixed-token probe with tools disabled and session
  persistence off.
- Claude `/codex:rescue` selected and completed `gpt-5.6-sol/high`, but that
  companion path has a different output contract and is not the current
  `advisor` transport.
- The companion app-server path also rejected Sol at `xhigh` and `ultra`; `high`
  is the verified advisor effort on that path.

## Update gate

Update an anchor only after a read-only fixed-token probe proves both the selected
model and effort in the runtime rollout. Re-probe after a Codex or Claude CLI
upgrade, a provider model/alias change, or a model-selection error. Record the new
versions and date here in the same change.
