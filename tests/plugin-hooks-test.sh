#!/usr/bin/env bash
# Offline contract test for the native Plugin hook manifest and all hook envelopes.
set -uo pipefail
cd "$(dirname "$0")/.."

ROOT="${VERBS_HOOK_ROOT:-$(pwd)}"
ROOT="$(cd "$ROOT" && pwd -P)"
MANIFEST="$ROOT/hooks/hooks.json"
SESSION="$ROOT/hooks/session-start"
GUARD="$ROOT/hooks/pretooluse-destructive-guard.sh"
TICKET="$ROOT/hooks/pretooluse-ticket-gate-guard.sh"
STOP="$ROOT/hooks/stop-verify-gate.py"
WORK="$(mktemp -d)"
trap '/bin/rm -rf "$WORK"' EXIT HUP INT TERM
pass=0 fail=0

record() {
  local ok="$1" desc="$2"
  if [ "$ok" = 0 ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    printf 'FAIL  %s\n' "$desc"
  fi
}

# Exact manifest equality makes extra events, matchers, descriptions, and
# retired ticket/skill-fire hooks fail together instead of testing a subset.
python3 - "$MANIFEST" <<'PY'
import json, sys

with open(sys.argv[1], encoding="utf-8") as handle:
    actual = json.load(handle)

expected = {
    "hooks": {
        "SessionStart": [{
            "matcher": "startup|clear|compact",
            "hooks": [{
                "type": "command",
                "command": '"${CLAUDE_PLUGIN_ROOT}/hooks/session-start"',
                "async": False,
            }],
        }],
        "PreToolUse": [{
            "matcher": "Bash",
            "hooks": [{
                "type": "command",
                "command": '"${CLAUDE_PLUGIN_ROOT}/hooks/pretooluse-destructive-guard.sh"',
                "async": False,
            }, {
                "type": "command",
                "command": '"${CLAUDE_PLUGIN_ROOT}/hooks/pretooluse-ticket-gate-guard.sh"',
                "async": False,
            }],
        }],
        "Stop": [{
            "hooks": [{
                "type": "command",
                "command": 'python3 "${CLAUDE_PLUGIN_ROOT}/hooks/stop-verify-gate.py"',
                "async": False,
            }],
        }],
    },
}
assert actual == expected, (actual, expected)
PY
record $? "manifest must register exactly SessionStart, PreToolUse Bash, and Stop"

for executable in "$SESSION" "$GUARD" "$TICKET" "$STOP"; do
  [ -x "$executable" ]
  record $? "hook must be executable: $executable"
done

SESSION_CMD=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hooks"]["SessionStart"][0]["hooks"][0]["command"])' "$MANIFEST")
GUARD_CMD=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hooks"]["PreToolUse"][0]["hooks"][0]["command"])' "$MANIFEST")
STOP_CMD=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hooks"]["Stop"][0]["hooks"][0]["command"])' "$MANIFEST")

# SessionStart: execute the registered command for Claude, then the same hook's
# SDK envelope for Codex. Both must contain only the live dispatch table.
CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$SESSION_CMD" >"$WORK/session-claude.out" 2>"$WORK/session-claude.err"
record $? "registered Claude SessionStart command must execute"
python3 - "$WORK/session-claude.out" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert set(data) == {"hookSpecificOutput"}
payload = data["hookSpecificOutput"]
assert payload["hookEventName"] == "SessionStart"
context = payload["additionalContext"]
assert "# Dispatch" in context
assert "<!--" not in context and "AGENTS.md" not in context and "gbrain" not in context
PY
record $? "Claude SessionStart envelope must inject only Dispatch"

env -u CLAUDE_PLUGIN_ROOT -u CURSOR_PLUGIN_ROOT -u COPILOT_CLI \
  "$SESSION" >"$WORK/session-codex.out" 2>"$WORK/session-codex.err"
record $? "Codex SessionStart hook must execute"
python3 - "$WORK/session-codex.out" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert set(data) == {"additionalContext"}
assert "# Dispatch" in data["additionalContext"]
PY
record $? "Codex SessionStart envelope must use top-level additionalContext"

CLAUDE_PLUGIN_ROOT="$ROOT" VERBS_SESSION_ADAPTER=off bash -c "$SESSION_CMD" \
  >"$WORK/session-off.out" 2>"$WORK/session-off.err"
[ $? = 0 ] && [ ! -s "$WORK/session-off.out" ] && [ ! -s "$WORK/session-off.err" ]
record $? "VERBS_SESSION_ADAPTER=off must allow quietly"

mkdir -p "$WORK/missing-root/hooks"
cp "$SESSION" "$WORK/missing-root/hooks/session-start"
"$WORK/missing-root/hooks/session-start" >"$WORK/session-missing.out" 2>"$WORK/session-missing.err"
[ $? = 0 ] && [ ! -s "$WORK/session-missing.out" ] && grep -Fq \
  '[verbs session-adapter] unavailable: missing DISPATCH.md; continuing without dispatch injection.' \
  "$WORK/session-missing.err"
record $? "missing Dispatch must fail open with a visible notice"

VERBS_SESSION_ADAPTER=off "$WORK/missing-root/hooks/session-start" \
  >"$WORK/session-missing-off.out" 2>"$WORK/session-missing-off.err"
[ $? = 0 ] && [ ! -s "$WORK/session-missing-off.out" ] && [ ! -s "$WORK/session-missing-off.err" ]
record $? "SessionStart kill switch must stay quiet when Dispatch is missing"

mkdir -p "$WORK/fail-bin"
printf '%s\n' '#!/usr/bin/env bash' 'exit 1' >"$WORK/fail-bin/sed"
chmod +x "$WORK/fail-bin/sed"
PATH="$WORK/fail-bin:/usr/bin:/bin" "$SESSION" \
  >"$WORK/session-read-fail.out" 2>"$WORK/session-read-fail.err"
[ $? = 0 ] && [ ! -s "$WORK/session-read-fail.out" ] && grep -Fq \
  '[verbs session-adapter] unavailable: unable to read DISPATCH.md; continuing without dispatch injection.' \
  "$WORK/session-read-fail.err"
record $? "SessionStart read failure must fail open visibly"

make_guard_payload() {
  COMMAND_TEXT="$1" python3 -c 'import json,os; print(json.dumps({"tool_name":"Bash","tool_input":{"command":os.environ["COMMAND_TEXT"]}}))'
}

run_guard() {
  local command="$1" setting="${2:-}" force="${3:-}"
  local env_args=(-u VERBS_DESTRUCTIVE_GUARD -u VERBS_FORCE "CLAUDE_PLUGIN_ROOT=$ROOT")
  [ -n "$setting" ] && env_args+=("VERBS_DESTRUCTIVE_GUARD=$setting")
  [ -n "$force" ] && env_args+=("VERBS_FORCE=$force")
  make_guard_payload "$command" >"$WORK/guard.json"
  env "${env_args[@]}" bash -c "$GUARD_CMD" \
    <"$WORK/guard.json" >"$WORK/guard.out" 2>"$WORK/guard.err"
  GUARD_RC=$?
}

run_guard "python3 -c 'print(\"rm -rf /\")'"
[ "$GUARD_RC" = 0 ] && [ ! -s "$WORK/guard.err" ]
record $? "danger tokens used as data must allow"

run_guard 'sudo -u www-data rm -rf /var/www'
[ "$GUARD_RC" = 2 ] && grep -Fq 'BLOCKED by Verbs destructive-guard:' "$WORK/guard.err"
record $? "destructive command behind an exec wrapper must block"

run_guard 'x=$(rm -rf /data)'
[ "$GUARD_RC" = 2 ] && grep -Fq 'BLOCKED by Verbs destructive-guard:' "$WORK/guard.err"
record $? "destructive command substitution must block"

run_guard 'git push --force' off
[ "$GUARD_RC" = 0 ] && [ ! -s "$WORK/guard.out" ] && [ ! -s "$WORK/guard.err" ]
record $? "VERBS_DESTRUCTIVE_GUARD=off must allow quietly"

run_guard 'git push --force' '' 1
[ "$GUARD_RC" = 0 ] && [ ! -s "$WORK/guard.out" ] && [ ! -s "$WORK/guard.err" ]
record $? "VERBS_FORCE=1 must remain a quiet override"

printf 'NOT-JSON' | CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$GUARD_CMD" \
  >"$WORK/guard-malformed.out" 2>"$WORK/guard-malformed.err"
[ $? = 0 ] && [ ! -s "$WORK/guard-malformed.out" ] && grep -Fq \
  '[verbs destructive-guard] unavailable: malformed PreToolUse input; allowing command.' \
  "$WORK/guard-malformed.err"
record $? "malformed PreToolUse payload must fail open visibly"

printf '{"tool_name":"Bash","tool_input":{}}' | CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$GUARD_CMD" \
  >"$WORK/guard-shape.out" 2>"$WORK/guard-shape.err"
[ $? = 0 ] && [ ! -s "$WORK/guard-shape.out" ] && grep -Fq \
  '[verbs destructive-guard] unavailable: malformed Bash tool input; allowing command.' \
  "$WORK/guard-shape.err"
record $? "malformed Bash tool input must fail open visibly"

printf 'NOT-JSON' | VERBS_DESTRUCTIVE_GUARD=off CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$GUARD_CMD" \
  >"$WORK/guard-malformed-off.out" 2>"$WORK/guard-malformed-off.err"
[ $? = 0 ] && [ ! -s "$WORK/guard-malformed-off.out" ] && [ ! -s "$WORK/guard-malformed-off.err" ]
record $? "destructive guard kill switch must stay quiet on malformed input"

# Ticket-gate: envelope-level checks only here (behavior suite lives in
# tests/ticket-gate-guard-test.sh with fixture repos).
TICKET_CMD=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hooks"]["PreToolUse"][0]["hooks"][1]["command"])' "$MANIFEST")

printf 'NOT-JSON git' | env -u PSTICKET_FORCE -u PANDA_FORCE -u VERBS_TICKET_GATE CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$TICKET_CMD" \
  >"$WORK/ticket-malformed.out" 2>"$WORK/ticket-malformed.err"
[ $? = 0 ] && [ ! -s "$WORK/ticket-malformed.out" ] && grep -Fq \
  '[verbs ticket-gate] unavailable: malformed PreToolUse input; allowing command.' \
  "$WORK/ticket-malformed.err"
record $? "ticket-gate malformed payload must fail open visibly"

printf 'NOT-JSON no relevant token' | env -u PSTICKET_FORCE -u PANDA_FORCE -u VERBS_TICKET_GATE CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$TICKET_CMD" \
  >"$WORK/ticket-prefilter.out" 2>"$WORK/ticket-prefilter.err"
[ $? = 0 ] && [ ! -s "$WORK/ticket-prefilter.out" ] && [ ! -s "$WORK/ticket-prefilter.err" ]
record $? "ticket-gate pre-filter must skip payloads without git quietly"

printf 'NOT-JSON git' | VERBS_TICKET_GATE=off CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$TICKET_CMD" \
  >"$WORK/ticket-off.out" 2>"$WORK/ticket-off.err"
[ $? = 0 ] && [ ! -s "$WORK/ticket-off.out" ] && [ ! -s "$WORK/ticket-off.err" ]
record $? "ticket-gate kill switch must stay quiet on malformed input"

# Stop: an edit without verify blocks once. The loop-prevention pass, kill
# switch, and malformed infrastructure input all allow; only the latter warns.
cat >"$WORK/transcript.jsonl" <<'JSONL'
{"type":"user","message":{"role":"user","content":"fix"}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"e1","name":"Edit","input":{"file_path":"/tmp/proj/app.py","old_string":"a","new_string":"b"}}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"e1","content":"ok","is_error":false}]}}
JSONL

make_stop_payload() {
  python3 - "$WORK/transcript.jsonl" "$1" <<'PY'
import json, sys
print(json.dumps({
    "hook_event_name": "Stop",
    "stop_hook_active": sys.argv[2] == "true",
    "transcript_path": sys.argv[1],
    "cwd": "/tmp/proj",
}))
PY
}

make_stop_payload false | CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$STOP_CMD" \
  >"$WORK/stop-first.out" 2>"$WORK/stop-first.err"
STOP_RC=$?
python3 - "$WORK/stop-first.out" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["decision"] == "block"
assert data["reason"].startswith("[verbs verify-gate]")
PY
STOP_JSON_RC=$?
[ "$STOP_RC" = 0 ] && [ "$STOP_JSON_RC" = 0 ] && [ ! -s "$WORK/stop-first.err" ]
record $? "first unverified code-edit Stop must block"

make_stop_payload true | CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$STOP_CMD" \
  >"$WORK/stop-second.out" 2>"$WORK/stop-second.err"
[ $? = 0 ] && [ ! -s "$WORK/stop-second.out" ] && [ ! -s "$WORK/stop-second.err" ]
record $? "second Stop pass must allow quietly"

make_stop_payload false | VERBS_VERIFY_GATE=off CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$STOP_CMD" \
  >"$WORK/stop-off.out" 2>"$WORK/stop-off.err"
[ $? = 0 ] && [ ! -s "$WORK/stop-off.out" ] && [ ! -s "$WORK/stop-off.err" ]
record $? "VERBS_VERIFY_GATE=off must allow quietly"

printf 'NOT-JSON' | CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$STOP_CMD" \
  >"$WORK/stop-malformed.out" 2>"$WORK/stop-malformed.err"
[ $? = 0 ] && [ ! -s "$WORK/stop-malformed.out" ] && grep -Fq \
  '[verbs verify-gate] unavailable: malformed or missing hook input; allowing stop.' \
  "$WORK/stop-malformed.err"
record $? "malformed Stop payload must fail open visibly"

printf '%s\n' 'NOT-JSON' >>"$WORK/transcript.jsonl"
make_stop_payload false | CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$STOP_CMD" \
  >"$WORK/stop-mixed.out" 2>"$WORK/stop-mixed.err"
[ $? = 0 ] && [ ! -s "$WORK/stop-mixed.out" ] && grep -Fq \
  '[verbs verify-gate] unavailable: malformed or missing hook input; allowing stop.' \
  "$WORK/stop-mixed.err"
record $? "partially malformed transcript must fail open visibly"
sed -i.bak '$d' "$WORK/transcript.jsonl"
rm -f "$WORK/transcript.jsonl.bak"

printf 'NOT-JSON' | VERBS_VERIFY_GATE=off CLAUDE_PLUGIN_ROOT="$ROOT" bash -c "$STOP_CMD" \
  >"$WORK/stop-malformed-off.out" 2>"$WORK/stop-malformed-off.err"
[ $? = 0 ] && [ ! -s "$WORK/stop-malformed-off.out" ] && [ ! -s "$WORK/stop-malformed-off.err" ]
record $? "Stop kill switch must stay quiet on malformed input"

mkdir -p "$WORK/missing-runtime/hooks"
cp "$STOP" "$WORK/missing-runtime/hooks/stop-verify-gate.py"
make_stop_payload false | python3 "$WORK/missing-runtime/hooks/stop-verify-gate.py" \
  >"$WORK/stop-runtime.out" 2>"$WORK/stop-runtime.err"
[ $? = 0 ] && [ ! -s "$WORK/stop-runtime.out" ] && grep -Fq \
  '[verbs verify-gate] unavailable: runtime event adapter missing; allowing stop.' \
  "$WORK/stop-runtime.err"
record $? "missing Stop runtime adapter must fail open visibly"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
