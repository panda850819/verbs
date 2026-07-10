#!/usr/bin/env bash
# Offline Claude + Codex truth table for the ticket/worktree PreToolUse guard.
set -uo pipefail

GUARD="$(cd "$(dirname "$0")/.." && pwd)/hooks/pretooluse-ticket-gate-guard.sh"
[ -x "$GUARD" ] || { echo "guard not executable: $GUARD" >&2; exit 1; }
pass=0 fail=0

TMP=$(mktemp -d)
cleanup() { chmod -R u+w "$TMP" 2>/dev/null; /bin/rm -rf "$TMP"; }
trap cleanup EXIT

REPO="$TMP/coderepo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email t@t.test
git -C "$REPO" config user.name tester
echo seed > "$REPO/seed.txt"
git -C "$REPO" add -A
git -C "$REPO" commit -qm seed
BASE_BRANCH=$(git -C "$REPO" branch --show-current)

ISSUE_WT="$TMP/issue-wt"
SCRATCH_WT="$TMP/scratch-wt"
git -C "$REPO" worktree add -q -b feat/pro-999999-demo "$ISSUE_WT"
git -C "$REPO" worktree add -q -b scratch "$SCRATCH_WT"

file_payload() {
  python3 -c 'import json,sys; print(json.dumps({"tool_name":sys.argv[1],"cwd":sys.argv[3],"tool_input":{"file_path":sys.argv[2]}}))' "$1" "$2" "$3"
}

patch_payload() {
  PATCH_TEXT="$1" python3 -c 'import json,os,sys; print(json.dumps({"tool_name":"apply_patch","cwd":sys.argv[1],"tool_input":{"command":os.environ["PATCH_TEXT"]}}))' "$2"
}

patch_payload_shape() {
  PATCH_TEXT="$1" python3 -c 'import json,os,sys; value=os.environ["PATCH_TEXT"] if sys.argv[2]=="raw" else {sys.argv[2]:os.environ["PATCH_TEXT"]}; print(json.dumps({"tool_name":"apply_patch","cwd":sys.argv[1],"tool_input":value}))' "$2" "$3"
}

# check_payload <expect 0|2> <desc> <json> [ENV=val]
check_payload() {
  local expect="$1" desc="$2" payload="$3" envkv="${4:-}" got
  if [ -n "$envkv" ]; then
    printf '%s' "$payload" | env "$envkv" "$GUARD" >/dev/null 2>&1
  else
    printf '%s' "$payload" | "$GUARD" >/dev/null 2>&1
  fi
  got=$?
  if [ "$got" = "$expect" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    printf 'FAIL  %-58s expected %s got %s\n' "$desc" "$expect" "$got"
  fi
}

check_file() {
  check_payload "$1" "$2" "$(file_payload "$3" "$4" "$5")" "${6:-}"
}

check_patch() {
  check_payload "$1" "$2" "$(patch_payload "$3" "$4")" "${5:-}"
}

# Claude tools on the primary checkout: code blocks; docs and unknown tools allow.
check_file 2 "Claude Edit code on primary default branch" Edit "$REPO/app.py" "$REPO"
check_file 2 "Claude Write code on primary default branch" Write "$REPO/lib.sh" "$REPO"
check_file 2 "Claude MultiEdit code on primary default branch" MultiEdit "$REPO/mod.ts" "$REPO"
check_file 0 "Claude Edit markdown on primary" Edit "$REPO/README.md" "$REPO"
check_file 0 "Claude Edit JSON on primary" Edit "$REPO/config.json" "$REPO"
check_file 0 "Non-editor tool allows" Read "$REPO/app.py" "$REPO"

# The gate requires both an issue token and a real linked worktree.
check_file 0 "Linked issue-keyed worktree allows" Edit "$ISSUE_WT/app.py" "$ISSUE_WT"
check_file 0 "Nonexistent issue token is offline syntax only" Edit "$ISSUE_WT/other.py" "$ISSUE_WT"
check_file 2 "Linked non-issue worktree blocks" Edit "$SCRATCH_WT/app.py" "$SCRATCH_WT"
git -C "$REPO" checkout -q -b feat/pro-88-primary
check_file 2 "Issue branch in primary checkout still blocks" Edit "$REPO/app.py" "$REPO"
git -C "$REPO" checkout -q "$BASE_BRANCH"
git -C "$REPO" checkout -q --detach
check_file 2 "Detached primary checkout blocks" Edit "$REPO/app.py" "$REPO"
git -C "$REPO" checkout -q "$BASE_BRANCH"

# Relative paths resolve against payload.cwd; new directories and case are covered.
check_file 2 "Relative Claude path uses payload cwd" Edit "src/app.py" "$REPO"
check_file 0 "Relative path in linked issue worktree allows" Write "src/app.py" "$ISSUE_WT"
check_file 0 "New directory in linked worktree allows" Write "$ISSUE_WT/new/deep/app.py" "$ISSUE_WT"
check_file 0 "Uppercase extension in linked worktree allows" Edit "$ISSUE_WT/App.PY" "$ISSUE_WT"

# Codex canonical apply_patch payloads use tool_input.command and patch headers.
CODE_PATCH=$'*** Begin Patch\n*** Update File: app.py\n@@\n-old\n+new\n*** End Patch'
DOC_PATCH=$'*** Begin Patch\n*** Add File: notes.md\n+hello\n*** End Patch'
MIXED_PATCH=$'*** Begin Patch\n*** Update File: notes.md\n@@\n-old\n+new\n*** Update File: src/app.ts\n@@\n-old\n+new\n*** End Patch'
MOVE_PATCH=$'*** Begin Patch\n*** Update File: notes.md\n*** Move to: src/moved.py\n@@\n-old\n+new\n*** End Patch'
DELETE_PATCH=$'*** Begin Patch\n*** Delete File: src/old.py\n*** End Patch'

check_patch 2 "Codex code patch on primary blocks" "$CODE_PATCH" "$REPO"
check_payload 2 "Codex raw-string patch payload blocks" "$(patch_payload_shape "$CODE_PATCH" "$REPO" raw)"
check_payload 2 "Codex patch-field payload blocks" "$(patch_payload_shape "$CODE_PATCH" "$REPO" patch)"
check_patch 0 "Codex doc-only patch on primary allows" "$DOC_PATCH" "$REPO"
check_patch 2 "Codex mixed doc/code patch blocks" "$MIXED_PATCH" "$REPO"
check_patch 2 "Codex move destination code path blocks" "$MOVE_PATCH" "$REPO"
check_patch 2 "Codex delete code path blocks" "$DELETE_PATCH" "$REPO"
check_patch 0 "Codex code patch in linked issue worktree allows" "$CODE_PATCH" "$ISSUE_WT"
check_patch 2 "Codex code patch in linked scratch worktree blocks" "$CODE_PATCH" "$SCRATCH_WT"
check_patch 0 "Malformed patch fails open" "not a patch" "$REPO"

# Existing carve-outs, loose files, explicit bypasses, and HOME fail-open stay intact.
check_file 0 "brain repo code exempt" Edit "$HOME/site/knowledge/brain/x.py" "$HOME/site/knowledge/brain"
check_file 0 ".agents harness code exempt" Edit "$HOME/.agents/x.sh" "$HOME/.agents"
check_file 0 ".claude harness code exempt" Edit "$HOME/.claude/x.py" "$HOME/.claude"
check_file 0 ".codex harness code exempt" Edit "$HOME/.codex/x.js" "$HOME/.codex"
check_file 0 "code file outside git allows" Edit "$TMP/loose.py" "$TMP"
check_file 0 "PSTICKET_FORCE bypass" Edit "$REPO/app.py" "$REPO" "PSTICKET_FORCE=1"
check_file 0 "PANDA_FORCE bypass" Edit "$REPO/app.py" "$REPO" "PANDA_FORCE=1"

HOMELESS=$(file_payload Edit "$REPO/app.py" "$REPO")
printf '%s' "$HOMELESS" | env -u HOME "$GUARD" >/dev/null 2>&1
got=$?
if [ "$got" = 0 ]; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  printf 'FAIL  %-58s expected 0 got %s\n' "HOME unset fails open" "$got"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
