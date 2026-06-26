#!/usr/bin/env bash
# lint-manifest-sync.sh — manifest.toml is the single source of truth for the
# skill list. This lint fails when manifest entries and skills/ directories
# drift, or when retired claims (38 skills, flows/, agents/) reappear in docs.
#
# Skills live one level deep under category buckets: skills/<bucket>/<skill>/.
#
# Usage: bash scripts/lint-manifest-sync.sh   (exit 0 = clean, 1 = drift)

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_root/manifest.toml"
skills_dir="$repo_root/skills"

fail=0

manifest_skills="$(grep -o '^\[skill\.[a-z0-9-]*\]' "$manifest" | sed 's/^\[skill\.//; s/\]$//' | sort)"
# Bucket layout: a skill dir is at depth 2 (skills/<bucket>/<skill>). Archived
# skills under skills/.archive/ are excluded by path.
disk_skills="$(find "$skills_dir" -mindepth 2 -maxdepth 2 -type d ! -path '*/.archive/*' -exec basename {} \; | sort)"

missing_on_disk="$(comm -23 <(echo "$manifest_skills") <(echo "$disk_skills"))"
missing_in_manifest="$(comm -13 <(echo "$manifest_skills") <(echo "$disk_skills"))"

if [ -n "$missing_on_disk" ]; then
  echo "FAIL: in manifest.toml but no skills/<bucket>/<name>/ directory:"
  echo "$missing_on_disk" | sed 's/^/  - /'
  fail=1
fi

if [ -n "$missing_in_manifest" ]; then
  echo "FAIL: on disk but missing a [skill.<name>] manifest entry:"
  echo "$missing_in_manifest" | sed 's/^/  - /'
  fail=1
fi

# Every skill dir must have a SKILL.md.
while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  if [ ! -f "$dir/SKILL.md" ]; then
    echo "FAIL: ${dir#"$repo_root"/}/ has no SKILL.md"
    fail=1
  fi
done <<< "$(find "$skills_dir" -mindepth 2 -maxdepth 2 -type d ! -path '*/.archive/*')"

# Retired claims must not reappear in living docs (historical sections in
# RESOLVER/CHANGELOG are exempt by not being scanned).
stale=$(grep -rn "38 skills\|7 lifecycle flows\|plugins/pandastack/agents/" \
  "$repo_root/README.md" "$repo_root/CLAUDE.md" \
  "$repo_root/.codex/INSTALL.md" \
  "$repo_root/skills/meta/using-pandastack/SKILL.md" 2>/dev/null || true)
if [ -n "$stale" ]; then
  echo "FAIL: stale claims found:"
  echo "$stale" | sed 's/^/  /'
  fail=1
fi

# DISPATCH.md must exist (session-start hook injects it).
if [ ! -f "$repo_root/DISPATCH.md" ]; then
  echo "FAIL: DISPATCH.md missing (session-start hook injects it)"
  fail=1
fi

# State store + its schema doc travel together.
if [ -f "$repo_root/scripts/pandastack-state" ] && [ ! -f "$repo_root/docs/state-schema.md" ]; then
  echo "FAIL: scripts/pandastack-state exists but docs/state-schema.md missing"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  count=$(echo "$disk_skills" | wc -l | tr -d ' ')
  echo "OK: manifest and skills/ in sync ($count skills), no stale claims."
fi
exit "$fail"
