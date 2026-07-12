#!/usr/bin/env bash
# PreToolUse guard — hard-blocks destructive Bash commands at code level.
# Nisi principle: enforce, don't instruct. A prompt-level "please confirm"
# can be skipped by the agent; an exit-2 hook cannot.
#
# Reads PreToolUse stdin JSON, inspects tool_input.command, exit 2 to block.
# Strategy: a danger token only counts as a command when it appears UNQUOTED.
# So we strip quoted strings first, then scan each ; && || newline segment for
# rm/git danger. A token inside python3 -c '...', echo "...", a commit message,
# or a heredoc value is therefore data, not a command, and passes — while a real
# `rm -rf` (incl. behind sudo / nice / timeout / ( ) / $()) is unquoted and still
# blocks. SQL DROP/TRUNCATE is command-scoped: the statement (seen raw) must also
# reach an actually-invoked client (seen stripped), so a bare mention passes.
# Bypass: a TRAILING `# FORCE_OK` comment (not a substring anywhere), or
# VERBS_FORCE=1 in the environment.
# Kill switch: VERBS_DESTRUCTIVE_GUARD=off. Infrastructure failures emit a
# visible notice and allow the command; only a positive danger match exits 2.
#
# Known residuals (fail-safe, rare — bias is over-block-not-under, except these):
#   - A danger token inside a QUOTED payload handed to an executing interpreter
#     (`bash -c "rm -rf"`, `eval "..."`, `ssh host "rm -rf"`) is indistinguishable
#     from documenting it, so it is NOT caught. Likewise quoting a flag itself
#     (`rm "-rf" x`, `git push "--force"`) evades the scan. Both are unusual.
#   - A safe statement that merely MENTIONS drop/truncate while a real client runs
#     elsewhere in the command over-blocks (e.g. a SELECT whose WHERE matches the
#     text). Remote `ssh host "psql ... DROP"` and DROP/TABLE split across physical
#     newlines are not caught. Non-rm/git verbs (find -delete, dd, shred) are out
#     of this guard's scope entirely.
#
# Test offline (zero risk):
#   echo '{"tool_name":"Bash","tool_input":{"command":"git push --force"}}' | ./pretooluse-destructive-guard.sh; echo $?
#   bash tests/destructive-guard-test.sh   # full positive/negative suite
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

log_event() {
  local decision="$1" reason_code="$2"
  case "$decision:$reason_code:${VERBS_GUARD_EVENT_LEVEL:-}" in
    allow:no_policy_match:*|allow:not_bash:*)
      case "${VERBS_GUARD_EVENT_LEVEL:-}" in
        [aA][lL][lL]) ;;
        *) return 0 ;;
      esac
      ;;
  esac
  printf '%s' "${INPUT-}" | python3 "$SCRIPT_DIR/guard_events.py" \
    --hook PreToolUse --action destructive-bash \
    --decision "$decision" --reason-code "$reason_code" || true
}

case "${VERBS_DESTRUCTIVE_GUARD:-}" in
  [oO][fF][fF]) exit 0 ;;
esac

fail_open() {
  trap - ERR
  log_event error "guard_unavailable"
  printf '[verbs destructive-guard] unavailable: %s; allowing command.\n' "$1" >&2
  exit 0
}
trap 'fail_open "internal guard error"' ERR

INPUT=$(cat) || fail_open "unable to read PreToolUse input"
# Single parser pass: tool gate + command extraction in one python3 spawn
# (was two — each cold interpreter start taxed every Bash tool call).
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
    print("BADBASH")
    sys.exit(0)
sys.stdout.write("BASH\n")
sys.stdout.write(tool_input["command"])
' 2>/dev/null); then
  fail_open "malformed PreToolUse input"
fi
case "$PARSED" in
  SKIP) log_event allow "not_bash"; exit 0 ;;
  BADBASH) fail_open "malformed Bash tool input" ;;
  BASH) fail_open "empty Bash command" ;;
esac
CMD=${PARSED#BASH$'\n'}
[ -n "$CMD" ] || fail_open "empty Bash command"

# From here on, a defect in the danger detector must surface as a hook error;
# it must never be converted into an exit-0 bypass by the parsing fail-open.
trap - ERR

# Bypass: marker must be a TRAILING comment, not a mention mid-command.
if printf '%s' "$CMD" | grep -qE '#[[:space:]]*FORCE_OK[[:space:]]*$'; then
  log_event allow "force_ok_override"
  exit 0
fi
if [ "${VERBS_FORCE:-}" = "1" ]; then
  log_event allow "verbs_force_override"
  exit 0
fi

block() {
  local reason_code="$1" detail="$2"
  log_event deny "$reason_code"
  echo "BLOCKED by Verbs destructive-guard: $detail" >&2
  echo "High-blast-radius op (force-push / recursive-force-rm / hard-reset / clean -f / DROP). Confirm explicitly or narrow it; append '# FORCE_OK' as a trailing comment to override." >&2
  exit 2
}

# SQL clients that actually execute a statement; used to bind DROP/TRUNCATE to a
# real executor rather than the words appearing as data. Space-padded for match.
SQL_CLIENTS=" psql mysql mariadb mysqldump sqlite3 cockroach mongo mongosh clickhouse-client "

# leading_exe <stage> — basename of the stage's lead command, skipping leading
# env-assignments (FOO=bar) and exec wrappers (sudo/env/...). Only ever called in
# command substitution, so the local `set -f` (glob off, so a literal * in data
# can't expand) stays contained.
leading_exe() {
  set -f
  local tok
  for tok in $1; do
    case "$tok" in
      [A-Za-z_]*=*) continue ;;                                  # env assignment
      sudo|doas|env|command|builtin|nice|nohup|time|ionice|stdbuf|xargs|then|do) continue ;;
    esac
    printf '%s' "${tok##*/}"
    return
  done
}

# cmd_has_sql_client <stripped-segments> — true if any pipe stage of any segment
# leads with a SQL client (psql/mysql/...). Fed the quote-STRIPPED command so a
# client named only as data (`echo "use psql"`) does not count.
cmd_has_sql_client() {
  local seg stage lx oIFS=$IFS rc=1
  set -f
  while IFS= read -r seg; do
    [ -n "$seg" ] || continue
    IFS='|'
    for stage in $seg; do
      lx=$(IFS=$oIFS; leading_exe "$stage")
      case "$SQL_CLIENTS" in *" $lx "*) rc=0; break 2 ;; esac
    done
    IFS=$oIFS
  done <<HEREDOC
$1
HEREDOC
  IFS=$oIFS; set +f
  return $rc
}

# Strip quoted strings (single then double), so a danger token that is DATA does
# not read as a command. Real destructive commands are unquoted and survive.
STRIPPED=$(printf '%s' "$CMD" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")
SEGS=$(printf '%s' "$STRIPPED" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g')

# SQL destructive: a DROP/TRUNCATE statement (seen in the raw command) that also
# reaches an actually-invoked SQL client (seen in the stripped command). Command-
# scoped so the statement (in a heredoc/quoted payload) and its client need not
# share a segment, while a bare textual mention with no client does not block.
if printf '%s' "$CMD" | grep -qiE '(drop|truncate)[[:space:]]+(table|database|schema)' \
   && cmd_has_sql_client "$SEGS"; then
  block "database_drop_or_truncate" "DROP/TRUNCATE handed to a database client"
fi

# rm / git rules: scan each quote-stripped segment as a whole — once data is
# stripped, position within the segment no longer matters.
while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  low=$(printf '%s' "$seg" | tr 'A-Z' 'a-z')

  # rm: blocks only when BOTH recursive AND force are present (any flag form /
  # order: -rf, -fr, -r -f, --recursive --force). `rm -i -v` etc. pass. Flags are
  # anchored to a token boundary so a PATH containing `-r..`/`-f..` (e.g.
  # `rm -f ./my-recovery-final.log`) is not misread as the flags.
  if printf '%s' "$seg" | grep -qE '(^|[^a-zA-Z._-])rm([^a-zA-Z._]|$)' \
     && printf '%s' "$seg" | grep -qE '(^|[[:space:]])(-[a-zA-Z]*r|--recursive)' \
     && printf '%s' "$seg" | grep -qE '(^|[[:space:]])(-[a-zA-Z]*f|--force)'; then
    block "recursive_force_remove" "$seg"
  fi

  # git push force: --force(-with-lease), a bundled short flag containing f
  # (-f / -uf), or a +ref refspec (git push origin +main). Tolerates global
  # options between git and push (git -C dir push ...).
  if printf '%s' "$low" | grep -qE '(^|[^a-z])git([^a-z]|$)' && printf '%s' "$low" | grep -qE '(^|[^a-z])push([^a-z]|$)'; then
    if printf '%s' "$low" | grep -qE -- '--force' \
       || printf '%s' "$low" | grep -qE '[[:space:]]-[a-z]*f([[:space:]]|$)' \
       || printf '%s' "$low" | grep -qE 'push[[:space:]][^|]*[[:space:]]\+[^[:space:]]'; then
      block "force_push" "$seg"
    fi
  fi

  # git reset --hard
  if printf '%s' "$low" | grep -qE '(^|[^a-z])git([^a-z]|$)' && printf '%s' "$low" | grep -qE '(^|[^a-z])reset([^a-z]|$)' && printf '%s' "$low" | grep -qE -- '--hard'; then
    block "hard_reset" "$seg"
  fi

  # git clean -f / --force (flag anchored to a token boundary, as with rm)
  if printf '%s' "$low" | grep -qE '(^|[^a-z])git([^a-z]|$)' && printf '%s' "$low" | grep -qE '(^|[^a-z])clean([^a-z]|$)' && printf '%s' "$low" | grep -qE '(^|[[:space:]])(-[a-z]*f|--force)'; then
    block "force_clean" "$seg"
  fi
done <<EOF
$SEGS
EOF
log_event allow "no_policy_match"
exit 0
