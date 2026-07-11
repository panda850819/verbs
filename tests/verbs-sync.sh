#!/usr/bin/env bash
# tests/verbs-sync.sh -- deterministic Panda Verbs loader-generation tests.
# No network and no host invocation. All drift mutations stay in a temp repo.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$repo_root/scripts/verbs"
PY3="$(command -v python3)"
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

pass()   { echo "PASS: $1"; }
fail_t() { echo "FAIL: $1"; fail=1; }

# ---------------------------------------------------------------------------
# S01 -- committed generated documents match the canonical manifest
# ---------------------------------------------------------------------------
if "$PY3" "$CLI" sync --check >/dev/null 2>&1; then
  pass "sync --check passes on the working tree"
else
  fail_t "sync --check should pass (run: scripts/verbs sync)"
fi

# ---------------------------------------------------------------------------
# Isolated fixture: complete [product], three skills, and all four loader docs
# ---------------------------------------------------------------------------
root="$tmp/root"
man="$root/manifest.toml"
mkdir -p "$root/.claude-plugin" "$root/.codex-plugin" \
         "$root/.agents/plugins" "$root/skills/engineering"

cat >"$man" <<'EOF'
[product]
id = "fixture-verbs"
display_name = "Fixture Verbs"
marketplace_id = "fixture-market"
repository = "fixture-owner/fixture-verbs"
homepage = "https://example.test/fixture-verbs"
description = "Fixture software-work description."
hero = "Fixture composable-skills hero."
support = "Fixture host support statement."
category = "Fixture Developer Tools"
archive_prefix = "fixture-verbs"
environment_prefix = "FIXTURE_VERBS"
keywords = ["fixture-skills", "testing"]

[manifest]
version = "9.9.9"

[skill.alpha]
tier = "core"

[skill.beta]
tier = "core"

[skill.gamma]
tier = "ext"
EOF

write_skill() {
  local name="$1"
  mkdir -p "$root/skills/engineering/$name"
  printf '%s\n' '---' "name: $name" 'user-invocable: false' '---' \
    >"$root/skills/engineering/$name/SKILL.md"
}
write_skill alpha
write_skill beta
write_skill gamma

printf '%s\n' '{"sentinel":"claude-plugin"}' >"$root/.claude-plugin/plugin.json"
printf '%s\n' '{"sentinel":"claude-marketplace"}' >"$root/.claude-plugin/marketplace.json"
printf '%s\n' '{"sentinel":"codex-plugin"}' >"$root/.codex-plugin/plugin.json"
printf '%s\n' '{"sentinel":"agents-marketplace"}' >"$root/.agents/plugins/marketplace.json"

run_sync() {
  PANDA_VERBS_REPO_ROOT="$root" \
  PANDA_VERBS_MANIFEST="$man" \
  PANDA_VERBS_SYNC_ROOT="$root" \
    "$PY3" "$CLI" sync "$@"
}

# ---------------------------------------------------------------------------
# S02 -- check reports drift and never mutates any generated document
# ---------------------------------------------------------------------------
if run_sync --check >/dev/null 2>&1; then
  fail_t "sync --check should exit nonzero on drifted four-document fixture"
else
  pass "sync --check detects drift across the four generated loader docs"
fi

if "$PY3" - "$root" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
expected = {
    ".claude-plugin/plugin.json": "claude-plugin",
    ".claude-plugin/marketplace.json": "claude-marketplace",
    ".codex-plugin/plugin.json": "codex-plugin",
    ".agents/plugins/marketplace.json": "agents-marketplace",
}
for relative, sentinel in expected.items():
    assert json.loads((root / relative).read_text())["sentinel"] == sentinel
PY
then
  pass "sync --check did not mutate any generated document"
else
  fail_t "sync --check mutated the fixture"
fi

# ---------------------------------------------------------------------------
# S03 -- apply fully renders identity, repository, hero, category, and skills
# ---------------------------------------------------------------------------
if run_sync >/dev/null 2>&1; then
  pass "sync apply renders all four loader docs"
else
  fail_t "sync apply should exit 0"
fi

if "$PY3" - "$root" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
claude = json.loads((root / ".claude-plugin/plugin.json").read_text())
market = json.loads((root / ".claude-plugin/marketplace.json").read_text())
codex = json.loads((root / ".codex-plugin/plugin.json").read_text())
agents = json.loads((root / ".agents/plugins/marketplace.json").read_text())

description = "Fixture software-work description. Includes 3 composable skills."
homepage = "https://example.test/fixture-verbs"
repository = "https://github.com/fixture-owner/fixture-verbs"
hero = "Fixture composable-skills hero."
paths = [
    "./skills/engineering/alpha",
    "./skills/engineering/beta",
    "./skills/engineering/gamma",
]

assert claude["name"] == "fixture-verbs"
assert claude["version"] == "9.9.9"
assert claude["description"] == description
assert claude["homepage"] == homepage
assert claude["repository"] == repository
assert claude["skills"] == paths

assert market["name"] == "fixture-market"
assert market["description"] == hero
assert market["plugins"][0]["name"] == "fixture-verbs"
assert market["plugins"][0]["description"] == description
assert market["plugins"][0]["homepage"] == homepage
assert market["plugins"][0]["category"] == "development"
assert "version" not in market

assert codex["name"] == "fixture-verbs"
assert codex["version"] == "9.9.9"
assert codex["homepage"] == homepage
assert codex["repository"] == repository
assert codex["interface"]["displayName"] == "Fixture Verbs"
assert codex["interface"]["shortDescription"] == hero
assert codex["interface"]["category"] == "Fixture Developer Tools"

assert agents["name"] == "fixture-market"
assert agents["interface"]["displayName"] == "Fixture Verbs"
assert agents["plugins"][0]["name"] == "fixture-verbs"
assert agents["plugins"][0]["source"] == {"source": "local", "path": "."}
assert agents["plugins"][0]["category"] == "Fixture Developer Tools"
assert "version" not in agents
PY
then
  pass "generated loader docs match product identity/repo/hero/category and skill paths"
else
  fail_t "generated loader docs do not match the complete [product] fixture"
fi

mutate_json() {
  local file="$1" path="$2" value="$3"
  "$PY3" - "$file" "$path" "$value" <<'PY'
import json
import sys

file, dotted, value = sys.argv[1:]
with open(file, encoding="utf-8") as handle:
    data = json.load(handle)
node = data
parts = dotted.split(".")
for part in parts[:-1]:
    node = node[int(part)] if isinstance(node, list) else node[part]
last = parts[-1]
if isinstance(node, list):
    node[int(last)] = value
else:
    node[last] = value
with open(file, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2)
    handle.write("\n")
PY
}

expect_drift() {
  local label="$1" file="$2" path="$3" value="$4"
  mutate_json "$file" "$path" "$value"
  if run_sync --check >/dev/null 2>&1; then
    fail_t "$label drift should fail sync --check"
  else
    pass "$label drift fails sync --check"
  fi
  if ! run_sync >/dev/null 2>&1; then
    fail_t "sync should restore the generated docs after $label drift"
  fi
}

expect_drift "identity" "$root/.claude-plugin/plugin.json" \
  "name" "stale-product-id"
expect_drift "repository" "$root/.codex-plugin/plugin.json" \
  "repository" "https://example.test/stale-repo"
expect_drift "hero" "$root/.claude-plugin/marketplace.json" \
  "description" "stale hero"
expect_drift "category" "$root/.agents/plugins/marketplace.json" \
  "plugins.0.category" "Personal OS"

# ---------------------------------------------------------------------------
# S04 -- restored fixture is clean and re-apply is idempotent
# ---------------------------------------------------------------------------
if run_sync --check >/dev/null 2>&1; then
  pass "sync --check is clean after generator restoration"
else
  fail_t "sync --check should be clean after generator restoration"
fi

reapply="$(run_sync 2>&1)"
case "$reapply" in
  *"already in sync"*) pass "sync re-apply is idempotent" ;;
  *) fail_t "sync re-apply should be a no-op, got: $reapply" ;;
esac

# ---------------------------------------------------------------------------
# S05 -- product contract and manifest version fail clearly
# ---------------------------------------------------------------------------
no_version="$tmp/no-version.toml"
cat >"$no_version" <<'EOF'
[product]
id = "fixture-verbs"
display_name = "Fixture Verbs"
marketplace_id = "fixture-market"
repository = "fixture-owner/fixture-verbs"
homepage = "https://example.test/fixture-verbs"
description = "Fixture software-work description."
hero = "Fixture composable-skills hero."
support = "Fixture host support statement."
category = "Fixture Developer Tools"
archive_prefix = "fixture-verbs"
environment_prefix = "FIXTURE_VERBS"
keywords = ["fixture-skills", "testing"]

[manifest]

[skill.alpha]
tier = "core"
[skill.beta]
tier = "core"
[skill.gamma]
tier = "ext"
EOF

if PANDA_VERBS_REPO_ROOT="$root" PANDA_VERBS_MANIFEST="$no_version" \
   PANDA_VERBS_SYNC_ROOT="$root" "$PY3" "$CLI" sync \
   >/dev/null 2>"$tmp/no-version.err"; then
  fail_t "manifest without a version should exit nonzero"
elif grep -q "Traceback" "$tmp/no-version.err"; then
  fail_t "manifest without a version should not print a traceback"
else
  pass "manifest without a version exits clearly without traceback"
fi

no_product="$tmp/no-product.toml"
cat >"$no_product" <<'EOF'
[manifest]
version = "9.9.9"
[skill.alpha]
tier = "core"
[skill.beta]
tier = "core"
[skill.gamma]
tier = "ext"
EOF

if PANDA_VERBS_REPO_ROOT="$root" PANDA_VERBS_MANIFEST="$no_product" \
   PANDA_VERBS_SYNC_ROOT="$root" "$PY3" "$CLI" sync \
   >/dev/null 2>"$tmp/no-product.err"; then
  fail_t "manifest without [product] should exit nonzero"
elif grep -qF "missing [product]" "$tmp/no-product.err"; then
  pass "manifest without [product] names the missing product contract"
else
  fail_t "manifest without [product] should report the missing product contract"
fi

[ "$fail" -eq 0 ] && echo "OK: verbs-sync all green" || echo "FAILURES present"
exit "$fail"
