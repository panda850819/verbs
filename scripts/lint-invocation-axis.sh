#!/usr/bin/env bash
# lint-invocation-axis.sh - every active runtime skill declares its invocation axis.
#
# Usage: bash scripts/lint-invocation-axis.sh   (exit 0 = clean, 1 = drift)

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
checked=0

surface_json="$(python3 "$repo_root/scripts/verbs" doctor --json)" || {
  echo "FAIL: doctor could not build the runtime surface"
  exit 1
}
if ! printf '%s' "$surface_json" | python3 -c '
import json,sys
raise SystemExit(0 if json.load(sys.stdin)["checks"]["runtime_surface"]["source"]["ok"] else 1)
'; then
  echo "FAIL: active runtime surface is not exact; run lint-manifest-sync first"
  exit 1
fi
skill_files="$(printf '%s' "$surface_json" | python3 -c '
import json,sys
for path in json.load(sys.stdin)["checks"]["runtime_surface"]["source"]["skill_files"]:
    print(path)
')"

while IFS= read -r skill_md; do
  [ -n "$skill_md" ] || continue
  checked=$((checked + 1))
  rel="${skill_md#"$repo_root"/}"
  if ! awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    in_frontmatter && $0 ~ /^user-invocable:[[:space:]]*(true|false)[[:space:]]*$/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$skill_md"; then
    echo "FAIL: $rel missing explicit user-invocable"
    fail=1
  fi
done <<< "$skill_files"

# Zero scanned skills (missing/renamed skills dir) must never pass as green.
if [ "$checked" -eq 0 ]; then
  echo "FAIL: runtime surface contains no SKILL.md — refusing to pass an empty gate"
  exit 1
fi

if [ "$fail" -eq 0 ]; then
  echo "OK: all $checked active runtime skills declare user-invocable."
fi
exit "$fail"
