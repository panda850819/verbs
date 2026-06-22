#!/usr/bin/env bash
# tests/drive-capability-fence.sh — PRO-62 (C6): widening what the daemon may touch
# unattended is a structural human-gate. Every capability-fence path — the driver and its
# libs (where SAFE_SKILLS lives), the cron, the worker, the blast policy ITSELF, and the
# launchd scheduler — must classify HIGH-BLAST against the REAL committed policy, so any
# auto-build that edits the fence is routed to a human PR and can never auto-merge. This
# test fails if a future edit drops a fence entry from config/high-blast-paths. PSDRIVE_TEST=1.
set -uo pipefail
export PSDRIVE_TEST=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
fail=0

# Use the REAL committed policy (do NOT set PSDRIVE_BLAST_POLICY) so this locks the shipped fence.
out="$(cd "$repo_root" && PSDRIVE_TEST=1 python3 - "$D" <<'PY'
import sys, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
pats = m.load_blast_policy()                       # reads config/high-blast-paths
assert pats, "high-blast policy is empty/unreadable — fence is not enforced"
fence = [
    "scripts/pandastack-drive",        # the driver + SAFE_SKILLS allowlist
    "scripts/drive-cron.py",           # the scheduler wrapper + autonomy config plumbing
    "scripts/agent-worker",            # the execution backend
    "scripts/pslib.py",                # shared lifecycle / readiness
    "config/high-blast-paths",         # the blast policy itself (self-protecting)
    "launchd/com.pandastack.drive.plist",  # the launchd scheduler
]
bad = [p for p in fence if m.classify_blast([p], pats)[0] != "high"]
# SAFE_SKILLS is a set literal inside the driver, so editing it == editing a high-blast file.
assert "SAFE_SKILLS" in open(sys.argv[1]).read(), "SAFE_SKILLS not found in the driver"
if bad:
    print("FENCE-HOLE " + ",".join(bad)); sys.exit(1)
print("FENCE-OK")
PY
)" || true
echo "$out" | grep -q "FENCE-OK" \
  && echo "PASS: every capability-fence path classifies high-blast (human-gated)" \
  || { echo "FAIL: capability fence has a hole — $out"; fail=1; }

[ "$fail" -eq 0 ] && echo "OK: drive-capability-fence all green" || echo "FAILURES present"
exit "$fail"
