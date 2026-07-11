#!/usr/bin/env bash
# model-anchors-test.sh -- keep role routing explicit and single-sourced.
set -euo pipefail
cd "$(dirname "$0")/.."

anchor="lib/model-anchors.md"

expected_rows=(
  '| `advisor.openai` | direct `codex exec` | `gpt-5.6-sol` | `high` | `codex >= 0.144.1` | read-only sandbox | verified |'
  '| `advisor.anthropic` | direct `claude -p` | `opus` | `high` | `claude >= 2.1.206` | clear `CLAUDECODE`, tools disabled, no session persistence | verified |'
  '| `advisor.panel.openai.fast` | direct `codex exec` | `gpt-5.6-terra` | `medium` | `codex >= 0.144.1` | read-only sandbox | verified |'
  '| `advisor.panel.fast` | direct `claude -p` | `sonnet` | `medium` | `claude >= 2.1.206` | clear `CLAUDECODE`, tools disabled, no session persistence | verified |'
  '| `advisor.panel.deep` | direct `claude -p` | `opus` | `high` | `claude >= 2.1.206` | clear `CLAUDECODE`, tools disabled, no session persistence | verified |'
  '| `handover.mechanical` | direct `codex exec` | `gpt-5.6-luna` | `medium` | `codex >= 0.144.1` | workspace-write sandbox | verified |'
  '| `handover.risky` | direct `codex exec` | `gpt-5.6-sol` | `high` | `codex >= 0.144.1` | workspace-write sandbox | verified |'
)

for row in "${expected_rows[@]}"; do
  grep -Fqx "$row" "$anchor" || {
    echo "FAIL: missing or changed model anchor row: $row"
    exit 1
  }
done

for skill in skills/engineering/advisor/SKILL.md skills/engineering/handover/SKILL.md skills/engineering/review/SKILL.md skills/engineering/sprint/SKILL.md; do
  grep -Fq -- '- repo: lib/model-anchors.md' "$skill" || {
    echo "FAIL: $skill does not declare the model anchor read"
    exit 1
  }
  body="$(awk 'NR == 1 && $0 == "---" { fm=1; next } fm && $0 == "---" { fm=0; next } !fm { print }' "$skill")"
  grep -Fq 'lib/model-anchors.md' <<<"$body" || {
    echo "FAIL: $skill does not consume the model anchor reference"
    exit 1
  }
done

if rg -n 'gpt-5\.6-(sol|terra|luna)|[0-9]+ (sonnet|opus)|--model[[:space:]].*(sonnet|opus)' skills/ >/dev/null; then
  echo "FAIL: runtime model selectors must stay in lib/model-anchors.md"
  rg -n 'gpt-5\.6-(sol|terra|luna)|[0-9]+ (sonnet|opus)|--model[[:space:]].*(sonnet|opus)' skills/
  exit 1
fi

grep -Fq -- '-m "{model}"' skills/engineering/handover/references/codex-invocation.md
grep -Fq 'model_reasoning_effort="{effort}"' skills/engineering/handover/references/codex-invocation.md
grep -Fq '<runtime>' skills/engineering/handover/references/codex-invocation.md
grep -Fq 'minimum_cli:' skills/engineering/handover/references/codex-invocation.md
grep -Fq 'guard:' skills/engineering/handover/references/codex-invocation.md
grep -Fq 'execution machine' skills/engineering/handover/SKILL.md
grep -Fq '<runtime>.minimum_cli' skills/engineering/handover/SKILL.md
grep -Fq -- '--sandbox read-only' "$anchor"
grep -Fq -- 'env -u CLAUDECODE claude -p' "$anchor"
grep -Fq -- '--tools "" --no-session-persistence' "$anchor"
grep -Fq 'Never inherit' "$anchor"

bash -n scripts/bootstrap.sh
grep -Fq 'ext_check_version "handover"       "codex"  "0.144.1"' scripts/bootstrap.sh
grep -Fq 'ext_check_version "advisor/codex"  "codex"  "0.144.1"' scripts/bootstrap.sh
grep -Fq 'ext_check_version "advisor/claude" "claude" "2.1.206"' scripts/bootstrap.sh

echo "OK: advisor and handover use explicit, single-sourced model anchors."
