#!/usr/bin/env bash
# tests/drive-verify.sh - BUILD host-verify wiring tests for pandastack-drive.
# Pure harness over a throwaway repo; no network, no Linear, no Codex.
set -uo pipefail
export PSDRIVE_TEST=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
export PSDRIVE_WORKER_JOB_ROOT="$(mktemp -d)"
fail=0

check() { # check <desc> <python-expr-bool> <json>
  if python3 -c "import json,os,sys; r=json.load(sys.stdin); sys.exit(0 if ($2) else 1)" <<<"$3"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"; fail=1
  fi
}

tmprepo="$(mktemp -d)"
git -C "$tmprepo" init -q
git -C "$tmprepo" config user.email t@t.t
git -C "$tmprepo" config user.name t
echo seed > "$tmprepo/seed.txt"
git -C "$tmprepo" add -A
git -C "$tmprepo" commit -qm seed

wt_build_verify() { # wt_build_verify <id> <expected-text>
  PSDRIVE_TEST=1 PSDRIVE_BUILD_STUB=PASS python3 - "$D" "$tmprepo" "$1" "$2" <<'PY'
import importlib.util
import json
import shlex
import sys
from importlib.machinery import SourceFileLoader

loader = SourceFileLoader("psdrive", sys.argv[1])
spec = importlib.util.spec_from_loader("psdrive", loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)

issue = sys.argv[3]
expected = shlex.quote(sys.argv[4])
desc = """Goal: prove host verify gates BUILD output
Context: the test backend self-reports PASS after writing .psdrive-stub
```acceptance
test -f .psdrive-stub
grep -q {expected} .psdrive-stub
```
""".format(expected=expected)
x = {
    "id": issue,
    "project": "t",
    "repo": sys.argv[2],
    "title": "verify wiring",
    "to_state": "Verifying",
    "build": True,
    "desc": desc,
}
print(json.dumps(m.exec_build(x)))
PY
}

bad_out="$(wt_build_verify VRF-BAD expected-content)"
check "bad build uses offline test backend" "r['worker']['worker']['backend']=='test'" "$bad_out"
check "bad build ran host verify" "r['verification']['ran'] is True and r['worker']['worker']['request']['allow_host_verify'] is True" "$bad_out"
check "bad build captures verify failure" "r['verification']['ok'] is False and r['verification']['returncode'] != 0 and 'stdout_tail' in r['verification'] and 'stderr_tail' in r['verification']" "$bad_out"
check "bad build demotes model PASS" "(not r['ok']) and r['verdict']!='PASS' and r.get('summary')=='verification failed'" "$bad_out"
check "bad build emits no advance proposal" "'advance' not in r" "$bad_out"
if git -C "$tmprepo" rev-parse --verify -q psdrive/VRF-BAD >/dev/null; then
  echo "FAIL: failing verify branch should be discarded"; fail=1
else
  echo "PASS: failing verify branch discarded"
fi

good_out="$(wt_build_verify VRF-GOOD 'stub build artifact')"
check "good build uses offline test backend" "r['worker']['worker']['backend']=='test'" "$good_out"
check "good build ran host verify green" "r['verification']['ran'] is True and r['verification']['ok'] is True and r['verification']['returncode']==0" "$good_out"
check "good build writes verify.sh artifact" "os.path.exists(os.path.join(r['artifacts']['job_dir'], 'verify.sh'))" "$good_out"
check "good build passes and keeps branch" "r['ok'] and r['verdict']=='PASS' and r.get('branch')=='psdrive/VRF-GOOD'" "$good_out"
check "good build emits advance proposal" "'pandastack-linear-advance --issue VRF-GOOD' in r.get('advance','')" "$good_out"
git -C "$tmprepo" rev-parse --verify -q psdrive/VRF-GOOD >/dev/null \
  && echo "PASS: passing verify branch kept" || { echo "FAIL: passing verify branch missing"; fail=1; }

# F-A mutation sentinel (PRO-41): a tautological acceptance passes on the pre-build
# tree, so a post-build PASS proves nothing -> BLOCKED, never trusted as green.
taut_out="$(PSDRIVE_TEST=1 PSDRIVE_BUILD_STUB=PASS python3 - "$D" "$tmprepo" <<'PY'
import importlib.util, json, sys
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
spec = importlib.util.spec_from_loader("psdrive", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
desc = "Goal: x\nContext: y\n\x60\x60\x60acceptance\ntrue\n\x60\x60\x60\n"
x = {"id":"VRF-TAUT","project":"t","repo":sys.argv[2],"title":"taut","to_state":"Verifying","build":True,"desc":desc}
print(json.dumps(m.exec_build(x)))
PY
)"
check "tautological acceptance (pre-build green) -> BLOCKED" "r['verdict']=='BLOCKED' and (not r['ok'])" "$taut_out"
check "tautological acceptance emits no advance" "'advance' not in r" "$taut_out"
if git -C "$tmprepo" rev-parse --verify -q psdrive/VRF-TAUT >/dev/null; then
  echo "FAIL: tautological build should keep no branch"; fail=1
else
  echo "PASS: tautological build kept no branch"
fi

[ "$(git -C "$tmprepo" worktree list | wc -l | tr -d ' ')" = "1" ] \
  && echo "PASS: no stray worktrees" || { echo "FAIL: stray worktree left"; fail=1; }

[ "$fail" -eq 0 ] && echo "OK: drive-verify all green" || echo "FAILURES present"
exit "$fail"
