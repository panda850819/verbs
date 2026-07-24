#!/usr/bin/env bash
# lint-manifest-sync.sh — manifest.toml is the single source of truth for the
# skill list. This lint fails when manifest entries and skills/ directories
# drift, or when retired/fixed-count claims reappear in living docs.
#
# Skills live one level deep under category buckets: skills/<bucket>/<skill>/.
#
# Usage: bash scripts/lint-manifest-sync.sh   (exit 0 = clean, 1 = drift)

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

# scripts/verbs owns skill discovery for every loader. Consume its source
# result here so doctor and CI cannot disagree about the exact active set.
surface_json="$(python3 "$repo_root/scripts/verbs" doctor --json)" || {
  echo "FAIL: doctor could not build the runtime surface"
  exit 1
}
if ! surface_drift="$(printf '%s' "$surface_json" | python3 -c '
import json,sys
s=json.load(sys.stdin)["checks"]["runtime_surface"]["source"]
if s["ok"]:
    raise SystemExit(0)
for key in ("source_recursive", "claude_registration", "codex_registration"):
    item=s[key]
    if item["missing"]: print("{} missing: {}".format(key, ", ".join(item["missing"])))
    if item["extra"]: print("{} extra: {}".format(key, ", ".join(item["extra"])))
    for issue in item["issues"]: print("{}: {}".format(key, issue))
if s["version_drift"]: print("version drift: " + ", ".join(s["version_drift"]))
for issue in s["issues"]: print(issue)
raise SystemExit(1)
')"; then
  echo "FAIL: runtime skill surface differs from manifest.toml:"
  printf '%s\n' "$surface_drift" | sed 's/^/  /'
  fail=1
fi
count="$(printf '%s' "$surface_json" | python3 -c '
import json,sys
print(len(json.load(sys.stdin)["checks"]["runtime_surface"]["expected"]))
')"

# Retired claims must not reappear in living docs. The persona layer (PR
# #100/#101) and the driver split (PR #92) are gone, retro-week/retro-month moved
# to the personal overlay (2026-06-30), and the live skill count is whatever
# manifest+disk agree on — a hard-coded 24-29 count, a persona ref, or a
# pre-flatten plugin paths in a living doc are drift. Current-count claims also
# drift; manifest.toml owns the tier list and scripts/verbs sync
# owns derived loader JSON descriptions. Historical sections in RESOLVER/CHANGELOG
# are exempt by not being scanned.
scan_docs=(
  "$repo_root/README.md"
  "$repo_root/CLAUDE.md"
  "$repo_root/.codex/INSTALL.md"
  "$repo_root/.claude-plugin/marketplace.json"
  "$repo_root/.claude-plugin/plugin.json"
  "$repo_root/.codex-plugin/plugin.json"
  "$repo_root/PHILOSOPHY.md"
)
stale=$(grep -niE "38 skills|2[4-9] skills|[0-9]+ active skills|[0-9]+ personas?|persona skills|persona lenses|7 lifecycle flows|7 context recipes|3 documented compositions" \
  "${scan_docs[@]}" 2>/dev/null || true)
current_counts=$(grep -niE "[0-9]+ skills? \(|\([0-9]+ core|[0-9]+ (core|ext)\b" \
  "${scan_docs[@]}" 2>/dev/null || true)
resolver_header_counts=$(head -20 "$repo_root/RESOLVER.md" | grep -niE "[0-9]+ skills? \(|\([0-9]+ core|[0-9]+ (core|ext)\b" || true)
if [ -n "$resolver_header_counts" ]; then
  resolver_header_counts=$(echo "$resolver_header_counts" | sed "s|^|$repo_root/RESOLVER.md:|")
fi
stale=$(printf "%s\n%s\n%s\n" "$stale" "$current_counts" "$resolver_header_counts" | sed '/^$/d')
if [ -n "$stale" ]; then
  echo "FAIL: stale claims found:"
  echo "$stale" | sed 's/^/  /'
  fail=1
fi

# Derived files restate selected manifest data. scripts/verbs sync is the
# generator; --check is the drift gate so loader JSON and the README skill
# catalog cannot silently fall behind a manifest change.
if ! sync_out="$(python3 "$repo_root/scripts/verbs" sync --check 2>&1)"; then
  echo "FAIL: derived files drift from manifest.toml:"
  echo "$sync_out" | sed 's/^/  /'
  fail=1
fi

# DISPATCH.md must exist (session-start hook injects it).
if [ ! -f "$repo_root/DISPATCH.md" ]; then
  echo "FAIL: DISPATCH.md missing (session-start hook injects it)"
  fail=1
fi

# State store + its schema doc travel together.
if [ "$fail" -eq 0 ]; then
  echo "OK: manifest and skills/ in sync ($count skills), no stale claims."
fi
exit "$fail"
