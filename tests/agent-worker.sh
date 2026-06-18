#!/usr/bin/env bash
# tests/agent-worker.sh — protocol adapter contract tests. No network, no Codex.
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$repo_root/scripts/agent-worker"
tmp="$(mktemp -d)"
fail=0

check_json() { # check_json <desc> <python-expr-bool> <json>
  if python3 -c "import json,os,sys; r=json.load(sys.stdin); sys.exit(0 if ($2) else 1)" <<<"$3"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"; fail=1
  fi
}

repo="$tmp/repo"
git -C "$tmp" init -q repo
git -C "$repo" config user.email t@t.t
git -C "$repo" config user.name t
echo seed > "$repo/seed.txt"
git -C "$repo" add -A
git -C "$repo" commit -qm seed

job="$tmp/job"
mkdir -p "$job/output" "$job/logs"
cat > "$job/prompt.md" <<'EOF'
Return RESULT only.
EOF
cat > "$job/request.json" <<'JSON'
{
  "mode": "workspace-write",
  "network_access": false,
  "timeout_seconds": 30,
  "allow_host_verify": true
}
JSON
cat > "$job/test.json" <<'JSON'
{
  "test_status": "PASS",
  "test_summary": "stubbed",
  "write_file": "worker-output.txt",
  "write_text": "ok\n"
}
JSON
cat > "$job/metadata.json" <<'JSON'
{"issue":"TST-0","project":"test","phase":"BUILD"}
JSON
cat > "$job/verify.sh" <<'EOF'
test -f worker-output.txt && grep -q ok worker-output.txt
EOF

out="$job/output/result.json"
if "$S" run --backend test --job-dir "$job" --worktree "$repo" --prompt "$job/prompt.md" --out "$out"; then
  echo "PASS: test backend command exits 0"
else
  echo "FAIL: test backend command failed"; fail=1
fi
result="$(cat "$out")"
check_json "result schema carries PASS status" "r['schema_version']==1 and r['status']=='PASS' and r['ok'] is True" "$result"
check_json "changed_files lists worker output" "'worker-output.txt' in r['changed_files']" "$result"
check_json "verification result is captured" "r['verification']['ran'] is True and r['verification']['ok'] is True" "$result"
check_json "logs surface stdout.jsonl path" "r['logs'].get('stdout_jsonl','').endswith('stdout.jsonl')" "$result"
check_json "artifacts surface durable diff patch" "r['artifacts'].get('diff_patch','').endswith('diff.patch') and os.path.exists(r['artifacts']['diff_patch'])" "$result"
[ -s "$job/logs/stdout.jsonl" ] && echo "PASS: stdout.jsonl written" || { echo "FAIL: stdout.jsonl missing"; fail=1; }
grep -q 'worker-output.txt' "$job/output/diff.patch" && echo "PASS: diff.patch includes untracked worker output" || { echo "FAIL: diff.patch missing worker output"; fail=1; }
check_json "request schema remains policy-only" "set(r['request']) == {'allow_host_verify','mode','network_access','timeout_seconds'}" "$result"
[ -s "$job/metadata.json" ] && echo "PASS: metadata.json may carry flow metadata" || { echo "FAIL: metadata.json missing"; fail=1; }

stagedjob="$tmp/stagedjob"
mkdir -p "$stagedjob/output" "$stagedjob/logs"
cp "$job/prompt.md" "$stagedjob/prompt.md"
echo staged > "$repo/staged.txt"
git -C "$repo" add staged.txt
cat > "$stagedjob/request.json" <<'JSON'
{"mode":"workspace-write"}
JSON
stagedout="$stagedjob/output/result.json"
"$S" run --backend test --job-dir "$stagedjob" --worktree "$repo" --prompt "$stagedjob/prompt.md" --out "$stagedout" >/dev/null
grep -q 'staged.txt' "$stagedjob/output/diff.patch" && echo "PASS: diff.patch includes staged changes" || { echo "FAIL: diff.patch missing staged changes"; fail=1; }
git -C "$repo" reset -q HEAD staged.txt

nestedjob="$tmp/nestedjob"
mkdir -p "$nestedjob/output" "$nestedjob/logs"
cp "$job/prompt.md" "$nestedjob/prompt.md"
cat > "$nestedjob/request.json" <<'JSON'
{
  "mode": "workspace-write"
}
JSON
cat > "$nestedjob/test.json" <<'JSON'
{
  "test_status": "PASS",
  "write_file": "nested/worker-output.txt",
  "write_text": "nested ok\n"
}
JSON
nestedout="$nestedjob/output/result.json"
"$S" run --backend test --job-dir "$nestedjob" --worktree "$repo" --prompt "$nestedjob/prompt.md" --out "$nestedout" >/dev/null
grep -q 'nested/worker-output.txt' "$nestedjob/output/diff.patch" && echo "PASS: diff.patch includes nested untracked files" || { echo "FAIL: diff.patch missing nested untracked files"; fail=1; }

printf 'SECRET=do-not-leak\n' > "$tmp/outside-secret"
ln -s "$tmp/outside-secret" "$repo/leak-env"
linkjob="$tmp/linkjob"
mkdir -p "$linkjob/output" "$linkjob/logs"
cp "$job/prompt.md" "$linkjob/prompt.md"
cat > "$linkjob/request.json" <<'JSON'
{"mode":"workspace-write"}
JSON
linkout="$linkjob/output/result.json"
"$S" run --backend test --job-dir "$linkjob" --worktree "$repo" --prompt "$linkjob/prompt.md" --out "$linkout" >/dev/null
if grep -q 'do-not-leak' "$linkjob/output/diff.patch"; then
  echo "FAIL: diff.patch dereferenced untracked symlink"; fail=1
else
  echo "PASS: diff.patch skips untracked symlink targets"
fi
rm -f "$repo/leak-env" "$tmp/outside-secret"

badjob="$tmp/badjob"
mkdir -p "$badjob/output" "$badjob/logs"
cp "$job/prompt.md" "$badjob/prompt.md"
cat > "$badjob/request.json" <<'JSON'
{
  "mode": "workspace-write",
  "allow_host_verify": true
}
JSON
cat > "$badjob/test.json" <<'JSON'
{
  "test_status": "PASS",
  "write_file": "missing.txt"
}
JSON
cat > "$badjob/verify.sh" <<'EOF'
test -f definitely-not-created.txt
EOF
badout="$badjob/output/result.json"
"$S" run --backend test --job-dir "$badjob" --worktree "$repo" --prompt "$badjob/prompt.md" --out "$badout" >/dev/null
badresult="$(cat "$badout")"
check_json "failing verify demotes PASS to FAIL" "r['status']=='FAIL' and r['ok'] is False and r['verification']['ok'] is False" "$badresult"

timeoutjob="$tmp/timeoutjob"
mkdir -p "$timeoutjob/output" "$timeoutjob/logs"
cp "$job/prompt.md" "$timeoutjob/prompt.md"
cat > "$timeoutjob/request.json" <<'JSON'
{
  "mode": "workspace-write",
  "timeout_seconds": 1,
  "allow_host_verify": true
}
JSON
cat > "$timeoutjob/verify.sh" <<'EOF'
sleep 2
EOF
timeoutout="$timeoutjob/output/result.json"
"$S" run --backend test --job-dir "$timeoutjob" --worktree "$repo" --prompt "$timeoutjob/prompt.md" --out "$timeoutout" >/dev/null
timeoutresult="$(cat "$timeoutout")"
check_json "verify timeout still writes normalized FAIL result" "r['status']=='FAIL' and r['verification'].get('timed_out') is True" "$timeoutresult"

outside="$tmp/outside"
mkdir -p "$outside"
ln -s "$outside" "$repo/link-out"
escapejob="$tmp/escapejob"
mkdir -p "$escapejob/output" "$escapejob/logs"
cp "$job/prompt.md" "$escapejob/prompt.md"
cat > "$escapejob/request.json" <<'JSON'
{
  "mode": "workspace-write"
}
JSON
cat > "$escapejob/test.json" <<'JSON'
{
  "test_status": "PASS",
  "write_file": "link-out/escaped.txt"
}
JSON
escapeout="$escapejob/output/result.json"
"$S" run --backend test --job-dir "$escapejob" --worktree "$repo" --prompt "$escapejob/prompt.md" --out "$escapeout" >/dev/null
escaperesult="$(cat "$escapeout")"
check_json "test backend rejects symlink escape writes" "r['status']=='ERROR' and 'escapes worktree' in r['summary']" "$escaperesult"
[ ! -e "$outside/escaped.txt" ] && echo "PASS: symlink escape did not write outside" || { echo "FAIL: symlink escape wrote outside"; fail=1; }

insidejob="$repo/job-inside"
mkdir -p "$insidejob/output" "$insidejob/logs"
cp "$job/prompt.md" "$insidejob/prompt.md"
cat > "$insidejob/request.json" <<'JSON'
{"mode":"workspace-write"}
JSON
if "$S" run --backend test --job-dir "$insidejob" --worktree "$repo" --prompt "$insidejob/prompt.md" --out "$insidejob/output/result.json" >/dev/null 2>&1; then
  echo "FAIL: workspace-write job-dir inside worktree should be rejected"; fail=1
else
  echo "PASS: workspace-write job-dir inside worktree rejected"
fi

badpolicyjob="$tmp/badpolicyjob"
mkdir -p "$badpolicyjob/output" "$badpolicyjob/logs"
cp "$job/prompt.md" "$badpolicyjob/prompt.md"
cat > "$badpolicyjob/request.json" <<'JSON'
{"mode":"workspace-write","network_access":"false"}
JSON
if "$S" run --backend test --job-dir "$badpolicyjob" --worktree "$repo" --prompt "$badpolicyjob/prompt.md" --out "$badpolicyjob/output/result.json" >/dev/null 2>&1; then
  echo "FAIL: string boolean network_access should be rejected"; fail=1
else
  echo "PASS: string boolean network_access rejected"
fi

extrakeyjob="$tmp/extrakeyjob"
mkdir -p "$extrakeyjob/output" "$extrakeyjob/logs"
cp "$job/prompt.md" "$extrakeyjob/prompt.md"
cat > "$extrakeyjob/request.json" <<'JSON'
{"mode":"workspace-write","write_file":"not-policy.txt"}
JSON
if "$S" run --backend test --job-dir "$extrakeyjob" --worktree "$repo" --prompt "$extrakeyjob/prompt.md" --out "$extrakeyjob/output/result.json" >/dev/null 2>&1; then
  echo "FAIL: request.json backend fields should be rejected"; fail=1
else
  echo "PASS: request.json backend fields rejected"
fi

outjob="$tmp/outjob"
mkdir -p "$outjob/output" "$outjob/logs"
cp "$job/prompt.md" "$outjob/prompt.md"
cat > "$outjob/request.json" <<'JSON'
{"mode":"read-only"}
JSON
if "$S" run --backend test --job-dir "$outjob" --worktree "$repo" --prompt "$outjob/prompt.md" --out "$repo/worker-result.json" >/dev/null 2>&1; then
  echo "FAIL: --out inside worktree should be rejected"; fail=1
else
  echo "PASS: --out inside worktree rejected"
fi

readonlywritejob="$tmp/readonlywritejob"
mkdir -p "$readonlywritejob/output" "$readonlywritejob/logs"
cp "$job/prompt.md" "$readonlywritejob/prompt.md"
cat > "$readonlywritejob/request.json" <<'JSON'
{"mode":"read-only"}
JSON
cat > "$readonlywritejob/test.json" <<'JSON'
{"test_status":"PASS","write_file":"should-not-write.txt"}
JSON
readonlyout="$readonlywritejob/output/result.json"
"$S" run --backend test --job-dir "$readonlywritejob" --worktree "$repo" --prompt "$readonlywritejob/prompt.md" --out "$readonlyout" >/dev/null
readonlyresult="$(cat "$readonlyout")"
check_json "test backend write_file requires workspace-write" "r['status']=='ERROR' and 'workspace-write' in r['summary']" "$readonlyresult"
[ ! -e "$repo/should-not-write.txt" ] && echo "PASS: read-only test backend did not write" || { echo "FAIL: read-only test backend wrote file"; fail=1; }

netjob="$tmp/netjob"
mkdir -p "$netjob/output" "$netjob/logs"
cp "$job/prompt.md" "$netjob/prompt.md"
cat > "$netjob/request.json" <<'JSON'
{"mode":"workspace-write","network_access":true}
JSON
if "$S" run --backend test --job-dir "$netjob" --worktree "$repo" --prompt "$netjob/prompt.md" --out "$netjob/output/result.json" >/dev/null 2>&1; then
  echo "FAIL: workspace-write network_access=true should be rejected"; fail=1
else
  echo "PASS: workspace-write network_access=true rejected"
fi

cmdcheck="$(python3 - "$S" <<'PY'
import importlib.util, json, sys
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader('agent_worker', sys.argv[1])
spec = importlib.util.spec_from_loader('agent_worker', loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
ww = m.codex_command({'mode':'workspace-write','network_access':False}, '/w', '/o', 'PROMPT')
ro = m.codex_command({'mode':'read-only','network_access':False}, '/w', '/o', 'PROMPT')
print(json.dumps({'workspace': ww, 'readonly': ro}))
PY
)"
check_json "workspace-write codex network-off flag lives in adapter" "'-c' in r['workspace'] and 'sandbox_workspace_write.network_access=false' in r['workspace']" "$cmdcheck"
check_json "read-only codex sandbox flag lives in adapter" "r['readonly'][0:4] == ['codex','exec','-s','read-only']" "$cmdcheck"

envcheck="$(python3 - "$S" "$repo_root/scripts/pandastack-drive" <<'PY'
import importlib.util, json, os, sys
from importlib.machinery import SourceFileLoader
old = os.environ.copy()
os.environ.clear()
os.environ.update({
    'PATH': '/bin',
    'HOME': '/tmp/home',
    'DATABASE_URL': 'postgres://secret',
    'DOCKER_AUTH_CONFIG': 'secret',
    'NPM_CONFIG__AUTH': 'secret',
    'PIP_INDEX_URL': 'https://secret',
    'FOO_TOKEN': 'secret',
})
out = {}
for name, path in [('agent_worker', sys.argv[1]), ('drive', sys.argv[2])]:
    loader = SourceFileLoader(name, path)
    spec = importlib.util.spec_from_loader(name, loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    out[name] = sorted(mod.worker_env())
os.environ.clear(); os.environ.update(old)
print(json.dumps(out))
PY
)"
check_json "worker env uses allowlist" "r['agent_worker'] == ['HOME','PATH'] and r['drive'] == ['HOME','PATH']" "$envcheck"

if grep -q 'subprocess.run(\["codex"' "$repo_root/scripts/pandastack-drive"; then
  echo "FAIL: pandastack-drive still constructs codex subprocess directly"; fail=1
else
  echo "PASS: pandastack-drive has no direct codex subprocess construction"
fi

[ "$fail" -eq 0 ] && echo "OK: agent-worker all green" || echo "FAILURES present"
exit "$fail"
