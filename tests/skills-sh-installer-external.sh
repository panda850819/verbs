#!/usr/bin/env bash
# Real skills.sh payload proof. Requires npm/GitHub network and is intentionally
# excluded from tests/run-all.sh's deterministic offline gate.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_version="1.5.16"
npx_bin="$(command -v npx)"
python_bin="$(command -v python3)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

home="$tmp/home"
cache="$tmp/npm-cache"
work="$tmp/work"
mkdir -p "$home" "$cache" "$work"

(
  cd "$work"
  env -i \
    HOME="$home" \
    CLAUDE_CONFIG_DIR="$home/.claude" \
    CODEX_HOME="$home/.codex" \
    PATH="$PATH" \
    DISABLE_TELEMETRY=1 \
    DO_NOT_TRACK=1 \
    CI=1 \
    NO_COLOR=1 \
    npm_config_cache="$cache" \
    npm_config_update_notifier=false \
    "$npx_bin" --yes "skills@$skills_version" add "$repo_root" \
      --skill '*' --global --agent claude-code codex --yes --copy
)

canonical="$home/.agents/skills"
"$python_bin" "$repo_root/tests/portable-skills-test.py" \
  --installed-root "$canonical"

installed_count="$({
  find "$canonical" -mindepth 2 -maxdepth 2 -name SKILL.md -print
} | wc -l | tr -d ' ')"
if [ "$installed_count" != "14" ]; then
  echo "FAIL: skills@$skills_version installed $installed_count skills, expected 14" >&2
  exit 1
fi

echo "OK: skills@$skills_version installed and validated 14 portable Verbs skills"
