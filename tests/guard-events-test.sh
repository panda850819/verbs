#!/usr/bin/env bash
# Durable, privacy-minimal guard event evidence. No fixture command is run.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$ROOT/hooks/guard_events.py"
DESTRUCTIVE="$ROOT/hooks/pretooluse-destructive-guard.sh"
TICKET="$ROOT/hooks/pretooluse-ticket-gate-guard.sh"
STOP="$ROOT/hooks/stop-verify-gate.py"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/verbs-guard-events.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
LOG="$WORK/guard-events.jsonl"
pass=0 fail=0

record() {
  if [ "$1" = 0 ]; then pass=$((pass+1)); else
    fail=$((fail+1)); echo "FAIL: $2"
  fi
}

claude_payload='{"runtime":"claude","session_id":"s1","cwd":"/tmp/repo","tool_name":"Bash","tool_input":{"command":"echo secret-command"}}'
codex_payload='{"runtime":"codex","thread_id":"t1","turn_id":"turn1","cwd":"/tmp/repo","tool_name":"Bash","tool_input":{"command":"git status"}}'

printf '%s' "$claude_payload" | VERBS_GUARD_EVENT_LOG="$LOG" python3 "$HELPER" \
  --hook PreToolUse --action ticket-gate --decision allow --reason-code no_policy_match
record $? "Claude event append"
printf '%s' "$codex_payload" | VERBS_GUARD_EVENT_LOG="$LOG" python3 "$HELPER" \
  --hook Stop --action verify-gate --decision deny --reason-code code_edit_unverified
record $? "Codex event append"

python3 - "$LOG" <<'PY'
import json, os, stat, sys
path = sys.argv[1]
rows = [json.loads(line) for line in open(path, encoding="utf-8")]
assert len(rows) == 2
assert [row["runtime"] for row in rows] == ["claude", "codex"]
required = {
    "schema", "timestamp", "runtime", "session_id", "turn_id", "hook",
    "action", "authority_scope", "decision", "reason_code", "artifact_ref",
}
assert all(set(row) == required for row in rows)
assert all(row["schema"] == "verbs.guard-event.v1" for row in rows)
assert "secret-command" not in open(path, encoding="utf-8").read()
assert stat.S_IMODE(os.stat(path).st_mode) == 0o600
PY
record $? "schema, privacy, and file mode"

for i in $(seq 1 24); do
  printf '%s' "$codex_payload" | VERBS_GUARD_EVENT_LOG="$LOG" python3 "$HELPER" \
    --hook PreToolUse --action ticket-gate --decision allow \
    --reason-code "concurrent_$i" &
done
wait
python3 - "$LOG" <<'PY'
import json, sys
rows = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8")]
codes = {row["reason_code"] for row in rows}
assert all("concurrent_{}".format(i) in codes for i in range(1, 25))
PY
record $? "concurrent O_APPEND rows remain complete JSON"

# The helper fsyncs before returning, so killing its caller cannot lose the row.
set +e
sh -c 'printf "%s" "$1" | VERBS_GUARD_EVENT_LOG="$2" python3 "$3" --hook PreToolUse --action ticket-gate --decision allow --reason-code interrupted_caller; kill -9 $$' sh "$claude_payload" "$LOG" "$HELPER" >/dev/null 2>&1
set -e
python3 - "$LOG" <<'PY'
import json, sys
rows = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8")]
assert rows[-1]["reason_code"] == "interrupted_caller"
PY
record $? "fsynced row survives caller interruption"

# Real guard entrypoints emit the same schema on deny and allow.
git init -q -b main "$WORK/repo"
git -C "$WORK/repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
ticket_payload=$(python3 -c 'import json,sys; print(json.dumps({"runtime":"codex","turn_id":"turn2","cwd":sys.argv[1],"tool_name":"Bash","tool_input":{"command":"git commit -m x"}}))' "$WORK/repo")
set +e
printf '%s' "$ticket_payload" | VERBS_GUARD_EVENT_LOG="$LOG" "$TICKET" >/dev/null 2>&1
ticket_rc=$?
set -e
[ "$ticket_rc" = 2 ]
record $? "ticket deny emits without weakening the block"

printf '{"type":"user","message":{"role":"user","content":"explain"}}\n' > "$WORK/transcript.jsonl"
stop_payload=$(python3 -c 'import json,sys; print(json.dumps({"runtime":"claude","session_id":"s2","hook_event_name":"Stop","stop_hook_active":False,"transcript_path":sys.argv[1],"cwd":"/tmp/repo"}))' "$WORK/transcript.jsonl")
stop_out=$(printf '%s' "$stop_payload" | VERBS_GUARD_EVENT_LEVEL=all VERBS_GUARD_EVENT_LOG="$LOG" python3 "$STOP" 2>/dev/null)
[ -z "$stop_out" ]
record $? "Stop allow emits silently"

python3 - "$LOG" <<'PY'
import json, sys
rows = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8")]
ticket = next(row for row in rows if row["action"] == "ticket-gate" and row["decision"] == "deny")
assert ticket["runtime"] == "codex"
assert ticket["turn_id"] == "turn2"
assert ticket["authority_scope"]
assert any(row["action"] == "verify-gate" and row["decision"] == "allow" for row in rows)
PY
record $? "guard entrypoints share the event schema"

printf '%s' "$ticket_payload" | PSTICKET_FORCE=1 VERBS_GUARD_EVENT_LOG="$LOG" "$TICKET" >/dev/null 2>&1
python3 - "$LOG" <<'PY'
import json, sys
rows = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8")]
assert rows[-1]["decision"] == "allow"
assert rows[-1]["reason_code"] == "psticket_force_override"
PY
record $? "emergency override remains auditable"

# Logging failure is visible but cannot turn a deny into an allow.
danger='{"runtime":"claude","cwd":"/tmp/repo","tool_name":"Bash","tool_input":{"command":"git push --force"}}'
set +e
notice=$(printf '%s' "$danger" | VERBS_GUARD_EVENT_LOG="$WORK" "$DESTRUCTIVE" 2>&1 >/dev/null)
rc=$?
set -e
[ "$rc" = 2 ] && printf '%s' "$notice" | grep -Fq '[verbs guard-events] unavailable:'
record $? "log failure leaves destructive deny intact and visible"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
