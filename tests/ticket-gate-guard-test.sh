#!/usr/bin/env bash
# Offline tests for pretooluse-ticket-gate-guard.sh. Zero risk: JSON is piped to
# the guard on stdin and only the exit code is checked; no file is edited. Temp
# git repos are created under mktemp to exercise the branch logic, then removed.
#
# Run: bash tests/ticket-gate-guard-test.sh
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

# check <expect 0|2> <desc> <tool> <file_path> [ENV=val]
check() {
  local expect="$1" desc="$2" tool="$3" fp="$4" envkv="${5:-}" json got
  json=$(python3 -c 'import json,sys;print(json.dumps({"tool_name":sys.argv[1],"tool_input":{"file_path":sys.argv[2]}}))' "$tool" "$fp")
  if [ -n "$envkv" ]; then
    printf '%s' "$json" | env "$envkv" "$GUARD" >/dev/null 2>&1
  else
    printf '%s' "$json" | "$GUARD" >/dev/null 2>&1
  fi
  got=$?
  if [ "$got" = "$expect" ]; then pass=$((pass+1)); else
    fail=$((fail+1)); printf 'FAIL  %-46s expected %s got %s\n' "$desc" "$expect" "$got"; fi
}

# --- on the default branch (main/master): code edits BLOCK ---
check 2 "Edit code on default branch"      Edit      "$REPO/app.py"
check 2 "Write code on default branch"     Write     "$REPO/lib.sh"
check 2 "MultiEdit code on default branch" MultiEdit "$REPO/mod.ts"

# --- doc / config / unknown extensions ALLOW even on default branch ---
check 0 "Edit .md on default branch"       Edit      "$REPO/README.md"
check 0 "Edit .json on default branch"     Edit      "$REPO/config.json"
check 0 "Edit no-extension on default"     Edit      "$REPO/Makefile"

# --- non-editor tools ALLOW ---
check 0 "Read tool on default-branch code" Read      "$REPO/app.py"
check 0 "Bash tool ignored"                Bash      "$REPO/app.py"

# --- carve-outs ALLOW (brain repo + harness config trees) ---
check 0 "brain repo code exempt"           Edit      "$HOME/site/knowledge/brain/x.py"
check 0 ".agents harness code exempt"      Edit      "$HOME/.agents/x.sh"
check 0 ".claude harness code exempt"      Edit      "$HOME/.claude/x.py"
check 0 ".codex harness code exempt"       Edit      "$HOME/.codex/x.js"

# --- non-git path ALLOW ---
check 0 "code file not in any git repo"    Edit      "$TMP/loose.py"

# --- bypass ALLOW ---
check 0 "PSTICKET_FORCE bypass"            Edit      "$REPO/app.py"  "PSTICKET_FORCE=1"
check 0 "PANDA_FORCE bypass"               Edit      "$REPO/app.py"  "PANDA_FORCE=1"

# --- issue-keyed worktree branches ALLOW (all the real forms, per review) ---
for br in feat/pro-1-demo fix/PRO-2-x panda-zeng/pro-51-x panda1/pro-51-x \
          feat/pro2-12-x feat/P1-12-x panda/feat/pro-12-x 42-fix-thing feat/42-fix; do
  git -C "$REPO" checkout -q -B "$br"
  check 0 "issue-keyed branch: $br"        Edit      "$REPO/app.py"
done

# --- non-issue branches still BLOCK ---
for br in scratch develop wip release-cut; do
  git -C "$REPO" checkout -q -B "$br"
  check 2 "non-issue branch blocks: $br"   Edit      "$REPO/app.py"
done

# --- on a blocking branch, the fail-open misses the review found are now closed ---
git -C "$REPO" checkout -q -B scratch
check 2 "Write into a not-yet-existing dir" Write    "$REPO/newdir/deep/new.py"
check 2 "uppercase .PY extension"           Edit     "$REPO/App.PY"

# --- detached HEAD fails open (mid-rebase / bisect / tag checkout) ---
git -C "$REPO" checkout -q --detach
check 0 "detached HEAD fails open"          Edit      "$REPO/app.py"

# --- HOME unset must NOT crash (exit 1); fail open (exit 0) ---
git -C "$REPO" checkout -q -B scratch
hjson=$(python3 -c 'import json,sys;print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":sys.argv[1]}}))' "$REPO/app.py")
printf '%s' "$hjson" | env -u HOME "$GUARD" >/dev/null 2>&1
hgot=$?
if [ "$hgot" = "0" ]; then pass=$((pass+1)); else fail=$((fail+1)); printf 'FAIL  %-46s expected 0 got %s\n' "HOME unset fails open (no crash)" "$hgot"; fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
