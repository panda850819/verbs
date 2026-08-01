#!/usr/bin/env bash
# Keep Agent Worker as an opt-in native-subagent protocol inside handover.
set -euo pipefail
cd "$(dirname "$0")/.."

contract="skills/engineering/handover/SKILL.md"
check_contract() {
  local target="$1"
  local field

  [ "$(grep -Fc 'Explicit Agent Worker or parallel read-only research' "$target")" -eq 1 ]
  grep -Fq 'at most two' "$target"
  grep -Fq 'disable nested delegation' "$target"
  grep -Fq 'keep every pilot worker read-only' "$target"
  grep -Fq 'main agent verifies evidence' "$target"
  grep -Fq 'records elapsed time, resolved' "$target"
  grep -Fq 'Record token usage only when the runtime' "$target"
  grep -Fq 'never from worker estimates' "$target"

  for field in objective scope deliverable acceptance permissions budget \
               status findings evidence gaps; do
    grep -Fq "\`$field\`" "$target"
  done
}

check_contract "$contract"
[ "$(rg -l 'Explicit Agent Worker or parallel read-only research' skills | wc -l | tr -d ' ')" -eq 1 ]
test ! -e skills/engineering/agent-worker/SKILL.md
test ! -e scripts/agent-worker

mutant="$(mktemp)"
trap 'rm -f "$mutant"' EXIT
sed 's/`gaps`/gaps/' "$contract" > "$mutant"
if check_contract "$mutant" 2>/dev/null; then
  echo 'FAIL: contract check accepted a missing required field marker' >&2
  exit 1
fi

echo 'OK: Agent Worker stays a thin native-subagent contract inside handover.'
