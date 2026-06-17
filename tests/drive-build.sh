#!/usr/bin/env bash
# tests/drive-build.sh — BUILD-autonomy classification tests for scripts/pandastack-drive.
# Pure logic over a fixture via PSDRIVE_FIXTURE; no network, no Linear, no codex.
# Exit 0 = all pass.
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
fx="$(mktemp)"
fail=0

cat > "$fx" <<'JSON'
{"issues":[
  {"identifier":"MUR-1","title":"build ready","project":"murmur","state":"Building","priority":1,"description":"Goal: ship X\n```acceptance\nbun test x green\n```","created_at":"2026-06-10T00:00:00Z"},
  {"identifier":"MUR-2","title":"build no spec","project":"murmur","state":"Building","priority":1,"description":"just do it","created_at":"2026-06-11T00:00:00Z"},
  {"identifier":"OTH-1","title":"other project","project":"shawn-trade","state":"Building","priority":1,"description":"Goal: y\n```acceptance\nrun y\n```","created_at":"2026-06-12T00:00:00Z"}
]}
JSON

check() { # check <desc> <python-expr-bool> <json>
  if python3 -c "import json,sys; r=json.load(sys.stdin); sys.exit(0 if ($2) else 1)" <<<"$3"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"; fail=1
  fi
}

# --build-auto requires --only (never global)
if PSDRIVE_FIXTURE="$fx" "$D" --json --build-auto >/dev/null 2>&1; then
  echo "FAIL: --build-auto without --only must error"; fail=1
else
  echo "PASS: --build-auto without --only errors"
fi

# flag OFF (default): no behavior change — Building stays auto-verify, no build entries
off="$(PSDRIVE_FIXTURE="$fx" "$D" --json)"
check "flag OFF: no build entries"                "not any(x.get('build') for x in r['AUTO'])"                         "$off"

# flag ON, --only murmur
on="$(PSDRIVE_FIXTURE="$fx" "$D" --json --build-auto --only murmur)"
check "MUR-1 build-ready -> AUTO with build flag"  "any(x['id']=='MUR-1' and x.get('build') for x in r['AUTO'])"        "$on"
check "MUR-1 advance target is Verifying"          "any(x['id']=='MUR-1' and x.get('to_state')=='Verifying' for x in r['AUTO'])" "$on"
check "MUR-2 no-spec -> gated needs-spec"          "any(x['id']=='MUR-2' and 'needs-spec' in (x.get('reason') or '') for x in r['GATE'])" "$on"
check "OTH-1 (other project) not auto-built"       "not any(x['id']=='OTH-1' and x.get('build') for x in r['AUTO'])"   "$on"

[ "$fail" -eq 0 ] && echo "OK: drive-build all green" || echo "FAILURES present"
exit "$fail"
