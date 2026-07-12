#!/usr/bin/env bash
# Offline Claude + Codex transcript truth table for the Stop verify gate.
set -uo pipefail
export VERBS_GUARD_EVENT_LOG=off

GATE="$(cd "$(dirname "$0")/.." && pwd)/hooks/stop-verify-gate.py"
[ -f "$GATE" ] || { echo "gate not found: $GATE" >&2; exit 1; }

WORK=$(mktemp -d)
trap '/bin/rm -rf "$WORK"' EXIT
FAIL_MARKER="$WORK/failure.marker"
pass=0 fail=0

WANT_REASON='[verbs verify-gate] code changed this turn with no test or verify run — run the relevant check, or state the change is not yet verified.'
WANT_UNAVAILABLE='[verbs verify-gate] unavailable: malformed or missing hook input; blocking stop until verification evidence is readable.'

# Claude JSONL builders.
u() { printf '{"type":"user","message":{"role":"user","content":"%s"}}\n' "$1"; }
ulist() { printf '{"type":"user","message":{"role":"user","content":[{"type":"text","text":"%s"}]}}\n' "$1"; }
ulistimg() { printf '{"type":"user","message":{"role":"user","content":[{"type":"image","source":{"type":"base64","media_type":"image/png","data":"AA=="}},{"type":"text","text":"%s"}]}}\n' "$1"; }
umeta() { printf '{"type":"user","isMeta":true,"message":{"role":"user","content":[{"type":"text","text":"%s"}]}}\n' "$1"; }
umixed() { printf '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"%s","content":"result","is_error":false},{"type":"text","text":"%s"}]}}\n' "$1" "$2"; }
cedit() { printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"%s","name":"%s","input":{"file_path":"%s","old_string":"a","new_string":"b"}}]}}\n' "$1" "$2" "$3"; }
cnbedit() { printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"%s","name":"NotebookEdit","input":{"notebook_path":"%s","new_source":"x"}}]}}\n' "$1" "$2"; }
cbash() { printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"%s","name":"Bash","input":{"command":"%s"}}]}}\n' "$1" "$2"; }
cbashbg() { printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"%s","name":"Bash","input":{"command":"%s","run_in_background":true}}]}}\n' "$1" "$2"; }
cresult() { printf '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"%s","content":"result","is_error":%s}]}}\n' "$1" "$2"; }
capply() {
  PATCH_TEXT="$2" python3 -c 'import json,os,sys; print(json.dumps({"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":sys.argv[1],"name":"apply_patch","input":{"command":os.environ["PATCH_TEXT"]}}]}}))' "$1"
}

# Codex rollout JSONL builders.
cturn() { printf '{"type":"turn_context","payload":{"turn_id":"%s","cwd":"/tmp/proj"}}\n' "$1"; }
cpatch() {
  PATCH_TEXT="$2" python3 -c 'import json,os,sys; print(json.dumps({"type":"response_item","payload":{"type":"custom_tool_call","call_id":sys.argv[1],"name":"apply_patch","input":os.environ["PATCH_TEXT"]}}))' "$1"
}
cpatch_result() { printf '{"type":"event_msg","payload":{"type":"patch_apply_end","call_id":"%s","turn_id":"turn-current","success":%s,"status":"completed"}}\n' "$1" "$2"; }
cexec() {
  CMD_TEXT="$2" python3 -c 'import json,os,sys; args=json.dumps({"cmd":os.environ["CMD_TEXT"]}); print(json.dumps({"type":"response_item","payload":{"type":"function_call","call_id":sys.argv[1],"name":"exec_command","arguments":args}}))' "$1"
}
cwrite_stdin() {
  python3 -c 'import json,sys; args=json.dumps({"session_id":int(sys.argv[2])}); print(json.dumps({"type":"response_item","payload":{"type":"function_call","call_id":sys.argv[1],"name":"write_stdin","arguments":args}}))' "$1" "$2"
}
cout() {
  OUT_TEXT="$2" python3 -c 'import json,os,sys; print(json.dumps({"type":"response_item","payload":{"type":"function_call_output","call_id":sys.argv[1],"output":os.environ["OUT_TEXT"]}}))' "$1"
}
cunknown_exec() { printf '{"type":"response_item","payload":{"type":"custom_tool_call","call_id":"%s","name":"exec","input":"tools.exec_command({cmd: \\"pytest -q\\"})"}}\n' "$1"; }
capp_exec() {
  python3 -c 'import json,sys; print(json.dumps({"type":"response_item","payload":{"type":"custom_tool_call","call_id":sys.argv[1],"name":"exec","input":sys.argv[2]}}))' "$1" "$2"
}
capp_patch_result() {
  python3 -c 'import json,sys; print(json.dumps({"type":"event_msg","payload":{"type":"patch_apply_end","call_id":sys.argv[1],"turn_id":"turn-current","success":True,"status":"completed","changes":{sys.argv[2]:{"type":"update"}}}}))' "$1" "$2"
}
capp_out() {
  python3 -c 'import json,sys; print(json.dumps({"type":"response_item","payload":{"type":"custom_tool_call_output","call_id":sys.argv[1],"output":[{"type":"input_text","text":sys.argv[2]}]}}))' "$1" "$2"
}

CODE_PATCH=$'*** Begin Patch\n*** Update File: app.py\n@@\n-old\n+new\n*** End Patch'
DOC_PATCH=$'*** Begin Patch\n*** Update File: README.md\n@@\n-old\n+new\n*** End Patch'

# run_gate <transcript> [active] [canonical env] [turn] [panda legacy] [stack legacy]
run_gate() {
  local transcript="$1" active="${2:-false}" new_gate_env="${3:-}" turn_id="${4:-turn-current}" panda_gate_env="${5:-}" stack_gate_env="${6:-}" payload
  local env_args=(-u VERBS_VERIFY_GATE -u PANDA_VERBS_VERIFY_GATE -u PANDASTACK_VERIFY_GATE "VERBS_VERIFY_GATE_FAILURE_MARKER=$FAIL_MARKER")
  payload=$(python3 -c 'import json,sys; print(json.dumps({"session_id":"t","turn_id":sys.argv[3],"hook_event_name":"Stop","stop_hook_active":sys.argv[2]=="true","transcript_path":sys.argv[1],"cwd":"/tmp/proj"}))' "$transcript" "$active" "$turn_id")
  [ -n "$new_gate_env" ] && env_args+=("VERBS_VERIFY_GATE=$new_gate_env")
  [ -n "$panda_gate_env" ] && env_args+=("PANDA_VERBS_VERIFY_GATE=$panda_gate_env")
  [ -n "$stack_gate_env" ] && env_args+=("PANDASTACK_VERIFY_GATE=$stack_gate_env")
  OUT=$(printf '%s' "$payload" | env "${env_args[@]}" python3 "$GATE" 2>/dev/null)
  RC=$?
}

expect_allow() {
  local desc="$1"
  if [ "$RC" = 0 ] && [ -z "$OUT" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    printf 'FAIL  %-58s expected silent exit 0, got rc=%s out=%s\n' "$desc" "$RC" "$OUT"
  fi
}

expect_block() {
  expect_block_reason "$1" "$WANT_REASON"
}

expect_block_reason() {
  local desc="$1" reason="$2"
  if [ "$RC" = 0 ] && printf '%s' "$OUT" | REASON="$reason" python3 -c '
import json, os, sys
d = json.loads(sys.stdin.read())
sys.exit(0 if d.get("decision") == "block" and d.get("reason") == os.environ["REASON"] else 1)
'; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    printf 'FAIL  %-58s expected block JSON, got rc=%s out=%s\n' "$desc" "$RC" "$OUT"
  fi
}

# Claude: outcomes, ordering, and current-turn boundary.
T="$WORK/claude.jsonl"
{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; } > "$T"
run_gate "$T"; expect_block "Claude successful code edit without verify"

{ u "fix"; capply e1 "$CODE_PATCH"; cresult e1 false; } > "$T"
run_gate "$T"; expect_block "Claude-envelope apply_patch without verify"

{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; cbash v1 "pytest -q"; cresult v1 false; } > "$T"
run_gate "$T"; expect_allow "Claude successful edit then passing verify"

{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; cbash v1 "pytest -q"; cresult v1 true; } > "$T"
run_gate "$T"; expect_block "Claude failing verify never becomes green"

{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 true; } > "$T"
run_gate "$T"; expect_allow "Claude failed edit does not count as changed"

{ u "docs"; cedit e1 Write /tmp/proj/README.md; cresult e1 false; } > "$T"
run_gate "$T"; expect_allow "Claude successful doc edit needs no verify"

{ u "old"; cbash v0 "pytest -q"; cresult v0 false; u "new"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; } > "$T"
run_gate "$T"; expect_block "Claude previous-turn green is stale"

# Window boundary: a prior turn's edit must be excluded from the current window
# (fails if _claude_window is neutralized to return all entries).
{ u "old"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; u "new question"; } > "$T"
run_gate "$T"; expect_allow "Claude previous-turn edit excluded from current window"

# A block-form user prompt (text list) still resets the window.
{ u "old"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; ulist "new question"; } > "$T"
run_gate "$T"; expect_allow "Claude list-form text prompt resets the window"

# An image+text block-form prompt also resets the window.
{ u "old"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; ulistimg "look at this"; } > "$T"
run_gate "$T"; expect_allow "Claude image+text prompt resets the window"

# Skill/slash-command metadata is injected by the host, not a user turn.
{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; umeta "skill injection"; } > "$T"
run_gate "$T"; expect_block "Claude list-form metadata does not reset the window"

# Ignore tool results when the same entry also contains a genuine user prompt.
{ u "old"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; umixed e1 "new question"; } > "$T"
run_gate "$T"; expect_allow "Claude mixed result+text prompt resets the window"

# A backgrounded verify returns only a launch ack, so it never counts as green.
{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; cbashbg v1 "pytest -q"; cresult v1 false; } > "$T"
run_gate "$T"; expect_block "Claude backgrounded verify is not green"

{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; cbash v1 "pytest -q"; cresult v1 false; cedit e2 Edit /tmp/proj/app.py; cresult e2 false; } > "$T"
run_gate "$T"; expect_block "Claude later successful edit relocks"

{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; cbash v1 "pytest -q"; cresult v1 false; cedit e2 Edit /tmp/proj/app.py; cresult e2 false; cbash v2 "pytest -q"; cresult v2 false; } > "$T"
run_gate "$T"; expect_allow "Claude reverify after later edit"

{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; cbash v1 "pytest -q"; cresult v1 false; cbash v2 "pytest -q"; cresult v2 true; } > "$T"
run_gate "$T"; expect_block "Claude later failing verify invalidates green"

{ u "notebook"; cnbedit e1 /tmp/proj/analysis.ipynb; cresult e1 false; } > "$T"
run_gate "$T"; expect_block "Claude notebook edit is code"

{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; cbash v1 "pip install pytest"; cresult v1 false; } > "$T"
run_gate "$T"; expect_block "Claude test-framework mention is not verify"

for cmd in "pytest -q || true" "pytest -q; true" "pytest --version" \
           "pytest -q | tee test.log" "pytest -q & echo done" \
           "pytest -q&"; do
  { u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; cbash v1 "$cmd"; cresult v1 false; } > "$T"
  run_gate "$T"; expect_block "Claude masked/no-op verify rejected: $cmd"
done

for cmd in "pytest -q && echo passed" "pytest -q 2>&1" \
           "pytest -q &>test.log" "pytest -q 1>&2"; do
  { u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; cbash v1 "$cmd"; cresult v1 false; } > "$T"
  run_gate "$T"; expect_allow "Claude status-preserving verify accepted: $cmd"
done

# Codex: canonical rollout calls, explicit patch/test outcomes, and turn_id.
T="$WORK/codex.jsonl"
{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; } > "$T"
run_gate "$T"; expect_block "Codex successful apply_patch without verify"
run_gate "$T" false "" turn-missing; expect_allow "Unknown Codex turn id fails open"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; cexec v1 "pytest -q"; cout v1 "Process exited with code 0"; } > "$T"
run_gate "$T"; expect_allow "Codex passing exec_command verifies"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; cexec v1 "pytest -q"; cout v1 "Process exited with code 1"; } > "$T"
run_gate "$T"; expect_block "Codex failing exec_command never verifies"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 false; } > "$T"
run_gate "$T"; expect_allow "Codex failed patch does not count as changed"

{ cturn turn-current; cpatch p1 "$DOC_PATCH"; cpatch_result p1 true; } > "$T"
run_gate "$T"; expect_allow "Codex doc-only patch needs no verify"

{ cturn turn-old; cpatch p0 "$CODE_PATCH"; cpatch_result p0 true; cexec v0 "pytest -q"; cout v0 "Process exited with code 0"; cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; } > "$T"
run_gate "$T" false "" turn-current; expect_block "Codex turn_id excludes previous green"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; cexec v1 "pytest -q"; cout v1 "Process exited with code 0"; cpatch p2 "$CODE_PATCH"; cpatch_result p2 true; } > "$T"
run_gate "$T"; expect_block "Codex later successful patch relocks"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; cexec v1 "pytest -q"; cout v1 "Process running with session ID 42"; cwrite_stdin w1 42; cout w1 "Process exited with code 0"; } > "$T"
run_gate "$T"; expect_allow "Codex async exec verified after write_stdin exit 0"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; cexec v1 "pytest -q"; cout v1 "Process running with session ID 42"; cwrite_stdin w1 42; cout w1 "Process exited with code 1"; } > "$T"
run_gate "$T"; expect_block "Codex async exec failure never verifies"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; cunknown_exec x1; } > "$T"
run_gate "$T"; expect_block "Unknown Codex wrapper is never guessed green"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; cexec v1 "pytest -q || true"; cout v1 "Process exited with code 0"; } > "$T"
run_gate "$T"; expect_block "Codex masked verify command is rejected"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; cexec v1 "pytest -q"; cout v1 $'Process running with session ID 42\nOutput:\n{"exit_code": 0}'; } > "$T"
run_gate "$T"; expect_block "Codex running async output cannot forge green"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; cexec v1 "pytest -q"; cout v1 "Process running with session ID 42"; cwrite_stdin w1 42; cout w1 $'Process running with session ID 42\nOutput:\nProcess exited with code 0'; } > "$T"
run_gate "$T"; expect_block "Codex running poll output cannot forge green"

{ cturn turn-current; cpatch p1 "$CODE_PATCH"; cpatch_result p1 true; cturn turn-current; } > "$T"
run_gate "$T"; expect_block "Duplicate same-turn context retains earlier edit"

# Codex App exposes nested patch success through patch_apply_end.changes with
# an unrelated exec-* ID. The outer exec result cannot prove nested test exit.
{ cturn turn-current; capp_exec outer1 'tools.apply_patch("...")'; capp_patch_result exec-nested /tmp/proj/app.py; capp_out outer1 "Script completed"; } > "$T"
run_gate "$T"; expect_block "Codex App nested patch is visible to Stop gate"

{ cturn turn-current; capp_exec outer1 'tools.apply_patch("...")'; capp_patch_result exec-nested /tmp/proj/app.py; capp_out outer1 "Script completed"; capp_exec outer2 'tools.exec_command({cmd:"pytest -q"})'; capp_out outer2 "Script completed"; } > "$T"
run_gate "$T"; expect_block "Codex App outer cell success is not test evidence"

# Loop prevention, kill switches, and pure Q&A pass. Missing verification
# infrastructure fails closed.
{ u "fix"; cedit e1 Edit /tmp/proj/app.py; cresult e1 false; } > "$T"
run_gate "$T" true; expect_allow "stop_hook_active soft pass"
run_gate "$T" false off; expect_allow "VERBS_VERIFY_GATE kill switch off"
run_gate "$T" false "" turn-current off; expect_allow "PANDA_VERBS_VERIFY_GATE remains a 0.x fallback"
run_gate "$T" false "" turn-current "" off; expect_allow "PANDASTACK_VERIFY_GATE remains a legacy fallback"
run_gate "$T" false on turn-current off off; expect_block "VERBS_VERIFY_GATE wins over legacy env"
rm -f "$FAIL_MARKER"
run_gate "$WORK/missing.jsonl"; expect_block_reason "missing transcript fails closed" "$WANT_UNAVAILABLE"
printf 'NOT-JSON\n{broken\n' > "$T"
rm -f "$FAIL_MARKER"
run_gate "$T"; expect_block_reason "malformed transcript fails closed" "$WANT_UNAVAILABLE"
u "what does this do" > "$T"
run_gate "$T"; expect_allow "pure Q&A allows"

# Completely unreadable hook stdin cannot expose stop_hook_active. Block once,
# then the failure marker prevents an unbounded Stop loop.
rm -f "$FAIL_MARKER"
OUT=$(printf 'NOT-JSON' | VERBS_VERIFY_GATE_FAILURE_MARKER="$FAIL_MARKER" python3 "$GATE" 2>/dev/null)
RC=$?; expect_block_reason "unreadable stdin first failure blocks" "$WANT_UNAVAILABLE"
OUT=$(printf 'NOT-JSON' | VERBS_VERIFY_GATE_FAILURE_MARKER="$FAIL_MARKER" python3 "$GATE" 2>/dev/null)
RC=$?; expect_allow "unreadable stdin second failure loop-prevents"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
