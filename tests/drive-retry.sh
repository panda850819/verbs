#!/usr/bin/env bash
# tests/drive-retry.sh — bounded retry + exponential backoff for pandastack-drive.
# Pure function tests over a temp retry store; no network, no Linear, no Codex.
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
tmp="$(mktemp -d)"
state="$tmp/retry.json"
fail=0

check() { # check <desc> <python-expr-bool> <json>
  if python3 -c "import json,sys; r=json.load(sys.stdin); sys.exit(0 if ($2) else 1)" <<<"$3"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"; fail=1
  fi
}

step() { # step <now_ms> <op>
  PSDRIVE_TEST=1 \
  PSDRIVE_RETRY_STATE="$state" \
  PSDRIVE_RETRY_BASE_MS=10000 \
  PSDRIVE_RETRY_CAP_MS=60000 \
  PSDRIVE_RETRY_MAX_ATTEMPTS=3 \
  PSDRIVE_NOW_MS="$1" \
  python3 - "$D" "$2" <<'PY'
import importlib.util, json, sys
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
spec = importlib.util.spec_from_loader("psdrive", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
x = {"id":"PRO-14", "project":"pandastack", "next":"BUILD", "skill":"sprint"}
x_changed = {**x, "source_rev":"changed"}
op = sys.argv[2]
if op == "gate":
    print(json.dumps({"gate": m.retry_gate(x)}))
elif op == "gate_changed":
    print(json.dumps({"gate": m.retry_gate(x_changed)}))
elif op == "fail":
    print(json.dumps({"note": m.record_retry(x, {"ok": False, "verdict": "FAIL", "summary": "flaky"})}))
elif op == "error":
    print(json.dumps({"note": m.record_retry(x, {"ok": False, "verdict": "ERROR", "summary": "timeout"})}))
elif op == "blocked":
    print(json.dumps({"note": m.record_retry(x, {"ok": False, "verdict": "BLOCKED", "summary": "needs human"})}))
elif op == "pass":
    print(json.dumps({"note": m.record_retry(x, {"ok": True, "verdict": "PASS", "summary": "ok"})}))
elif op == "state":
    print(json.dumps(m.load_retry_state()))
else:
    raise SystemExit("bad op")
PY
}

initial="$(step 0 gate)"
check "no retry record initially" "r['gate'] is None" "$initial"

first="$(step 0 fail)"
check "first FAIL schedules retry #2 after 10s" "'attempt 2/3' in r['note'] and '10000ms' in r['note']" "$first"
wait="$(step 9999 gate)"
check "before next_allowed -> backoff gate" "r['gate'] and 'backoff' in r['gate']" "$wait"
ready="$(step 10000 gate)"
check "at next_allowed -> runnable again" "r['gate'] is None" "$ready"

second="$(step 10000 fail)"
check "second FAIL schedules retry #3 after 20s" "'attempt 3/3' in r['note'] and '20000ms' in r['note']" "$second"
state2="$(step 10000 state)"
check "retry state stores two attempts" "list(r.values())[0]['attempts'] == 2" "$state2"
not_ready="$(step 29999 gate)"
check "second backoff waits until 30s" "r['gate'] and 'backoff' in r['gate']" "$not_ready"

third="$(step 30000 error)"
check "third failure exhausts retries" "'exhausted after 3 attempts' in r['note']" "$third"
exhausted="$(step 30000 gate)"
check "exhausted item stops retrying" "r['gate'] and 'exhausted after 3 attempts' in r['gate']" "$exhausted"

blocked="$(step 30000 blocked)"
check "BLOCKED records manual-review gate" "'BLOCKED' in r['note'] and 'no retry' in r['note']" "$blocked"
blocked_gate="$(step 30000 gate)"
check "BLOCKED gate stops future ticks" "r['gate'] and 'BLOCKED' in r['gate']" "$blocked_gate"
changed_gate="$(step 30000 gate_changed)"
check "source change ignores stale retry gate" "r['gate'] is None" "$changed_gate"
changed_state="$(step 30000 state)"
check "stale retry record is not pruned by read-only gate" "r != {}" "$changed_state"

step 30000 fail >/dev/null
clear="$(step 30000 pass)"
check "PASS clears retry state" "'cleared' in r['note']" "$clear"
empty="$(step 30000 state)"
check "retry store empty after PASS" "r == {}" "$empty"

badenv="$({ PSDRIVE_TEST=1 PSDRIVE_RETRY_BASE_MS=bad PSDRIVE_RETRY_CAP_MS=0 PSDRIVE_RETRY_MAX_ATTEMPTS=-2 python3 - "$D" <<'PY'
import importlib.util, json, sys
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive_badenv", sys.argv[1])
spec = importlib.util.spec_from_loader("psdrive_badenv", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
print(json.dumps({"base": m.RETRY_BASE_MS, "cap": m.RETRY_CAP_MS, "max": m.RETRY_MAX_ATTEMPTS}))
PY
} )"
check "invalid retry env falls back to safe defaults" "r == {'base': 10000, 'cap': 300000, 'max': 3}" "$badenv"

testmode="$({ PSDRIVE_TEST=0 PANDASTACK_STATE_HOME="$tmp/state-home" PSDRIVE_RETRY_STATE="$tmp/unsafe.json" python3 - "$D" <<'PY'
import importlib.util, json, sys
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive_testmode", sys.argv[1])
spec = importlib.util.spec_from_loader("psdrive_testmode", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
print(json.dumps({"test_mode": m.TEST_MODE, "path": m.retry_state_path()}))
PY
} )"
check "PSDRIVE_TEST requires exact 1" "r['test_mode'] is False and not r['path'].endswith('unsafe.json')" "$testmode"

loop_out="$({
  PSDRIVE_TEST=1 \
  PSDRIVE_RETRY_STATE="$tmp/loop-retry.json" \
  PSDRIVE_RETRY_BASE_MS=10000 \
  PSDRIVE_RETRY_CAP_MS=60000 \
  PSDRIVE_RETRY_MAX_ATTEMPTS=3 \
  PSDRIVE_NOW_MS=0 \
  python3 - "$D" "$tmp" <<'PY'
import contextlib, importlib.util, io, json, os, subprocess, sys
from importlib.machinery import SourceFileLoader
driver, tmp = sys.argv[1], sys.argv[2]
repo = os.path.join(tmp, "repo")
fixture = os.path.join(tmp, "issues.json")
os.mkdir(repo)
subprocess.run(["git", "-C", repo, "init", "-q"], check=True)
subprocess.run(["git", "-C", repo, "config", "user.email", "t@t.t"], check=True)
subprocess.run(["git", "-C", repo, "config", "user.name", "t"], check=True)
open(os.path.join(repo, "seed.txt"), "w").write("seed\n")
subprocess.run(["git", "-C", repo, "add", "-A"], check=True)
subprocess.run(["git", "-C", repo, "commit", "-qm", "seed"], check=True)
open(fixture, "w").write(json.dumps({"issues":[{"identifier":"INT-1","title":"build","project":"tmp","state":"Building","priority":1,"description":"Goal: x\nContext: y\n```acceptance\nrun x\n```","created_at":"2026-06-17T00:00:00Z"}]}))
os.environ["PSDRIVE_FIXTURE"] = fixture
os.environ["PSDRIVE_BUILD_STUB"] = "FAIL"
loader = SourceFileLoader("psdrive_loop", driver)
spec = importlib.util.spec_from_loader("psdrive_loop", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
m.PROJECT_REPO["tmp"] = repo
def run_once(now):
    os.environ["PSDRIVE_NOW_MS"] = str(now)
    sys.argv = [driver, "--execute", "--max", "1", "--only", "tmp", "--build-auto"]
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = m.main()
    return {"rc": rc, "out": buf.getvalue()}
first = run_once(0)
os.environ["PSDRIVE_BUILD_STUB"] = "PASS"
os.environ["PSDRIVE_NOW_MS"] = "9999"
queued = m.build_queue(build_auto=True, only="tmp")
second = run_once(9999)
print(json.dumps({"first": first, "queued": queued, "second": second}))
PY
} )"
check "execute loop records retry after failed build" "'retry scheduled' in r['first']['out']" "$loop_out"
check "retry-gated item leaves AUTO queue" "not any(x['id']=='INT-1' for x in r['queued']['AUTO']) and any(x['id']=='INT-1' and 'retry-gate' in x.get('reason','') for x in r['queued']['GATE'])" "$loop_out"
check "execute loop honors backoff before invoking build again" "'retry-gate' in r['second']['out'] and 'retry state cleared' not in r['second']['out']" "$loop_out"

wt_fail="$({ PSDRIVE_TEST=1 PSDRIVE_RETRY_STATE="$tmp/wt-fail.json" python3 - "$D" "$tmp" <<'PY'
import importlib.util, json, os, sys
from importlib.machinery import SourceFileLoader
driver, tmp = sys.argv[1], sys.argv[2]
not_git = os.path.join(tmp, "not-git")
os.mkdir(not_git)
loader = SourceFileLoader("psdrive_wtfail", driver)
spec = importlib.util.spec_from_loader("psdrive_wtfail", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
x = {"id":"WT-1", "project":"tmp", "repo": not_git, "title":"bad repo", "to_state":"Verifying", "next":"BUILD", "build": True}
r = m.exec_build(x)
note = m.record_retry(x, r)
print(json.dumps({"result": r, "note": note, "state": m.load_retry_state()}))
PY
} )"
check "worktree add failure is retryable ERROR" "r['result']['ran'] and r['result']['verdict']=='ERROR' and 'retry scheduled' in r['note']" "$wt_fail"

# editing the issue (source_rev rotates) must restart the attempt counter, not just
# unblock the gate — otherwise the first post-edit failure inherits the old count.
reset_fail() { # reset_fail <source_rev>
  PSDRIVE_TEST=1 PSDRIVE_RETRY_STATE="$tmp/reset.json" \
  PSDRIVE_RETRY_BASE_MS=10000 PSDRIVE_RETRY_CAP_MS=60000 PSDRIVE_RETRY_MAX_ATTEMPTS=3 \
  PSDRIVE_NOW_MS=0 python3 - "$D" "$1" <<'PY'
import importlib.util, json, sys
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive_reset", sys.argv[1])
spec = importlib.util.spec_from_loader("psdrive_reset", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
x = {"id":"PRO-99", "project":"p", "next":"BUILD", "source_rev": sys.argv[2]}
print(json.dumps({"note": m.record_retry(x, {"ok": False, "verdict": "FAIL", "summary": "f"})}))
PY
}
reset_fail A >/dev/null   # attempt 1, rev A
reset_fail A >/dev/null   # attempt 2, rev A
ex="$(reset_fail A)"      # attempt 3, rev A -> exhausted
check "rev A exhausts after 3 attempts" "'exhausted after 3 attempts' in r['note']" "$ex"
edited="$(reset_fail B)"  # first failure after edit (rev B) -> fresh counter
check "source_rev change restarts attempt counter" "'attempt 2/3' in r['note'] and 'exhausted' not in r['note']" "$edited"

[ "$fail" -eq 0 ] && echo "OK: drive-retry all green" || echo "FAILURES present"
exit "$fail"
