#!/usr/bin/env bash
# Real local-marketplace installer smoke in a disposable host profile.
# Unlike runtime-surface-test.py, this script never copies caches or writes
# registry/config receipts. The host installer must create them. Authentication
# is reused without copying host configuration: Claude loads the exact installed
# artifact in a fresh authenticated process; Codex uses a disposable API-key
# login when OPENAI_API_KEY is available, otherwise it copies only auth.json
# with mode 0600.
set -euo pipefail

usage() {
  echo "Usage:" >&2
  echo "  bash scripts/installer-smoke.sh claude|codex <checkout> [exact-tag]" >&2
  echo "  bash scripts/installer-smoke.sh claude|codex --upgrade <v0.5-checkout> <v0.6-checkout>" >&2
  exit 2
}

manifest_version() {
  python3 - "$1/manifest.toml" <<'PY'
import re
import sys

section = ""
for raw in open(sys.argv[1], encoding="utf-8"):
    line = raw.strip()
    if line.startswith("[") and line.endswith("]"):
        section = line
        continue
    if section == "[manifest]":
        match = re.fullmatch(r'version\s*=\s*"([^"]+)"', line)
        if match:
            print(match.group(1))
            raise SystemExit(0)
raise SystemExit(1)
PY
}

require_exact_checkout() {
  local root="$1" required_tag="$2" version actual_tag
  version="$(manifest_version "$root")" || {
    echo "ERROR: cannot read manifest version: $root" >&2
    exit 1
  }
  [ "$required_tag" = "v$version" ] || {
    echo "ERROR: tag $required_tag does not match manifest version $version" >&2
    exit 1
  }
  actual_tag="$(git -C "$root" describe --tags --exact-match HEAD 2>/dev/null || true)"
  [ "$actual_tag" = "$required_tag" ] || {
    echo "ERROR: checkout HEAD is $actual_tag, expected exact tag $required_tag" >&2
    exit 1
  }
  [ -z "$(git -C "$root" status --porcelain --untracked-files=all)" ] || {
    echo "ERROR: exact-tag installer smoke requires a clean checkout: $root" >&2
    exit 1
  }
}

[ "$#" -ge 2 ] || usage
host="$1"
case "$host" in claude|codex) ;; *) usage ;; esac

mode="fresh"
expected_tag=""
baseline_root=""
if [ "$2" = "--upgrade" ]; then
  [ "$#" = 4 ] || usage
  mode="upgrade"
  baseline_root="$(cd "$3" && pwd -P)"
  source_root="$(cd "$4" && pwd -P)"
else
  [ "$#" -le 3 ] || usage
  source_root="$(cd "$2" && pwd -P)"
  expected_tag="${3:-}"
fi

check_manifest() {
  [ -f "$1/manifest.toml" ] || {
    echo "ERROR: checkout has no manifest.toml: $1" >&2
    exit 1
  }
}
check_manifest "$source_root"
[ -z "$baseline_root" ] || check_manifest "$baseline_root"

if [ "$mode" = fresh ] && [ -n "$expected_tag" ]; then
  require_exact_checkout "$source_root" "$expected_tag"
elif [ "$mode" = upgrade ]; then
  require_exact_checkout "$baseline_root" v0.5.0
  require_exact_checkout "$source_root" v0.6.0
fi

real_home="$HOME"
real_claude_config="${CLAUDE_CONFIG_DIR:-}"
real_codex_home="${CODEX_HOME:-$real_home/.codex}"
profile="$(mktemp -d "${TMPDIR:-/tmp}/verbs-$host-install.XXXXXX")"

cleanup() {
  status=$?
  trap - EXIT HUP INT TERM
  rm -f "$profile/.codex/auth.json" || true
  if [ "${VERBS_KEEP_SMOKE_HOME:-0}" = 1 ]; then
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

profile_path_guard() {
  local path="$1"
  local install_real profile_real expected_prefix
  install_real="$(cd "$path" && pwd -P)"
  profile_real="$(cd "$profile" && pwd -P)"
  if [ "$host" = claude ]; then
    expected_prefix="$profile_real/.claude/plugins"
  else
    expected_prefix="$profile_real/.codex/plugins"
  fi
  case "$install_real" in
    "$expected_prefix"/*)
      INSTALLED_PATH="$install_real"
      ;;
    *)
      echo "ERROR: installer returned a non-profile install path: $install_real" >&2
      exit 1
      ;;
  esac
}

claude_cmd() {
  HOME="$profile" CLAUDE_CONFIG_DIR="$profile/.claude" claude "$@"
}

codex_cmd() {
  HOME="$profile" CODEX_HOME="$profile/.codex" codex "$@"
}

prepare_codex_auth() {
  mkdir -p "$profile/.codex"
  if [ -n "${OPENAI_API_KEY:-}" ]; then
    printf '%s' "$OPENAI_API_KEY" | codex_cmd login --with-api-key >/dev/null
  elif [ -f "$real_codex_home/auth.json" ]; then
    install -m 600 "$real_codex_home/auth.json" "$profile/.codex/auth.json"
  fi
}

install_claude_source() {
  local source="$1" expected="$2" inventory path
  claude_cmd plugin validate "$source"
  claude_cmd plugin marketplace add "$source" --scope user
  claude_cmd plugin install verbs@verbs --scope user
  inventory="$(claude_cmd plugin list --json)"
  path="$(printf '%s' "$inventory" | python3 -c '
import json, sys
version = sys.argv[1]
rows = [row for row in json.load(sys.stdin) if row.get("id") == "verbs@verbs"]
if len(rows) != 1 or rows[0].get("version") != version or not rows[0].get("enabled"):
    raise SystemExit(1)
print(rows[0].get("installPath", ""))
' "$expected")"
  [ -n "$path" ] || {
    echo "ERROR: Claude inventory lacks install path for version $expected" >&2
    exit 1
  }
  profile_path_guard "$path"
}

remove_claude_source() {
  claude_cmd plugin uninstall verbs@verbs --scope user
  claude_cmd plugin marketplace remove verbs --scope user
}

install_codex_source() {
  local source="$1" expected="$2" result path
  codex_cmd plugin marketplace add "$source" --json
  result="$(codex_cmd plugin add verbs@verbs --json)"
  path="$(printf '%s' "$result" | python3 -c '
import json, sys
version = sys.argv[1]
data = json.load(sys.stdin)
if data.get("pluginId") != "verbs@verbs" or data.get("version") != version:
    raise SystemExit(1)
print(data.get("installedPath", ""))
' "$expected")"
  [ -n "$path" ] || {
    echo "ERROR: Codex installer lacks install path for version $expected" >&2
    exit 1
  }
  profile_path_guard "$path"
}

remove_codex_source() {
  codex_cmd plugin remove verbs@verbs --json
  codex_cmd plugin marketplace remove verbs --json
}

verify_installed_inventory() {
  local source="$1"
  if [ "$host" = claude ]; then
    HOME="$profile" CLAUDE_CONFIG_DIR="$profile/.claude" \
      VERBS_REPO_ROOT="$source" \
      VERBS_SMOKE_EXPECT_HOME="$profile" \
      VERBS_SMOKE_INVENTORY_ONLY=1 \
      bash "$source/scripts/conformance-smoke.sh" claude
  else
    HOME="$profile" CODEX_HOME="$profile/.codex" \
      VERBS_REPO_ROOT="$source" \
      VERBS_SMOKE_EXPECT_HOME="$profile" \
      VERBS_SMOKE_INVENTORY_ONLY=1 \
      bash "$source/scripts/conformance-smoke.sh" codex
  fi
}

verify_installed_hooks() {
  local source="$1" details
  [ -f "$INSTALLED_PATH/hooks/hooks.json" ] || {
    echo "ERROR: installed v0.6 Plugin has no hooks/hooks.json" >&2
    exit 1
  }
  if [ "$host" = claude ]; then
    HOME="$profile" CLAUDE_CONFIG_DIR="$profile/.claude" \
      VERBS_HOOK_ROOT="$INSTALLED_PATH" \
      bash "$source/tests/plugin-hooks-test.sh"
  else
    HOME="$profile" CODEX_HOME="$profile/.codex" \
      VERBS_HOOK_ROOT="$INSTALLED_PATH" \
      bash "$source/tests/plugin-hooks-test.sh"
  fi
  if [ "$host" = claude ]; then
    details="$(claude_cmd plugin details verbs@verbs)"
    printf '%s\n' "$details" | grep -Fq 'Hooks (3)' || {
      echo "ERROR: Claude component inventory does not register three hooks" >&2
      exit 1
    }
    for event in SessionStart PreToolUse Stop; do
      printf '%s\n' "$details" | grep -Fq "$event" || {
        echo "ERROR: Claude component inventory lacks $event" >&2
        exit 1
      }
    done
  else
    HOME="$profile" CODEX_HOME="$profile/.codex" \
      python3 "$source/scripts/codex-hook-smoke.py" "$profile" "$INSTALLED_PATH"
  fi
  echo "PASS [$host]: installed v0.6 Plugin discovery and hook behavior passed"
}

verify_rollback_hooks_absent() {
  local details
  if [ "$host" = claude ]; then
    details="$(claude_cmd plugin details verbs@verbs)"
    printf '%s\n' "$details" | grep -Fq 'Hooks (0)' || {
      echo "ERROR: Claude rollback left Verbs hooks registered" >&2
      exit 1
    }
    echo "PASS [claude]: rollback left no Verbs hooks registered"
  else
    HOME="$profile" CODEX_HOME="$profile/.codex" \
      python3 "$source_root/scripts/codex-hook-smoke.py" \
        --expect-none "$profile"
  fi
}

run_upgrade_cycle() {
  local baseline_version target_version
  baseline_version="$(manifest_version "$baseline_root")" || {
    echo "ERROR: cannot read baseline manifest version" >&2
    exit 1
  }
  target_version="$(manifest_version "$source_root")" || {
    echo "ERROR: cannot read target manifest version" >&2
    exit 1
  }
  [ "$baseline_version" = "0.5.0" ] || {
    echo "ERROR: upgrade baseline is $baseline_version, expected 0.5.0" >&2
    exit 1
  }
  [ "$target_version" = "0.6.0" ] || {
    echo "ERROR: upgrade target is $target_version, expected 0.6.0" >&2
    exit 1
  }

  if [ "$host" = claude ]; then
    command -v claude >/dev/null 2>&1 || {
      echo "ERROR: claude CLI not on PATH" >&2
      exit 1
    }
    echo "INFO [claude]: phase 1 install v0.5.0"
    install_claude_source "$baseline_root" "$baseline_version"
    verify_installed_inventory "$baseline_root"
    remove_claude_source
    echo "INFO [claude]: phase 2 reinstall v0.6.0"
    install_claude_source "$source_root" "$target_version"
    verify_installed_inventory "$source_root"
    verify_installed_hooks "$source_root"
    remove_claude_source
    echo "INFO [claude]: phase 3 rollback v0.5.0"
    install_claude_source "$baseline_root" "$baseline_version"
    verify_installed_inventory "$baseline_root"
    verify_rollback_hooks_absent
  else
    command -v codex >/dev/null 2>&1 || {
      echo "ERROR: codex CLI not on PATH" >&2
      exit 1
    }
    prepare_codex_auth
    echo "INFO [codex]: phase 1 install v0.5.0"
    install_codex_source "$baseline_root" "$baseline_version"
    verify_installed_inventory "$baseline_root"
    remove_codex_source
    echo "INFO [codex]: phase 2 reinstall v0.6.0"
    install_codex_source "$source_root" "$target_version"
    verify_installed_inventory "$source_root"
    verify_installed_hooks "$source_root"
    remove_codex_source
    echo "INFO [codex]: phase 3 rollback v0.5.0"
    install_codex_source "$baseline_root" "$baseline_version"
    verify_installed_inventory "$baseline_root"
    verify_rollback_hooks_absent
  fi
  echo "OK: real $host same-profile v0.5.0 -> v0.6.0 -> v0.5.0 cycle passed"
}

if [ "$mode" = upgrade ]; then
  run_upgrade_cycle
  exit 0
fi

if [ "$host" = claude ]; then
  command -v claude >/dev/null 2>&1 || {
    echo "ERROR: claude CLI not on PATH" >&2
    exit 1
  }
  source_version="$(manifest_version "$source_root")"
  install_claude_source "$source_root" "$source_version"
  verify_installed_inventory "$source_root"
  install_path="$INSTALLED_PATH"
  if [ "$source_version" = 0.6.0 ]; then
    verify_installed_hooks "$source_root"
  fi
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
  prepare_codex_auth
  source_version="$(manifest_version "$source_root")"
  install_codex_source "$source_root" "$source_version"
  codex_smoke_bypass=0
  if [ "$source_version" = 0.6.0 ]; then
    verify_installed_hooks "$source_root"
    codex_smoke_bypass=1
  fi
  (
    cd "$profile"
    HOME="$profile" CODEX_HOME="$profile/.codex" \
      VERBS_REPO_ROOT="$source_root" \
      VERBS_SMOKE_EXPECT_HOME="$profile" \
      VERBS_SMOKE_MODEL=gpt-5.4-mini \
      VERBS_SMOKE_BYPASS_HOOK_TRUST="$codex_smoke_bypass" \
      VERBS_SMOKE_DISABLE_REMOTE_PLUGINS=1 \
      bash "$source_root/scripts/conformance-smoke.sh" codex
  )
fi

echo "OK: real $host installer and cold-start invocation passed"
