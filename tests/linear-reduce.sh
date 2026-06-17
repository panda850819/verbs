#!/usr/bin/env bash
# tests/linear-reduce.sh — reduce-logic tests for scripts/pandastack-linear-reduce.
# Pure logic over a fixture; no network, no key. Exit 0 = all pass.

set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$repo_root/scripts/pandastack-linear-reduce"
fx="$(mktemp)"
fail=0

cat > "$fx" <<'JSON'
{"issues":[
  {"identifier":"MUR-A","title":"high early","state":"Building","priority":2,"created_at":"2026-06-10T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-B","title":"urgent late","state":"Building","priority":1,"created_at":"2026-06-12T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-C","title":"blocked by A","state":"Planning","priority":3,"created_at":"2026-06-11T00:00:00Z","blocked_by":["MUR-A"]},
  {"identifier":"MUR-D","title":"needs decision","state":"Needs Decision","priority":1,"created_at":"2026-06-09T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-E","title":"already done","state":"Done","priority":1,"created_at":"2026-06-08T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-F","title":"no priority","state":"Building","priority":0,"created_at":"2026-06-07T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-G","title":"gated by label","state":"Building","priority":1,"labels":["needs-human"],"created_at":"2026-06-06T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-H","title":"verify no acceptance","state":"Verifying","priority":2,"description":"Goal: ship it","created_at":"2026-06-05T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-I","title":"verify with acceptance","state":"Verifying","priority":3,"description":"Goal: ship it\n```acceptance\nbun test transcribe green\n```","created_at":"2026-06-04T00:00:00Z","blocked_by":[]}
]}
JSON

out="$("$S" --source fixture --file "$fx" --json)"

check() { # check <desc> <python-expr-bool>
  if python3 -c "import json,sys; r=json.load(sys.stdin); sys.exit(0 if ($2) else 1)" <<<"$out"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"; fail=1
  fi
}
disp='[i["identifier"] for i in r["dispatchable"]]'
gated='[i["identifier"] for i in r["gated"]]'
blocked='[i["identifier"] for i in r["blocked"]]'

check "dispatchable order = B(urgent), A(high), I(med), F(none last)" "$disp == ['MUR-B','MUR-A','MUR-I','MUR-F']"
check "terminal (Done) excluded entirely"                    "'MUR-E' not in $disp+$gated+$blocked"
check "Needs Decision state is gated, not dispatched"        "'MUR-D' in $gated and 'MUR-D' not in $disp"
check "needs-human label is gated (even in Building)"        "'MUR-G' in $gated and 'MUR-G' not in $disp"
check "issue blocked by a non-terminal blocker is blocked"   "'MUR-C' in $blocked and 'MUR-C' not in $disp"
check "none-priority sorts last among dispatchable"          "$disp[-1] == 'MUR-F'"
check "VERIFY with no acceptance is gated as needs-spec"     "'MUR-H' not in $disp and any(i['identifier']=='MUR-H' and i.get('reason')=='needs-spec' for i in r['gated'])"
check "VERIFY with a machine-checkable acceptance dispatches" "'MUR-I' in $disp"

[ "$fail" -eq 0 ] && echo "OK: linear-reduce all green" || echo "FAILURES present"
exit "$fail"
