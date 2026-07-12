#!/usr/bin/env bash
# Executable bank for the four observed M1-M3 regressions.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export VERBS_GUARD_EVENT_LOG=off
WORK=$(mktemp -d "${TMPDIR:-/tmp}/verbs-guard-bank.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
pass=0 fail=0

record() {
  if [ "$1" = 0 ]; then pass=$((pass+1)); else
    fail=$((fail+1)); echo "FAIL: $2"
  fi
}

# Regression: default-branch commit once passed despite the contract.
git init -q -b main "$WORK/repo"
git -C "$WORK/repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
payload=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":"git commit -m x"}}))' "$WORK/repo")
printf '%s' "$payload" | "$ROOT/hooks/pretooluse-ticket-gate-guard.sh" >/dev/null 2>&1
[ $? = 2 ]; record $? "default-branch commit must block"

# Regression: destructive command text used as data once false-blocked.
payload='{"tool_name":"Bash","tool_input":{"command":"python3 -c '\''print(\"rm -rf /\")'\''"}}'
printf '%s' "$payload" | "$ROOT/hooks/pretooluse-destructive-guard.sh" >/dev/null 2>&1
[ $? = 0 ]; record $? "quoted command data must allow"
payload='{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/x"}}'
printf '%s' "$payload" | "$ROOT/hooks/pretooluse-destructive-guard.sh" >/dev/null 2>&1
[ $? = 2 ]; record $? "real destructive command must block"

# Regression: malformed verification evidence once failed open.
out=$(printf 'NOT-JSON' | python3 "$ROOT/hooks/stop-verify-gate.py" 2>/dev/null)
printf '%s' "$out" | python3 -c 'import json,sys; assert json.load(sys.stdin)["decision"] == "block"'
record $? "malformed verify evidence must fail closed"

# Regression: installed hook manifests once drifted from source intent.
python3 - "$ROOT/hooks/hooks.json" <<'PY'
import json, sys
hooks = json.load(open(sys.argv[1]))["hooks"]
bash = hooks["PreToolUse"][0]
commands = [item["command"] for item in bash["hooks"]]
assert bash["matcher"] == "Bash"
assert any("pretooluse-destructive-guard.sh" in command for command in commands)
assert any("pretooluse-ticket-gate-guard.sh" in command for command in commands)
assert any("stop-verify-gate.py" in item["command"] for group in hooks["Stop"] for item in group["hooks"])
PY
record $? "hook manifest must contain all guard entrypoints"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
