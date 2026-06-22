#!/usr/bin/env python3
"""Offline tests for PRO-61: the auto-merge-OFF invariant. A merge that lands while the tick
ran without --merge-auto is a breach — stamped on the audit line (merge_auto + violation),
surfaced, and force-alerted by notify ahead of the gate/digest cadence. No driver/network:
a stub driver emits a ledger carrying a merge. Run: python3 tests/drive-invariant-test.py"""
import importlib.util
import json
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
DC_PATH = os.path.join(HERE, "..", "scripts", "drive-cron.py")
spec = importlib.util.spec_from_file_location("drive_cron", DC_PATH)
dc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dc)

passed = failed = 0


def check(desc, cond):
    global passed, failed
    if cond:
        passed += 1
    else:
        failed += 1
        print(f"FAIL  {desc}")


# a stub driver that emits a ledger with one auto-merged item (ignores its args)
sentinel = dc.pslib.LEDGER_SENTINEL
stub_path = tempfile.NamedTemporaryFile("w", suffix=".py", delete=False).name
with open(stub_path, "w") as f:
    f.write("print(%r + ' {\"auto\":1,\"gate\":0,\"blocked\":0,\"gate_ids\":[],\"executed\":"
            "[{\"id\":\"PRO-9\",\"verdict\":\"PASS\",\"merged\":\"psdrive/integration\","
            "\"merged_sha\":\"abc\"}]}')\n" % sentinel)

dc.DRIVE = stub_path
dc.AUDIT = tempfile.NamedTemporaryFile(suffix=".jsonl", delete=False).name
dc.DETAIL_DIR = tempfile.mkdtemp()

# 1. a merge with --merge-auto OFF -> invariant violation, stamped on the audit line
rec = dc.run_one(["--execute", "--max", "1"], "2026-06-22T00:00:00Z")
check("merge_auto off recorded on the record", rec.get("merge_auto") is False)
check("merge with auto OFF -> invariant_violation cites the issue", "PRO-9" in (rec.get("invariant_violation") or ""))
audit_last = json.loads(open(dc.AUDIT).read().strip().splitlines()[-1])
check("audit line is greppable (merge_auto false + violation)",
      audit_last.get("merge_auto") is False and bool(audit_last.get("invariant_violation")))

# 2. the SAME merge WITH --merge-auto is allowed -> no violation
rec2 = dc.run_one(["--execute", "--build-auto", "--only", "p", "--merge-auto", "--max", "1"],
                  "2026-06-22T00:00:00Z", label="p")
check("merge with --merge-auto -> no violation", rec2.get("merge_auto") is True and "invariant_violation" not in rec2)

# 3. notify force-alerts on a violation, bypassing the gate/digest cadence
cap = tempfile.NamedTemporaryFile(suffix=".cap", delete=False).name
st = tempfile.NamedTemporaryFile(suffix=".json", delete=False).name
os.unlink(st)
os.environ["PSDRIVE_NOTIFY_CMD"] = f"cat >> {cap}"
dc.streak_signals = lambda: {}
out = dc.notify([{"gate_ids": [], "auto": 1, "gate": 0, "blocked": 0, "executed": [],
                  "invariant_violation": "merged with --merge-auto OFF: PRO-9"}],
                "2026-06-22", state_path=st)
check("notify returns an alert decision", bool(out) and out[0] == "alert")
body = open(cap).read()
check("alert delivered with the breach + issue", "INVARIANT BREACH" in body and "PRO-9" in body)

for p in (stub_path, dc.AUDIT, cap, st):
    try:
        os.unlink(p)
    except OSError:
        pass

print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
