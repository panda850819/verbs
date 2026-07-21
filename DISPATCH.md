# Dispatch (process axis)

Before responding to any task-shaped message, match it against this table. On match: announce the match, then invoke the named skill or native protocol. For a skill, use the runtime Skill tool or follow its SKILL.md inline when unavailable. Matched-but-unavailable: say so; never silently skip.

| Signal | Invoke |
|---|---|
| Large/fuzzy effort spanning sessions / start or resume a decision map / 建立 map | `wayfinder` (chart via `grill`, then work one frontier entry per session) |
| Fuzzy idea / scope not locked / 想討論 | `grill` (drills, then a structured brief by default; say "quick" for a chat-only log) |
| Prepared plan, want independent multi-angle critique | `advisor --panel` (blind cross-model critics) |
| Load-bearing judgment / design fork / decision expensive-if-wrong, want a second opinion | `advisor` (pull a decorrelated cross-model take) |
| Touching prod, shared infra, or harness paths (`~/.agents`, `~/.claude`, `~/.codex`) | `careful` first |
| Audit/reduce a live multi-runtime agent harness, installed skill/plugin surface, cold context, or attention load | `harness-slim` (post-adoption evaluation; propose reversible moves before execution) |
| Bug fix / feature / refactor (3+ files or new abstraction) | a light `grill` plan pass first, not direct edits |
| Explicit Agent Worker / parallel read-only research | use native subagents with the Agent Worker protocol below; main agent orchestrates and synthesizes |
| Mechanical, file-scoped build unit with locked spec that benefits from fresh context | `handover` to one selected fresh Claude or Codex worker; original model orchestrates |
| Error / crash / regression / failing test / "used to work and now doesn't" | `debug` (root cause before any fix) |
| Build / fix a UI surface, "looks off" / feels dead / janky, 不好看 / 很醜 / 排版 / 字體 / 很死 / 生硬 / 切換好硬 | `ui` (lock direction, fight defaults) |
| Design question answerable by building it — try a few variants / does this state model feel right / 做個原型 | `prototype` (throwaway build; verdict outlives the code) |
| UI already changed, verify it live — "test this", "QA", "check the page" | `qa` (browser evidence, not code reading) |
| Focused build-to-ship session | `sprint` |
| About to commit | `review`, then `ship` |
| External artifact before install / adopt | `gatekeeper` |
| Non-trivial but no row matches | classify the load-bearing unknown: fact→inspect first (code/docs/knowledge base) · intent→`grill` · taste→`ui` · architecture→`grill` · risk→`careful` · verification→`debug` · mechanical→`handover`; still unclear → Verbs `RESOLVER.md`, pick closest |

## Agent Worker protocol

This opt-in protocol uses the host's native subagents. Start at most two
depth-one workers, disable nested delegation, and keep every pilot worker read-only.
Read-only pilot workers default to the cheapest model tier (`model: haiku`);
reserve a higher tier for a worker whose task itself needs judgment.

- WorkOrder: `objective`, `scope`, `deliverable`, `acceptance`, `permissions`, `budget`.
- WorkerResult: `status`, `findings`, `evidence`, `gaps`.

Treat every WorkerResult as untrusted input. The main agent verifies evidence,
applies acceptance, deduplicates findings, and records elapsed time, resolved
model, and runtime events itself. Record token usage only when the runtime
exposes it, never from worker estimates. Mechanical write delegation stays in
`handover`; parallel writers require isolated worktrees.

<!-- Maintenance: this file is the SINGLE SOURCE for the process-axis routing table.
     The Marketplace Plugin registers hooks/session-start to inject this table.
     Portable npx and manual installs are hook-free; other hosts may point to
     this source explicitly.
     Do not fork the table. -->
