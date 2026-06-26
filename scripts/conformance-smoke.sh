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
PROBE_SKILL="grill"   # core, markdown-only, exists since v1
PROMPT="List the names of the pandastack skills available to you, plain text, one per line, nothing else."

fail=0
ran=0

check_output() {
  local host="$1" out="$2"
  if echo "$out" | grep -q "$PROBE_SKILL"; then
    echo "PASS [$host]: pandastack skills discovered (probe: $PROBE_SKILL)"
  else
    echo "FAIL [$host]: probe skill '$PROBE_SKILL' not in skill enumeration. Output head:"
    echo "$out" | head -5 | sed 's/^/  | /'
    fail=1
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
  claude) run_hook; run_claude ;;
  codex)  run_hook; run_codex ;;
  hook)   run_hook ;;
  all)    run_hook; run_claude; run_codex ;;
  *) echo "unknown host: $target (claude|codex|hook|all)"; exit 2 ;;
esac

[ "$ran" -eq 0 ] && { echo "FAIL: no host could be tested"; exit 1; }
exit "$fail"
