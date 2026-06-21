#!/usr/bin/env bash
# tests/drive-secrets.sh — C5: staged secrets are blocked at the auto-build commit (fail
# closed), since the driver commits with hooks off and --merge-auto would self-land them.
set -uo pipefail
export PSDRIVE_TEST=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
export PSDRIVE_WORKER_JOB_ROOT="$(mktemp -d)"
fail=0; ok(){ echo "PASS: $1"; }; bad(){ echo "FAIL: $1"; fail=1; }

# ---------- 1. unit: staged_secrets — path + content hits, clean code passes ----------
python3 - "$D" <<'PY'
import sys, os, tempfile, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
wt = tempfile.mkdtemp()
os.makedirs(os.path.join(wt, "app"))
open(os.path.join(wt, "app/.env"), "w").write("API=1")
open(os.path.join(wt, "deploy.key"), "w").write("k")
open(os.path.join(wt, "id_rsa"), "w").write("k")
open(os.path.join(wt, "creds.json"), "w").write("{}")        # 'cred' in name
open(os.path.join(wt, "leak.txt"), "w").write("-----BEGIN OPENSSH PRIVATE KEY-----\nabc\n")
open(os.path.join(wt, "main.py"), "w").write("print('hello world')\n")
porc = "\n".join("?? " + p for p in ("app/.env", "deploy.key", "id_rsa", "creds.json", "leak.txt", "main.py"))
hits = " ".join(m.staged_secrets(wt, porc))
for want in ("path:app/.env", "path:deploy.key", "path:id_rsa", "path:creds.json", "content:leak.txt"):
    assert want in hits, (want, hits)
assert "main.py" not in hits, ("clean code flagged", hits)
print("PASS: staged_secrets catches .env/key/id_rsa/cred path + private-key content; clean code passes")
PY
[ $? -eq 0 ] || bad "staged_secrets unit"

# ---------- 2. e2e: a build that stages app/.env -> BLOCKED, no commit, branch discarded ----------
tmprepo="$(mktemp -d)"
git -C "$tmprepo" init -q; git -C "$tmprepo" config user.email t@t.t; git -C "$tmprepo" config user.name t
echo seed > "$tmprepo/seed.txt"; git -C "$tmprepo" add -A; git -C "$tmprepo" commit -qm seed >/dev/null
o="$(PSDRIVE_TEST=1 PSDRIVE_BUILD_STUB=PASS PSDRIVE_BUILD_STUB_FILE=app/.env python3 - "$D" "$tmprepo" <<'PY'
import sys, json, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
x = {"id": "SEC-1", "project": "t", "repo": sys.argv[2], "title": "leaky", "next": "BUILD",
     "to_state": "Verifying", "build": True, "desc": "Goal: x\nContext: y\n"}
print(json.dumps(m.exec_build(x)))
PY
)"
echo "$o" | python3 -c "import json,sys;r=json.load(sys.stdin);assert r['verdict']=='BLOCKED' and 'secret' in r['summary'],r" \
  && ok "e2e: staged .env -> BLOCKED (fail closed)" || bad "secret not blocked: $o"
git -C "$tmprepo" rev-parse --verify -q psdrive/SEC-1 >/dev/null 2>&1 && bad "secret build branch kept" || ok "secret build branch discarded (nothing committed)"

# ---------- 3. e2e: a clean build still commits (no false positive) ----------
o2="$(PSDRIVE_TEST=1 PSDRIVE_BUILD_STUB=PASS PSDRIVE_BUILD_STUB_FILE=src/util.py python3 - "$D" "$tmprepo" <<'PY'
import sys, json, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
x = {"id": "SEC-2", "project": "t", "repo": sys.argv[2], "title": "clean", "next": "BUILD",
     "to_state": "Verifying", "build": True, "desc": "Goal: x\nContext: y\n"}
print(json.dumps(m.exec_build(x)))
PY
)"
echo "$o2" | python3 -c "import json,sys;r=json.load(sys.stdin);assert r['verdict']=='PASS' and r['ok'],r" \
  && ok "clean build still commits (no false positive)" || bad "clean build blocked: $o2"

[ "$fail" -eq 0 ] && echo "OK: drive-secrets all green" || echo "FAILURES present"
exit "$fail"
