#!/usr/bin/env python3
"""drive-cron.py — the audit-logged wrapper that launchd runs.

Runs pandastack-drive --execute, then writes TWO trails so every autonomous run is
auditable later:

  1. structured  → ~/site/knowledge/brain/_automation/portfolio-status/drive-log.jsonl
     one JSON line per run {ts, auto, gate, blocked, gate_ids, executed[]}. Lives in
     the brain so the auto-commit turns it into git history = a tamper-evident,
     reset-proof audit trail (the "看得見變動" pattern applied to the driver).
  2. detail      → ~/Library/Logs/pandastack-drive/<date>.log
     full human-readable stdout (queue + each verdict + each proposed advance).

No flock: launchd never runs a second instance of the same job while one is live,
so overlap is already impossible (flock is a cron concern, not launchd).
The driver itself writes nothing (Linear stays the single source; advances are
proposed, run by hand), so this wrapper only records — it changes no state.
"""
import datetime
import json
import os
import re
import subprocess
import sys

DRIVE = os.path.expanduser("~/site/skills/pandastack/scripts/pandastack-drive")
AUDIT = os.path.expanduser(
    "~/site/knowledge/brain/_automation/portfolio-status/drive-log.jsonl")
DETAIL_DIR = os.path.expanduser("~/Library/Logs/pandastack-drive")
MAX = os.environ.get("PSDRIVE_MAX", "1")


def parse(out):
    """Pull a structured summary out of the driver's text output."""
    def count(label):
        m = re.search(rf"{re.escape(label)}.*?:\s*(\d+)", out)
        return int(m.group(1)) if m else 0
    gate_ids = re.findall(r"^\s+([A-Z]+-\d+)\s+\S+\s+.*?←", out, re.M)
    executed = []
    # blocks like:  "    PASS: ..."  optionally followed by an advance proposal
    for m in re.finditer(r"▶\s+([A-Z]+-\d+).*?\n\s+(PASS|FAIL|BLOCKED|ERROR|skipped)"
                         r"[:\s]\s*(.*?)(?:\n\s+→ ready to advance.*?:\s*(.*))?(?=\n|$)",
                         out, re.S):
        executed.append({"id": m.group(1), "verdict": m.group(2),
                         "summary": (m.group(3) or "").strip()[:200],
                         "advance": (m.group(4) or "").strip() or None})
    return {"auto": count("▶ AUTO"), "gate": count("⏸ GATE"),
            "blocked": count("⛔ BLOCKED"), "gate_ids": gate_ids, "executed": executed}


def main():
    ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    os.makedirs(DETAIL_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(AUDIT), exist_ok=True)
    try:
        out = subprocess.run([sys.executable, DRIVE, "--execute", "--max", MAX],
                             capture_output=True, text=True, timeout=3000)
        text = (out.stdout or "") + (("\n[stderr]\n" + out.stderr) if out.stderr else "")
        rec = parse(text)
        rec["error"] = None if out.returncode == 0 else (out.stderr or "")[:200]
    except Exception as e:
        text = f"drive-cron exception: {e}"
        rec = {"auto": 0, "gate": 0, "blocked": 0, "gate_ids": [], "executed": [],
               "error": str(e)[:200]}

    detail = os.path.join(DETAIL_DIR, datetime.date.today().isoformat() + ".log")
    with open(detail, "a", encoding="utf-8") as f:
        f.write(f"\n===== {ts} =====\n{text}\n")

    rec = {"ts": ts, **rec, "detail": detail}
    with open(AUDIT, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")

    adv = [e for e in rec["executed"] if e.get("advance")]
    print(f"{ts}  auto={rec['auto']} gate={rec['gate']} blocked={rec['blocked']} "
          f"ran={len(rec['executed'])} proposals={len(adv)}"
          + (f" ERROR={rec['error']}" if rec.get("error") else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
