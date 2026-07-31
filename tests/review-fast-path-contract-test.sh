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

# ship gate 3 must not re-read the store an escalated review just read, and must
# still fire on the low-risk path where recall never ran (#296).
ship="skills/engineering/ship/SKILL.md"
# Match on whitespace-normalized text: these fragments wrap across lines, and a
# line-anchored grep would pass or fail on rewrapping rather than on meaning.
ship_flat=$(tr '\n' ' ' < "$ship" | tr -s ' ')
for fragment in \
  'only when recall did not already run on this diff' \
  'it took the low-risk fast path, which stops before' \
  'the gate narrows rather than disappears'; do
  case "$ship_flat" in
    *"$fragment"*) ;;
    *) echo "FAIL: ship gate 3 missing contract fragment: $fragment" >&2; exit 1 ;;
  esac
done

echo "OK: review fast path precedes and preserves escalated review"
