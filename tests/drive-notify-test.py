#!/usr/bin/env python3
"""Offline tests for drive-cron.py C4 notify — the pure decision + the state/deliver wiring.
No driver, no drive-pulse, no network. Run: python3 tests/drive-notify-test.py"""
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


SIG = {"fake_green": 0, "trust_streak": 7, "streak_target": 20}
COUNTS = {"auto": 2, "gate": 1, "blocked": 0, "proposals": 0}

# --- go_no_go ---
check("GO when zero fake-green, carries streak", dc.go_no_go(SIG).startswith("GO") and "7/20" in dc.go_no_go(SIG))
check("NO-GO when fake-green > 0",
      dc.go_no_go({"fake_green": 1, "trust_streak": 0, "streak_target": 20}).startswith("NO-GO"))
check("n/a when uninstrumented", dc.go_no_go({}) == "streak n/a")

# --- notify_decision (pure) ---
d = dc.notify_decision(["PRO-9"], COUNTS, SIG, {}, "2026-06-22")
check("new gate -> gate ping with id + go/no-go", d and d[0] == "gate" and "PRO-9" in d[1] and "GO" in d[1])
check("unchanged gate, contacted today -> silent",
      dc.notify_decision(["PRO-9"], COUNTS, SIG,
                         {"seen_gate_ids": ["PRO-9"], "last_contact_date": "2026-06-22"}, "2026-06-22") is None)
d = dc.notify_decision(["PRO-9"], COUNTS, SIG,
                       {"seen_gate_ids": ["PRO-9"], "last_contact_date": "2026-06-21"}, "2026-06-22")
check("new day, no new gate -> digest floor", d and d[0] == "digest" and "GO" in d[1])
check("reappeared gate (absent last tick) -> gate ping",
      (dc.notify_decision(["PRO-9"], COUNTS, SIG,
                          {"seen_gate_ids": [], "last_contact_date": "2026-06-22"}, "2026-06-22") or [None])[0] == "gate")
check("no gates, contacted today -> silent",
      dc.notify_decision([], COUNTS, SIG,
                         {"seen_gate_ids": [], "last_contact_date": "2026-06-22"}, "2026-06-22") is None)

# --- notify() integration: state file + delivery shim ---
dc.streak_signals = lambda: SIG                       # bypass the drive-pulse subprocess
cap = tempfile.NamedTemporaryFile("w", suffix=".cap", delete=False).name
st = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False).name
os.unlink(st)                                          # start with no state
os.environ["PSDRIVE_NOTIFY_CMD"] = f"cat >> {cap}"


def rec(gate_ids, auto=1, gate=0, blocked=0):
    return {"gate_ids": gate_ids, "auto": auto, "gate": gate, "blocked": blocked, "executed": []}


dc.notify([rec(["PRO-9"], gate=1)], "2026-06-22", state_path=st)
b1 = open(cap).read()
check("tick1 new gate delivered", "PRO-9" in b1)
dc.notify([rec(["PRO-9"], gate=1)], "2026-06-22", state_path=st)
check("tick2 unchanged, same day -> silent (no new delivery)", open(cap).read() == b1)
dc.notify([rec(["PRO-9"], gate=1)], "2026-06-23", state_path=st)
b3 = open(cap).read()
check("tick3 new day -> digest delivered", len(b3) > len(b1) and "drive daily" in b3)
state = json.load(open(st))
check("state tracks last_contact_date", state.get("last_contact_date") == "2026-06-23")
check("state tracks seen gate ids", state.get("seen_gate_ids") == ["PRO-9"])

# --- deliver with no command configured -> no crash ---
os.environ.pop("PSDRIVE_NOTIFY_CMD", None)
try:
    dc.deliver("hello")
    check("deliver unset -> no crash (logs to stdout)", True)
except Exception:
    check("deliver unset -> no crash (logs to stdout)", False)

for p in (cap, st):
    try:
        os.unlink(p)
    except OSError:
        pass

print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
