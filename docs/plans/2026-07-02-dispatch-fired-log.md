---
date: 2026-07-02
issue: 138
branch: feat/138-dispatch-fired-log
type: plan
---

# Plan — dispatch-fired-log (#138)

> One PreToolUse hook records every Skill invocation to `~/.agents/memory/dispatch-fired.log`, making routing quality (right-skill-fired rate) measurable next to the existing manual miss-log. Observes only — never blocks, degrades silently on public clones without the `~/.agents` substrate. Base: chore/v3.4.0-fable5-harness-cut (8321ff4).

### dispatch-fired-log-T01 — hook script
- scope: hooks/pretooluse-skill-fired-log.sh (new, executable)
- goal: bash 3.2-portable hook, style-matched to hooks/pretooluse-destructive-guard.sh (stdin JSON, `python3 -c` JSON parse with `|| true` fallbacks, header comment stating principle + test command). Behavior:
  - parse tool_name from stdin JSON; not "Skill" → exit 0
  - parse tool_input.skill; empty → exit 0
  - target dir "$HOME/.agents/memory" missing → exit 0 (public clone; do NOT mkdir)
  - runtime: `[ -n "${CODEX_SANDBOX:-}${CODEX_SESSION_ID:-}" ] && runtime=codex || runtime=claude`
  - append one line to "$HOME/.agents/memory/dispatch-fired.log": `$(date +%FT%T) | $runtime | $(basename "$PWD") | $skill`
  - ALWAYS exit 0 on every path (bad JSON, unwritable file — append errors suppressed). This hook observes, never gates; it must be impossible for it to block a Skill invocation.
- acceptance: `T=$(mktemp -d); mkdir -p "$T/.agents/memory"; echo '{"tool_name":"Skill","tool_input":{"skill":"pandastack:debug"}}' | HOME="$T" bash hooks/pretooluse-skill-fired-log.sh; echo $?` prints 0 and the log contains one line ending in `| pandastack:debug`; the same pipe with a bare `HOME=$(mktemp -d)` exits 0 and creates nothing
- depends-on: none
- status: todo

### dispatch-fired-log-T02 — hooks.json wiring
- scope: hooks/hooks.json
- goal: add a PreToolUse entry `{"matcher": "Skill", "hooks": [{"type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/pretooluse-skill-fired-log.sh\"", "async": false}]}` following the shape of the existing Bash / Edit|Write|MultiEdit entries exactly.
- acceptance: `python3 -c 'import json;d=json.load(open("hooks/hooks.json"));assert any(e["matcher"]=="Skill" for e in d["hooks"]["PreToolUse"])'` exits 0
- depends-on: dispatch-fired-log-T01
- status: todo

### dispatch-fired-log-T03 — offline test
- scope: tests/skill-fired-log-test.sh (new)
- goal: self-contained offline test in the style of tests/destructive-guard-test.sh (mktemp HOME, cleanup trap, PASS/FAIL counters, keyed on exit codes). Cases: (1) Skill fire with memory dir present → exit 0, exactly one well-formed line appended (4 pipe-separated fields, field 4 = the skill name); (2) memory dir absent → exit 0, no file created; (3) tool_name "Bash" → exit 0, no append; (4) malformed JSON on stdin → exit 0. Discovered automatically by tests/run-all.sh's `tests/*.sh` glob — no runner changes needed.
- acceptance: `bash tests/skill-fired-log-test.sh` exits 0; `bash tests/run-all.sh` lists it as PASS and reports 0 failed
- depends-on: dispatch-fired-log-T01
- status: todo

### dispatch-fired-log-T04 — DISPATCH.md doc line
- scope: DISPATCH.md
- goal: in the miss-log paragraph, add ONE sentence documenting the fired-log: invocations are appended automatically by the plugin's PreToolUse hook to `~/.agents/memory/dispatch-fired.log`, reviewed together with the miss-log. Keep the file compact — it lands in every session's context.
- acceptance: `grep -c "dispatch-fired.log" DISPATCH.md` prints 1
- depends-on: none
- status: todo
