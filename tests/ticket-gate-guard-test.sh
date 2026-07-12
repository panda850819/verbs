#!/usr/bin/env bash
# Offline tests for pretooluse-ticket-gate-guard.sh. Zero risk: fixture git
# repos live under mktemp; every case is a JSON object piped to the guard on
# stdin, and the guard only ever runs read-only git queries (symbolic-ref /
# rev-parse) against the fixtures. Nothing in the JSON is executed.
#
# Run: bash tests/ticket-gate-guard-test.sh
set -uo pipefail

GUARD="$(cd "$(dirname "$0")/.." && pwd)/hooks/pretooluse-ticket-gate-guard.sh"
[ -x "$GUARD" ] || { echo "guard not executable: $GUARD" >&2; exit 1; }
pass=0 fail=0
WANT_NOTICE='BLOCKED by Verbs ticket-gate:'

TMPROOT=$(mktemp -d "${TMPDIR:-/tmp}/ticket-gate-test.XXXXXX")
trap 'rm -rf "$TMPROOT"' EXIT

mkrepo() { # <name> <branch> → prints repo path
  local d="$TMPROOT/$1"
  git init -q -b "$2" "$d"
  git -C "$d" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  printf '%s' "$d"
}

REPO_MAIN=$(mkrepo main-repo main)
REPO_MASTER=$(mkrepo master-repo master)
REPO_FEAT=$(mkrepo feat-repo feat/203-guard)
REPO_OFF=$(mkrepo off-repo main)
touch "$REPO_OFF/.verbs-ticket-gate-off"
REPO_DETACHED=$(mkrepo detached-repo main)
git -C "$REPO_DETACHED" checkout -q --detach
NONREPO="$TMPROOT/plain"
mkdir -p "$NONREPO"

# check <expect 0|2> <description> <cwd> <command-string> [ENV=val]
check() {
  local expect="$1" desc="$2" cwd="$3" cmd="$4" envkv="${5:-}" json got notice
  json=$(printf '%s' "$cmd" | python3 -c 'import sys,json;print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.stdin.read()}}))' "$cwd")
  if [ -n "$envkv" ]; then
    notice=$(printf '%s' "$json" | env "$envkv" "$GUARD" 2>&1 >/dev/null)
  else
    notice=$(printf '%s' "$json" | "$GUARD" 2>&1 >/dev/null)
  fi
  got=$?
  if [ "$got" = "$expect" ] && { [ "$expect" != 2 ] || printf '%s' "$notice" | grep -qF "$WANT_NOTICE"; }; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    printf 'FAIL  %-36s expected exit %s, got %s out=%s\n' "$desc" "$expect" "$got" "$notice"
  fi
}

# raw_check <expect> <description> <raw-json>
raw_check() {
  local expect="$1" desc="$2" raw="$3" got
  printf '%s' "$raw" | "$GUARD" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$expect" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    printf 'FAIL  %-36s expected exit %s, got %s\n' "$desc" "$expect" "$got"
  fi
}

# --- must BLOCK (exit 2) ---
check 2 "commit on main"              "$REPO_MAIN"   'git commit -m msg'
check 2 "commit --amend on master"    "$REPO_MASTER" 'git commit --amend --no-edit'
check 2 "commit via -C from outside"  "$NONREPO"     "git -C $REPO_MAIN commit -m msg"
check 2 "chained commit on main"      "$REPO_MAIN"   'echo ok && git commit -m msg'
check 2 "push explicit main"          "$REPO_FEAT"   'git push origin main'
check 2 "push refspec HEAD:main"      "$REPO_FEAT"   'git push origin HEAD:main'
check 2 "push +main force refspec"    "$REPO_FEAT"   'git push origin +main'
check 2 "push refs/heads/master"      "$REPO_FEAT"   'git push origin refs/heads/master'
check 2 "bare push while on main"     "$REPO_MAIN"   'git push'

# --- must ALLOW (exit 0) ---
check 0 "commit on issue branch"      "$REPO_FEAT"   'git commit -m msg'
check 0 "push issue branch"           "$REPO_FEAT"   'git push origin feat/203-guard'
check 0 "bare push on issue branch"   "$REPO_FEAT"   'git push'
check 0 "status on main"              "$REPO_MAIN"   'git status'
check 0 "pull on main"                "$REPO_MAIN"   'git pull origin main'
check 0 "log main ref"                "$REPO_MAIN"   'git log main --oneline'
check 0 "commit word as data"         "$REPO_MAIN"   'echo "git commit on main"'
check 0 "commit msg mentions main"    "$REPO_FEAT"   'git commit -m "fix main path handling"'
check 0 "non-git command"             "$REPO_MAIN"   'ls -la'
check 0 "non-repo cwd"                "$NONREPO"     'git commit -m msg'
check 0 "detached HEAD (rebase-like)" "$REPO_DETACHED" 'git commit -m msg'
check 0 "marker repo commit on main"  "$REPO_OFF"    'git commit -m msg'
check 0 "marker repo push main"       "$REPO_OFF"    'git push origin main'
check 0 "kill switch off"             "$REPO_MAIN"   'git commit -m msg' 'VERBS_TICKET_GATE=off'
check 0 "PSTICKET_FORCE bypass"       "$REPO_MAIN"   'git commit -m msg' 'PSTICKET_FORCE=1'
check 0 "PANDA_FORCE bypass"          "$REPO_MAIN"   'git commit -m msg' 'PANDA_FORCE=1'

# --- payload shapes ---
raw_check 0 "tool is not Bash"        '{"tool_name":"Read","tool_input":{"file_path":"/tmp/git"}}'
raw_check 0 "malformed json fail-open" '{"tool_name":"Bash","tool_input":{"command":"git commit'
raw_check 0 "no git substring"        '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}'
raw_check 0 "missing command field"   '{"tool_name":"Bash","tool_input":{"note":"git commit"}}'

echo "ticket-gate-guard-test: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
