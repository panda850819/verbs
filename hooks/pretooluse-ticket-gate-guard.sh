#!/usr/bin/env bash
# PreToolUse guard for the ticket-gated worktree contract.
# Blocks commit on main/master, explicit pushes to main/master, implicit pushes
# while checked out on main/master, and push --all/--mirror. Branch naming stays
# advisory. Read-only git inspection is delegated to ticket_gate.py so quoted
# git -C paths, subcommand options, and refspecs are parsed by position.
#
# Opt-out: .verbs-ticket-gate-off at repo top.
# Bypass: PSTICKET_FORCE=1 or PANDA_FORCE=1. Kill switch: VERBS_TICKET_GATE=off.
# Malformed input and unresolvable repo state fail open visibly.
# Residuals: `sh -c`/`bash -c` quoted payloads, git aliases, `cd repo && git`,
# and default branches with names other than main/master remain outside scope.
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

log_event() {
  local decision="$1" reason_code="$2" artifact_ref="${3:-}"
  case "$decision:$reason_code:${VERBS_GUARD_EVENT_LEVEL:-}" in
    allow:no_policy_match:*|allow:not_bash:*|allow:no_git_token:*)
      case "${VERBS_GUARD_EVENT_LEVEL:-}" in
        [aA][lL][lL]) ;;
        *) return 0 ;;
      esac
      ;;
  esac
  if [ -n "$artifact_ref" ]; then
    printf '%s' "${INPUT-}" | python3 "$SCRIPT_DIR/guard_events.py" \
      --hook PreToolUse --action ticket-gate \
      --decision "$decision" --reason-code "$reason_code" \
      --artifact-ref "$artifact_ref" || true
  else
    printf '%s' "${INPUT-}" | python3 "$SCRIPT_DIR/guard_events.py" \
      --hook PreToolUse --action ticket-gate \
      --decision "$decision" --reason-code "$reason_code" || true
  fi
}

fail_open() {
  log_event error "guard_unavailable"
  printf '[verbs ticket-gate] unavailable: %s; allowing command.\n' "$1" >&2
  exit 0
}

INPUT=$(cat) || fail_open "unable to read PreToolUse input"
case "$INPUT" in
  *git*) ;;
  *) log_event allow "no_git_token"; exit 0 ;;
esac
case "${VERBS_TICKET_GATE:-}" in
  [oO][fF][fF]) log_event allow "kill_switch_off"; exit 0 ;;
esac
if [ "${PSTICKET_FORCE:-}" = "1" ]; then
  log_event allow "psticket_force_override"
  exit 0
fi
if [ "${PANDA_FORCE:-}" = "1" ]; then
  log_event allow "panda_force_override"
  exit 0
fi

if ! RESULT=$(printf '%s' "$INPUT" | python3 "$SCRIPT_DIR/ticket_gate.py" 2>/dev/null); then
  fail_open "malformed PreToolUse input"
fi
IFS=$'\t' read -r DECISION REASON_CODE DETAIL ARTIFACT_REF <<EOF
$RESULT
EOF
if [ "$DECISION" = "deny" ]; then
  log_event deny "$REASON_CODE" "$ARTIFACT_REF"
  echo "BLOCKED by Verbs ticket-gate: $DETAIL" >&2
  echo "Code rides issue-keyed branches (feat/<issue>-slug / fix/local-<n>); the branch's PR is the only path to main. Emergency bypass: PSTICKET_FORCE=1. Non-code repos opt out with .verbs-ticket-gate-off." >&2
  exit 2
fi
log_event allow "${REASON_CODE:-no_policy_match}"
exit 0
