#!/usr/bin/env bash
# tests/linear-linkback.sh — dry-run coverage for Linear ledger + PR review artifact helpers.
# No network: all checks use --dry-run.
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LC="$repo_root/scripts/pandastack-linear-comment"
PC="$repo_root/scripts/pandastack-pr-review-comment"
fail=0

check_contains() { # check_contains <desc> <haystack> <needle>
  if grep -Fq -- "$3" <<<"$2"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"; fail=1
  fi
}

ledger_out="$($LC --issue PRO-XX --repo panda850819/pandastack \
  --branch feat/linear-writeback-ledger --commit abc1234 \
  --pr https://github.com/panda850819/pandastack/pull/99 \
  --checks "tests/linear-linkback.sh green" \
  --review-url https://github.com/panda850819/pandastack/pull/99#issuecomment-1 \
  --verdict "ready for human review" --dry-run)"

check_contains "linear ledger dry-run names issue" "$ledger_out" "PRO-XX"
check_contains "linear ledger includes repo" "$ledger_out" "- Repo: panda850819/pandastack"
check_contains "linear ledger includes branch" "$ledger_out" "- Branch: \`feat/linear-writeback-ledger\`"
check_contains "linear ledger includes commit" "$ledger_out" "- Commit: \`abc1234\`"
check_contains "linear ledger includes PR URL" "$ledger_out" "https://github.com/panda850819/pandastack/pull/99"
check_contains "linear ledger includes review URL" "$ledger_out" "https://github.com/panda850819/pandastack/pull/99#issuecomment-1"
check_contains "linear ledger includes verdict" "$ledger_out" "ready for human review"

body_file="$(mktemp)"
cat > "$body_file" <<'MD'
## PandaStack PR Review

- Verdict: ready for human review
- Tests: green
MD

review_out="$($PC --repo panda850819/pandastack --pr 0 --body-file "$body_file" --dry-run)"
check_contains "PR review dry-run names target" "$review_out" "panda850819/pandastack PR #0"
check_contains "PR review dry-run includes body" "$review_out" "## PandaStack PR Review"
check_contains "PR review dry-run includes verdict" "$review_out" "ready for human review"

# a malformed --repo must be rejected before it can rewrite the GitHub API URL path
if "$PC" --repo "owner/repo/../../x" --pr 1 --body-file "$body_file" --dry-run >/dev/null 2>&1; then
  echo "FAIL: PR review rejects malformed --repo"; fail=1
else
  echo "PASS: PR review rejects malformed --repo"
fi

[ "$fail" -eq 0 ] && echo "OK: linear-linkback all green" || echo "FAILURES present"
exit "$fail"
