#!/usr/bin/env bash
# tests/pandastack-sync.sh -- `pandastack sync` derived-manifest generator tests.
# No network, no real Claude/Codex invocation. Drift cases run against an
# isolated temp root (PANDASTACK_SYNC_ROOT + PANDASTACK_MANIFEST) so the real
# repo files are never mutated. Pass/fail is keyed on exit code + parsed JSON,
# never on stderr text.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$repo_root/scripts/pandastack"
PY3="$(command -v python3)"
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

pass()   { echo "PASS: $1"; }
fail_t() { echo "FAIL: $1"; fail=1; }

# ---------------------------------------------------------------------------
# S01 -- the committed repo is in sync (the gate lint-manifest-sync relies on)
# ---------------------------------------------------------------------------
if "$PY3" "$CLI" sync --check >/dev/null 2>&1; then
  pass "sync --check passes on the committed repo"
else
  fail_t "sync --check should pass on the committed repo (run: scripts/pandastack sync)"
fi

# ---------------------------------------------------------------------------
# Isolated fixture: a temp manifest (version 9.9.9, 3 skills) + 3 drifted
# loader files under a temp sync root.
# ---------------------------------------------------------------------------
man="$tmp/manifest.toml"
cat > "$man" <<'EOF'
[manifest]
version = "9.9.9"

[skill.alpha]
tier = "core"

[skill.beta]
tier = "core"

[skill.gamma]
tier = "ext"
EOF

root="$tmp/root"
mkdir -p "$root/.claude-plugin" "$root/.codex-plugin"
printf '%s\n' '{"name":"x","version":"0.0.0","description":"OS with 99 skills in buckets"}' \
  > "$root/.claude-plugin/plugin.json"
printf '%s\n' '{"name":"x","version":"1.1.1","description":"stack with 25 skills, tiered"}' \
  > "$root/.codex-plugin/plugin.json"
printf '%s\n' '{"name":"m","plugins":[{"description":"7 skills in buckets"}]}' \
  > "$root/.claude-plugin/marketplace.json"

run_sync() { PANDASTACK_MANIFEST="$man" PANDASTACK_SYNC_ROOT="$root" "$PY3" "$CLI" sync "$@"; }
jq_field() { "$PY3" -c "import json,sys; print(json.load(open(sys.argv[1]))$2)" "$1"; }

# ---------------------------------------------------------------------------
# S02 -- --check reports drift (nonzero) before any write
# ---------------------------------------------------------------------------
if run_sync --check >/dev/null 2>&1; then
  fail_t "sync --check should exit nonzero on drifted fixture"
else
  pass "sync --check exits nonzero on drift"
fi
# --check must not mutate
if [ "$(jq_field "$root/.codex-plugin/plugin.json" "['version']")" = "1.1.1" ]; then
  pass "sync --check did not mutate the fixture"
else
  fail_t "sync --check must not write"
fi

# ---------------------------------------------------------------------------
# S03 -- apply rewrites version + count from the manifest
# ---------------------------------------------------------------------------
if run_sync >/dev/null 2>&1; then
  pass "sync (apply) exits 0"
else
  fail_t "sync (apply) should exit 0"
fi

cl_ver="$(jq_field "$root/.claude-plugin/plugin.json" "['version']")"
cx_ver="$(jq_field "$root/.codex-plugin/plugin.json" "['version']")"
[ "$cl_ver" = "9.9.9" ] && [ "$cx_ver" = "9.9.9" ] \
  && pass "version synced to manifest (9.9.9) in both plugin.json" \
  || fail_t "version not synced: claude=$cl_ver codex=$cx_ver"

cl_desc="$(jq_field "$root/.claude-plugin/plugin.json" "['description']")"
cx_desc="$(jq_field "$root/.codex-plugin/plugin.json" "['description']")"
mp_desc="$(jq_field "$root/.claude-plugin/marketplace.json" "['plugins'][0]['description']")"
case "$cl_desc$cx_desc$mp_desc" in
  *"99 skills"*|*"25 skills"*|*"7 skills"*) fail_t "stale count survived: cl=$cl_desc cx=$cx_desc mp=$mp_desc" ;;
  *"3 skills"*"3 skills"*"3 skills"*)       pass "skill count synced to 3 across all three files" ;;
  *) fail_t "unexpected descriptions: cl=$cl_desc cx=$cx_desc mp=$mp_desc" ;;
esac

# marketplace.json has no version key; sync must not invent one
if "$PY3" -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if 'version' not in d else 1)" \
     "$root/.claude-plugin/marketplace.json"; then
  pass "sync did not add a version key to marketplace.json"
else
  fail_t "sync should not add a version key to marketplace.json"
fi

# ---------------------------------------------------------------------------
# S04 -- after apply, --check is clean and a re-apply is a no-op
# ---------------------------------------------------------------------------
if run_sync --check >/dev/null 2>&1; then
  pass "sync --check clean after apply"
else
  fail_t "sync --check should be clean after apply"
fi

reapply="$(run_sync 2>&1)"
case "$reapply" in
  *"already in sync"*) pass "re-apply is a no-op (idempotent)" ;;
  *) fail_t "re-apply should report already in sync, got: $reapply" ;;
esac

# ---------------------------------------------------------------------------
# S05 -- a manifest with no version exits nonzero, no traceback
# ---------------------------------------------------------------------------
nover="$tmp/noversion.toml"
printf '%s\n' '[skill.alpha]' 'tier = "core"' > "$nover"
if PANDASTACK_MANIFEST="$nover" PANDASTACK_SYNC_ROOT="$root" "$PY3" "$CLI" sync \
     >/dev/null 2>"$tmp/nover_err.txt"; then
  fail_t "sync with no manifest version should exit nonzero"
else
  pass "sync with no manifest version exits nonzero"
fi
if grep -q "Traceback" "$tmp/nover_err.txt" 2>/dev/null; then
  fail_t "no-version manifest should not print a traceback"
else
  pass "no-version manifest shows no traceback"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
[ "$fail" -eq 0 ] && echo "OK: pandastack-sync all green" || echo "FAILURES present"
exit "$fail"
