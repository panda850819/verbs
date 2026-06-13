# Dispatch (process axis)

Before responding to any task-shaped message, match it against this table. On match: announce the match, then invoke the skill (runtime with a Skill tool) or follow its SKILL.md inline (runtime without). Matched-but-unavailable: say so; never silently skip.

| Signal | Invoke |
|---|---|
| Fuzzy idea / scope not locked / 想討論 | `grill` (atomic drill) or `office-hours` (structured brief) |
| Plan done, want multi-lens critique | `boardroom` |
| Touching prod, shared infra, or harness paths (`~/.agents`, `~/.claude`, `~/.codex`) | `careful` first |
| Bug fix / feature / refactor (3+ files or new abstraction) | grill-lite plan first, not direct edits |
| Focused build-to-ship session | `sprint` |
| About to commit | `review`, then `ship` |
| Knowledge note or decision closed | `ship knowledge <path>` |
| External artifact before install / adopt | `gatekeeper` |
| Weekly / monthly retro | `retro-week` / `retro-month` |
| Non-trivial but no row matches | read pandastack `RESOLVER.md`, pick closest |

Miss log: 事後發現該用而沒用 → append `date | runtime | signal | skill` to `~/.agents/memory/dispatch-miss.log`. Reviewed at `retro-week`.

<!-- Maintenance: this file is the SINGLE SOURCE for the process-axis routing table.
     Injected at session start by hooks/session-start (Claude Code + Codex both run
     plugin hooks). Hosts without plugin hooks read this file directly.
     ~/.agents/AGENTS.md § Dispatch Protocol is a pointer here — do not fork the table.
     Keep this file compact: it lands in every session's context. -->
