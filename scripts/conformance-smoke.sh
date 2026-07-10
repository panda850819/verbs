#!/usr/bin/env bash
# conformance-smoke.sh — cross-runtime conformance smoke for pandastack.
# Verifies each host actually discovers pandastack skills, headless.
# ADDING_A_HOST.md requires "one real invocation path tested"; this is that
# test, automated. Run after skill renames, manifest changes, or hook edits.
#
# Usage:
#   bash scripts/conformance-smoke.sh            # all available hosts
#   bash scripts/conformance-smoke.sh claude     # one host
#   bash scripts/conformance-smoke.sh codex
#
# Each host check costs one short LLM call. Exit 0 = all attempted hosts pass.

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_JSON="$(python3 "$repo_root/scripts/pandastack" doctor --json | python3 -c '
import json,sys
print(json.dumps(json.load(sys.stdin)["checks"]["runtime_surface"]["expected"]))
')"
PROMPT='Return the exact basenames of every available pandastack skill, and no skills from other packs. Output one line only in this format: PANDASTACK_SKILLS_JSON=["name", "name"].'

fail=0
ran=0

parse_skill_output() {
  local out="$1"
  printf '%s' "$out" | python3 -c '
import json,re,sys
expected=set(json.loads(sys.argv[1]))
text=sys.stdin.read()
matches=re.findall(r"PANDASTACK_SKILLS_JSON\s*=\s*(\[[^\n]*\])", text)
if not matches:
    print("missing PANDASTACK_SKILLS_JSON marker")
    raise SystemExit(1)
try:
    raw=json.loads(matches[-1])
except ValueError as exc:
    print("invalid skill JSON: {}".format(exc))
    raise SystemExit(1)
if not isinstance(raw, list) or not all(isinstance(item, str) for item in raw):
    print("skill JSON must be an array of strings")
    raise SystemExit(1)
def normalize(value):
    name=value.strip().strip("`")
    qualified=name.lstrip("/")
    if ":" in qualified:
        prefix,name=qualified.rsplit(":", 1)
        if prefix != "pandastack":
            raise ValueError("foreign namespace: " + prefix)
    elif "/" in name:
        raise ValueError("foreign path: " + name)
    return name
try:
    actual={normalize(item) for item in raw}
except ValueError as exc:
    print(str(exc))
    raise SystemExit(1)
missing=sorted(expected-actual)
extra=sorted(actual-expected)
if missing: print("missing: " + ", ".join(missing))
if extra: print("extra: " + ", ".join(extra))
raise SystemExit(1 if missing or extra else 0)
' "$EXPECTED_JSON"
}

check_output() {
  local host="$1" out="$2"
  if parse_skill_output "$out"; then
    echo "PASS [$host]: exact pandastack skill surface discovered"
  else
    echo "FAIL [$host]: discovered skill surface differs from manifest. Output head:"
    echo "$out" | head -5 | sed 's/^/  | /'
    fail=1
  fi
}

run_parser_tests() {
  ran=1
  local missing extra foreign namespaced
  if parse_skill_output "PANDASTACK_SKILLS_JSON=$EXPECTED_JSON" >/dev/null; then
    echo "PASS [parser]: exact set accepted"
  else
    echo "FAIL [parser]: exact set rejected"
    fail=1
  fi
  namespaced="$(python3 -c 'import json,sys; print(json.dumps(["pandastack:"+x for x in json.loads(sys.argv[1])]))' "$EXPECTED_JSON")"
  if parse_skill_output "PANDASTACK_SKILLS_JSON=$namespaced" >/dev/null; then
    echo "PASS [parser]: pandastack namespace accepted"
  else
    echo "FAIL [parser]: pandastack namespace rejected"
    fail=1
  fi
  missing="$(python3 -c 'import json,sys; a=json.loads(sys.argv[1]); print(json.dumps(a[1:]))' "$EXPECTED_JSON")"
  if parse_skill_output "PANDASTACK_SKILLS_JSON=$missing" >/dev/null; then
    echo "FAIL [parser]: missing skill accepted"
    fail=1
  else
    echo "PASS [parser]: missing skill rejected"
  fi
  extra="$(python3 -c 'import json,sys; a=json.loads(sys.argv[1]); a.append("checkpoint"); print(json.dumps(a))' "$EXPECTED_JSON")"
  if parse_skill_output "PANDASTACK_SKILLS_JSON=$extra" >/dev/null; then
    echo "FAIL [parser]: extra retired skill accepted"
    fail=1
  else
    echo "PASS [parser]: extra retired skill rejected"
  fi
  foreign="$(python3 -c 'import json,sys; a=json.loads(sys.argv[1]); a[0]="gbrain:"+a[0]; print(json.dumps(a))' "$EXPECTED_JSON")"
  if parse_skill_output "PANDASTACK_SKILLS_JSON=$foreign" >/dev/null; then
    echo "FAIL [parser]: foreign namespace collision accepted"
    fail=1
  else
    echo "PASS [parser]: foreign namespace collision rejected"
  fi
}

run_claude() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "SKIP [claude]: claude CLI not on PATH"
    return
  fi
  ran=1
  local out
  out="$(claude -p --max-turns 1 "$PROMPT" 2>&1)" || { echo "FAIL [claude]: invocation error: $(echo "$out" | head -2)"; fail=1; return; }
  check_output claude "$out"
}

run_codex() {
  if ! command -v codex >/dev/null 2>&1; then
    echo "SKIP [codex]: codex CLI not on PATH"
    return
  fi
  ran=1
  local out
  out="$(codex exec --skip-git-repo-check "$PROMPT" 2>&1)" || { echo "FAIL [codex]: invocation error: $(echo "$out" | head -2)"; fail=1; return; }
  check_output codex "$out"
}

# Hook conformance: session-start must emit valid JSON in every envelope.
run_hook() {
  ran=1
  local hook="$repo_root/hooks/session-start"
  local out
  for envelope in codex claude cursor; do
    case "$envelope" in
      codex)  out="$(env -u CLAUDE_PLUGIN_ROOT -u CURSOR_PLUGIN_ROOT -u COPILOT_CLI bash "$hook")" ;;
      claude) out="$(env -u CURSOR_PLUGIN_ROOT -u COPILOT_CLI CLAUDE_PLUGIN_ROOT=/tmp bash "$hook")" ;;
      cursor) out="$(env -u COPILOT_CLI CURSOR_PLUGIN_ROOT=/tmp bash "$hook")" ;;
    esac
    if echo "$out" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
      echo "PASS [hook:$envelope]: session-start emits valid JSON"
    else
      echo "FAIL [hook:$envelope]: session-start output is not valid JSON"
      fail=1
    fi
  done
}

target="${1:-all}"
case "$target" in
  claude) run_hook; run_parser_tests; run_claude ;;
  codex)  run_hook; run_parser_tests; run_codex ;;
  hook)   run_hook; run_parser_tests ;;
  all)    run_hook; run_parser_tests; run_claude; run_codex ;;
  *) echo "unknown host: $target (claude|codex|hook|all)"; exit 2 ;;
esac

[ "$ran" -eq 0 ] && { echo "FAIL: no host could be tested"; exit 1; }
exit "$fail"
