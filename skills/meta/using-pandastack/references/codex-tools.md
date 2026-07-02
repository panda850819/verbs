# Codex Tool Mapping

Pandastack skills are written using Claude Code tool names. When you encounter these in a skill, use your Codex equivalent:

| Skill references | Codex equivalent |
|------------------|------------------|
| `Skill` tool (invoke a pandastack skill) | Skills load natively — just follow the SKILL.md instructions |
| `Agent` tool (dispatch subagent) | `spawn_agent` (see [Named subagent dispatch](#named-subagent-dispatch)) |
| Multiple `Agent` calls (parallel) | Multiple `spawn_agent` calls |
| Agent returns result | `wait` |
| Agent completes automatically | `close_agent` to free slot |
| `TaskCreate` / `TaskUpdate` (progress tracking) | `update_plan` |
| `Read`, `Write`, `Edit` (files) | Use your native file tools |
| `Bash` (run commands) | Use your native shell tools |
| `WebFetch` / `WebSearch` | Use your native web tools or `defuddle parse <url> --md` if installed |

## Subagent dispatch requires multi-agent support

Add to your Codex config (`~/.codex/config.toml`):

```toml
[features]
multi_agent = true
```

This enables `spawn_agent`, `wait`, and `close_agent` for bounded multi-agent checks.

## Named subagent dispatch

Pandastack references named subagents (e.g. `subagent_type=Explore`). Codex does not have a named agent registry — `spawn_agent` creates generic agents from built-in roles (`default`, `explorer`, `worker`).

When a pandastack skill says to dispatch a named subagent type:

1. Check if the agent's prompt file exists at `agents/<name>.md` in the pandastack plugin root
2. Read the prompt content
3. Fill any template placeholders (e.g. `{TASK}`, `{CONTEXT}`)
4. Spawn a `worker` agent with the filled content as the `message`

| Skill instruction | Codex equivalent |
|-------------------|------------------|
| `Agent({subagent_type: "Explore", ...})` | `spawn_agent(agent_type="explorer", message=<task>)` |
| `Agent({subagent_type: "general-purpose", ...})` | `spawn_agent(message=<task>)` |

### Message framing

The `message` parameter is user-level input, not a system prompt. Structure it for maximum instruction adherence:

```
Your task is to perform the following. Follow the instructions below exactly.

<agent-instructions>
[filled prompt content from the agent's .md file]
</agent-instructions>

Execute this now. Output ONLY the structured response following the format
specified in the instructions above.
```

- Use task-delegation framing ("Your task is...") rather than persona framing ("You are...")
- Wrap instructions in XML tags — the model treats tagged blocks as authoritative
- End with an explicit execution directive to prevent summarization of the instructions

### When this workaround can be removed

Codex's plugin system does not yet support an `agents` field in `RawPluginManifest`. When that lands, pandastack can symlink `agents/` (mirroring the existing `skills/` symlink) and skills can dispatch named subagent types directly.

## Local CLI dependencies

Many pandastack skills (especially `tool-*`) invoke Panda's local CLI tools. These are **not portable** to a Codex environment that does not have them installed:

| Tool | Pandastack skills that depend on it | What it needs |
|---|---|---|
| `rg` / `find` | ship knowledge, vault search, vault hygiene scans | local vault on disk |
| `agent-browser` | agent-browser, qa | Headless Chrome session |
| `curl` + `jq` | deepwiki | preinstalled on most systems |

Notion / Slack ops moved to **Claude.ai Notion / Slack MCP** in v2.2.0 (OAuth, no local token). The decision-note variant of `/ship knowledge` writes proposals to `Inbox/ship-proposals/` as markdown — the user walks the `[ ]` items manually via MCP.

Personal-tier CLI dependencies (`bird`, `gog`, `feed-server`, `defuddle`) are required only by skills in the personal overlay (`~/.agents/skills/` — see its RESOLVER-private.md). (Notion + Slack + Jira ops retired from CLI in 2026-05; now MCP-only — see Tool Routing in `~/.agents/AGENTS.md`.)

If a pandastack skill calls one of these and the binary is not installed, the skill will fail with a clear "command not found" error. These skills are intentionally local-environment-bound — there is no graceful cross-CLI fallback.

If you only want the portable lifecycle skills, symlink individual skill directories instead of the whole `skills/` folder. See `.codex/INSTALL.md` for the portable subset list.

## Hooks

Pandastack uses a SessionStart hook to inject the `using-pandastack` cognitive contract at conversation start. The hook script (`hooks/session-start`) detects platform via env vars (`CLAUDE_PLUGIN_ROOT` / `CURSOR_PLUGIN_ROOT` / `COPILOT_CLI`) and emits the correct JSON format per platform. Codex falls through to the SDK-standard `additionalContext` format. No additional setup required.
