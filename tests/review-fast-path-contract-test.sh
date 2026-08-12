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

grep -Fq 'Do not load review learnings' "$skill"
if grep -Fq 'lib/model-anchors.md' "$skill"; then
  echo 'FAIL: Review still names Advisor model anchors' >&2
  exit 1
fi
grep -Fq 'Read `lib/learning-recall.md`' "$skill"
grep -Fq 'isolated read-only reviewer' "$skill"
grep -Fq 'the transport and model family do not define the review' "$skill"
grep -Fq 'Cold review: unavailable — no isolation capability' "$skill"
grep -Fq 'A second pass in this same context is not a cold review' "$skill"
grep -Fq 'High uses every relevant lens plus a' "$skill"
grep -Fq 'Cold review: <not earned | completed | unavailable>' "$skill"
grep -Fq 'review` after it selects or promotes to medium/high' "$recall"

# ship gate 3 keeps its own search: review recall and gate 3 query the same
# store on different fields, so "review ran" is not evidence of coverage (#296).
ship="skills/engineering/ship/SKILL.md"
# Match on whitespace-normalized text: these fragments wrap across lines, and a
# line-anchored grep would pass or fail on rewrapping rather than on meaning.
ship_flat=$(tr '\n' ' ' < "$ship" | tr -s ' ')
for fragment in \
  'Skip only what an earlier read this session already listed by this same query' \
  'Running `review` is not itself evidence' \
  'takes the top 3-5, and drops effective confidence below 3' \
  'Same store, different query'; do
  case "$ship_flat" in
    *"$fragment"*) ;;
    *) echo "FAIL: ship gate 3 missing contract fragment: $fragment" >&2; exit 1 ;;
  esac
done

echo "OK: review fast path precedes and preserves escalated review"
