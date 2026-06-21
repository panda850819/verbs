#!/usr/bin/env bash
# tests/drive-evidence.sh — T04: the auto-build commit carries the host-verify evidence
# inline, so a human's pre-graduation 30-second stamp sees what was actually checked.
set -uo pipefail
export PSDRIVE_TEST=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
export PSDRIVE_WORKER_JOB_ROOT="$(mktemp -d)"
fail=0

tmprepo="$(mktemp -d)"
git -C "$tmprepo" init -q; git -C "$tmprepo" config user.email t@t.t; git -C "$tmprepo" config user.name t
echo seed > "$tmprepo/seed.txt"; git -C "$tmprepo" add -A; git -C "$tmprepo" commit -qm seed >/dev/null

PSDRIVE_TEST=1 PSDRIVE_BUILD_STUB=PASS python3 - "$D" "$tmprepo" <<'PY'
import sys, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
desc = "Goal: ship X\nContext: y\n```acceptance\ntest -f .psdrive-stub\n```\n"
x = {"id": "EV-1", "project": "t", "repo": sys.argv[2], "title": "evidence me",
     "next": "BUILD", "to_state": "Verifying", "build": True, "desc": desc}
m.exec_build(x)   # merge_auto off → keeps branch psdrive/EV-1 with the build commit
PY

body="$(git -C "$tmprepo" log psdrive/EV-1 -1 --format=%B 2>/dev/null)"
grep -q "auto-build evidence" <<<"$body" && echo "PASS: evidence block present in commit body" || { echo "FAIL: no evidence block"; fail=1; }
grep -q "host-verify: PASS" <<<"$body" && echo "PASS: host-verify result inline" || { echo "FAIL: no host-verify line"; fail=1; }
grep -q "test -f .psdrive-stub" <<<"$body" && echo "PASS: acceptance shown inline" || { echo "FAIL: acceptance not inline"; fail=1; }
grep -q "changed files:" <<<"$body" && echo "PASS: changed-file count inline" || { echo "FAIL: no changed-file count"; fail=1; }
# subject stays a clean conventional-commit line (evidence is in the body, not the subject)
subj="$(git -C "$tmprepo" log psdrive/EV-1 -1 --format=%s)"
[ "$subj" = "feat(EV-1): evidence me" ] && echo "PASS: subject unchanged (evidence in body only)" || { echo "FAIL: subject polluted: $subj"; fail=1; }

[ "$fail" -eq 0 ] && echo "OK: drive-evidence all green" || echo "FAILURES present"
exit "$fail"
