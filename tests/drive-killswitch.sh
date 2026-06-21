#!/usr/bin/env bash
# tests/drive-killswitch.sh — kill-switch: a flag-file halts autonomous DISPATCH on
# the next tick, at BOTH loop boundaries (the drive-cron launchd wrapper and a direct
# pandastack-drive --execute), while read-only visibility is preserved. The check is
# unconditional; the loop never decides whether to obey. Pure logic — no network,
# no Linear, no codex. (PRO-36, boundary #12 / review F-E / F-J)
set -uo pipefail
export PSDRIVE_TEST=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
CRON="$repo_root/scripts/drive-cron.py"
fail=0
tmp="$(mktemp -d)"
FLAG="$tmp/STOP"
AUDIT="$tmp/drive-log.jsonl"

# fixture with one dispatchable AUTO item (Backlog -> next phase PLAN, not gated)
fx="$tmp/fx.json"
cat > "$fx" <<'JSON'
{"issues":[{"identifier":"KS-1","title":"plan me","project":"murmur","state":"Backlog","priority":1,"description":"just a title here","created_at":"2026-06-10T00:00:00Z"}]}
JSON
emptyfx="$tmp/empty.json"
echo '{"issues":[]}' > "$emptyfx"

pass() { echo "PASS: $1"; }
fl()   { echo "FAIL: $1"; fail=1; }

# ---- predicate (pslib single source) ----
rm -f "$FLAG"
PSDRIVE_STOP_FLAG="$FLAG" python3 -c "import sys; sys.path.insert(0,'$repo_root/scripts'); import pslib; sys.exit(0 if not pslib.drive_suppressed() else 1)" \
  && pass "predicate: flag absent -> not suppressed" || fl "predicate flag absent"
: > "$FLAG"
PSDRIVE_STOP_FLAG="$FLAG" python3 -c "import sys; sys.path.insert(0,'$repo_root/scripts'); import pslib; sys.exit(0 if pslib.drive_suppressed() else 1)" \
  && pass "predicate: flag present -> suppressed" || fl "predicate flag present"

# ---- layer 2: direct pandastack-drive --execute ----
# flag ON + --execute -> zero dispatch (queue never built), kill-switch marker, exit 0
out="$(PSDRIVE_STOP_FLAG="$FLAG" PSDRIVE_FIXTURE="$fx" "$D" --execute 2>&1)"; rc=$?
{ [ "$rc" -eq 0 ] && grep -q "kill-switch" <<<"$out" && ! grep -q "TODAY'S QUEUE" <<<"$out"; } \
  && pass "flag ON + --execute -> suppressed, zero dispatch, exit 0" || fl "execute not suppressed (rc=$rc)"

# flag ON + --json (read-only) -> NOT suppressed; the queue is still visible
js="$(PSDRIVE_STOP_FLAG="$FLAG" PSDRIVE_FIXTURE="$fx" "$D" --json 2>&1)"
echo "$js" | python3 -c "import json,sys; r=json.load(sys.stdin); sys.exit(0 if any(x['id']=='KS-1' for x in r['AUTO']) else 1)" 2>/dev/null \
  && pass "flag ON + --json read-only -> visibility preserved (not suppressed)" || fl "read-only got suppressed"

# flag ON + --execute WITH the auto-merge ratchet flags on -> kill-switch still wins:
# zero dispatch, no @@PSDRIVE_LEDGER@@, nothing built or merged. The one out-of-band
# control must hold ABOVE the ratchet, not just in read-only mode.
: > "$FLAG"
outm="$(PSDRIVE_STOP_FLAG="$FLAG" PSDRIVE_FIXTURE="$fx" "$D" --execute --build-auto --merge-auto --only murmur --max 1 2>&1)"; rc=$?
{ [ "$rc" -eq 0 ] && grep -q "kill-switch" <<<"$outm" && ! grep -q "@@PSDRIVE_LEDGER@@" <<<"$outm"; } \
  && pass "flag ON + --merge-auto ratchet -> kill-switch wins, zero dispatch, no merge" || fl "kill-switch lost to the ratchet flags (rc=$rc)"

# flag OFF + --execute (empty fixture) -> normal path, not suppressed, no codex, exit 0
rm -f "$FLAG"
out2="$(PSDRIVE_STOP_FLAG="$FLAG" PSDRIVE_FIXTURE="$emptyfx" "$D" --execute 2>&1)"; rc=$?
{ [ "$rc" -eq 0 ] && ! grep -q "kill-switch" <<<"$out2"; } \
  && pass "flag OFF + --execute -> normal path, not suppressed" || fl "flag OFF suppressed (rc=$rc)"

# ---- layer 1: drive-cron launchd wrapper ----
# flag ON -> suppressed record + exit 0, driver NEVER invoked. PSDRIVE_DRIVE_BIN points
# at /bin/false: if the guard failed and the driver ran, the record would not be
# suppressed (and would carry an error), so this also proves zero dispatch.
: > "$FLAG"
PSDRIVE_STOP_FLAG="$FLAG" PSDRIVE_AUDIT="$AUDIT" PSDRIVE_DRIVE_BIN="/bin/false" python3 "$CRON" >/dev/null 2>&1; rc=$?
last="$(tail -1 "$AUDIT" 2>/dev/null)"
{ [ "$rc" -eq 0 ] && echo "$last" | python3 -c "import json,sys; r=json.load(sys.stdin); sys.exit(0 if r.get('suppressed') is True and not r['executed'] else 1)"; } \
  && pass "drive-cron flag ON -> drive-log suppressed:true, zero dispatch, exit 0" || fl "cron suppressed record (rc=$rc)"

# flag OFF -> drive-cron invokes the driver (stub), writes a normal (non-suppressed) record
rm -f "$FLAG"
stub="$tmp/stub-drive"; printf '#!/usr/bin/env bash\necho "X AUTO (x): 0"\n' > "$stub"; chmod +x "$stub"
: > "$AUDIT"
PSDRIVE_STOP_FLAG="$FLAG" PSDRIVE_AUDIT="$AUDIT" PSDRIVE_DRIVE_BIN="$stub" python3 "$CRON" >/dev/null 2>&1; rc=$?
last2="$(tail -1 "$AUDIT" 2>/dev/null)"
{ [ "$rc" -eq 0 ] && echo "$last2" | python3 -c "import json,sys; r=json.load(sys.stdin); sys.exit(0 if not r.get('suppressed') else 1)"; } \
  && pass "drive-cron flag OFF -> driver invoked, non-suppressed record" || fl "cron OFF record (rc=$rc)"

[ "$fail" -eq 0 ] && echo "OK: drive-killswitch all green" || echo "FAILURES present"
exit "$fail"
