#!/usr/bin/env bash
# tests/drive-concurrency.sh — whole-loop dispatch lock (CC, review C1).
#
# Asserts: a second --execute that finds the dispatch lock held yields cleanly
# (skip line, no dispatch loop, exit 0); read-only --json is never blocked by the
# held lock; once the lock frees, --execute acquires it and enters the loop.
# A GATE-only fixture guarantees zero codex calls (no AUTO item ever dispatches).
set -uo pipefail
export PSDRIVE_TEST=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
export PSDRIVE_WORKER_JOB_ROOT="$(mktemp -d)"
fail=0

lock="$(mktemp -u).lock"
ready="$(mktemp -u).ready"
fx="$(mktemp)"
cat > "$fx" <<'JSON'
{"issues":[
  {"identifier":"GAT-1","title":"needs a human decision","project":"murmur","state":"Needs Decision","priority":1,"description":"Goal: decide\nContext: y","created_at":"2026-06-10T00:00:00Z"}
]}
JSON

# Holder: flock the exact dispatch-lock file and hold it while the assertions run.
python3 - "$lock" "$ready" <<'PY' &
import fcntl, sys, time
f = open(sys.argv[1], "w")
fcntl.flock(f.fileno(), fcntl.LOCK_EX)
open(sys.argv[2], "w").write("held")
time.sleep(8)
PY
holder=$!
for _ in $(seq 1 100); do [ -f "$ready" ] && break; sleep 0.05; done

# 1) contended --execute yields cleanly
out="$(PSDRIVE_TEST=1 PSDRIVE_DISPATCH_LOCK="$lock" PSDRIVE_FIXTURE="$fx" "$D" --execute --max 1 2>&1)"; rc=$?
echo "$out" | grep -q "concurrency lock" \
  && echo "PASS: contended --execute prints the concurrency-skip line" \
  || { echo "FAIL: no concurrency-skip line"; fail=1; }
if echo "$out" | grep -q "Codex headless"; then
  echo "FAIL: dispatch loop ran despite a held lock"; fail=1
else
  echo "PASS: dispatch loop short-circuited before any exec"
fi
[ "$rc" -eq 0 ] && echo "PASS: contended --execute exits 0" || { echo "FAIL: contended exit rc=$rc"; fail=1; }

# 2) read-only --json is never blocked by the held lock
if PSDRIVE_DISPATCH_LOCK="$lock" PSDRIVE_FIXTURE="$fx" "$D" --json >/dev/null 2>&1; then
  echo "PASS: read-only --json unaffected while lock held"
else
  echo "FAIL: --json blocked by the dispatch lock"; fail=1
fi

kill "$holder" 2>/dev/null; wait "$holder" 2>/dev/null

# 3) lock free → --execute acquires it and enters the loop (GATE-only → no codex)
out2="$(PSDRIVE_TEST=1 PSDRIVE_DISPATCH_LOCK="$lock" PSDRIVE_FIXTURE="$fx" "$D" --execute --max 1 2>&1)"
if echo "$out2" | grep -q "Codex headless"; then
  echo "PASS: uncontended --execute acquires the lock and dispatches"
else
  echo "FAIL: uncontended --execute did not enter the loop"; fail=1
fi

[ "$fail" -eq 0 ] && echo "OK: drive-concurrency all green" || echo "FAILURES present"
exit "$fail"
