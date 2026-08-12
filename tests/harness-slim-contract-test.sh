#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

procedure="maintainer/harness-slim.md"

check_contract() {
  local target="$1"
  local token
  for token in actual_invocation dispatch_selection load_proxy \
               "source / installed / live" "always-on / deferred / task-local" \
               "foreground lane" "Propose before any move" \
               "at least 30 days" "20 eligible opportunities" \
               "Use only usage evidence the host actually exposes" \
               "Rate: UNAVAILABLE" "NO CONCLUSION" "NEEDS TRACE" \
               "without host evidence, zero-use pruning"; do
    grep -Fq "$token" "$target" || return 1
  done
}

check_contract "$procedure"
grep -Fq 'maintainer-only' "$procedure"
grep -Fq 'not registered' "$procedure"
grep -Fq 'maintainer/harness-slim.md' README.md
grep -Fq 'maintainer/harness-slim.md' RESOLVER.md

test ! -e skills/meta/harness-slim
test -z "$(find skills -type f -path '*/harness-slim/*' -print -quit)"
! grep -Fq '[skill.harness-slim]' manifest.toml
! grep -Fq '`verbs:harness-slim`' RESOLVER.md
! grep -Fq '/verbs:harness-slim' README.md
! grep -Fq 'harness-slim/codex' scripts/bootstrap.sh
! grep -Fq 'harness-slim/claude' scripts/bootstrap.sh

if rg -n '/Users/|~/.agents/skills/harness-slim|brain\.pdzeng\.com' "$procedure"; then
  echo "FAIL: maintainer procedure contains a personal machine path" >&2
  exit 1
fi

mutant="$(mktemp)"
trap 'rm -f "$mutant"' EXIT
sed 's/load_proxy/load-proxy/' "$procedure" >"$mutant"
if check_contract "$mutant" 2>/dev/null; then
  echo "FAIL: contract accepted a missing telemetry event kind" >&2
  exit 1
fi

echo "OK: harness-slim is a read-only maintainer procedure outside runtime registration."
