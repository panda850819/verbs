#!/usr/bin/env bash
# tests/linear-reduce.sh — reduce-logic tests for scripts/pandastack-linear-reduce.
# Pure logic over fixtures; no network, no key. Exit 0 = all pass.
# Readiness is keyed on the TO-RUN (next) phase (pslib.readiness_gap):
#   Building (next VERIFY)  -> needs a RUNNABLE ```acceptance``` block
#   Verifying (next REVIEW) -> needs a diff/artifact ref
#   Backlog/Planning (next PLAN/GATE) -> not gated (grill bootstraps; GATE is human)
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$repo_root/scripts/pandastack-linear-reduce"
fx="$(mktemp)"
fail=0

cat > "$fx" <<'JSON'
{"issues":[
  {"identifier":"MUR-A","title":"high early","state":"Backlog","priority":2,"created_at":"2026-06-10T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-B","title":"urgent late","state":"Backlog","priority":1,"created_at":"2026-06-12T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-C","title":"blocked by A","state":"Planning","priority":3,"created_at":"2026-06-11T00:00:00Z","blocked_by":["MUR-A"]},
  {"identifier":"MUR-D","title":"needs decision","state":"Needs Decision","priority":1,"created_at":"2026-06-09T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-E","title":"already done","state":"Done","priority":1,"created_at":"2026-06-08T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-F","title":"no priority","state":"Backlog","priority":0,"created_at":"2026-06-07T00:00:00Z","blocked_by":[]},
  {"identifier":"MUR-G","title":"gated by label","state":"Building","priority":1,"labels":["needs-human"],"created_at":"2026-06-06T00:00:00Z","blocked_by":[]}
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

check "dispatchable order = B(urgent), A(high), F(none last)" "$disp == ['MUR-B','MUR-A','MUR-F']"
check "terminal (Done) excluded entirely"                    "'MUR-E' not in $disp+$gated+$blocked"
check "Needs Decision state is gated, not dispatched"        "'MUR-D' in $gated and 'MUR-D' not in $disp"
check "needs-human label is gated (even in Building)"        "'MUR-G' in $gated and 'MUR-G' not in $disp"
check "issue blocked by a non-terminal blocker is blocked"   "'MUR-C' in $blocked and 'MUR-C' not in $disp"
check "none-priority sorts last among dispatchable"          "$disp[-1] == 'MUR-F'"

# ---- per-phase readiness (keyed on to-run / next phase) ----
fx2="$(mktemp)"
cat > "$fx2" <<'JSON'
{"issues":[
  {"identifier":"B-1","title":"build->verify ok","state":"Building","priority":2,"description":"Goal: x\n```acceptance\nbun test x green\n```","created_at":"2026-06-10T00:00:00Z"},
  {"identifier":"B-2","title":"build no acceptance","state":"Building","priority":2,"description":"just build it","created_at":"2026-06-11T00:00:00Z"},
  {"identifier":"B-3","title":"acceptance is prose","state":"Building","priority":2,"description":"```acceptance\nit should feel polished and human\n```","created_at":"2026-06-12T00:00:00Z"},
  {"identifier":"B-4","title":"build no declared lane","state":"Building","priority":2,"description":"Goal: x\nContext: y\nAcceptance: visually done","created_at":"2026-06-12T12:00:00Z"},
  {"identifier":"B-5","title":"build evidence lane","state":"Building","priority":2,"description":"Goal: x\n```evidence\nscreenshot of settings panel\n```","created_at":"2026-06-12T13:00:00Z"},
  {"identifier":"V-1","title":"verify->review ok","state":"Verifying","priority":2,"description":"Deliverable: branch psdrive/V-1 (/pull/5)","created_at":"2026-06-13T00:00:00Z"},
  {"identifier":"V-2","title":"verify no artifact","state":"Verifying","priority":2,"description":"please review this","created_at":"2026-06-14T00:00:00Z"},
  {"identifier":"BL-1","title":"bare backlog","state":"Backlog","priority":2,"description":"","created_at":"2026-06-15T00:00:00Z"}
]}
JSON
out="$("$S" --source fixture --file "$fx2" --json)"
check "Building w/ runnable acceptance dispatches (next VERIFY)"   "'B-1' in $disp"
check "Building w/o acceptance gated needs-spec (VERIFY gap)"      "'B-2' in $gated and any(i['identifier']=='B-2' and 'VERIFY' in (i.get('gap') or '') for i in r['gated'])"
check "Building w/ PROSE acceptance gated (not machine-checkable)" "'B-3' in $gated and 'B-3' not in $disp"
check "Building w/ neither runnable acceptance nor evidence gated (VERIFY gap)" "'B-4' in $gated and any(i['identifier']=='B-4' and 'VERIFY' in (i.get('gap') or '') for i in r['gated'])"
check "Building w/ named evidence dispatches (human-merge lane)"    "'B-5' in $disp"
check "Verifying w/ artifact dispatches (next REVIEW)"             "'V-1' in $disp"
check "Verifying w/o artifact gated needs-spec (REVIEW gap)"       "'V-2' in $gated and any(i['identifier']=='V-2' and 'REVIEW' in (i.get('gap') or '') for i in r['gated'])"
check "bare Backlog dispatches (next PLAN not gated; grill bootstraps)" "'BL-1' in $disp"

[ "$fail" -eq 0 ] && echo "OK: linear-reduce all green" || echo "FAILURES present"
exit "$fail"
