#!/usr/bin/env bash
# Structural guard for the real installer smoke. This is not installer proof;
# release evidence comes only from executing scripts/installer-smoke.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

script="scripts/installer-smoke.sh"
bash -n "$script"
bash -n scripts/conformance-smoke.sh
python3 -c 'compile(open("scripts/codex-hook-smoke.py", encoding="utf-8").read(), "scripts/codex-hook-smoke.py", "exec")'

grep -Fq 'claude_cmd plugin marketplace add "$source" --scope user' "$script"
grep -Fq 'claude_cmd plugin install verbs@verbs --scope user' "$script"
grep -Fq 'install_claude_source "$source_root" "$source_version"' "$script"
grep -Fq 'codex_cmd plugin marketplace add "$source" --json' "$script"
grep -Fq 'codex_cmd plugin add verbs@verbs --json' "$script"
grep -Fq 'install_codex_source "$source_root" "$source_version"' "$script"
grep -Fq 'VERBS_SMOKE_EXPECT_HOME="$profile"' "$script"
grep -Fq 'describe --tags --exact-match HEAD' "$script"
grep -Fq 'rm -f "$profile/.codex/auth.json"' "$script"
grep -Fq "trap 'exit 130' INT" "$script"
grep -Fq -- '--setting-sources project,local' "$script"
grep -Fq -- '--output-format stream-json --verbose' "$script"
grep -Fq 'tool_use_result' "$script"
grep -Fq 'require_exact_checkout "$baseline_root" v0.5.0' "$script"
grep -Fq 'require_exact_checkout "$source_root" v0.6.0' "$script"
grep -Fq 'tag $required_tag does not match manifest version $version' "$script"

# Upgrade/rollback proof must use one disposable profile, official host
# uninstall/reinstall commands, and the exact source versions at each phase.
grep -Fq 'claude_cmd plugin uninstall verbs@verbs --scope user' "$script"
grep -Fq 'claude_cmd plugin marketplace remove verbs --scope user' "$script"
grep -Fq 'codex_cmd plugin remove verbs@verbs --json' "$script"
grep -Fq 'codex_cmd plugin marketplace remove verbs --json' "$script"
grep -Fq 'expected 0.5.0' "$script"
grep -Fq 'expected 0.6.0' "$script"
grep -Fq 'same-profile v0.5.0 -> v0.6.0 -> v0.5.0 cycle passed' "$script"

# The v0.6 phase executes every registered hook from the installed cache.
grep -Fq 'VERBS_HOOK_ROOT="$INSTALLED_PATH"' "$script"
grep -Fq 'bash "$source/tests/plugin-hooks-test.sh"' "$script"
grep -Fq 'claude_cmd plugin details verbs@verbs' "$script"
grep -Fq "grep -Fq 'Hooks (3)'" "$script"
grep -Fq 'for event in SessionStart PreToolUse Stop; do' "$script"
grep -Fq 'python3 "$source/scripts/codex-hook-smoke.py" "$profile" "$INSTALLED_PATH"' "$script"
grep -Fq 'verify_rollback_hooks_absent' "$script"
grep -Fq -- '--expect-none "$profile"' "$script"
grep -Fq 'HOME="$profile" CODEX_HOME="$profile/.codex"' "$script"
grep -Fq -- '--skip-git-repo-check' scripts/conformance-smoke.sh

python3 - "$script" <<'PY'
import sys

text = open(sys.argv[1], encoding="utf-8").read()
assert text.count('profile="$(mktemp -d ') == 1
for host in ("claude", "codex"):
    markers = [
        f'INFO [{host}]: phase 1 install v0.5.0',
        f'INFO [{host}]: phase 2 reinstall v0.6.0',
        f'INFO [{host}]: phase 3 rollback v0.5.0',
    ]
    positions = [text.index(marker) for marker in markers]
    assert positions == sorted(positions), (host, positions)
PY

tmp="$(mktemp -d "${TMPDIR:-/tmp}/verbs-installer-identity.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

make_checkout() {
  local root="$1" version="$2" tag="$3"
  mkdir -p "$root/scripts" "$root/tests" "$root/hooks"
  git -C "$root" init -q
  git -C "$root" config user.name "Verbs Test"
  git -C "$root" config user.email "verbs-test@example.invalid"
  printf '[manifest]\nversion = "%s"\n' "$version" >"$root/manifest.toml"
  cat >"$root/scripts/conformance-smoke.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd -P)"
version="$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$root/manifest.toml")"
config="${CLAUDE_CONFIG_DIR:-${CODEX_HOME:-}}"
printf 'conformance:%s|%s|%s\n' "$version" "$HOME" "$config" \
  >>"$VERBS_TEST_LOG"
SH
  cat >"$root/tests/plugin-hooks-test.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd -P)"
version="$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$root/manifest.toml")"
[ -f "$VERBS_HOOK_ROOT/hooks/hooks.json" ]
config="${CLAUDE_CONFIG_DIR:-${CODEX_HOME:-}}"
printf 'hooks:%s|%s|%s\n' "$version" "$HOME" "$config" \
  >>"$VERBS_TEST_LOG"
SH
  cat >"$root/scripts/codex-hook-smoke.py" <<'PY'
#!/usr/bin/env python3
import os
from pathlib import Path
import sys

root = Path(__file__).resolve().parent.parent
version = next(
    line.split('"')[1]
    for line in (root / "manifest.toml").read_text(encoding="utf-8").splitlines()
    if line.startswith("version = ")
)
operation = "codex-hooks-none" if "--expect-none" in sys.argv else "codex-hooks-present"
with open(os.environ["VERBS_TEST_LOG"], "a", encoding="utf-8") as handle:
    handle.write("{}:{}|{}|{}\n".format(
        operation, version, os.environ["HOME"], os.environ["CODEX_HOME"]))
PY
  chmod +x "$root/scripts/conformance-smoke.sh" "$root/tests/plugin-hooks-test.sh"
  if [ "$version" = 0.6.0 ]; then
    printf '{"hooks":{}}\n' >"$root/hooks/hooks.json"
  fi
  git -C "$root" add .
  git -C "$root" commit -qm fixture
  git -C "$root" tag -a "$tag" -m "$tag"
}

make_checkout "$tmp/fresh-mismatch" 9.9.9 v0.6.0
if bash "$script" claude "$tmp/fresh-mismatch" v0.6.0 >/dev/null 2>&1; then
  echo "FAIL: fresh smoke accepted a tag/manifest mismatch" >&2
  exit 1
fi

make_checkout "$tmp/fresh-dirty" 0.6.0 v0.6.0
printf 'dirty\n' >"$tmp/fresh-dirty/untracked.txt"
if bash "$script" claude "$tmp/fresh-dirty" v0.6.0 >/dev/null 2>&1; then
  echo "FAIL: fresh smoke accepted a dirty exact-tag checkout" >&2
  exit 1
fi

make_checkout "$tmp/baseline-wrong" 0.5.0 v0.5.1
make_checkout "$tmp/target-good" 0.6.0 v0.6.0
if bash "$script" claude --upgrade "$tmp/baseline-wrong" "$tmp/target-good" \
    >/dev/null 2>&1; then
  echo "FAIL: upgrade smoke accepted a non-v0.5.0 baseline" >&2
  exit 1
fi

make_checkout "$tmp/baseline-good" 0.5.0 v0.5.0
make_checkout "$tmp/target-wrong" 0.6.0 v0.6.1
if bash "$script" codex --upgrade "$tmp/baseline-good" "$tmp/target-wrong" \
    >/dev/null 2>&1; then
  echo "FAIL: upgrade smoke accepted a non-v0.6.0 target" >&2
  exit 1
fi

mkdir -p "$tmp/fake-bin"
cat >"$tmp/fake-bin/claude" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

record() {
  printf '%s|%s|%s\n' "$1" "$HOME" "${CLAUDE_CONFIG_DIR:-}" \
    >>"$VERBS_TEST_LOG"
}

source_root() {
  cat "$VERBS_TEST_STATE"
}

source_version() {
  sed -n 's/^version = "\([^"]*\)"/\1/p' "$(source_root)/manifest.toml"
}

if [ "$1" = plugin ] && [ "$2" = validate ]; then
  record validate
elif [ "$1" = plugin ] && [ "$2" = marketplace ] && [ "$3" = add ]; then
  printf '%s\n' "$4" >"$VERBS_TEST_STATE"
  record marketplace-add
elif [ "$1" = plugin ] && [ "$2" = install ]; then
  version="$(source_version)"
  dest="$CLAUDE_CONFIG_DIR/plugins/cache/verbs/verbs/$version"
  mkdir -p "$dest/hooks"
  if [ -f "$(source_root)/hooks/hooks.json" ]; then
    cp "$(source_root)/hooks/hooks.json" "$dest/hooks/hooks.json"
  fi
  record "install:$version"
elif [ "$1" = plugin ] && [ "$2" = list ]; then
  version="$(source_version)"
  dest="$CLAUDE_CONFIG_DIR/plugins/cache/verbs/verbs/$version"
  printf '[{"id":"verbs@verbs","version":"%s","enabled":true,"installPath":"%s"}]\n' \
    "$version" "$dest"
  record "list:$version"
elif [ "$1" = plugin ] && [ "$2" = details ]; then
  version="$(source_version)"
  if [ "$version" = 0.6.0 ]; then
    printf 'Hooks (3) SessionStart PreToolUse Stop\n'
  else
    printf 'Hooks (0)\n'
  fi
  record "details:$version"
elif [ "$1" = plugin ] && [ "$2" = uninstall ]; then
  record uninstall
elif [ "$1" = plugin ] && [ "$2" = marketplace ] && [ "$3" = remove ]; then
  record marketplace-remove
else
  echo "unexpected fake Claude command: $*" >&2
  exit 1
fi
SH
chmod +x "$tmp/fake-bin/claude"

trace="$tmp/upgrade-trace.log"
state="$tmp/claude-source"
PATH="$tmp/fake-bin:$PATH" VERBS_TEST_LOG="$trace" VERBS_TEST_STATE="$state" \
  bash "$script" claude --upgrade "$tmp/baseline-good" "$tmp/target-good" \
  >/dev/null

python3 - "$trace" <<'PY'
import sys

rows = [line.rstrip("\n").split("|") for line in open(sys.argv[1], encoding="utf-8")]
assert rows and all(len(row) == 3 for row in rows), rows
homes = {row[1] for row in rows}
configs = {row[2] for row in rows}
assert len(homes) == 1, homes
home = next(iter(homes))
assert configs == {home + "/.claude"}, configs
operations = [row[0] for row in rows]
expected = [
    "validate", "marketplace-add", "install:0.5.0", "list:0.5.0",
    "conformance:0.5.0", "uninstall", "marketplace-remove", "validate",
    "marketplace-add", "install:0.6.0", "list:0.6.0",
    "conformance:0.6.0", "hooks:0.6.0", "details:0.6.0", "uninstall",
    "marketplace-remove", "validate", "marketplace-add", "install:0.5.0",
    "list:0.5.0", "conformance:0.5.0", "details:0.5.0",
]
assert operations == expected, (operations, expected)
PY

cat >"$tmp/fake-bin/codex" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

record() {
  printf '%s|%s|%s\n' "$1" "$HOME" "${CODEX_HOME:-}" \
    >>"$VERBS_TEST_LOG"
}

source_root() {
  cat "$VERBS_TEST_STATE"
}

source_version() {
  sed -n 's/^version = "\([^"]*\)"/\1/p' "$(source_root)/manifest.toml"
}

if [ "$1" = plugin ] && [ "$2" = marketplace ] && [ "$3" = add ]; then
  printf '%s\n' "$4" >"$VERBS_TEST_STATE"
  record marketplace-add
elif [ "$1" = plugin ] && [ "$2" = add ]; then
  version="$(source_version)"
  dest="$CODEX_HOME/plugins/cache/verbs/verbs/$version"
  mkdir -p "$dest/hooks"
  if [ -f "$(source_root)/hooks/hooks.json" ]; then
    cp "$(source_root)/hooks/hooks.json" "$dest/hooks/hooks.json"
  fi
  printf '{"pluginId":"verbs@verbs","version":"%s","installedPath":"%s"}\n' \
    "$version" "$dest"
  record "install:$version"
elif [ "$1" = plugin ] && [ "$2" = remove ]; then
  record plugin-remove
  printf '{}\n'
elif [ "$1" = plugin ] && [ "$2" = marketplace ] && [ "$3" = remove ]; then
  record marketplace-remove
  printf '{}\n'
else
  echo "unexpected fake Codex command: $*" >&2
  exit 1
fi
SH
chmod +x "$tmp/fake-bin/codex"

trace="$tmp/codex-upgrade-trace.log"
state="$tmp/codex-source"
PATH="$tmp/fake-bin:$PATH" OPENAI_API_KEY= CLAUDE_CONFIG_DIR= \
  CODEX_HOME="$tmp/no-auth-codex" VERBS_TEST_LOG="$trace" \
  VERBS_TEST_STATE="$state" \
  bash "$script" codex --upgrade "$tmp/baseline-good" "$tmp/target-good" \
  >/dev/null

python3 - "$trace" <<'PY'
import sys

rows = [line.rstrip("\n").split("|") for line in open(sys.argv[1], encoding="utf-8")]
assert rows and all(len(row) == 3 for row in rows), rows
homes = {row[1] for row in rows}
configs = {row[2] for row in rows}
assert len(homes) == 1, homes
home = next(iter(homes))
assert configs == {home + "/.codex"}, configs
operations = [row[0] for row in rows]
expected = [
    "marketplace-add", "install:0.5.0", "conformance:0.5.0",
    "plugin-remove", "marketplace-remove", "marketplace-add",
    "install:0.6.0", "conformance:0.6.0", "hooks:0.6.0",
    "codex-hooks-present:0.6.0", "plugin-remove", "marketplace-remove",
    "marketplace-add", "install:0.5.0", "conformance:0.5.0",
    "codex-hooks-none:0.6.0",
]
assert operations == expected, (operations, expected)
PY

if grep -Eq 'cp .*(plugins/cache|installed_plugins|config\.toml)|installed_plugins\.json.*>|config\.toml.*>' "$script"; then
  echo "FAIL: installer smoke must not synthesize cache or receipt state" >&2
  exit 1
fi

echo "OK: installer smoke uses official host commands and no synthetic receipts"
