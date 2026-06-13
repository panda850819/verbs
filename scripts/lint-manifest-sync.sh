#!/usr/bin/env bash
# lint-manifest-sync.sh — manifest.toml is the single source of truth for the
# skill list. This lint fails when manifest entries and skills/ directories
# drift, or when retired claims (38 skills, flows/, agents/) reappear in docs.
#
# Usage: bash scripts/lint-manifest-sync.sh   (exit 0 = clean, 1 = drift)

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_root="$repo_root/plugins/pandastack"
manifest="$plugin_root/manifest.toml"
skills_dir="$plugin_root/skills"

fail=0

manifest_skills="$(grep -o '^\[skill\.[a-z0-9-]*\]' "$manifest" | sed 's/^\[skill\.//; s/\]$//' | sort)"
disk_skills="$(find "$skills_dir" -maxdepth 1 -mindepth 1 -type d ! -name '.archive' -exec basename {} \; | sort)"

missing_on_disk="$(comm -23 <(echo "$manifest_skills") <(echo "$disk_skills"))"
missing_in_manifest="$(comm -13 <(echo "$manifest_skills") <(echo "$disk_skills"))"

if [ -n "$missing_on_disk" ]; then
  echo "FAIL: in manifest.toml but no skills/<name>/ directory:"
  echo "$missing_on_disk" | sed 's/^/  - /'
  fail=1
fi

if [ -n "$missing_in_manifest" ]; then
  echo "FAIL: on disk but missing a [skill.<name>] manifest entry:"
  echo "$missing_in_manifest" | sed 's/^/  - /'
  fail=1
fi

# Every skill dir must have a SKILL.md.
while IFS= read -r name; do
  if [ ! -f "$skills_dir/$name/SKILL.md" ]; then
    echo "FAIL: skills/$name/ has no SKILL.md"
    fail=1
  fi
done <<< "$disk_skills"

# Retired claims must not reappear in living docs (historical sections in
# RESOLVER/CHANGELOG are exempt by not being scanned).
stale=$(grep -n "38 skills\|7 lifecycle flows\|plugins/pandastack/agents/" \
  "$repo_root/README.md" "$plugin_root/CLAUDE.md" \
  "$plugin_root/.codex/INSTALL.md" \
  "$plugin_root/skills/using-pandastack/SKILL.md" 2>/dev/null || true)
if [ -n "$stale" ]; then
  echo "FAIL: stale claims found:"
  echo "$stale" | sed 's/^/  /'
  fail=1
fi

# DISPATCH.md must exist (session-start hook injects it).
if [ ! -f "$plugin_root/DISPATCH.md" ]; then
  echo "FAIL: plugins/pandastack/DISPATCH.md missing (session-start hook injects it)"
  fail=1
fi

# State store + its schema doc travel together.
if [ -f "$repo_root/scripts/pandastack-state" ] && [ ! -f "$plugin_root/docs/state-schema.md" ]; then
  echo "FAIL: scripts/pandastack-state exists but docs/state-schema.md missing"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  count=$(echo "$disk_skills" | wc -l | tr -d ' ')
  echo "OK: manifest and skills/ in sync ($count skills), no stale claims."
fi
exit "$fail"
