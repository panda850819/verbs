#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

skill="skills/meta/harness-slim/SKILL.md"

check_contract() {
  local target="$1"
  local token
  for token in actual_invocation dispatch_selection load_proxy \
               "source / installed / live" "always-on / deferred / task-local" \
               "foreground lane" "Propose before any move" \
               "at least 30 days" "20 eligible opportunities" \
               "scripts/verbs guard-report" "Rate: UNAVAILABLE" \
               "NO CONCLUSION" "NEEDS TRACE" \
               "Zero denials and zero use never prove a healthy surface" \
               "never from frequency alone"; do
    grep -Fq "$token" "$target" || return 1
  done
}

check_contract "$skill"
grep -Fq 'name: harness-slim' "$skill"
grep -Fq 'user-invocable: true' "$skill"
grep -Fq '[skill.harness-slim]' manifest.toml
grep -Fq 'tier = "ext"' <(sed -n '/^\[skill.harness-slim\]/,/^\[skill\./p' manifest.toml)
grep -Fq 'requires = ["cli:git", "cli:codex", "cli:claude"]' manifest.toml
grep -Fq 'harness-slim/codex' scripts/bootstrap.sh
grep -Fq 'harness-slim/claude' scripts/bootstrap.sh
grep -Fq '`verbs:harness-slim`' RESOLVER.md
grep -Fq '| Audit/reduce a live multi-runtime agent harness' DISPATCH.md
grep -Fq '/verbs:harness-slim' README.md

if rg -n '/Users/|~/.agents/skills/harness-slim|brain\.pdzeng\.com' "$skill"; then
  echo "FAIL: public harness-slim contains a personal machine path" >&2
  exit 1
fi

mutant="$(mktemp)"
trap 'rm -f "$mutant"' EXIT
sed 's/load_proxy/load-proxy/' "$skill" >"$mutant"
if check_contract "$mutant" 2>/dev/null; then
  echo "FAIL: contract accepted a missing telemetry event kind" >&2
  exit 1
fi

echo "OK: harness-slim remains a read-only post-adoption evaluator."
