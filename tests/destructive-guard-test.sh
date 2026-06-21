#!/usr/bin/env bash
# Offline tests for pretooluse-destructive-guard.sh. Zero risk: every case is a
# JSON object piped to the guard on stdin; nothing in the fixtures is executed.
# Mirrors the guard header's echo-JSON-pipe smoke style.
#
# Run: bash tests/destructive-guard-test.sh
# (Danger tokens live INSIDE this file as data, never in an invoking argv, so a
#  live PreToolUse guard does not false-trigger on the test runner itself.)
set -uo pipefail

GUARD="$(cd "$(dirname "$0")/.." && pwd)/plugins/pandastack/hooks/pretooluse-destructive-guard.sh"
[ -x "$GUARD" ] || { echo "guard not executable: $GUARD" >&2; exit 1; }
pass=0 fail=0

# check <expect 0|2> <description> <command-string>
check() {
  local expect="$1" desc="$2" cmd="$3" json got
  json=$(printf '%s' "$cmd" | python3 -c 'import sys,json;print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.stdin.read()}}))')
  printf '%s' "$json" | "$GUARD" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$expect" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    printf 'FAIL  %-34s expected exit %s, got %s\n' "$desc" "$expect" "$got"
  fi
}

# --- must BLOCK (exit 2): real leading danger commands ---
check 2 "rm -rf leading"            'rm -rf /tmp/x'
check 2 "rm -fr flag order"         'rm -fr build'
check 2 "rm -r -f split flags"      'rm -r -f node_modules'
check 2 "sudo rm -rf"               'sudo rm -rf /var/cache/x'
check 2 "find | xargs rm -rf"       'find . -name "*.tmp" | xargs rm -rf'
check 2 "loop do rm -rf"            'for d in a b; do rm -rf "$d"; done'
check 2 "git push --force"          'git push --force'
check 2 "git push -f short"         'git push -f origin main'
check 2 "git -C dir push --force"   'git -C /repo push --force origin main'
check 2 "git push +ref"             'git push origin +main'
check 2 "git reset --hard"          'git reset --hard HEAD~3'
check 2 "git clean -fd"             'git clean -fd'
check 2 "psql -c DROP TABLE"        'psql mydb -c "DROP TABLE users"'
check 2 "echo DROP | psql"          'echo "DROP TABLE users" | psql mydb'
check 2 "TRUNCATE via mysql"        'mysql -e "TRUNCATE TABLE logs"'
check 2 "psql heredoc DROP"         $'psql <<\'SQL\'\nDROP TABLE x;\nSQL'
# real danger behind wrappers / grouping / substitution (unquoted -> still caught)
check 2 "sudo -u USER rm -rf"        'sudo -u www-data rm -rf /var/www'
check 2 "nice -n N rm -rf"           'nice -n 19 rm -rf /node_modules'
check 2 "env -u VAR rm -rf"          'env -u STALE rm -rf /data'
check 2 "timeout N rm -rf"           'timeout 5 rm -rf /tmp/build'
check 2 "subshell ( rm -rf )"        '( rm -rf /data )'
check 2 "cmd-subst x=\$(rm -rf)"     'x=$(rm -rf /data)'
check 2 "flock rm -rf"               'flock /tmp/lock rm -rf /var/cache'

# --- must ALLOW (exit 0): danger tokens as DATA, not the command ---
check 0 "python3 -c rm string"      "python3 -c 'print(\"rm -rf /\")'"
check 0 "python3 -c git push str"   "python3 -c 'x=\"git push --force\"'"
check 0 "git commit msg drop table" 'git commit -m "migration to DROP TABLE old_logs"'
check 0 "echo documents drop table" 'echo "to clean up run DROP TABLE x in psql"'
check 0 "curl payload has rm -rf"   'curl -d "cmd=rm -rf /" https://example.test/api'
check 0 "rm -i no force"            'rm -i file.txt'
check 0 "rm -r no force"            'rm -r emptydir'
check 0 "git push no force"         'git push origin feature'
check 0 "git status"                'git status'
check 0 "grep for rm in file"       'grep "rm -rf" notes.md'
check 0 "printf drop table doc"     'printf "DROP TABLE syntax\n"'
check 0 "python heredoc data dump"  $'python3 - <<\'PY\'\ndesc = "fixes rm -rf and git push --force mentions"\nprint(desc)\nPY'
# danger flags inside a quoted filename / payload (data) -> must pass
check 0 "rm quoted name has -rf"     'rm "old -rf backup.txt"'
check 0 "rm quoted path has --force" 'rm "./logs/run --force.log"'
check 0 "echo danger | tee file"     'echo "rm -rf /" | tee danger-doc.txt'
check 0 "psql SELECT no drop"        'psql mydb -c "SELECT count(*) FROM t"'
check 0 "commit msg force push words" 'git commit -m "notes on force push and reset --hard"'
check 0 "unicode data payload"       "python3 -c 'print(\"中文 rm -rf /\")'"
check 0 "rm -f path has -r substr"   'rm -f ./my-recursive-force-notes.txt'
check 0 "rm -r dir has -f substr"    'rm -r ./build-final-output'

# --- bypass still works ---
check 0 "FORCE_OK trailing override" 'git push --force  # FORCE_OK'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
