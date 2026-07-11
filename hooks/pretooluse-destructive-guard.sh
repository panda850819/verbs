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

INPUT=$(cat)
TOOL=$(printf '%s' "$INPUT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null || true)
[ "$TOOL" = "Bash" ] || exit 0

CMD=$(printf '%s' "$INPUT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)
[ -n "$CMD" ] || exit 0

# Bypass: marker must be a TRAILING comment, not a mention mid-command.
printf '%s' "$CMD" | grep -qE '#[[:space:]]*FORCE_OK[[:space:]]*$' && exit 0
[ "${VERBS_FORCE:-}" = "1" ] && exit 0

block() {
  echo "BLOCKED by Verbs destructive-guard: $1" >&2
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
  block "DROP/TRUNCATE handed to a database client"
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
    block "$seg"
  fi

  # git push force: --force(-with-lease), a bundled short flag containing f
  # (-f / -uf), or a +ref refspec (git push origin +main). Tolerates global
  # options between git and push (git -C dir push ...).
  if printf '%s' "$low" | grep -qE '(^|[^a-z])git([^a-z]|$)' && printf '%s' "$low" | grep -qE '(^|[^a-z])push([^a-z]|$)'; then
    if printf '%s' "$low" | grep -qE -- '--force' \
       || printf '%s' "$low" | grep -qE '[[:space:]]-[a-z]*f([[:space:]]|$)' \
       || printf '%s' "$low" | grep -qE 'push[[:space:]][^|]*[[:space:]]\+[^[:space:]]'; then
      block "$seg"
    fi
  fi

  # git reset --hard
  if printf '%s' "$low" | grep -qE '(^|[^a-z])git([^a-z]|$)' && printf '%s' "$low" | grep -qE '(^|[^a-z])reset([^a-z]|$)' && printf '%s' "$low" | grep -qE -- '--hard'; then
    block "$seg"
  fi

  # git clean -f / --force (flag anchored to a token boundary, as with rm)
  if printf '%s' "$low" | grep -qE '(^|[^a-z])git([^a-z]|$)' && printf '%s' "$low" | grep -qE '(^|[^a-z])clean([^a-z]|$)' && printf '%s' "$low" | grep -qE '(^|[[:space:]])(-[a-z]*f|--force)'; then
    block "$seg"
  fi
done <<EOF
$SEGS
EOF
exit 0
