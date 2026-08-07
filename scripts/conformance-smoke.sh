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

check_planning_invocation() {
  host="$1"
  out="$2"
  if printf '%s\n' "$out" | python3 -c '
import json
import sys

host = sys.argv[1]
events = []
for raw in sys.stdin:
    try:
        events.append(json.loads(raw))
    except json.JSONDecodeError:
        pass

if host == "claude":
    discovered = any(
        event.get("type") == "system"
        and event.get("subtype") == "init"
        and "verbs:sprint" in event.get("slash_commands", [])
        for event in events
    )
    completed = any(
        event.get("type") == "result"
        and "Execution: NOT_RUN" in event.get("result", "")
        for event in events
    )
    ok = discovered and completed
else:
    completed = any(
        event.get("type") == "item.completed"
        and event.get("item", {}).get("type") == "agent_message"
        and "Execution: NOT_RUN" in event.get("item", {}).get("text", "")
        for event in events
    )
    ok = completed and any(event.get("type") == "turn.completed" for event in events)

raise SystemExit(0 if ok else 1)
' "$host"; then
    echo "PASS [$host]: explicit human-only sprint invocation completed"
  else
    echo "FAIL [$host]: explicit human-only sprint invocation lacks proof" >&2
    fail=1
  fi
}

check_invocation() {
  host="$1"
  out="$2"
  if printf '%s\n' "$out" | python3 "$repo_root/scripts/conformance_events.py" "$host"; then
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
  planning_out="$(claude -p --tools Skill --no-session-persistence \
    --output-format stream-json --verbose \
    '/verbs:sprint This request is planning-only. Follow the skill boundary and do not act.' 2>&1)" || {
    echo "FAIL [claude]: explicit sprint invocation error" >&2
    fail=1
    return
  }
  check_planning_invocation claude "$planning_out"
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
  planning_out="$(env -u VERBS_REPO_ROOT -u VERBS_MANIFEST \
    codex "${codex_args[@]}" \
    '$verbs:sprint This request is planning-only. Follow the skill boundary and do not act.' 2>&1)" || {
    echo "FAIL [codex]: explicit sprint invocation error" >&2
    fail=1
    return
  }
  check_planning_invocation codex "$planning_out"
}

target="${1:-all}"
case "$target" in
  claude) run_claude ;;
  codex) run_codex ;;
  all) run_claude; run_codex ;;
  *) echo "unknown host: $target (claude|codex|all)" >&2; exit 2 ;;
esac

if [ "$host_ran" -eq 0 ]; then
  echo "FAIL: no requested host was tested" >&2
  exit 1
fi
exit "$fail"
