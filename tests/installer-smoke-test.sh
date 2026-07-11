#!/usr/bin/env bash
# Structural guard for the real installer smoke. This is not installer proof;
# release evidence comes only from executing scripts/installer-smoke.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

script="scripts/installer-smoke.sh"
bash -n "$script"

grep -Fq 'claude plugin marketplace add "$source_root" --scope user' "$script"
grep -Fq 'claude plugin install verbs@verbs --scope user' "$script"
grep -Fq 'codex plugin marketplace add "$source_root" --json' "$script"
grep -Fq 'codex plugin add verbs@verbs --json' "$script"
grep -Fq 'VERBS_SMOKE_EXPECT_HOME="$profile"' "$script"
grep -Fq 'describe --tags --exact-match HEAD' "$script"
grep -Fq 'rm -f "$profile/.codex/auth.json"' "$script"
grep -Fq "trap 'exit 130' INT" "$script"
grep -Fq -- '--setting-sources project,local' "$script"
grep -Fq -- '--output-format stream-json --verbose' "$script"
grep -Fq 'tool_use_result' "$script"

if grep -Eq 'cp .*(plugins/cache|installed_plugins|config\.toml)|installed_plugins\.json.*>|config\.toml.*>' "$script"; then
  echo "FAIL: installer smoke must not synthesize cache or receipt state" >&2
  exit 1
fi

echo "OK: installer smoke uses official host commands and no synthetic receipts"
