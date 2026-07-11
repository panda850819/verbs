# Dispatch (process axis)

Before responding to any task-shaped message, match it against this table. On match: announce the match, then invoke the skill (runtime with a Skill tool) or follow its SKILL.md inline (runtime without). Matched-but-unavailable: say so; never silently skip.

| Signal | Invoke |
|---|---|
| Fuzzy idea / scope not locked / 想討論 | `grill` (atomic drill; use `grill --brief` for structured brief) |
| Prepared plan, want independent multi-angle critique | `advisor --panel` (blind cross-model critics) |
| Load-bearing judgment / design fork / decision expensive-if-wrong, want a second opinion | `advisor` (pull a decorrelated cross-model take) |
| Touching prod, shared infra, or harness paths (`~/.agents`, `~/.claude`, `~/.codex`) | `careful` first |
| Bug fix / feature / refactor (3+ files or new abstraction) | grill-lite plan first, not direct edits |
| Mechanical, file-scoped build units with locked spec | delegate — `handover` (Codex) or subagent; main model orchestrates |
| Error / crash / regression / failing test / "used to work and now doesn't" | `debug` (root cause before any fix) |
| Build / fix a UI surface, "looks off", 不好看 / 很醜 / 排版 / 字體 | `ui` (lock direction, fight defaults) |
| Focused build-to-ship session | `sprint` |
| About to commit | `review`, then `ship` |
| External artifact before install / adopt | `gatekeeper` |
| Non-trivial but no row matches | classify the load-bearing unknown: fact→inspect first (code/docs/knowledge base) · intent→`grill` · taste→`ui` · architecture→`grill --brief` · risk→`careful` · verification→`debug` · mechanical→`handover`; still unclear → Panda Verbs `RESOLVER.md`, pick closest |

<!-- Maintenance: this file is the SINGLE SOURCE for the process-axis routing table.
     Hosts may point to it directly or explicitly wire hooks/session-start as a
     reference adapter. Panda Verbs does not register the adapter automatically.
     Do not fork the table. -->
