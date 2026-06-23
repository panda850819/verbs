#!/usr/bin/env bash
# tests/drive-acceptance-cwd-contract.sh — pslib enforces the cwd-relative acceptance
# contract (PRO-71). An acceptance anchored on $BASH_SOURCE/$0 is classed NOT runnable
# (needs-spec) because drive runs `bash <job_dir>/verify.sh` with cwd=worktree, so such
# a path resolves outside the worktree and FAILs a correct build. A cwd-relative one
# (e.g. PRO-68's `python3 scripts/drive-pulse`) stays machine-runnable.
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root/scripts" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pslib
ok = True
def chk(cond, label):
    global ok
    print(("PASS: " if cond else "FAIL: ") + label)
    ok = ok and bool(cond)

# anchored on $BASH_SOURCE — runnable-looking (has `grep`) but cwd-UNSAFE
BAD = '```acceptance\nROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"\n"$ROOT/bin/x" --baseline a && grep -q ok out\n```'
# anchored on dirname "$0" — has `test`, cwd-UNSAFE
BAD2 = '```acceptance\ncd "$(dirname "$0")"; ./bin/x test\n```'
# cwd-relative — runnable + safe
GOOD = '```acceptance\nbin/x --baseline tests/fixtures/clean && grep -q ok out\n```'
# PRO-68 style (the one autonomous build that worked) — interpreter-invoked, cwd-relative
GOOD68 = '```acceptance\npython3 scripts/drive-pulse --version 2>&1 | grep -qiE "drive-pulse [0-9]"\n```'

chk(not pslib.acceptance_runnable(BAD), "BASH_SOURCE-anchored acceptance -> not runnable")
chk(not pslib.acceptance_runnable(BAD2), 'dirname "$0"-anchored acceptance -> not runnable')
chk(pslib.acceptance_runnable(GOOD), "cwd-relative acceptance -> runnable")
chk(pslib.acceptance_runnable(GOOD68), "PRO-68-style cwd-relative acceptance -> runnable")
chk(pslib.acceptance_cwd_safe("bin/x tests/fixtures/clean"), "plain cwd-relative -> cwd_safe")
chk(not pslib.acceptance_cwd_safe('dirname "$0"'), 'dirname "$0" -> not cwd_safe')

# readiness_gap on a Building issue: specific, actionable reason for the anchored case ...
gap = pslib.readiness_gap("Building", "## Goal x\n## Context y\n" + BAD)
chk(gap is not None and "BASH_SOURCE" in gap, "readiness_gap flags the anchor with a specific reason")
# ... and no gap for the cwd-relative case
chk(pslib.readiness_gap("Building", "## Goal x\n## Context y\n" + GOOD) is None,
    "cwd-relative Building issue passes readiness")

sys.exit(0 if ok else 1)
PY
rc=$?
[ "$rc" -eq 0 ] && echo "OK: drive-acceptance-cwd-contract all green" || echo "FAILURES present"
exit "$rc"
