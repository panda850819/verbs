#!/usr/bin/env bash
# lint-invocation-axis.sh - every shipped skill (incl. _deprecated) must declare its invocation axis.
#
# Usage: bash scripts/lint-invocation-axis.sh   (exit 0 = clean, 1 = drift)

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="$repo_root/skills"

fail=0

while IFS= read -r skill_md; do
  [ -n "$skill_md" ] || continue
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
done <<< "$(find "$skills_dir" -mindepth 3 -maxdepth 4 -path '*/SKILL.md' ! -path '*/.archive/*' | sort)"

if [ "$fail" -eq 0 ]; then
  echo "OK: all skills (incl. _deprecated, still shipped to Codex) declare user-invocable."
fi
exit "$fail"
