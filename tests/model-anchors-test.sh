#!/usr/bin/env bash
# model-anchors-test.sh -- keep role routing explicit and single-sourced.
set -euo pipefail
cd "$(dirname "$0")/.."

anchor="lib/model-anchors.md"

expected_rows=(
  '| `advisor.openai` | direct `codex exec` | `gpt-5.6-sol` | `high` | `codex >= 0.144.1` | read-only sandbox | verified |'
  '| `advisor.anthropic` | direct `claude -p` | `opus` | `high` | `claude >= 2.1.206` | clear `CLAUDECODE`, tools disabled, no session persistence | verified |'
  '| `advisor.panel.openai.fast` | direct `codex exec` | `gpt-5.6-luna` | `max` | `codex >= 0.144.1` | read-only sandbox | verified |'
  '| `advisor.panel.fast` | direct `claude -p` | `sonnet` | `medium` | `claude >= 2.1.206` | clear `CLAUDECODE`, tools disabled, no session persistence | verified |'
  '| `advisor.panel.deep` | direct `claude -p` | `opus` | `high` | `claude >= 2.1.206` | clear `CLAUDECODE`, tools disabled, no session persistence | verified |'
)

for row in "${expected_rows[@]}"; do
  grep -Fqx "$row" "$anchor" || {
    echo "FAIL: missing or changed model anchor row: $row"
    exit 1
  }
done

for skill in skills/engineering/advisor/SKILL.md skills/engineering/review/SKILL.md; do
  grep -Fq -- '- skill: lib/model-anchors.md' "$skill" || {
    echo "FAIL: $skill does not declare the model anchor read"
    exit 1
  }
  cmp -s "$anchor" "$(dirname "$skill")/lib/model-anchors.md" || {
    echo "FAIL: $skill does not carry the canonical model anchor resource"
    exit 1
  }
  body="$(awk 'NR == 1 && $0 == "---" { fm=1; next } fm && $0 == "---" { fm=0; next } !fm { print }' "$skill")"
  grep -Fq 'lib/model-anchors.md' <<<"$body" || {
    echo "FAIL: $skill does not consume the model anchor reference"
    exit 1
  }
done

if rg -n -g '!**/lib/model-anchors.md' 'gpt-5\.6-(sol|luna)|[0-9]+ (sonnet|opus|fable)|--model[[:space:]].*(sonnet|opus|fable)' skills/ >/dev/null; then
  echo "FAIL: runtime model selectors must stay in lib/model-anchors.md"
  rg -n -g '!**/lib/model-anchors.md' 'gpt-5\.6-(sol|luna)|[0-9]+ (sonnet|opus|fable)|--model[[:space:]].*(sonnet|opus|fable)' skills/
  exit 1
fi

if rg -ni 'fable' "$anchor" skills/engineering/*/lib/model-anchors.md; then
  echo "FAIL: expired Fable anchor remains in the active model contract"
  exit 1
fi

grep -Fq -- '--sandbox read-only' "$anchor"
grep -Fq -- 'env -u CLAUDECODE claude -p' "$anchor"
grep -Fq -- '--tools "" --no-session-persistence' "$anchor"
grep -Fq 'Never inherit' "$anchor"

bash -n scripts/bootstrap.sh
grep -Fq 'ext_check_version "advisor/codex" "$codex_probe_state" "$codex_probe_version" "0.144.1"' scripts/bootstrap.sh
grep -Fq 'ext_check_version "advisor/claude" "$claude_probe_state" "$claude_probe_version" "2.1.206"' scripts/bootstrap.sh

echo "OK: advisor uses explicit, single-sourced model selection."
