#!/usr/bin/env bash
# Offline tests for pretooluse-skill-fired-log.sh. Every case is JSON piped to
# the observer on stdin; the hook must never block a Skill invocation.
#
# Run: bash tests/skill-fired-log-test.sh
set -uo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/pretooluse-skill-fired-log.sh"
[ -x "$HOOK" ] || { echo "hook not executable: $HOOK" >&2; exit 1; }
pass=0 fail=0

TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT

record_pass() {
  pass=$((pass+1))
}

record_fail() {
  fail=$((fail+1))
  printf 'FAIL  %s\n' "$1"
}

check_skill_appends() {
  local home="$TMPROOT/skill-appends" log got lines fields skill
  mkdir -p "$home/.agents/memory"
  log="$home/.agents/memory/dispatch-fired.log"

  echo '{"tool_name":"Skill","tool_input":{"skill":"pandastack:debug"}}' | HOME="$home" "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" != 0 ]; then
    record_fail "skill fire exits 0, got $got"
    return
  fi

  [ -f "$log" ] || { record_fail "skill fire creates log when memory dir exists"; return; }
  lines=$(wc -l <"$log" | tr -d ' ')
  [ "$lines" = 1 ] || { record_fail "skill fire appends exactly one line, got $lines"; return; }

  fields=$(awk -F'|' 'NR==1 {print NF}' "$log")
  [ "$fields" = 4 ] || { record_fail "log line has 4 pipe-separated fields, got $fields"; return; }

  skill=$(awk -F'|' 'NR==1 {gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}' "$log")
  [ "$skill" = "pandastack:debug" ] || { record_fail "field 4 is skill name, got $skill"; return; }

  record_pass
}

check_memory_absent_noop() {
  local home="$TMPROOT/memory-absent" got
  mkdir -p "$home"

  echo '{"tool_name":"Skill","tool_input":{"skill":"pandastack:debug"}}' | HOME="$home" "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" != 0 ]; then
    record_fail "memory dir absent exits 0, got $got"
    return
  fi

  [ ! -e "$home/.agents/memory/dispatch-fired.log" ] || { record_fail "memory dir absent creates no log"; return; }
  [ ! -d "$home/.agents/memory" ] || { record_fail "memory dir absent does not mkdir"; return; }

  record_pass
}

check_non_skill_noop() {
  local home="$TMPROOT/non-skill" log got lines
  mkdir -p "$home/.agents/memory"
  log="$home/.agents/memory/dispatch-fired.log"

  echo '{"tool_name":"Bash","tool_input":{"skill":"pandastack:debug"}}' | HOME="$home" "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" != 0 ]; then
    record_fail "non-Skill tool exits 0, got $got"
    return
  fi

  if [ -f "$log" ]; then
    lines=$(wc -l <"$log" | tr -d ' ')
    [ "$lines" = 0 ] || { record_fail "non-Skill tool appends no lines, got $lines"; return; }
  fi

  record_pass
}

check_malformed_json_noop() {
  local home="$TMPROOT/malformed-json" got
  mkdir -p "$home/.agents/memory"

  printf '{not json\n' | HOME="$home" "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" != 0 ]; then
    record_fail "malformed JSON exits 0, got $got"
    return
  fi

  record_pass
}

check_skill_appends
check_memory_absent_noop
check_non_skill_noop
check_malformed_json_noop

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
