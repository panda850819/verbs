#!/usr/bin/env bash
# PreToolUse guard — hard-blocks destructive Bash commands at code level.
# Nisi principle: enforce, don't instruct. A prompt-level "please confirm"
# can be skipped by the agent; an exit-2 hook cannot.
#
# Reads PreToolUse stdin JSON, inspects tool_input.command, exit 2 to block.
# Test offline (zero risk):
#   echo '{"tool_name":"Bash","tool_input":{"command":"git push --force"}}' | ./pretooluse-destructive-guard.sh; echo $?
set -euo pipefail

INPUT=$(cat)
TOOL=$(printf '%s' "$INPUT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null || echo "")
[ "$TOOL" = "Bash" ] || exit 0

CMD=$(printf '%s' "$INPUT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || echo "")

# Explicit bypass: Panda appends "# FORCE_OK" to a command he has consciously
# authorized, or exports PANDA_FORCE=1 before launching the session. In-command
# marker is preferred — it survives across hook subprocess env boundaries and
# documents the override at the call site.
case "$CMD" in *"# FORCE_OK"*|*"#FORCE_OK"*) exit 0 ;; esac
[ "${PANDA_FORCE:-}" = "1" ] && exit 0

# Destructive patterns. Conservative: only unambiguous high-blast-radius ops.
DANGER='git push +(-f|--force)|git push .*--force-with-lease|rm +-[a-zA-Z]*[rR][a-zA-Z]* +/|rm +-[a-zA-Z]*f[a-zA-Z]*r|git reset +--hard|git clean +-[a-zA-Z]*f|DROP +(TABLE|DATABASE|SCHEMA)|TRUNCATE +TABLE|git push +.* +:[^ ]'

shopt -s extglob
if [[ "$CMD" =~ git\ push\ +(-f|--force) ]] \
   || printf '%s' "$CMD" | grep -qEi 'git +push +(-f|--force)|git +push +.*--force(-with-lease)?|rm +-[a-zA-Z]*[rR][a-zA-Z]*f|rm +-[a-zA-Z]*f[a-zA-Z]*[rR]|rm +-[a-zA-Z]* +-[a-zA-Z]|git +reset +--hard|git +clean +-[a-zA-Z]*f|DROP +(TABLE|DATABASE|SCHEMA)|TRUNCATE +TABLE'; then
  echo "BLOCKED by pandastack destructive-guard: \"$CMD\"" >&2
  echo "This command is high-blast-radius (force-push / recursive-force-rm / hard-reset / DROP). Confirm with the user explicitly, or narrow the command, before re-running." >&2
  exit 2
fi
exit 0
