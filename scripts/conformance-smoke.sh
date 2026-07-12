#!/usr/bin/env bash
# Verify enabled plugin inventory, exact packaged parity, and one namespaced
# Verbs invocation. Host install is a prerequisite; this script never
# creates registry/cache fixtures.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cli="$repo_root/scripts/verbs"
fail=0
host_ran=0

if [ -n "${VERBS_SMOKE_EXPECT_HOME:-}" ]; then
  actual_home="$(cd "$HOME" 2>/dev/null && pwd -P)" || actual_home=""
  expected_home="$(cd "$VERBS_SMOKE_EXPECT_HOME" 2>/dev/null && pwd -P)" \
    || expected_home=""
  if [ -z "$actual_home" ] || [ "$actual_home" != "$expected_home" ]; then
    echo "FAIL: HOME is not the expected disposable smoke profile" >&2
    exit 1
  fi
fi

expected_version="$(python3 "$cli" doctor --json | python3 -c '
import json,sys
print(json.load(sys.stdin)["checks"]["runtime_surface"]["source"]["versions"]["manifest"])
')" || exit 1

check_inventory() {
  host="$1"
  printf '%s' "$2" | python3 -c '
import json, sys

host, version = sys.argv[1:]
data = json.load(sys.stdin)
if host == "claude":
    rows = data
    matches = [row for row in rows if row.get("id") == "verbs@verbs"]
    legacy = [row for row in rows if row.get("id") == "pandastack@pandastack" and row.get("enabled")]
    ok = len(matches) == 1 and matches[0].get("enabled") is True and matches[0].get("version") == version
else:
    rows = data.get("installed", [])
    matches = [row for row in rows if row.get("pluginId") == "verbs@verbs"]
    legacy = [row for row in rows if row.get("pluginId") == "pandastack@pandastack" and row.get("enabled")]
    ok = len(matches) == 1 and matches[0].get("installed") is True and matches[0].get("enabled") is True and matches[0].get("version") == version
if legacy:
    print("legacy pandastack plugin remains enabled", file=sys.stderr)
    raise SystemExit(1)
if not ok:
    print("verbs@verbs is not installed+enabled at version " + version, file=sys.stderr)
    raise SystemExit(1)
' "$host" "$expected_version"
}

check_doctor() {
  host="$1"
  if python3 "$cli" doctor --host "$host" --strict >/dev/null; then
    echo "PASS [$host]: enabled receipt and packaged surface match source"
  else
    echo "FAIL [$host]: doctor strict rejected installed parity" >&2
    fail=1
    return 1
  fi
}

check_invocation() {
  host="$1"
  out="$2"
  if printf '%s\n' "$out" | python3 -c '
import json
import sys

host = sys.argv[1]
activation = "CAREFUL mode ON. Will confirm before destructive actions."
events = []
for raw in sys.stdin:
    try:
        events.append(json.loads(raw))
    except json.JSONDecodeError:
        pass

if host == "claude":
    called = any(
        item.get("type") == "tool_use"
        and item.get("name") == "Skill"
        and item.get("input", {}).get("skill") == "verbs:careful"
        for event in events
        if event.get("type") == "assistant"
        for item in event.get("message", {}).get("content", [])
    )
    launched = any(
        event.get("type") == "user"
        and event.get("tool_use_result", {}).get("success") is True
        and event.get("tool_use_result", {}).get("commandName") == "verbs:careful"
        for event in events
    )
    completed = any(
        event.get("type") == "result"
        and event.get("subtype") == "success"
        and event.get("result") == activation
        for event in events
    )
    ok = called and launched and completed
else:
    messages = [
        event.get("item", {}).get("text")
        for event in events
        if event.get("type") == "item.completed"
        and event.get("item", {}).get("type") == "agent_message"
    ]
    tool_types = {
        "command_execution", "file_change", "mcp_tool_call", "web_search",
        "image_generation", "dynamic_tool_call", "tool_call",
    }
    used_tool = any(
        event.get("type") == "item.completed"
        and event.get("item", {}).get("type") in tool_types
        for event in events
    )
    turn_done = any(event.get("type") == "turn.completed" for event in events)
    ok = messages == [activation] and turn_done and not used_tool

raise SystemExit(0 if ok else 1)
' "$host"; then
    echo "PASS [$host]: namespaced careful invocation completed"
  else
    echo "FAIL [$host]: namespaced careful invocation lacks dispatch proof" >&2
    printf '%s\n' "$out" | head -5 | sed 's/^/  | /' >&2
    fail=1
  fi
}

run_claude() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "FAIL [claude]: claude CLI not on PATH" >&2
    fail=1
    return
  fi
  host_ran=$((host_ran + 1))
  inventory="$(claude plugin list --json 2>&1)" || {
    echo "FAIL [claude]: plugin inventory failed" >&2
    fail=1
    return
  }
  if check_inventory claude "$inventory"; then
    echo "PASS [claude]: official inventory shows verbs@verbs enabled"
  else
    echo "FAIL [claude]: official inventory rejected" >&2
    fail=1
    return
  fi
  check_doctor claude || return
  if [ "${VERBS_SMOKE_INVENTORY_ONLY:-0}" = 1 ]; then
    echo "PASS [claude]: inventory-only smoke completed"
    return
  fi
  prompt='Invoke verbs:careful. Return the skill standard activation announcement exactly as written, then stop.'
  out="$(claude -p --tools Skill --no-session-persistence \
    --output-format stream-json --verbose "$prompt" 2>&1)" || {
    echo "FAIL [claude]: namespaced invocation error" >&2
    fail=1
    return
  }
  check_invocation claude "$out"
}

run_codex() {
  local -a codex_args
  if ! command -v codex >/dev/null 2>&1; then
    echo "FAIL [codex]: codex CLI not on PATH" >&2
    fail=1
    return
  fi
  host_ran=$((host_ran + 1))
  inventory="$(codex plugin list --json 2>&1)" || {
    echo "FAIL [codex]: plugin inventory failed" >&2
    fail=1
    return
  }
  if check_inventory codex "$inventory"; then
    echo "PASS [codex]: official inventory shows verbs@verbs enabled"
  else
    echo "FAIL [codex]: official inventory rejected" >&2
    fail=1
    return
  fi
  check_doctor codex || return
  if [ "${VERBS_SMOKE_INVENTORY_ONLY:-0}" = 1 ]; then
    echo "PASS [codex]: inventory-only smoke completed"
    return
  fi
  prompt='$verbs:careful Return the skill standard activation announcement exactly as written, then stop.'
  codex_args=(exec --sandbox read-only --json)
  if [ -n "${VERBS_SMOKE_EXPECT_HOME:-}" ]; then
    codex_args+=(--cd "$VERBS_SMOKE_EXPECT_HOME" --skip-git-repo-check)
  fi
  if [ "${VERBS_SMOKE_BYPASS_HOOK_TRUST:-0}" = 1 ]; then
    codex_args+=(--dangerously-bypass-hook-trust)
  fi
  if [ -n "${VERBS_SMOKE_MODEL:-}" ]; then
    codex_args+=(--model "$VERBS_SMOKE_MODEL")
  fi
  if [ "${VERBS_SMOKE_DISABLE_REMOTE_PLUGINS:-0}" = 1 ]; then
    codex_args+=(--disable remote_plugin --disable plugin_sharing)
  fi
  out="$(env -u VERBS_REPO_ROOT -u VERBS_MANIFEST \
    codex "${codex_args[@]}" "$prompt" 2>&1)" || {
    echo "FAIL [codex]: namespaced invocation error" >&2
    fail=1
    return
  }
  check_invocation codex "$out"
}

run_adapter() {
  hook="$repo_root/hooks/session-start"
  for envelope in codex claude cursor; do
    case "$envelope" in
      codex) out="$(env -u CLAUDE_PLUGIN_ROOT -u CURSOR_PLUGIN_ROOT -u COPILOT_CLI bash "$hook")" ;;
      claude) out="$(env -u CURSOR_PLUGIN_ROOT -u COPILOT_CLI CLAUDE_PLUGIN_ROOT=/tmp bash "$hook")" ;;
      cursor) out="$(env -u COPILOT_CLI CURSOR_PLUGIN_ROOT=/tmp bash "$hook")" ;;
    esac
    if printf '%s' "$out" | python3 -c '
import json,sys
data=json.load(sys.stdin)
payload=data.get("additional_context") or data.get("additionalContext") or data.get("hookSpecificOutput",{}).get("additionalContext","")
assert "# Dispatch" in payload
assert "AGENTS.md" not in payload and "gbrain" not in payload
' 2>/dev/null; then
      echo "PASS [adapter:$envelope]: reference session-start envelope is valid"
    else
      echo "FAIL [adapter:$envelope]: invalid reference session-start envelope" >&2
      fail=1
    fi
  done
}

target="${1:-all}"
case "$target" in
  claude) run_claude ;;
  codex) run_codex ;;
  adapter|hook) run_adapter ;;
  all) run_claude; run_codex ;;
  *) echo "unknown host: $target (claude|codex|adapter|all)" >&2; exit 2 ;;
esac

if [ "$target" != adapter ] && [ "$target" != hook ] && [ "$host_ran" -eq 0 ]; then
  echo "FAIL: no requested host was tested" >&2
  exit 1
fi
exit "$fail"
