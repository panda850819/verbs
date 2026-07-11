#!/usr/bin/env bash
# tests/verbs-sync.sh -- deterministic Verbs loader-generation tests.
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
         "$root/.agents/plugins" "$root/skills/engineering" "$root/lib"
printf '%s\n' '# shared fixture resource' >"$root/lib/shared.md"

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
environment_prefix = "FIXTURE_VERBS"
keywords = ["fixture-skills", "testing"]

[manifest]
version = "9.9.9"

[skill.alpha]
tier = "core"
resources = ["lib/shared.md"]
composes = ["beta"]

[skill.beta]
tier = "core"
resources = []
composes = ["gamma"]

[skill.gamma]
tier = "ext"
resources = []
composes = []
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
mkdir -p "$root/skills/engineering/alpha/lib"
printf '%s\n' '# handwritten local helper' \
  >"$root/skills/engineering/alpha/lib/handwritten.md"

printf '%s\n' '{"sentinel":"claude-plugin"}' >"$root/.claude-plugin/plugin.json"
printf '%s\n' '{"sentinel":"claude-marketplace"}' >"$root/.claude-plugin/marketplace.json"
printf '%s\n' '{"sentinel":"codex-plugin"}' >"$root/.codex-plugin/plugin.json"
printf '%s\n' '{"sentinel":"agents-marketplace"}' >"$root/.agents/plugins/marketplace.json"

run_sync() {
  VERBS_REPO_ROOT="$root" \
  VERBS_MANIFEST="$man" \
  VERBS_SYNC_ROOT="$root" \
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
import stat
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

resource = root / "skills/engineering/alpha/lib/shared.md"
assert resource.read_text() == "# shared fixture resource\n"
resource_index = json.loads(
    (root / "skills/.verbs-resource-index.json").read_text()
)
assert resource_index == {
    "schema": 1,
    "files": ["skills/engineering/alpha/lib/shared.md"],
}
assert stat.S_IMODE(resource.stat().st_mode) == 0o644
assert stat.S_IMODE(
    (root / "skills/.verbs-resource-index.json").stat().st_mode
) == 0o644
PY
then
  pass "generated loaders and skill-local resource match the manifest"
else
  fail_t "generated loaders/resources do not match the complete manifest fixture"
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
# S04 -- resource drift, stale cleanup, composition, and symlink safety
# ---------------------------------------------------------------------------
resource="$root/skills/engineering/alpha/lib/shared.md"
printf '%s\n' 'stale resource bytes' >"$resource"
if run_sync --check >/dev/null 2>&1; then
  fail_t "resource byte drift should fail sync --check"
elif grep -qF 'stale resource bytes' "$resource"; then
  pass "sync --check detects resource byte drift without mutating it"
else
  fail_t "sync --check mutated a drifted resource"
fi
if run_sync >/dev/null 2>&1 && cmp -s "$resource" "$root/lib/shared.md"; then
  pass "sync restores a drifted resource from the canonical source"
else
  fail_t "sync should restore canonical resource bytes"
fi

chmod +x "$resource"
if run_sync --check >/dev/null 2>&1; then
  fail_t "executable generated resource mode should fail sync --check"
elif run_sync >/dev/null 2>&1 && [ ! -x "$resource" ]; then
  pass "sync restores generated resource mode to 0644"
else
  fail_t "sync should restore generated resource mode to 0644"
fi

cp "$man" "$tmp/manifest-with-resource.toml"
"$PY3" - "$man" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = 'resources = ["lib/shared.md"]'
assert text.count(old) == 1
path.write_text(text.replace(old, 'resources = []'))
PY
if run_sync --check >/dev/null 2>&1; then
  fail_t "removing a manifest resource should make sync --check fail"
elif run_sync >/dev/null 2>&1 && [ ! -e "$resource" ]; then
  pass "ordinary sync removes a stale generated resource"
else
  fail_t "ordinary sync should remove the stale generated resource"
fi
cp "$tmp/manifest-with-resource.toml" "$man"
if run_sync >/dev/null 2>&1 && cmp -s "$resource" "$root/lib/shared.md"; then
  pass "sync re-adds a restored manifest resource"
else
  fail_t "sync should re-add a restored manifest resource"
fi

cp "$man" "$tmp/manifest-valid-compose.toml"
"$PY3" - "$man" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = 'composes = ["gamma"]'
assert text.count(old) == 1
path.write_text(text.replace(old, 'composes = ["missing"]'))
PY
if run_sync --check >/dev/null 2>&1; then
  fail_t "missing composed skill should fail sync --check"
else
  pass "sync rejects a missing composed skill"
fi
cp "$tmp/manifest-valid-compose.toml" "$man"

printf '%s\n' '# must never overwrite a skill verdict' >"$root/eval.md"
cp "$man" "$tmp/manifest-no-eval-collision.toml"
"$PY3" - "$man" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = 'resources = ["lib/shared.md"]'
assert text.count(old) == 1
path.write_text(text.replace(old, 'resources = ["eval.md"]'))
PY
if run_sync --check >"$tmp/eval-collision.out" 2>&1; then
  fail_t "eval.md resource collision should fail sync --check"
elif grep -qF 'resource collides with eval.md' "$tmp/eval-collision.out"; then
  pass "sync rejects a resource that would overwrite eval.md"
else
  fail_t "eval.md collision failed without the expected diagnostic"
fi
cp "$tmp/manifest-no-eval-collision.toml" "$man"
rm -f "$root/eval.md"

mv "$root/lib" "$root/lib-real"
ln -s lib-real "$root/lib"
if run_sync --check >/dev/null 2>&1; then
  fail_t "symlinked source parent should fail sync --check"
else
  pass "sync rejects a symlinked source parent"
fi
unlink "$root/lib"
mv "$root/lib-real" "$root/lib"

mv "$root/skills/engineering/alpha/lib" \
   "$root/skills/engineering/alpha/lib-real"
ln -s lib-real "$root/skills/engineering/alpha/lib"
if run_sync --check >/dev/null 2>&1; then
  fail_t "symlinked destination parent should fail sync --check"
else
  pass "sync rejects a symlinked destination parent"
fi
unlink "$root/skills/engineering/alpha/lib"
mv "$root/skills/engineering/alpha/lib-real" \
   "$root/skills/engineering/alpha/lib"

index="$root/skills/.verbs-resource-index.json"
cp "$index" "$tmp/resource-index-clean.json"
"$PY3" - "$index" <<'PY'
import json
from pathlib import Path
import sys

path = Path(sys.argv[1])
data = json.loads(path.read_text())
data["files"].append("skills/engineering/alpha/lib/handwritten.md")
path.write_text(json.dumps(data, indent=2) + "\n")
PY
if run_sync >/dev/null 2>&1; then
  fail_t "poisoned resource index should not authorize local-file deletion"
elif grep -qF '# handwritten local helper' \
  "$root/skills/engineering/alpha/lib/handwritten.md"; then
  pass "poisoned resource index cannot delete a handwritten local helper"
else
  fail_t "poisoned resource index deleted or changed a handwritten helper"
fi
cp "$tmp/resource-index-clean.json" "$index"

# ---------------------------------------------------------------------------
# S05 -- restored fixture is clean and re-apply is idempotent
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
# S06 -- product contract and manifest version fail clearly
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

if VERBS_REPO_ROOT="$root" VERBS_MANIFEST="$no_version" \
   VERBS_SYNC_ROOT="$root" "$PY3" "$CLI" sync \
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

if VERBS_REPO_ROOT="$root" VERBS_MANIFEST="$no_product" \
   VERBS_SYNC_ROOT="$root" "$PY3" "$CLI" sync \
   >/dev/null 2>"$tmp/no-product.err"; then
  fail_t "manifest without [product] should exit nonzero"
elif grep -qF "missing [product]" "$tmp/no-product.err"; then
  pass "manifest without [product] names the missing product contract"
else
  fail_t "manifest without [product] should report the missing product contract"
fi

[ "$fail" -eq 0 ] && echo "OK: verbs-sync all green" || echo "FAILURES present"
exit "$fail"
