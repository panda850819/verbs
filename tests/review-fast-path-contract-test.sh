#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

skill="skills/engineering/review/SKILL.md"
recall="lib/learning-recall.md"

fast_line=$(grep -n '^### Low-risk fast path$' "$skill" | cut -d: -f1)
escalated_line=$(grep -n '^## 3\. Escalated review$' "$skill" | cut -d: -f1)
[ -n "$fast_line" ]
[ -n "$escalated_line" ]
[ "$fast_line" -lt "$escalated_line" ]

grep -Fq 'Do not load review learnings or model anchors' "$skill"
grep -Fq 'Read `lib/learning-recall.md`' "$skill"
grep -Fq 'Read `lib/model-anchors.md` only' "$skill"
grep -Fq 'High uses every relevant lens plus a' "$skill"
grep -Fq 'Cold review: <not earned | completed | unavailable>' "$skill"
grep -Fq 'review` after it selects or promotes to medium/high' "$recall"

echo "OK: review fast path precedes and preserves escalated review"
