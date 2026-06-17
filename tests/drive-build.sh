#!/usr/bin/env bash
# tests/drive-build.sh — BUILD-autonomy classification + worktree lifecycle tests for
# scripts/pandastack-drive. Pure logic over fixtures; no network, no Linear, no codex.
# Test seams require PSDRIVE_TEST=1 (else PSDRIVE_FIXTURE/STUB are ignored in prod).
set -uo pipefail
export PSDRIVE_TEST=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
fx="$(mktemp)"
fail=0

cat > "$fx" <<'JSON'
{"issues":[
  {"identifier":"MUR-1","title":"build ready","project":"murmur","state":"Building","priority":1,"description":"Goal: ship X\nContext: because Y\n```acceptance\nbun test x green\n```","created_at":"2026-06-10T00:00:00Z"},
  {"identifier":"MUR-2","title":"build no context","project":"murmur","state":"Building","priority":1,"description":"Goal: x\n```acceptance\nrun it\n```","created_at":"2026-06-11T00:00:00Z"},
  {"identifier":"OTH-1","title":"other project","project":"shawn-trade","state":"Building","priority":1,"description":"Goal: y\nContext: z\n```acceptance\nrun y\n```","created_at":"2026-06-12T00:00:00Z"}
]}
JSON

check() { # check <desc> <python-expr-bool> <json>
  if python3 -c "import json,sys; r=json.load(sys.stdin); sys.exit(0 if ($2) else 1)" <<<"$3"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"; fail=1
  fi
}

# --build-auto requires --only (never global)
if PSDRIVE_FIXTURE="$fx" "$D" --json --build-auto >/dev/null 2>&1; then
  echo "FAIL: --build-auto without --only must error"; fail=1
else
  echo "PASS: --build-auto without --only errors"
fi

# flag OFF (default): no behavior change — Building stays auto-verify, no build entries
off="$(PSDRIVE_FIXTURE="$fx" "$D" --json)"
check "flag OFF: no build entries"                "not any(x.get('build') for x in r['AUTO'])"                         "$off"

# flag ON, --only murmur
on="$(PSDRIVE_FIXTURE="$fx" "$D" --json --build-auto --only murmur)"
check "MUR-1 (full work-order) -> AUTO with build flag" "any(x['id']=='MUR-1' and x.get('build') for x in r['AUTO'])"   "$on"
check "MUR-1 advance target is Verifying"          "any(x['id']=='MUR-1' and x.get('to_state')=='Verifying' for x in r['AUTO'])" "$on"
check "MUR-2 (no Context) -> gated needs-spec"     "any(x['id']=='MUR-2' and 'needs-spec' in (x.get('reason') or '') for x in r['GATE'])" "$on"
check "OTH-1 (other project) not auto-built"       "not any(x['id']=='OTH-1' and x.get('build') for x in r['AUTO'])"   "$on"

# ---- isolated worktree lifecycle (PSDRIVE_BUILD_STUB, throwaway repo, no codex) ----
tmprepo="$(mktemp -d)"
git -C "$tmprepo" init -q
git -C "$tmprepo" config user.email t@t.t; git -C "$tmprepo" config user.name t
echo seed > "$tmprepo/seed.txt"; git -C "$tmprepo" add -A; git -C "$tmprepo" commit -qm seed

wt_build() { # wt_build <stub> <id>  -> prints exec_build() JSON  (PSDRIVE_TEST honored)
  PSDRIVE_TEST=1 PSDRIVE_BUILD_STUB="$1" python3 - "$D" "$tmprepo" "$2" <<'PY'
import sys, json, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
spec = importlib.util.spec_from_loader("psdrive", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
x = {"id": sys.argv[3], "project": "t", "repo": sys.argv[2], "title": "t", "to_state": "Verifying", "build": True}
print(json.dumps(m.exec_build(x)))
PY
}

pass_out="$(wt_build PASS TST-1)"
check "build PASS -> ok + verdict + branch"   "r['ok'] and r['verdict']=='PASS' and r.get('branch')=='psdrive/TST-1'" "$pass_out"
check "build PASS logs staged files"          "'psdrive-stub' in (r.get('staged') or '')" "$pass_out"
git -C "$tmprepo" rev-parse --verify -q psdrive/TST-1 >/dev/null \
  && echo "PASS: PASS branch kept (driver committed) for PR" || { echo "FAIL: PASS branch missing"; fail=1; }
git -C "$tmprepo" log --oneline -1 psdrive/TST-1 | grep -q "feat(TST-1)" \
  && echo "PASS: driver made the commit (hooks off)" || { echo "FAIL: no driver commit on branch"; fail=1; }

fail_out="$(wt_build FAIL TST-2)"
check "build FAIL -> not ok"                  "(not r['ok']) and r['verdict']=='FAIL'" "$fail_out"
if git -C "$tmprepo" rev-parse --verify -q psdrive/TST-2 >/dev/null; then
  echo "FAIL: FAIL branch should be discarded"; fail=1
else
  echo "PASS: FAIL branch discarded"
fi

# stale-branch: a kept PASS branch is NOT rebuilt next tick (finding C)
stale_out="$(wt_build PASS TST-1)"   # TST-1 branch already exists from the PASS above
echo "$stale_out" | python3 -c "import json,sys; r=json.load(sys.stdin); sys.exit(0 if (not r['ran'] and '已存在' in r.get('why','')) else 1)" \
  && echo "PASS: existing psdrive branch -> skipped, not rebuilt" || { echo "FAIL: stale branch not skipped"; fail=1; }

# isolation: no stray worktrees, no temp-dir leak, nothing pushed (no remote)
[ "$(git -C "$tmprepo" worktree list | wc -l | tr -d ' ')" = "1" ] \
  && echo "PASS: no stray worktrees (live tree isolated)" || { echo "FAIL: stray worktree left"; fail=1; }
[ -z "$(ls -d "${TMPDIR:-/tmp}"/psdrive-wt-TST-* 2>/dev/null)" ] \
  && echo "PASS: no leaked worktree temp dirs" || { echo "FAIL: leaked psdrive-wt temp dir"; fail=1; }
[ -z "$(git -C "$tmprepo" remote)" ] \
  && echo "PASS: no push path (driver never adds a remote)" || { echo "FAIL: unexpected remote"; fail=1; }

[ "$fail" -eq 0 ] && echo "OK: drive-build all green" || echo "FAILURES present"
exit "$fail"
