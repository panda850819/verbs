#!/usr/bin/env bash
# Offline tests for hooks/stop-verify-gate.py (Stop-hook verify gate).
# Each case writes a small hand-made JSONL transcript fixture into a mktemp
# dir, pipes a Stop-hook stdin payload into the gate, and keys pass/fail on
# exit code + stdout. Fully offline; nothing in the fixtures is executed.
#
# Run: bash tests/stop-verify-gate-test.sh
set -uo pipefail

GATE="$(cd "$(dirname "$0")/.." && pwd)/hooks/stop-verify-gate.py"
[ -f "$GATE" ] || { echo "gate not found: $GATE" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
pass=0 fail=0

WANT_REASON='[pandastack verify-gate] code changed this turn with no test or verify run — run the relevant check, or state the change is not yet verified.'

# --- fixture line builders (one JSONL entry per call; args must not contain ") ---
u()       { printf '{"type":"user","message":{"role":"user","content":"%s"}}\n' "$1"; }
edit()    { printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t","name":"%s","input":{"file_path":"%s","old_string":"a","new_string":"b"}}]}}\n' "$1" "$2"; }
bashcmd() { printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t","name":"Bash","input":{"command":"%s"}}]}}\n' "$1"; }
toolres() { printf '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t","content":"ok"}]}}\n'; }

# run_gate <transcript-path> [stop_hook_active] [PANDASTACK_VERIFY_GATE value]
# -> sets OUT (stdout) and RC (exit code)
run_gate() {
  local transcript="$1" active="${2:-false}" gate_env="${3:-}"
  local payload
  payload=$(printf '{"session_id":"t","hook_event_name":"Stop","stop_hook_active":%s,"transcript_path":"%s"}' "$active" "$transcript")
  if [ -n "$gate_env" ]; then
    OUT=$(printf '%s' "$payload" | PANDASTACK_VERIFY_GATE="$gate_env" python3 "$GATE" 2>/dev/null)
  else
    OUT=$(printf '%s' "$payload" | env -u PANDASTACK_VERIFY_GATE python3 "$GATE" 2>/dev/null)
  fi
  RC=$?
}

expect_allow() {
  local desc="$1"
  if [ "$RC" = 0 ] && [ -z "$OUT" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    printf 'FAIL  %-48s expected silent exit 0, got rc=%s out=%s\n' "$desc" "$RC" "$OUT"
  fi
}

expect_block() {
  local desc="$1"
  if [ "$RC" = 0 ] && printf '%s' "$OUT" | REASON="$WANT_REASON" python3 -c '
import json, os, sys
d = json.loads(sys.stdin.read())
ok = d.get("decision") == "block" and d.get("reason") == os.environ["REASON"]
sys.exit(0 if ok else 1)
'; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    printf 'FAIL  %-48s expected block JSON, got rc=%s out=%s\n' "$desc" "$RC" "$OUT"
  fi
}

# --- case 1: code edit, no test command -> block JSON on stdout ---
for tool in Edit MultiEdit; do
  T="$WORK/c1.jsonl"
  { u "fix the bug"; edit "$tool" /tmp/proj/app.py; toolres; } > "$T"
  run_gate "$T"
  expect_block "c1 code edit, no test cmd ($tool)"
done

# --- case 2: code edit + verify command after the edit -> silent exit 0 ---
for cmd in "python3 -m pytest tests/ -v" "bun test" "bash tests/x.sh" "bash scripts/lint-suite.sh"; do
  T="$WORK/c2.jsonl"
  { u "fix the bug"; edit Edit /tmp/proj/app.py; toolres; bashcmd "$cmd"; toolres; } > "$T"
  run_gate "$T"
  expect_allow "c2 verify after edit: $cmd"
done

# --- case 3: doc-only edits (.md/.json) -> silent exit 0 ---
T="$WORK/c3.jsonl"
{ u "update the docs"; edit Write /tmp/proj/README.md; toolres; edit Edit /tmp/proj/config.json; toolres; } > "$T"
run_gate "$T"
expect_allow "c3 md/json-only edits"

# --- case 4: stop_hook_active=true -> silent exit 0 even with unverified edit ---
T="$WORK/c4.jsonl"
{ u "fix the bug"; edit Edit /tmp/proj/app.py; toolres; } > "$T"
run_gate "$T" true
expect_allow "c4 stop_hook_active soft pass"

# --- case 5: missing / malformed transcript -> fail-open silent exit 0 ---
run_gate "$WORK/nonexistent.jsonl"
expect_allow "c5a missing transcript fails open"
T="$WORK/c5.jsonl"
printf 'NOT-JSON-LINE\n{broken\n' > "$T"
run_gate "$T"
expect_allow "c5b malformed transcript fails open"

# --- case 6: PANDASTACK_VERIFY_GATE=off -> silent exit 0 on a would-block fixture ---
T="$WORK/c6.jsonl"
{ u "fix the bug"; edit Edit /tmp/proj/app.py; toolres; } > "$T"
run_gate "$T" false off
expect_allow "c6 kill switch off"

# --- case 7: test ran BEFORE the last user prompt, edit after -> stale green, block ---
T="$WORK/c7.jsonl"
{ u "run the suite"; bashcmd "python3 -m pytest tests/ -v"; toolres; u "now fix the bug"; edit Edit /tmp/proj/app.py; toolres; } > "$T"
run_gate "$T"
expect_block "c7 stale green before last prompt"

# --- extra: local-command entries after the edit are not a turn boundary -> still block ---
T="$WORK/c8.jsonl"
{ u "fix the bug"; edit Edit /tmp/proj/app.py; toolres; u "<command-name>/model</command-name>"; u "<local-command-stdout>Set model</local-command-stdout>"; } > "$T"
run_gate "$T"
expect_block "c8 local-command entries keep turn open"

# --- extra: pure Q&A turn, no tool use -> silent exit 0 ---
T="$WORK/c9.jsonl"
u "what does this function do" > "$T"
run_gate "$T"
expect_allow "c9 pure Q&A"

# --- extra: green THEN a later code edit, same window -> verification reset, block ---
T="$WORK/c10.jsonl"
{ u "fix the bug"; bashcmd "python3 -m pytest tests/ -v"; toolres; edit Edit /tmp/proj/app.py; toolres; } > "$T"
run_gate "$T"
expect_block "c10 edit after green voids verification"

# --- extra: edit, verify, re-edit, re-verify -> final green counts, allow ---
T="$WORK/c11.jsonl"
{ u "fix the bug"; edit Edit /tmp/proj/app.py; toolres; bashcmd "pytest -q"; toolres; edit Edit /tmp/proj/app.py; toolres; bashcmd "pytest -q"; toolres; } > "$T"
run_gate "$T"
expect_allow "c11 re-verify after re-edit"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
