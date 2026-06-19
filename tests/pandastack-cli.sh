#!/usr/bin/env bash
# tests/pandastack-cli.sh -- pandastack CLI front-door tests.
# No network, no real Claude/Codex invocation. Uses fake PATH and temp HOME.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$repo_root/scripts/pandastack"
# Capture absolute python3 path so fake-PATH tests can still invoke it.
PY3="$(command -v python3)"
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

pass()   { echo "PASS: $1"; }
fail_t() { echo "FAIL: $1"; fail=1; }

# ---------------------------------------------------------------------------
# T01 -- basic invocations
# ---------------------------------------------------------------------------
if "$PY3" "$CLI" help >/dev/null 2>&1; then
  pass "help exits 0"
else
  fail_t "help exits nonzero"
fi

if ! "$PY3" "$CLI" notacommand >/dev/null 2>&1; then
  pass "unknown command exits nonzero"
else
  fail_t "unknown command should exit nonzero"
fi

# ---------------------------------------------------------------------------
# T01/T02 -- doctor --json is valid JSON with required top-level keys
# ---------------------------------------------------------------------------
json_out="$("$PY3" "$CLI" doctor --json 2>&1)"
if echo "$json_out" | "$PY3" -m json.tool >/dev/null 2>&1; then
  pass "doctor --json is valid JSON"
else
  fail_t "doctor --json is not valid JSON"
fi

echo "$json_out" | "$PY3" -c "
import json, sys
r = json.load(sys.stdin)
required = ['schema_version','repo','host','roles','checks','recommendation','next_actions']
missing = [k for k in required if k not in r]
if missing:
    print('missing: ' + ', '.join(missing)); sys.exit(1)
" 2>/dev/null \
  && pass "JSON has all required top-level keys" \
  || fail_t "JSON missing required top-level keys"

# ---------------------------------------------------------------------------
# T02 -- manifest counts
# ---------------------------------------------------------------------------
# Assert structural invariants, not literal counts: manifest.ok is the real
# drift guard (manifest <-> skills/ in sync). Hardcoding core==24/ext==2 would
# break on every legitimate skill addition while manifest.ok stays True.
core_count="$(echo "$json_out" | "$PY3" -c \
  "import json,sys; r=json.load(sys.stdin); print(r['checks']['manifest']['skill_counts']['core'])")"
ext_count="$(echo "$json_out" | "$PY3" -c \
  "import json,sys; r=json.load(sys.stdin); print(r['checks']['manifest']['skill_counts']['ext'])")"
total_count="$(echo "$json_out" | "$PY3" -c \
  "import json,sys; r=json.load(sys.stdin); print(r['checks']['manifest']['skill_counts']['total'])")"
manifest_ok_val="$(echo "$json_out" | "$PY3" -c \
  "import json,sys; r=json.load(sys.stdin); print(r['checks']['manifest']['ok'])")"

[ "$manifest_ok_val" = "True" ] \
  && pass "manifest.ok=True (manifest <-> skills/ in sync)" \
  || fail_t "manifest.ok expected True, got $manifest_ok_val"
{ [ "$core_count" -gt 0 ] 2>/dev/null; } \
  && pass "manifest skill_counts.core > 0 ($core_count)" \
  || fail_t "manifest skill_counts.core should be > 0, got $core_count"
[ "$total_count" = "$((core_count + ext_count))" ] \
  && pass "manifest total == core + ext ($total_count)" \
  || fail_t "manifest total ($total_count) != core+ext ($core_count+$ext_count)"

# T02 -- missing manifest exits nonzero with error, no traceback
bad_manifest="$tmp/nonexistent-manifest.toml"
if PANDASTACK_MANIFEST="$bad_manifest" "$PY3" "$CLI" doctor --json 2>"$tmp/err.txt"; then
  fail_t "missing manifest should exit nonzero"
else
  pass "missing manifest exits nonzero"
fi
if grep -q "Traceback" "$tmp/err.txt" 2>/dev/null; then
  fail_t "missing manifest should not print traceback"
else
  pass "missing manifest shows no traceback"
fi
if grep -qiE "error|not found" "$tmp/err.txt" 2>/dev/null; then
  pass "missing manifest shows clear error message"
else
  fail_t "missing manifest should show clear error message"
fi

# ---------------------------------------------------------------------------
# T03 -- text output contains role section headers
# ---------------------------------------------------------------------------
text_out="$("$PY3" "$CLI" doctor 2>&1)"
echo "$text_out" | grep -q "Host runtime" \
  && pass "text output contains 'Host runtime'" \
  || fail_t "text output missing 'Host runtime'"
echo "$text_out" | grep -q "Worker runtime" \
  && pass "text output contains 'Worker runtime'" \
  || fail_t "text output missing 'Worker runtime'"
echo "$text_out" | grep -q "Operator runtime" \
  && pass "text output contains 'Operator runtime'" \
  || fail_t "text output missing 'Operator runtime'"

# T03 -- JSON has roles.host, roles.worker, roles.operator
echo "$json_out" | "$PY3" -c "
import json,sys
r=json.load(sys.stdin)
assert 'host' in r['roles'],'host missing'
assert 'worker' in r['roles'],'worker missing'
assert 'operator' in r['roles'],'operator missing'
" 2>/dev/null \
  && pass "JSON has roles.host, roles.worker, roles.operator" \
  || fail_t "JSON missing roles structure"

# ---------------------------------------------------------------------------
# T04 -- recommendation profiles via fake PATH
# ---------------------------------------------------------------------------

fake_bin() {  # fake_bin <dir> <name>
  printf '#!/bin/sh\necho "fake %s"\n' "$2" > "$1/$2"
  chmod +x "$1/$2"
}

# no claude, no codex -> bootstrap-only
fake_empty="$tmp/path_empty"
mkdir -p "$fake_empty"
profile_empty="$(PATH="$fake_empty" "$PY3" "$CLI" doctor --json 2>/dev/null \
  | "$PY3" -c "import json,sys; r=json.load(sys.stdin); print(r['recommendation']['profile'])")"
[ "$profile_empty" = "bootstrap-only" ] \
  && pass "no claude/codex -> bootstrap-only" \
  || fail_t "expected bootstrap-only, got $profile_empty"

# claude only -> claude-only
fake_claude="$tmp/path_claude"
mkdir -p "$fake_claude"
fake_bin "$fake_claude" claude
out_claude="$(PATH="$fake_claude" "$PY3" "$CLI" doctor --json 2>/dev/null)"
profile_claude="$(echo "$out_claude" | "$PY3" -c \
  "import json,sys; r=json.load(sys.stdin); print(r['recommendation']['profile'])")"
[ "$profile_claude" = "claude-only" ] \
  && pass "claude present, no codex -> claude-only" \
  || fail_t "expected claude-only, got $profile_claude"

# codex only -> codex-only
fake_codex="$tmp/path_codex"
mkdir -p "$fake_codex"
fake_bin "$fake_codex" codex
out_codex="$(PATH="$fake_codex" "$PY3" "$CLI" doctor --json 2>/dev/null)"
profile_codex="$(echo "$out_codex" | "$PY3" -c \
  "import json,sys; r=json.load(sys.stdin); print(r['recommendation']['profile'])")"
[ "$profile_codex" = "codex-only" ] \
  && pass "codex present, no claude -> codex-only" \
  || fail_t "expected codex-only, got $profile_codex"

# claude + codex -> cross-runtime
fake_both="$tmp/path_both"
mkdir -p "$fake_both"
fake_bin "$fake_both" claude
fake_bin "$fake_both" codex
out_both="$(PATH="$fake_both" "$PY3" "$CLI" doctor --json 2>/dev/null)"
profile_both="$(echo "$out_both" | "$PY3" -c \
  "import json,sys; r=json.load(sys.stdin); print(r['recommendation']['profile'])")"
[ "$profile_both" = "cross-runtime" ] \
  && pass "claude + codex -> cross-runtime" \
  || fail_t "expected cross-runtime, got $profile_both"

# T04 -- missing codex is a worker warning, not a fatal doctor failure
echo "$out_claude" | "$PY3" -c "
import json,sys
r=json.load(sys.stdin)
warnings = r['roles']['worker'].get('warnings', [])
if any('codex' in w.lower() for w in warnings):
    sys.exit(0)
sys.exit(1)
" 2>/dev/null \
  && pass "missing codex shows worker warning, not fatal" \
  || fail_t "missing codex should show worker warning"

# T04 -- output never requires Bun or Node as the first priority action
echo "$out_codex" | "$PY3" -c "
import json,sys
r=json.load(sys.stdin)
for a in r['next_actions']:
    if a['priority'] == 0:
        for cmd in a.get('commands', []):
            low = cmd.lower().strip()
            if low.startswith('bun ') or low.startswith('npm '):
                print('First action requires Bun/Node:', cmd); sys.exit(1)
" 2>/dev/null \
  && pass "first-priority actions do not require Bun/Node" \
  || fail_t "first-priority action should not require Bun/Node"

# ---------------------------------------------------------------------------
# T02 -- substrate check with missing AGENTS.md (fake HOME)
# ---------------------------------------------------------------------------
fake_home="$tmp/home_no_agents"
mkdir -p "$fake_home"
out_no_agents="$(HOME="$fake_home" "$PY3" "$CLI" doctor --json 2>/dev/null)"
agents_ok="$(echo "$out_no_agents" | "$PY3" -c "
import json,sys
r=json.load(sys.stdin)
c=next(x for x in r['checks']['substrate'] if x['name']=='substrate.agents_md')
print(c['ok'])
")"
[ "$agents_ok" = "False" ] \
  && pass "missing AGENTS.md reported as substrate check failure" \
  || fail_t "missing AGENTS.md should be substrate failure, got ok=$agents_ok"

# ---------------------------------------------------------------------------
# T05 -- init --dry-run
# ---------------------------------------------------------------------------
init_claude_out="$("$PY3" "$CLI" init --host claude --dry-run 2>&1)"
echo "$init_claude_out" | grep -q "plugin marketplace add" \
  && pass "init --host claude --dry-run includes marketplace add" \
  || fail_t "init claude --dry-run missing 'plugin marketplace add'"
echo "$init_claude_out" | grep -q "plugin install pandastack" \
  && pass "init --host claude --dry-run includes plugin install" \
  || fail_t "init claude --dry-run missing 'plugin install pandastack'"
echo "$init_claude_out" | grep -qF "$repo_root" \
  && pass "init --host claude --dry-run includes absolute repo path" \
  || fail_t "init claude --dry-run missing absolute repo path"

init_codex_out="$("$PY3" "$CLI" init --host codex --dry-run 2>&1)"
echo "$init_codex_out" | grep -q "\.codex/skills" \
  && pass "init --host codex --dry-run includes .codex/skills" \
  || fail_t "init codex --dry-run missing '.codex/skills'"
echo "$init_codex_out" | grep -qF "$repo_root" \
  && pass "init --host codex --dry-run includes absolute repo path" \
  || fail_t "init codex --dry-run missing absolute repo path"

init_hermes_out="$("$PY3" "$CLI" init --host hermes --dry-run 2>&1)"
echo "$init_hermes_out" | grep -qiE "hermes|pdctx" \
  && pass "init --host hermes --dry-run mentions hermes/pdctx" \
  || fail_t "init hermes --dry-run missing hermes/pdctx mention"

# T05 -- non-dry-run for claude/hermes exits nonzero (no mutation)
for bad_host in claude hermes; do
  if "$PY3" "$CLI" init --host "$bad_host" >/dev/null 2>&1; then
    fail_t "init --host $bad_host without --dry-run should exit nonzero"
  else
    pass "init --host $bad_host without --dry-run exits nonzero (safe)"
  fi
done

# T05 -- non-dry-run never touches ~/.claude or ~/.hermes.
# Use an isolated fake HOME with sentinel files and a portable hash (cksum is
# POSIX; bare `md5` is macOS-only and a missing binary would pass vacuously).
guard_home="$tmp/guard_home"
mkdir -p "$guard_home/.claude" "$guard_home/.hermes"
echo sentinel > "$guard_home/.claude/keep"
echo sentinel > "$guard_home/.hermes/keep"
hash_dir() { find "$1" -type f -exec cksum {} \; 2>/dev/null | sort | cksum; }
for watch_dir in "$guard_home/.claude" "$guard_home/.hermes"; do
  before="$(hash_dir "$watch_dir")"
  HOME="$guard_home" "$PY3" "$CLI" init --host claude >/dev/null 2>&1 || true
  after="$(hash_dir "$watch_dir")"
  [ "$before" = "$after" ] \
    && pass "init --host claude did not mutate $watch_dir" \
    || fail_t "init --host claude mutated $watch_dir"
done

# ---------------------------------------------------------------------------
# T06 -- init --host codex (non-dry-run) is the only fs-mutating path: assert it
# creates a symlink, is idempotent, and fails gracefully on a real-dir target.
# ---------------------------------------------------------------------------
codex_home="$tmp/codex_home"
mkdir -p "$codex_home"
HOME="$codex_home" "$PY3" "$CLI" init --host codex >/dev/null 2>&1
codex_link="$codex_home/.codex/skills/pandastack"
[ -L "$codex_link" ] \
  && pass "init --host codex creates a symlink" \
  || fail_t "init --host codex should create a symlink at $codex_link"

if HOME="$codex_home" "$PY3" "$CLI" init --host codex >/dev/null 2>&1 \
   && [ -L "$codex_link" ]; then
  pass "init --host codex is idempotent (re-run over existing symlink)"
else
  fail_t "init --host codex second run should be idempotent"
fi

# Real (non-symlink) directory at the target: must refuse cleanly, no traceback.
codex_home_dir="$tmp/codex_home_dir"
mkdir -p "$codex_home_dir/.codex/skills/pandastack"
HOME="$codex_home_dir" "$PY3" "$CLI" init --host codex >/dev/null 2>"$tmp/codex_err.txt"
if [ $? -ne 0 ]; then
  pass "init --host codex on real-dir target exits nonzero"
else
  fail_t "init --host codex on real-dir target should exit nonzero"
fi
if grep -q "Traceback" "$tmp/codex_err.txt" 2>/dev/null; then
  fail_t "init --host codex on real-dir target should not print a traceback"
else
  pass "init --host codex on real-dir target shows no traceback"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
[ "$fail" -eq 0 ] && echo "OK: pandastack-cli all green" || echo "FAILURES present"
exit "$fail"
