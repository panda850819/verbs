#!/usr/bin/env bash
# tests/state-store.sh — round-trip + reducer tests for scripts/pandastack-state.
# Exit 0 = all pass. No external deps (python3 stdlib only).

set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$repo_root/scripts/pandastack-state"
export PANDASTACK_STATE_HOME="$(mktemp -d)"
fail=0

assert() { # assert <desc> <expected-substring> <actual>
  if echo "$3" | grep -qF "$2"; then echo "PASS: $1"; else
    echo "FAIL: $1"; echo "  expected to contain: $2"; echo "  got: $3"; fail=1; fi
}
assert_exit() { # assert_exit <desc> <expected-code> <actual-code>
  if [ "$2" = "$3" ]; then echo "PASS: $1"; else
    echo "FAIL: $1 (expected exit $2, got $3)"; fail=1; fi
}

# 1. append + reduce round-trip
"$S" append --slug t --item alpha --event phase_enter --phase DEFINE --skill office-hours >/dev/null
"$S" append --slug t --item alpha --event phase_enter --phase BUILD  --skill sprint >/dev/null
out="$("$S" reduce --slug t)"
assert "item folds to last phase entered" "alpha" "$out"
assert "alpha active in BUILD" "BUILD" "$out"

# 2. paused keeps phase, status flips
"$S" append --slug t --item alpha --event paused --phase BUILD --skill checkpoint >/dev/null
out="$("$S" reduce --slug t --item alpha)"
assert "paused status reduced" "paused" "$out"

# 3. terminal item dropped from `next`
"$S" append --slug t --item beta --event shipped --phase SHIP --skill ship >/dev/null
nxt="$("$S" next --slug t)"
assert "active item present in next" "alpha" "$nxt"
if echo "$nxt" | grep -qF "beta"; then echo "FAIL: shipped item leaked into next"; fail=1; else echo "PASS: terminal item excluded from next"; fi

# 4. delegated sets codex owner
"$S" append --slug t --item gamma --event phase_enter --phase VERIFY --skill sprint --runtime codex >/dev/null
"$S" append --slug t --item gamma --event delegated --skill handover --runtime codex >/dev/null
j="$("$S" reduce --slug t --item gamma --json)"
assert "delegated marks codex owner" '"owner": "codex"' "$j"

# 5. validation rejects bad event / missing phase
"$S" append --slug t --item x --event bogus --skill sprint >/dev/null 2>&1; assert_exit "bad event rejected" 1 $?
"$S" append --slug t --item x --event phase_enter --skill sprint >/dev/null 2>&1; assert_exit "phase_enter needs phase" 1 $?

# 6. append-only — line count grows, never rewrites
lines="$(wc -l < "$("$S" path --slug t)")"
[ "$lines" -ge 6 ] && echo "PASS: append-only log accumulated ($lines lines)" || { echo "FAIL: expected >=6 lines, got $lines"; fail=1; }

[ "$fail" -eq 0 ] && echo "OK: state-store all green" || echo "FAILURES present"
exit "$fail"
