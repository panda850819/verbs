#!/usr/bin/env bash
# Keep Agent Worker as an opt-in native-subagent protocol, not another runner.
set -euo pipefail
cd "$(dirname "$0")/.."

check_contract() {
  local dispatch="$1"
  local field

  [ "$(grep -Fc 'Explicit Agent Worker / parallel read-only research' "$dispatch")" -eq 1 ]
  grep -Fq 'at most two' "$dispatch"
  grep -Fq 'disable nested delegation' "$dispatch"
  grep -Fq 'keep every pilot worker read-only' "$dispatch"
  grep -Fq 'main agent verifies evidence' "$dispatch"
  grep -Fq 'records elapsed time, resolved' "$dispatch"
  grep -Fq 'Record token usage only when the runtime' "$dispatch"
  grep -Fq 'never from worker estimates' "$dispatch"

  for field in objective scope deliverable acceptance permissions budget \
               status findings evidence gaps; do
    grep -Fq "\`$field\`" "$dispatch"
  done
}

check_contract DISPATCH.md
grep -Fq 'Native read-only Agent Worker fan-out' skills/engineering/handover/SKILL.md
grep -Fq 'delegation to one fresh Claude or Codex worker' skills/engineering/handover/SKILL.md

claude_payload="$(mktemp)"
codex_payload="$(mktemp)"
mutant="$(mktemp)"
trap 'rm -f "$mutant" "$claude_payload" "$codex_payload"' EXIT
CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/session-start > "$claude_payload"
env -u CLAUDE_PLUGIN_ROOT -u CURSOR_PLUGIN_ROOT -u COPILOT_CLI \
  bash hooks/session-start > "$codex_payload"
python3 - "$claude_payload" "$codex_payload" <<'PY'
import json
import sys

claude = json.load(open(sys.argv[1], encoding="utf-8"))
codex = json.load(open(sys.argv[2], encoding="utf-8"))
contexts = (
    claude["hookSpecificOutput"]["additionalContext"],
    codex["additionalContext"],
)
for context in contexts:
    assert "Explicit Agent Worker / parallel read-only research" in context
    assert "WorkerResult" in context
    assert "never from worker estimates" in context
PY

test ! -e skills/engineering/agent-worker/SKILL.md
test ! -e scripts/agent-worker

sed 's/`gaps`/gaps/' DISPATCH.md > "$mutant"
if check_contract "$mutant" 2>/dev/null; then
  echo 'FAIL: contract check accepted a missing required field marker' >&2
  exit 1
fi

echo 'OK: Agent Worker stays a thin native-subagent contract.'
