#!/usr/bin/env bash
# tests/drive-ledger.sh — structured ledger instrumentation (LG, F-K/F-L).
#
# Asserts: (1) ledger_record maps the executor result into verify_ran/verify_ok/
# verify_cmd/verify_required and the fake-green predicate fires only on a PASS that
# proposed a verify-required advance with no host-verify; (2) a REAL host-verify run
# sets verify_ran=true (the anti-fake-green guarantee, not just a present field);
# (3) drive-cron consumes the structured @@PSDRIVE_LEDGER@@ line verbatim and still
# falls back to the legacy regex when no sentinel is present.
# Pure logic over fixtures; no network, no Linear, no codex. PSDRIVE_TEST=1 gates seams.
set -uo pipefail
export PSDRIVE_TEST=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
CRON="$repo_root/scripts/drive-cron.py"
export PSDRIVE_WORKER_JOB_ROOT="$(mktemp -d)"
fail=0

# ---------- 1. ledger_record: field mapping + fake-green predicate ----------
python3 - "$D" <<'PY'
import sys, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader))
loader.exec_module(m)

def fake_green(e):
    return e["verdict"] == "PASS" and e["advance"] and e["verify_required"] and not e["verify_ran"]

# a real BUILD PASS that ran host-verify → verified, not fake-green
x = {"id": "MUR-1", "project": "murmur", "next": "BUILD", "build": True}
r = {"verdict": "PASS", "summary": "built", "advance": "pandastack-linear-advance ...",
     "verify_cmd": "bun test x green",
     "verification": {"ran": True, "ok": True, "command": "/tmp/job/verify.sh",
                      "stdout_tail": "1 pass"}}
rec = m.ledger_record(x, r)
assert rec["verify_required"] is True and rec["verify_ran"] is True and rec["verify_ok"] is True, rec
assert rec["verify_cmd"] == "bun test x green", rec
assert not fake_green(rec), "a verified PASS must NOT be fake-green"

# a read-only AUTO advisory advance (no host-verify, F-M) → not required, not fake-green
x2 = {"id": "MUR-2", "project": "murmur", "next": "REVIEW"}   # no build flag
r2 = {"verdict": "PASS", "summary": "looks good", "advance": "pandastack-linear-advance ...",
      "verification": {}}
rec2 = m.ledger_record(x2, r2)
assert rec2["verify_required"] is False and rec2["verify_ran"] is False, rec2
assert not fake_green(rec2), "read-only advisory advance must NOT count as fake-green"

# a fake-green: BUILD PASS that proposed an advance but no host-verify ran
x3 = {"id": "MUR-3", "project": "murmur", "next": "BUILD", "build": True}
r3 = {"verdict": "PASS", "summary": "claimed", "advance": "pandastack-linear-advance ...",
      "verification": {}}
rec3 = m.ledger_record(x3, r3)
assert rec3["verify_required"] is True and rec3["verify_ran"] is False, rec3
assert fake_green(rec3), "PASS+advance+verify_required+no-verify MUST be flagged fake-green"

# the grep over a mixed ledger counts exactly the one bad record
bad = [e for e in (rec, rec2, rec3) if fake_green(e)]
assert len(bad) == 1 and bad[0]["id"] == "MUR-3", bad
print("PASS: ledger_record fields + fake-green predicate (1 flagged of 3)")
PY
[ $? -eq 0 ] || { echo "FAIL: ledger_record unit"; fail=1; }

# ---------- 2. e2e: a REAL host-verify sets verify_ran=true ----------
tmprepo="$(mktemp -d)"
git -C "$tmprepo" init -q
git -C "$tmprepo" config user.email t@t.t; git -C "$tmprepo" config user.name t
echo seed > "$tmprepo/seed.txt"; git -C "$tmprepo" add -A; git -C "$tmprepo" commit -qm seed

e2e="$(PSDRIVE_TEST=1 PSDRIVE_BUILD_STUB=PASS python3 - "$D" "$tmprepo" <<'PY'
import sys, json, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader))
loader.exec_module(m)
# discriminating acceptance: FAILS pre-build (stub file absent → survives the F-A
# anti-tautology sentinel), PASSES post-build (the PASS stub writes .psdrive-stub).
desc = "Goal: ship X\nContext: because Y\n```acceptance\ntest -f .psdrive-stub\n```\n"
x = {"id": "LED-1", "project": "t", "repo": sys.argv[2], "title": "ledger e2e",
     "next": "BUILD", "to_state": "Verifying", "build": True, "desc": desc}
r = m.exec_build(x)
print(json.dumps({"verdict": r.get("verdict"), "v": r.get("verification"),
                  "rec": m.ledger_record(x, r)}))
PY
)"
echo "$e2e" | python3 -c '
import json, sys
o = json.load(sys.stdin); rec = o["rec"]; v = o["v"] or {}
assert o["verdict"] == "PASS", o
assert v.get("ran") is True and v.get("ok") is True, o
assert rec["verify_ran"] is True and rec["verify_ok"] is True, rec
assert rec["verify_required"] is True, rec
assert rec["verify_cmd"] == "test -f .psdrive-stub", rec
assert rec["advance"], rec
print("PASS: real host-verify → verify_ran=true, verify_ok=true, verify_cmd captured")
' || { echo "FAIL: e2e host-verify wiring"; fail=1; }

# ---------- 3. drive-cron consumes the structured sentinel verbatim ----------
python3 - "$CRON" <<'PY'
import sys, json, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("drivecron", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("drivecron", loader))
loader.exec_module(m)

blob = {"auto": 2, "gate": 1, "blocked": 0, "gate_ids": ["PRO-9"],
        "executed": [
          {"id": "A-1", "verdict": "PASS", "advance": "adv", "verify_required": True,
           "verify_ran": True, "verify_ok": True, "verify_cmd": "bun test"},
          {"id": "A-2", "verdict": "PASS", "advance": "adv", "verify_required": True,
           "verify_ran": False, "verify_ok": None, "verify_cmd": None},
        ]}
stdout = "TODAY'S QUEUE ...\n  > A-1 ...\n" + m.pslib.LEDGER_SENTINEL + " " + json.dumps(blob) + "\n"
rec = m.parse(stdout)
assert rec["auto"] == 2 and rec["gate"] == 1 and rec["gate_ids"] == ["PRO-9"], rec
assert len(rec["executed"]) == 2, rec
# fields survived verbatim (not regex-reconstructed, which would drop verify_*)
assert rec["executed"][0]["verify_ran"] is True and rec["executed"][0]["verify_cmd"] == "bun test", rec
bad = [e for e in rec["executed"]
       if e["verdict"] == "PASS" and e["advance"] and e["verify_required"] and not e["verify_ran"]]
assert len(bad) == 1 and bad[0]["id"] == "A-2", bad

# fallback: no sentinel → legacy regex still parses the human stdout
legacy = ("▶ AUTO ...:  1\n⏸ GATE ...:  0\n"
          "  ▶ B-1 (p) → codex verify …\n    PASS: ok\n"
          "    → ready to advance (run it yourself): adv-cmd\n")
rl = m.parse(legacy)
assert rl["auto"] == 1 and any(e["id"] == "B-1" and e["verdict"] == "PASS" for e in rl["executed"]), rl
print("PASS: drive-cron parses structured ledger verbatim + legacy fallback intact")
PY
[ $? -eq 0 ] || { echo "FAIL: drive-cron structured parse"; fail=1; }

[ "$fail" -eq 0 ] && echo "OK: drive-ledger all green" || echo "FAILURES present"
exit "$fail"
