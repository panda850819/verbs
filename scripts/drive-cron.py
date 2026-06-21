#!/usr/bin/env python3
"""drive-cron.py — the audit-logged wrapper that launchd runs.

Runs pandastack-drive --execute, then writes TWO trails so every autonomous run is
auditable later:

  1. structured  → ~/site/knowledge/brain/_automation/portfolio-status/drive-log.jsonl
     one JSON line per run {ts, auto, gate, blocked, gate_ids, executed[]}, where each
     executed[] item carries verify_ran / verify_ok / verify_cmd / verify_required so
     fake-green is git-greppable (LG, F-K/F-L). Lives in the brain so the auto-commit
     turns it into git history = a tamper-evident, reset-proof audit trail (the
     "看得見變動" pattern applied to the driver).
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

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pslib  # kill-switch predicate (single source, shared with pandastack-drive)

DRIVE = os.environ.get(
    "PSDRIVE_DRIVE_BIN",
    os.path.expanduser("~/site/skills/pandastack/scripts/pandastack-drive"))
AUDIT = os.environ.get(
    "PSDRIVE_AUDIT",
    os.path.expanduser("~/site/knowledge/brain/_automation/portfolio-status/drive-log.jsonl"))
DETAIL_DIR = os.path.expanduser("~/Library/Logs/pandastack-drive")
MAX = os.environ.get("PSDRIVE_MAX", "1")
CONFIG = os.environ.get(
    "PSDRIVE_AUTONOMY_CONFIG",
    os.path.expanduser("~/.config/pandastack/drive-autonomy.json"))


def parse(out):
    """Pull a structured summary out of the driver's output.

    Primary path (LG, F-K/F-L): the driver emits one machine-readable
    `@@PSDRIVE_LEDGER@@ {json}` line carrying the per-item ledger with
    verify_ran / verify_ok / verify_cmd. Append it verbatim — no lossy regex, so
    'zero fake-green' (verdict==PASS AND advance AND verify_required AND NOT
    verify_ran) stays git-greppable in drive-log.jsonl. Fallback: an old driver
    or a non-execute run has no sentinel, so regex the human stdout for back-compat.
    """
    for ln in out.splitlines():
        if ln.startswith(pslib.LEDGER_SENTINEL):
            try:
                blob = json.loads(ln[len(pslib.LEDGER_SENTINEL):].strip())
            except (ValueError, TypeError):
                break   # malformed sentinel → fall through to the regex fallback
            return {"auto": blob.get("auto", 0), "gate": blob.get("gate", 0),
                    "blocked": blob.get("blocked", 0),
                    "gate_ids": blob.get("gate_ids", []),
                    "executed": blob.get("executed", [])}
    # --- fallback: legacy regex over the human stdout (no structured ledger) ---
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


def load_autonomy_config(path=None):
    """Read the per-project autonomy config. Missing file or malformed JSON →
    empty dict, so the tick falls back to today's global read-only sweep. Never
    raises: a broken config must not wedge the scheduler."""
    path = path or CONFIG
    try:
        with open(path, encoding="utf-8") as f:
            cfg = json.load(f)
        return cfg if isinstance(cfg, dict) else {}
    except FileNotFoundError:
        return {}
    except (ValueError, OSError) as e:
        print(f"drive-cron: ignoring unreadable autonomy config {path}: {e}",
              file=sys.stderr)
        return {}


def build_invocations(cfg, max_):
    """Pure: map the autonomy config to the pandastack-drive arg lists to run this
    tick. No build_auto project (incl. empty config) → exactly today's single
    global read-only sweep, labelled None so its audit/detail lines stay byte-for-
    byte unchanged. Each build_auto project gets its own `--build-auto --only` run
    (+ `--merge-auto` when set). merge_auto without build_auto is a config error:
    warn and build without auto-merge (the driver enforces the same prerequisite).
    Returns a list of (label, args); label None = the legacy global run."""
    autonomy = []
    for proj, opts in (cfg or {}).items():
        if not isinstance(opts, dict):
            continue
        build = bool(opts.get("build_auto"))
        merge = bool(opts.get("merge_auto"))
        if merge and not build:
            print(f"drive-cron: {proj}: merge_auto without build_auto is a config "
                  f"error; building without auto-merge this tick", file=sys.stderr)
            build, merge = True, False
        if not build:
            continue
        args = ["--execute", "--build-auto", "--only", proj]
        if merge:
            args.append("--merge-auto")
        args += ["--max", str(max_)]
        autonomy.append((proj, args))
    if not autonomy:
        return [(None, ["--execute", "--max", str(max_)])]
    return autonomy


def run_one(args, ts, label=None):
    """Run one pandastack-drive invocation and write its detail + audit trails.
    With label=None the trails are identical to the pre-config single-run path."""
    tag = f" [{label}]" if label else ""
    try:
        out = subprocess.run([sys.executable, DRIVE, *args],
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
        f.write(f"\n===== {ts}{tag} =====\n{text}\n")

    rec = {"ts": ts, **rec, "detail": detail}
    if label is not None:
        rec["invocation"] = label
    with open(AUDIT, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")

    adv = [e for e in rec["executed"] if e.get("advance")]
    print(f"{ts}{tag}  auto={rec['auto']} gate={rec['gate']} blocked={rec['blocked']} "
          f"ran={len(rec['executed'])} proposals={len(adv)}"
          + (f" ERROR={rec['error']}" if rec.get("error") else ""))


def main():
    ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    os.makedirs(os.path.dirname(AUDIT), exist_ok=True)
    # Kill-switch: halt before invoking the driver. Record the suppression to the
    # audit trail and exit clean — zero dispatch this tick (PRO-36, boundary #12).
    if pslib.drive_suppressed():
        rec = {"ts": ts, "suppressed": True, "auto": 0, "gate": 0, "blocked": 0,
               "gate_ids": [], "executed": [], "error": None}
        with open(AUDIT, "a", encoding="utf-8") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
        print(f"{ts}  suppressed — kill-switch at {pslib.stop_flag_path()} (zero dispatch)")
        return 0
    os.makedirs(DETAIL_DIR, exist_ok=True)
    # Per-project autonomy: empty/missing config → one global read-only sweep
    # (label None = today's behavior, byte-for-byte). A build_auto project gets
    # its own --build-auto --only run (+ --merge-auto when set).
    for label, args in build_invocations(load_autonomy_config(), MAX):
        run_one(args, ts, label)
    return 0


if __name__ == "__main__":
    sys.exit(main())
