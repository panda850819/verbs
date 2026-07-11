#!/usr/bin/env bash
# Real local-marketplace installer smoke in a disposable host profile.
# Unlike runtime-surface-test.py, this script never copies caches or writes
# registry/config receipts. The host installer must create them. Authentication
# is reused without copying host configuration: Claude loads the exact installed
# artifact in a fresh authenticated process; Codex copies only auth.json into
# the disposable profile with mode 0600.
set -euo pipefail

usage() {
  echo "Usage: bash scripts/installer-smoke.sh claude|codex <checkout> [exact-tag]" >&2
  exit 2
}

[ "$#" -ge 2 ] && [ "$#" -le 3 ] || usage
host="$1"
source_input="$2"
expected_tag="${3:-}"
case "$host" in claude|codex) ;; *) usage ;; esac

source_root="$(cd "$source_input" && pwd -P)"
[ -f "$source_root/manifest.toml" ] || {
  echo "ERROR: checkout has no manifest.toml: $source_root" >&2
  exit 1
}

if [ -n "$expected_tag" ]; then
  actual_tag="$(git -C "$source_root" describe --tags --exact-match HEAD 2>/dev/null || true)"
  [ "$actual_tag" = "$expected_tag" ] || {
    echo "ERROR: checkout HEAD is $actual_tag, expected exact tag $expected_tag" >&2
    exit 1
  }
  [ -z "$(git -C "$source_root" status --porcelain --untracked-files=all)" ] || {
    echo "ERROR: exact-tag installer smoke requires a clean checkout" >&2
    exit 1
  }
fi

real_home="$HOME"
real_claude_config="${CLAUDE_CONFIG_DIR:-}"
real_codex_home="${CODEX_HOME:-$real_home/.codex}"
profile="$(mktemp -d "${TMPDIR:-/tmp}/panda-verbs-$host-install.XXXXXX")"

cleanup() {
  status=$?
  trap - EXIT HUP INT TERM
  rm -f "$profile/.codex/auth.json" || true
  if [ "${PANDA_VERBS_KEEP_SMOKE_HOME:-0}" = 1 ]; then
    echo "INFO: kept disposable profile at $profile"
  else
    rm -rf "$profile"
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

echo "INFO: real $host installer smoke in disposable HOME"

if [ "$host" = claude ]; then
  command -v claude >/dev/null 2>&1 || {
    echo "ERROR: claude CLI not on PATH" >&2
    exit 1
  }
  HOME="$profile" CLAUDE_CONFIG_DIR="$profile/.claude" \
    claude plugin validate "$source_root"
  HOME="$profile" CLAUDE_CONFIG_DIR="$profile/.claude" \
    claude plugin marketplace add "$source_root" --scope user
  HOME="$profile" CLAUDE_CONFIG_DIR="$profile/.claude" \
    claude plugin install verbs@verbs --scope user
  HOME="$profile" CLAUDE_CONFIG_DIR="$profile/.claude" \
    PANDA_VERBS_REPO_ROOT="$source_root" \
    PANDA_VERBS_SMOKE_EXPECT_HOME="$profile" \
    PANDA_VERBS_SMOKE_INVENTORY_ONLY=1 \
    bash "$source_root/scripts/conformance-smoke.sh" claude
  install_path="$(
    HOME="$profile" CLAUDE_CONFIG_DIR="$profile/.claude" \
      claude plugin list --json | python3 -c '
import json,sys
rows=[row for row in json.load(sys.stdin) if row.get("id") == "verbs@verbs"]
if len(rows) != 1 or not rows[0].get("installPath"):
    raise SystemExit(1)
print(rows[0]["installPath"])
'
  )"
  install_path="$(cd "$install_path" && pwd -P)"
  profile_real="$(cd "$profile" && pwd -P)"
  case "$install_path" in
    "$profile_real"/.claude/plugins/*) ;;
    *) echo "ERROR: Claude inventory returned a non-profile install path" >&2; exit 1 ;;
  esac
  prompt='Invoke verbs:careful. Return the skill standard activation announcement exactly as written, then stop.'
  if [ -n "$real_claude_config" ]; then
    invocation="$(
      cd "$profile"
      HOME="$real_home" CLAUDE_CONFIG_DIR="$real_claude_config" \
        claude -p --setting-sources project,local \
        --plugin-dir "$install_path" --tools Skill --no-session-persistence \
        --output-format stream-json --verbose "$prompt" 2>&1
    )"
  else
    invocation="$(
      cd "$profile"
      env -u CLAUDE_CONFIG_DIR HOME="$real_home" \
        claude -p --setting-sources project,local \
        --plugin-dir "$install_path" --tools Skill --no-session-persistence \
        --output-format stream-json --verbose "$prompt" 2>&1
    )"
  fi
  printf '%s\n' "$invocation" | python3 -c '
import json
import pathlib
import sys

expected_path = pathlib.Path(sys.argv[1]).resolve()
activation = "CAREFUL mode ON. Will confirm before destructive actions."
events = []
for raw in sys.stdin:
    try:
        events.append(json.loads(raw))
    except json.JSONDecodeError:
        pass

plugins = [
    plugin
    for event in events
    if event.get("type") == "system" and event.get("subtype") == "init"
    for plugin in event.get("plugins", [])
    if plugin.get("name") == "verbs"
]
exact_plugin = (
    len(plugins) == 1
    and pathlib.Path(plugins[0].get("path", "")).resolve() == expected_path
)
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
raise SystemExit(0 if exact_plugin and called and launched and completed else 1)
' "$install_path" || {
    echo "ERROR: Claude installed-artifact invocation proof failed" >&2
    exit 1
  }
  echo "PASS [claude]: exact installed artifact invoked in a fresh authenticated process"
else
  command -v codex >/dev/null 2>&1 || {
    echo "ERROR: codex CLI not on PATH" >&2
    exit 1
  }
  mkdir -p "$profile/.codex"
  if [ -f "$real_codex_home/auth.json" ]; then
    install -m 600 "$real_codex_home/auth.json" "$profile/.codex/auth.json"
  fi
  HOME="$profile" CODEX_HOME="$profile/.codex" \
    codex plugin marketplace add "$source_root" --json
  HOME="$profile" CODEX_HOME="$profile/.codex" \
    codex plugin add verbs@verbs --json
  HOME="$profile" CODEX_HOME="$profile/.codex" \
    PANDA_VERBS_REPO_ROOT="$source_root" \
    PANDA_VERBS_SMOKE_EXPECT_HOME="$profile" \
    bash "$source_root/scripts/conformance-smoke.sh" codex
fi

echo "OK: real $host installer and cold-start invocation passed"
