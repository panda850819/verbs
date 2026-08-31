#!/usr/bin/env bash
# tests/verbs-cli.sh -- Verbs CLI front-door regression tests.
# No network and no real Claude/Codex invocation. Every HOME is isolated.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLI="$repo_root/scripts/verbs"
PY3="$(command -v python3)"
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Keep this suite hermetic even when the host has real Claude/Codex binaries.
fake_cli_bin="$tmp/fake-cli-bin"
mkdir -p "$fake_cli_bin"
cat >"$fake_cli_bin/claude" <<'EOF'
#!/bin/sh
[ "${1:-}" = "--version" ] || exit 64
printf '%s\n' '2.1.220 (Claude Code)'
EOF
cat >"$fake_cli_bin/codex" <<'EOF'
#!/bin/sh
[ "${1:-}" = "--version" ] || exit 64
printf '%s\n' 'codex-cli 0.146.0'
EOF
chmod +x "$fake_cli_bin/claude" "$fake_cli_bin/codex"
export PATH="$fake_cli_bin:$PATH"

pass()   { echo "PASS: $1"; }
fail_t() { echo "FAIL: $1"; fail=1; }

clean_home="$tmp/clean-home"
mkdir -p "$clean_home"

# ---------------------------------------------------------------------------
# T01 -- canonical front door and basic invocations
# ---------------------------------------------------------------------------
if "$PY3" "$CLI" help >/dev/null 2>&1; then
  pass "scripts/verbs help exits 0"
else
  fail_t "scripts/verbs help exits nonzero"
fi

canonical_help="$($PY3 "$CLI" help)"
if [ ! -e "$repo_root/scripts/pandastack" ] \
    && [ ! -L "$repo_root/scripts/pandastack" ]; then
  pass "retired pandastack shim is absent"
else
  fail_t "retired pandastack shim still exists"
fi

if ! "$PY3" "$CLI" notacommand >/dev/null 2>&1; then
  pass "unknown command exits nonzero"
else
  fail_t "unknown command should exit nonzero"
fi

# ---------------------------------------------------------------------------
# T02 -- doctor schema is the narrow Verbs product/install report
# ---------------------------------------------------------------------------
json_out="$(HOME="$clean_home" "$PY3" "$CLI" doctor --json 2>&1)"
if echo "$json_out" | "$PY3" -m json.tool >/dev/null 2>&1; then
  pass "doctor --json is valid JSON"
else
  fail_t "doctor --json is not valid JSON"
fi

echo "$json_out" | "$PY3" -c '
import json, sys
r = json.load(sys.stdin)
assert set(r) == {"schema_version", "product", "repo", "host", "checks"}, set(r)
assert r["schema_version"] == 2
assert set(r["checks"]) == {"manifest", "runtime_surface"}
assert r["product"]["id"] == "verbs"
assert r["product"]["display_name"] == "Verbs"
assert r["product"]["marketplace_id"] == "verbs"
assert r["product"]["repository"] == "panda850819/verbs"
assert r["product"]["environment_prefix"] == "VERBS"
for retired in ("roles", "recommendation", "next_actions", "capabilities_paths"):
    assert retired not in r, retired
assert "substrate" not in r["checks"]
' 2>/dev/null \
  && pass "doctor JSON has only the Verbs product/repo/host/check surface" \
  || fail_t "doctor JSON contains missing or retired fields"

core_count="$(echo "$json_out" | "$PY3" -c \
  "import json,sys; print(json.load(sys.stdin)['checks']['manifest']['skill_counts']['core'])")"
ext_count="$(echo "$json_out" | "$PY3" -c \
  "import json,sys; print(json.load(sys.stdin)['checks']['manifest']['skill_counts']['ext'])")"
total_count="$(echo "$json_out" | "$PY3" -c \
  "import json,sys; print(json.load(sys.stdin)['checks']['manifest']['skill_counts']['total'])")"
manifest_ok="$(echo "$json_out" | "$PY3" -c \
  "import json,sys; print(json.load(sys.stdin)['checks']['manifest']['ok'])")"

[ "$manifest_ok" = "True" ] \
  && pass "manifest.ok=True (manifest and source surface agree)" \
  || fail_t "manifest.ok expected True, got $manifest_ok"
{ [ "$core_count" -gt 0 ] 2>/dev/null; } \
  && pass "manifest skill_counts.core > 0 ($core_count)" \
  || fail_t "manifest skill_counts.core should be > 0, got $core_count"
[ "$total_count" = "$((core_count + ext_count))" ] \
  && pass "manifest total == core + ext ($total_count)" \
  || fail_t "manifest total ($total_count) != core+ext ($core_count+$ext_count)"

# The old internal env name must not be needed by the canonical CLI.
bad_manifest="$tmp/nonexistent-manifest.toml"
if HOME="$clean_home" VERBS_MANIFEST="$bad_manifest" \
    "$PY3" "$CLI" doctor --json >/dev/null 2>"$tmp/manifest.err"; then
  fail_t "missing manifest should exit nonzero"
else
  pass "VERBS_MANIFEST controls the canonical manifest path"
fi
if grep -q "Traceback" "$tmp/manifest.err" 2>/dev/null; then
  fail_t "missing manifest should not print a traceback"
elif grep -qiE "error|not found" "$tmp/manifest.err" 2>/dev/null; then
  pass "missing manifest shows a clear error without traceback"
else
  fail_t "missing manifest should show a clear error"
fi

if HOME="$clean_home" PANDA_VERBS_MANIFEST="$bad_manifest" \
    "$PY3" "$CLI" doctor --json >/dev/null 2>"$tmp/legacy-manifest.err"; then
  fail_t "PANDA_VERBS_MANIFEST fallback should still control the manifest path"
else
  pass "PANDA_VERBS_MANIFEST remains a bounded 0.x fallback"
fi

if HOME="$clean_home" VERBS_MANIFEST="$repo_root/manifest.toml" \
    PANDA_VERBS_MANIFEST="$bad_manifest" "$PY3" "$CLI" doctor --json \
    >/dev/null 2>"$tmp/manifest-precedence.err"; then
  pass "VERBS_MANIFEST wins over the legacy fallback"
else
  fail_t "canonical manifest variable should win over the legacy fallback"
fi

text_out="$(HOME="$clean_home" "$PY3" "$CLI" doctor 2>&1)"
for required in "Verbs doctor" "manifest:" "source registrations:" \
                "claude install:" "codex install:"; do
  if echo "$text_out" | grep -qF "$required"; then
    pass "doctor text contains '$required'"
  else
    fail_t "doctor text missing '$required'"
  fi
done
if echo "$text_out" | grep -qiE "Host runtime|Worker runtime|Operator runtime|Substrate|Recommendation"; then
  fail_t "doctor text should not expose retired roles/substrate/recommendation sections"
else
  pass "doctor text omits retired roles/substrate/recommendation sections"
fi

for retired_flag in --capabilities-json --write-capabilities; do
  if HOME="$clean_home" "$PY3" "$CLI" doctor "$retired_flag" \
      >/dev/null 2>"$tmp/retired-flag.err"; then
    fail_t "doctor should reject retired flag $retired_flag"
  elif grep -q "Traceback" "$tmp/retired-flag.err"; then
    fail_t "retired flag $retired_flag should not print a traceback"
  else
    pass "doctor rejects retired flag $retired_flag"
  fi
done

# ---------------------------------------------------------------------------
# T03 -- report-only host install instructions
# ---------------------------------------------------------------------------
init_claude="$(HOME="$clean_home" "$PY3" "$CLI" init --host claude --dry-run 2>&1)"
for command in \
  "claude plugin validate $repo_root" \
  "claude plugin marketplace add $repo_root --scope user" \
  "claude plugin install verbs@verbs --scope user"; do
  if echo "$init_claude" | grep -qF "$command"; then
    pass "Claude report includes: $command"
  else
    fail_t "Claude report missing: $command"
  fi
done

init_codex="$(HOME="$clean_home" "$PY3" "$CLI" init --host codex --dry-run 2>&1)"
for command in \
  "codex plugin marketplace add $repo_root --json" \
  "codex plugin add verbs@verbs --json"; do
  if echo "$init_codex" | grep -qF "$command"; then
    pass "Codex report includes: $command"
  else
    fail_t "Codex report missing: $command"
  fi
done
if echo "$init_codex" | grep -qF ".codex/skills"; then
  fail_t "Codex report should use the local marketplace, not mutate a skill symlink"
else
  pass "Codex report contains no legacy skill-symlink install"
fi

# Paste-ready commands must remain one shell argument when the checkout path
# contains spaces. Exercise both the Python front door and Bash bootstrap.
space_root="$tmp/panda verbs"
mkdir -p "$space_root/scripts"
cp "$repo_root/manifest.toml" "$space_root/manifest.toml"
cp "$repo_root/scripts/bootstrap.sh" "$space_root/scripts/bootstrap.sh"

VERBS_REPO_ROOT="$space_root" "$PY3" "$CLI" \
  init --host claude --dry-run >"$tmp/spaced-claude.out"
VERBS_REPO_ROOT="$space_root" "$PY3" "$CLI" \
  init --host codex --dry-run >"$tmp/spaced-codex.out"
bash "$space_root/scripts/bootstrap.sh" --claude >"$tmp/spaced-bootstrap.out"

if "$PY3" - "$space_root" "$tmp/spaced-claude.out" \
    "$tmp/spaced-codex.out" "$tmp/spaced-bootstrap.out" <<'PY'
import shlex
import sys
from pathlib import Path

root = sys.argv[1]
roots = {root, str(Path(root).resolve())}
claude, codex, bootstrap = [Path(path).read_text().splitlines() for path in sys.argv[2:]]


def commands(lines):
    parsed = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith(("claude plugin ", "codex plugin ")):
            parsed.append(shlex.split(stripped))
    return parsed


claude_commands = commands(claude)
codex_commands = commands(codex)
bootstrap_commands = commands(bootstrap)
def has_validate(rows):
    return any(row[:3] == ["claude", "plugin", "validate"] and row[3] in roots for row in rows)


def has_claude_add(rows):
    return any(
        row[:4] == ["claude", "plugin", "marketplace", "add"]
        and row[4] in roots and row[5:] == ["--scope", "user"]
        for row in rows
    )


def has_codex_add(rows):
    return any(
        row[:4] == ["codex", "plugin", "marketplace", "add"]
        and row[4] in roots and row[5:] == ["--json"]
        for row in rows
    )


assert has_validate(claude_commands)
assert has_claude_add(claude_commands)
assert has_codex_add(codex_commands)
assert has_validate(bootstrap_commands)
assert has_claude_add(bootstrap_commands)
PY
then
  pass "paste-ready install commands shell-quote checkout paths with spaces"
else
  fail_t "paste-ready install commands split checkout paths with spaces"
fi

if HOME="$clean_home" "$PY3" "$CLI" init --host hermes --dry-run \
    >/dev/null 2>"$tmp/init-hermes-unsupported.err"; then
  fail_t "init --host hermes should be unsupported"
elif grep -q "Traceback" "$tmp/init-hermes-unsupported.err"; then
  fail_t "unsupported Hermes init should not print a traceback"
else
  pass "Hermes is not an init host"
fi

# Every non-dry init path is report-only and leaves HOME tree-for-tree.
guard_home="$tmp/guard-home"
mkdir -p "$guard_home/.claude" "$guard_home/.codex" "$guard_home/.hermes"
echo sentinel >"$guard_home/.claude/keep"
echo sentinel >"$guard_home/.codex/keep"
echo sentinel >"$guard_home/.hermes/keep"
# Warm the Python/CLI startup path before measuring init-specific effects. Some
# hosts create interpreter cache state on the first command under a fresh HOME.
HOME="$guard_home" "$PY3" "$CLI" help >/dev/null 2>&1
baseline_tree="$(find "$guard_home" -mindepth 1 -print \
  | sed "s|^$guard_home/||" | sort)"
baseline_files="$(find "$guard_home" -type f -exec cksum {} \; | sort)"

for host in claude codex; do
  if HOME="$guard_home" "$PY3" "$CLI" init --host "$host" \
      >/dev/null 2>"$tmp/init-$host.err"; then
    fail_t "init --host $host without --dry-run should exit nonzero"
  elif grep -q "Traceback" "$tmp/init-$host.err"; then
    fail_t "init --host $host without --dry-run should not print a traceback"
  else
    pass "init --host $host is report-only"
  fi
  actual_tree="$(find "$guard_home" -mindepth 1 -print \
    | sed "s|^$guard_home/||" | sort)"
  actual_files="$(find "$guard_home" -type f -exec cksum {} \; | sort)"
  if [ "$actual_tree" = "$baseline_tree" ] \
     && [ "$actual_files" = "$baseline_files" ] \
     && grep -qx sentinel "$guard_home/.claude/keep" \
     && grep -qx sentinel "$guard_home/.codex/keep" \
     && grep -qx sentinel "$guard_home/.hermes/keep"; then
    pass "init --host $host did not mutate HOME"
  else
    fail_t "init --host $host mutated HOME"
  fi
done

[ "$fail" -eq 0 ] && echo "OK: verbs-cli all green" || echo "FAILURES present"
exit "$fail"
