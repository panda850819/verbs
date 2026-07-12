#!/usr/bin/env bash
# PreToolUse guard — ticket-gated worktree enforcement at code level.
# Enforce, don't instruct (same Nisi principle as the destructive guard): the
# AGENTS.md rule "never commit code directly on the default branch; the
# issue-keyed branch's PR is the only path to main" is only real as an exit-2
# hook. Reinstated per issue #203 (GitHub-issue flavored; Linear retired in
# substrate v0.9.13).
#
# Blocks, for Bash git commands:
#   1. `git commit` while the target repo's HEAD is on main/master
#   2. `git push` with an explicit main/master refspec
#   3. bare `git push` while HEAD is on main/master (implicit upstream push)
# Branch NAMING (feat/<issue>-slug / fix/local-<n>) stays advisory — the block
# message documents it; rebase/detached-HEAD states never block.
#
# Repo resolution: first `git -C <path>` in the segment (relative paths resolve
# against the hook payload cwd), else the payload cwd. Known residuals, all in
# the fail-open direction: a `cd`-then-git chain resolves to the payload cwd;
# a quoted `-C` path containing spaces resolves wrong and passes; a repo whose
# default branch is neither main nor master is not recognized.
#
# Opt-out per repo: a `.verbs-ticket-gate-off` file at the repo toplevel
# (brain/knowledge repos, harness config repos — surfaces that are exempt from
# ticket-gated dev per AGENTS.md and legitimately commit to main).
# Bypass: PSTICKET_FORCE=1 or PANDA_FORCE=1 (emergency, per CLAUDE.md delta).
# Kill switch: VERBS_TICKET_GATE=off.
# Fail-open: malformed input, non-repo cwd, detached HEAD, unresolvable state
# allow the command; only a positive match on a resolvable repo blocks.
#
# Test offline (zero risk):
#   bash tests/ticket-gate-guard-test.sh
set -euo pipefail

case "${VERBS_TICKET_GATE:-}" in
  [oO][fF][fF]) exit 0 ;;
esac
[ "${PSTICKET_FORCE:-}" = "1" ] && exit 0
[ "${PANDA_FORCE:-}" = "1" ] && exit 0

fail_open() {
  trap - ERR
  printf '[verbs ticket-gate] unavailable: %s; allowing command.\n' "$1" >&2
  exit 0
}
trap 'fail_open "internal guard error"' ERR

INPUT=$(cat) || fail_open "unable to read PreToolUse input"
# Cheap pre-filter: no "git" substring anywhere → nothing to gate, no parser.
case "$INPUT" in *git*) ;; *) exit 0 ;; esac

if ! PARSED=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
if not isinstance(data, dict):
    sys.exit(1)
if data.get("tool_name", "") != "Bash":
    print("SKIP")
    sys.exit(0)
tool_input = data.get("tool_input")
if not isinstance(tool_input, dict) or not isinstance(tool_input.get("command"), str):
    print("SKIP")
    sys.exit(0)
cwd = data.get("cwd", "")
if not isinstance(cwd, str):
    cwd = ""
sys.stdout.write("BASH\n")
sys.stdout.write(cwd + "\n")
sys.stdout.write(tool_input["command"])
' 2>/dev/null); then
  fail_open "malformed PreToolUse input"
fi
[ "$PARSED" = "SKIP" ] && exit 0

REST=${PARSED#BASH$'\n'}
HOOK_CWD=${REST%%$'\n'*}
case "$REST" in
  *$'\n'*) CMD=${REST#*$'\n'} ;;
  *) CMD="" ;;
esac
[ -n "$CMD" ] || exit 0
[ -n "$HOOK_CWD" ] || HOOK_CWD=$(pwd)

# From here on, a defect in the detector must surface as a hook error; it must
# never be converted into an exit-0 bypass (same contract as the destructive
# guard). Expected git failures (not a repo, detached HEAD) are handled
# explicitly below and fail open by design.
trap - ERR

block() {
  echo "BLOCKED by Verbs ticket-gate: $1" >&2
  echo "Code rides issue-keyed branches (feat/<issue>-slug / fix/local-<n>); the branch's PR is the only path to main (AGENTS.md ticket-gated worktree dev). Bypass for a real emergency: PSTICKET_FORCE=1. A non-code repo opts out with a .verbs-ticket-gate-off file at its toplevel." >&2
  exit 2
}

# repo_dir <raw-segment> — repo a git command targets: first `-C <path>` value
# (surrounding quotes stripped, relative resolved against hook cwd), else the
# hook cwd.
repo_dir() {
  local dir
  dir=$(printf '%s' "$1" | awk '{for(i=1;i<NF;i++) if($i=="-C"){print $(i+1); exit}}')
  dir=${dir#\'}; dir=${dir%\'}; dir=${dir#\"}; dir=${dir%\"}
  if [ -z "$dir" ]; then
    printf '%s' "$HOOK_CWD"
    return
  fi
  case "$dir" in
    /*) printf '%s' "$dir" ;;
    *) printf '%s/%s' "$HOOK_CWD" "$dir" ;;
  esac
}

# current_branch <dir> — short branch name; empty when detached or not a repo.
current_branch() {
  git -C "$1" symbolic-ref --short -q HEAD 2>/dev/null || true
}

# gate_off <dir> — 0 when the repo carries the opt-out marker at its toplevel.
gate_off() {
  local top
  top=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || return 1
  [ -f "$top/.verbs-ticket-gate-off" ]
}

# Strip quoted strings so git/commit/push/main inside a commit message or echo
# payload reads as data, then split on && || ; into segments.
STRIPPED=$(printf '%s' "$CMD" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")
SEGS=$(printf '%s' "$STRIPPED" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g')

while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  low=$(printf '%s' "$seg" | tr 'A-Z' 'a-z')
  printf '%s' "$low" | grep -qE '(^|[^a-z])git([^a-z]|$)' || continue

  if printf '%s' "$low" | grep -qE '(^|[^a-z])commit([^a-z]|$)'; then
    dir=$(repo_dir "$seg")
    br=$(current_branch "$dir")
    case "$br" in
      main|master)
        gate_off "$dir" || block "git commit on default branch '$br'"
        ;;
    esac
  fi

  if printf '%s' "$low" | grep -qE '(^|[^a-z])push([^a-z]|$)'; then
    dir=$(repo_dir "$seg")
    if printf '%s' "$low" | grep -qE '(^|[[:space:]])[+]?(refs/heads/)?(main|master)([[:space:]]|$)|:(refs/heads/)?(main|master)([[:space:]]|$)'; then
      # Explicit main/master refspec: block whenever the target is a real repo.
      if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
        gate_off "$dir" || block "git push targeting the default branch"
      fi
    else
      br=$(current_branch "$dir")
      case "$br" in
        main|master)
          gate_off "$dir" || block "bare git push while on default branch '$br'"
          ;;
      esac
    fi
  fi
done <<EOF
$SEGS
EOF
exit 0
