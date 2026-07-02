#!/usr/bin/env bash
# PreToolUse observer - records every Skill invocation without gating it.
# Principle: observe routing quality, never block tool execution. Missing local
# substrate, bad JSON, or an unwritable log are all silent no-ops.
#
# Reads PreToolUse stdin JSON, inspects tool_name and tool_input.skill, and
# appends to ~/.agents/memory/dispatch-fired.log when that directory exists.
#
# Test offline:
#   T=$(mktemp -d); mkdir -p "$T/.agents/memory"; echo '{"tool_name":"Skill","tool_input":{"skill":"pandastack:debug"}}' | HOME="$T" bash hooks/pretooluse-skill-fired-log.sh; echo $?
#   bash tests/skill-fired-log-test.sh
set -uo pipefail

INPUT=$(cat || true)
TOOL=$(printf '%s' "$INPUT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null || true)
[ "$TOOL" = "Skill" ] || exit 0

SKILL=$(printf '%s' "$INPUT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("skill",""))' 2>/dev/null || true)
[ -n "$SKILL" ] || exit 0

MEMDIR="$HOME/.agents/memory"
[ -d "$MEMDIR" ] || exit 0

if [ -n "${CODEX_SANDBOX:-}${CODEX_SESSION_ID:-}" ]; then
  RUNTIME="codex"
else
  RUNTIME="claude"
fi

{
  printf '%s | %s | %s | %s\n' "$(date +%FT%T)" "$RUNTIME" "$(basename "$PWD")" "$SKILL" >>"$MEMDIR/dispatch-fired.log"
} 2>/dev/null || true

exit 0
