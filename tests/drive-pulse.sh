#!/usr/bin/env bash
# tests/drive-pulse.sh — drive-pulse renders a windowed vital-signs read from the driver
# ledger: headlines with delta vs the prior window, no-data markers for un-instrumented
# signals, and drive-log-distill wrapped as followups. (PRO-44 / read-side)
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$repo_root/scripts/drive-pulse"
fail=0
tmp="$(mktemp -d)"
log="$tmp/drive-log.jsonl"

# anchor now=2026-06-15, days=7 -> current=[06-08,06-15), prior=[06-01,06-08)
# current: 3 PASS of A (stuck), 1 advance, 2 gate of G, 1 suppressed tick
# prior:   1 PASS of A
{
  echo '{"ts":"2026-06-03T00:00:00Z","executed":[{"id":"A","verdict":"PASS"}],"gate_ids":[]}'
  echo '{"ts":"2026-06-09T00:00:00Z","executed":[{"id":"A","verdict":"PASS","advance":"adv A"}],"gate_ids":["G"]}'
  echo '{"ts":"2026-06-10T00:00:00Z","executed":[{"id":"A","verdict":"PASS"}],"gate_ids":["G"]}'
  echo '{"ts":"2026-06-11T00:00:00Z","executed":[{"id":"A","verdict":"PASS"}],"gate_ids":[]}'
  echo '{"ts":"2026-06-12T00:00:00Z","suppressed":true,"executed":[],"gate_ids":[]}'
} > "$log"

pass(){ echo "PASS: $1"; }
fl(){ echo "FAIL: $1"; fail=1; }

out="$("$S" "$log" --now 2026-06-15 --days 7 --json 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fl "drive-pulse errored (rc=$rc)"

J() { echo "$out" | python3 -c "import json,sys;r=json.load(sys.stdin);sys.exit(0 if ($1) else 1)"; }

J "r['current']['passes']==3"        && pass "current window: 3 PASS"           || fl "current passes wrong"
J "r['prior']['passes']==1"          && pass "prior window: 1 PASS (delta basis)" || fl "prior passes wrong"
J "r['current']['advances']==1"      && pass "current window: 1 advance"        || fl "advances wrong"
J "r['current']['suppressed']==1"    && pass "current window: 1 suppressed tick" || fl "suppressed wrong"
J "any(i=='A' and c==3 for i,c in r['current']['top_stuck_pass'])" && pass "vital: A is top stuck-PASS ×3" || fl "top_stuck_pass wrong"
J "'no data' in r['no_data']['fake_green'] and 'no data' in r['no_data']['agreement_streak']" && pass "no-data rendered for un-instrumented signals" || fl "no-data missing"
J "len(r['followups'])>0" && pass "followups wraps drive-log-distill output" || fl "followups empty"

# text mode renders delta (+2 passes vs prior) and the no-data section
txt="$("$S" "$log" --now 2026-06-15 --days 7 2>&1)"
grep -q "(+2)" <<<"$txt" && pass "text: PASS delta +2 rendered" || fl "delta not rendered"
grep -q "NO DATA" <<<"$txt" && pass "text: NO DATA section present" || fl "no-data section missing"

[ "$fail" -eq 0 ] && echo "OK: drive-pulse all green" || echo "FAILURES present"
exit "$fail"
