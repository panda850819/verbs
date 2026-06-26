#!/usr/bin/env bash
# tests/pandastack-capabilities.sh — capability map contract tests.
# No network, no real Claude/Codex/Hermes invocation. Uses fake PATH and temp HOME.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$repo_root/scripts/pandastack"
PY3="$(command -v python3)"
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

pass()   { echo "PASS: $1"; }
fail_t() { echo "FAIL: $1"; fail=1; }

fake_empty="$tmp/path_empty"
mkdir -p "$fake_empty"
fake_home_caps="$tmp/home_caps"
mkdir -p "$fake_home_caps"

# ---------------------------------------------------------------------------
# T01 — pandastack.toml exists and is parseable with schema_version = 1
# ---------------------------------------------------------------------------
[ -f "$repo_root/pandastack.toml" ] \
  && pass "pandastack.toml exists" \
  || fail_t "pandastack.toml missing"

"$PY3" - "$repo_root/pandastack.toml" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()
assert "[capabilities]" in text, "missing [capabilities] section"
try:
    import tomllib
    d = tomllib.loads(text)
    assert d["capabilities"]["schema_version"] == 1, "schema_version != 1"
except ImportError:
    # Python < 3.11: minimal check on raw text
    assert "schema_version = 1" in text, "schema_version = 1 not found"
PY
[ $? -eq 0 ] \
  && pass "pandastack.toml parseable with schema_version=1" \
  || fail_t "pandastack.toml parse/schema check failed"

# ---------------------------------------------------------------------------
# T02 — gitignore behavior
# ---------------------------------------------------------------------------
git -C "$repo_root" check-ignore ".pandastack/local/capabilities.json" >/dev/null 2>&1 \
  && pass ".pandastack/local/capabilities.json is gitignored" \
  || fail_t ".pandastack/local/capabilities.json should be gitignored"

# pandastack.toml must NOT be gitignored
git -C "$repo_root" check-ignore "pandastack.toml" >/dev/null 2>&1 \
  && fail_t "pandastack.toml should NOT be gitignored" \
  || pass "pandastack.toml is not gitignored"

# ---------------------------------------------------------------------------
# T03/T04 — --capabilities-json emits valid JSON with all required fields
# ---------------------------------------------------------------------------
# Isolate: pin HOME and PANDASTACK_LOCAL_STATE so the auth=unsupported assertions
# below are deterministic regardless of the developer's real ~/.pandastack state.
caps_out="$(HOME="$fake_home_caps" \
  PANDASTACK_LOCAL_STATE="$tmp/caps_out_none.json" \
  PATH="$fake_empty" "$PY3" "$CLI" doctor --capabilities-json 2>/dev/null)"

echo "$caps_out" | "$PY3" -m json.tool >/dev/null 2>&1 \
  && pass "--capabilities-json emits valid JSON" \
  || fail_t "--capabilities-json does not emit valid JSON"

echo "$caps_out" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
required = ['schema_version','roles','runtimes','skills','auth','limits','next_actions']
missing = [k for k in required if k not in r]
if missing:
    print('missing: ' + ', '.join(missing)); sys.exit(1)
" 2>/dev/null \
  && pass "--capabilities-json has all required top-level fields" \
  || fail_t "--capabilities-json missing required fields"

echo "$caps_out" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
assert 'host' in r['roles'], 'roles.host missing'
assert 'worker' in r['roles'], 'roles.worker missing'
assert 'operator' in r['roles'], 'roles.operator missing'
" 2>/dev/null \
  && pass "--capabilities-json has roles.host, .worker, .operator" \
  || fail_t "--capabilities-json missing roles sub-keys"

echo "$caps_out" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
sc = r['skills']['counts']
assert 'core' in sc and 'ext' in sc and 'total' in sc, 'skills.counts incomplete'
" 2>/dev/null \
  && pass "--capabilities-json has skills.counts" \
  || fail_t "--capabilities-json missing skills.counts"

echo "$caps_out" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
for rt in ['claude', 'codex', 'hermes']:
    assert rt in r['auth'], f'auth.{rt} missing'
    assert 'status' in r['auth'][rt], f'auth.{rt}.status missing'
" 2>/dev/null \
  && pass "--capabilities-json has auth for claude/codex/hermes" \
  || fail_t "--capabilities-json missing auth fields"

# ---------------------------------------------------------------------------
# T03 — missing runtimes produce auth=unsupported (not unknown)
# ---------------------------------------------------------------------------
echo "$caps_out" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
for rt in ['claude', 'codex', 'hermes']:
    st = r['auth'][rt]['status']
    assert st == 'unsupported', f'expected unsupported for {rt} (empty PATH), got {st}'
" 2>/dev/null \
  && pass "missing runtimes produce auth=unsupported" \
  || fail_t "missing runtimes should produce auth=unsupported"

# ---------------------------------------------------------------------------
# T04 — missing state files produce warnings, not a crash
# ---------------------------------------------------------------------------
fake_home_empty="$tmp/home_empty"
mkdir -p "$fake_home_empty"
caps_no_files="$(HOME="$fake_home_empty" \
  PANDASTACK_LOCAL_STATE="$tmp/nonexistent.json" \
  PATH="$fake_empty" \
  "$PY3" "$CLI" doctor --capabilities-json 2>/dev/null)"

echo "$caps_no_files" | "$PY3" -m json.tool >/dev/null 2>&1 \
  && pass "--capabilities-json valid JSON with no generated files" \
  || fail_t "--capabilities-json crashed with no generated files"

echo "$caps_no_files" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
w = r.get('warnings', [])
assert len(w) > 0, 'expected warnings for missing state files'
" 2>/dev/null \
  && pass "--capabilities-json includes warnings when state files are missing" \
  || fail_t "--capabilities-json should include warnings for missing files"

# warnings should mention the fix command
echo "$caps_no_files" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
combined = ' '.join(r.get('warnings', []))
assert 'write-capabilities' in combined, 'warnings should mention --write-capabilities'
" 2>/dev/null \
  && pass "warnings mention --write-capabilities fix command" \
  || fail_t "warnings should mention --write-capabilities"

# ---------------------------------------------------------------------------
# T03 — --write-capabilities writes both files with correct shape
# ---------------------------------------------------------------------------
fake_home_write="$tmp/home_write"
local_state_file="$tmp/local_caps.json"

PANDASTACK_NOW="2026-06-18T00:00:00Z" \
  HOME="$fake_home_write" \
  PANDASTACK_LOCAL_STATE="$local_state_file" \
  PATH="$fake_empty" \
  "$PY3" "$CLI" doctor --write-capabilities >/dev/null 2>&1 \
  && pass "--write-capabilities exits 0" \
  || fail_t "--write-capabilities failed"

[ -f "$local_state_file" ] \
  && pass "--write-capabilities wrote local capabilities.json" \
  || fail_t "--write-capabilities should write local capabilities.json"

[ -f "$fake_home_write/.pandastack/runtimes.json" ] \
  && pass "--write-capabilities wrote global runtimes.json" \
  || fail_t "--write-capabilities should write global runtimes.json"

# ---------------------------------------------------------------------------
# T03 — PANDASTACK_NOW produces deterministic timestamp
# ---------------------------------------------------------------------------
ts="$("$PY3" -c "import json; r=json.load(open('$local_state_file')); print(r['generated_at'])" 2>/dev/null)"
[ "$ts" = "2026-06-18T00:00:00Z" ] \
  && pass "PANDASTACK_NOW sets deterministic timestamp in capabilities.json" \
  || fail_t "expected 2026-06-18T00:00:00Z in capabilities.json, got '$ts'"

ts_rt="$("$PY3" -c "
import json; r=json.load(open('$fake_home_write/.pandastack/runtimes.json'))
print(r['generated_at'])
" 2>/dev/null)"
[ "$ts_rt" = "2026-06-18T00:00:00Z" ] \
  && pass "PANDASTACK_NOW sets deterministic timestamp in runtimes.json" \
  || fail_t "expected 2026-06-18T00:00:00Z in runtimes.json, got '$ts_rt'"

# capabilities.json required schema
"$PY3" - "$local_state_file" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
required = ['schema_version','generated_at','repo','source','roles','runtimes','skills','auth','limits','next_actions']
missing = [k for k in required if k not in r]
assert not missing, f"missing keys: {missing}"
assert r['schema_version'] == 1
PY
[ $? -eq 0 ] \
  && pass "capabilities.json has correct schema" \
  || fail_t "capabilities.json schema check failed"

# runtimes.json schema
"$PY3" - "$fake_home_write/.pandastack/runtimes.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
assert r['schema_version'] == 1
assert 'runtimes' in r
for rt in ['claude', 'codex', 'hermes']:
    d = r['runtimes'][rt]
    assert 'present' in d and 'path' in d and 'auth' in d, f"incomplete entry for {rt}"
    assert d['present'] is False, f"expected False for {rt} in empty PATH"
    assert d['auth'] == 'unsupported', f"expected unsupported for {rt}, got {d['auth']}"
PY
[ $? -eq 0 ] \
  && pass "runtimes.json has correct schema and unsupported auth for empty PATH" \
  || fail_t "runtimes.json schema or auth check failed"

# ---------------------------------------------------------------------------
# T03 — --write-capabilities --json prints JSON to stdout
# ---------------------------------------------------------------------------
fake_home_wj="$tmp/home_wj"
write_json_out="$(PANDASTACK_NOW="2026-06-18T00:00:00Z" \
  HOME="$fake_home_wj" \
  PANDASTACK_LOCAL_STATE="$tmp/wj_caps.json" \
  PATH="$fake_empty" \
  "$PY3" "$CLI" doctor --write-capabilities --json 2>/dev/null)"

echo "$write_json_out" | "$PY3" -m json.tool >/dev/null 2>&1 \
  && pass "--write-capabilities --json emits valid JSON to stdout" \
  || fail_t "--write-capabilities --json should emit valid JSON to stdout"

wj_ts="$(echo "$write_json_out" | "$PY3" -c \
  "import json,sys; r=json.load(sys.stdin); print(r['generated_at'])" 2>/dev/null)"
[ "$wj_ts" = "2026-06-18T00:00:00Z" ] \
  && pass "--write-capabilities --json timestamp matches PANDASTACK_NOW" \
  || fail_t "expected 2026-06-18T00:00:00Z in stdout JSON, got '$wj_ts'"

# ---------------------------------------------------------------------------
# T04 — with fixture local file, --capabilities-json reflects fixture state
# ---------------------------------------------------------------------------
fake_home_fix="$tmp/home_fixture"
local_fix="$tmp/fixture_caps.json"
mkdir -p "$fake_home_fix"

"$PY3" - "$local_fix" <<'PY'
import json, sys
cap = {
    "schema_version": 1,
    "generated_at": "2026-01-01T00:00:00Z",
    "repo": "/fixture/repo",
    "source": "fixture",
    "roles": {"host": {"claude": {}}, "worker": {}, "operator": {}},
    "runtimes": {"claude": True},
    "skills": {"counts": {"core": 10, "ext": 1, "total": 11}, "available": []},
    "auth": {
        "claude": {"status": "present"},
        "codex": {"status": "unsupported"},
        "hermes": {"status": "unsupported"}
    },
    "limits": {"network": "available", "write_scope": "workspace-write"},
    "next_actions": []
}
json.dump(cap, open(sys.argv[1], "w"), indent=2)
PY

caps_fix="$(HOME="$fake_home_fix" \
  PANDASTACK_LOCAL_STATE="$local_fix" \
  "$PY3" "$CLI" doctor --capabilities-json 2>/dev/null)"

echo "$caps_fix" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
assert r['generated_at'] == '2026-01-01T00:00:00Z', f'expected fixture ts, got {r[\"generated_at\"]}'
assert r['skills']['counts']['core'] == 10, f'expected core=10 from fixture'
assert r['auth']['claude']['status'] == 'present', 'expected fixture auth=present'
" 2>/dev/null \
  && pass "--capabilities-json reflects fixture state when local file exists" \
  || fail_t "--capabilities-json should reflect fixture state"

# ---------------------------------------------------------------------------
# T04b — global runtimes.json overlay is applied and worker state re-derived
# ---------------------------------------------------------------------------
fake_home_global="$tmp/home_global"
mkdir -p "$fake_home_global/.pandastack"

"$PY3" - "$fake_home_global/.pandastack/runtimes.json" <<'PY'
import json, sys
data = {
    "schema_version": 1,
    "generated_at": "2026-02-02T00:00:00Z",
    "runtimes": {
        "claude": {"present": True, "path": "/fake/claude", "auth": "present"},
        "codex": {"present": True, "path": "/fake/codex", "auth": "present"},
        "hermes": {"present": False, "path": None, "auth": "unsupported"},
    },
}
json.dump(data, open(sys.argv[1], "w"), indent=2)
PY

# No local file + empty PATH: without the overlay these would be False/unsupported.
caps_global="$(HOME="$fake_home_global" \
  PANDASTACK_LOCAL_STATE="$tmp/global_overlay_none.json" \
  PATH="$fake_empty" \
  "$PY3" "$CLI" doctor --capabilities-json 2>/dev/null)"

echo "$caps_global" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
assert r['runtimes'].get('codex') is True, 'global overlay should set runtimes.codex=True'
assert r['auth']['codex']['status'] == 'present', 'global overlay should set auth.codex=present'
assert r['roles']['worker']['codex_backend_ready'] is True, \
    'worker.codex_backend_ready must be re-derived from the merged runtimes map'
" 2>/dev/null \
  && pass "global runtimes.json overlay applied and worker re-derived" \
  || fail_t "global overlay not applied or worker not re-derived"

# A schema-mismatched state file is ignored with a warning, not merged or crashed.
fake_home_badver="$tmp/home_badver"
mkdir -p "$fake_home_badver/.pandastack"
printf '{"schema_version": 99, "runtimes": {}}' \
  > "$fake_home_badver/.pandastack/runtimes.json"
caps_badver="$(HOME="$fake_home_badver" \
  PANDASTACK_LOCAL_STATE="$tmp/badver_none.json" \
  PATH="$fake_empty" \
  "$PY3" "$CLI" doctor --capabilities-json 2>/dev/null)"
echo "$caps_badver" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
assert any('schema_version' in w for w in r.get('warnings', [])), \
    'schema-mismatched file should be ignored with a warning'
" 2>/dev/null \
  && pass "schema-mismatched state file ignored with warning" \
  || fail_t "schema-mismatched state file should be ignored with warning"

# A valid-JSON-but-wrong-shape file (top-level list) must not crash the command.
fake_home_badshape="$tmp/home_badshape"
mkdir -p "$fake_home_badshape/.pandastack"
printf '[1, 2, 3]' > "$fake_home_badshape/.pandastack/runtimes.json"
HOME="$fake_home_badshape" \
  PANDASTACK_LOCAL_STATE="$tmp/badshape_none.json" \
  PATH="$fake_empty" \
  "$PY3" "$CLI" doctor --capabilities-json 2>/dev/null \
  | "$PY3" -m json.tool >/dev/null 2>&1 \
  && pass "wrong-shape (JSON list) state file does not crash --capabilities-json" \
  || fail_t "wrong-shape state file should not crash --capabilities-json"

# ---------------------------------------------------------------------------
# T06 — docs file exists and contains required content
# ---------------------------------------------------------------------------
doc_file="$repo_root/docs/capabilities.md"
[ -f "$doc_file" ] \
  && pass "capabilities.md doc exists" \
  || fail_t "docs/capabilities.md missing"

grep -q "capabilities.json" "$doc_file" 2>/dev/null \
  && pass "capabilities.md references capabilities.json" \
  || fail_t "capabilities.md should reference capabilities.json"

grep -qiE "claude.*code|codex|hermes" "$doc_file" 2>/dev/null \
  && pass "capabilities.md names Claude Code, Codex, Hermes" \
  || fail_t "capabilities.md should name Claude Code, Codex, and Hermes"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
[ "$fail" -eq 0 ] && echo "OK: pandastack-capabilities all green" || echo "FAILURES present"
exit "$fail"
