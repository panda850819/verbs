#!/usr/bin/env bash
# Seeded regression cases for the Verbs living-brand linter.
set -uo pipefail
cd "$(dirname "$0")/.."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
root="$tmp/root"
mkdir -p "$root/scripts"
allow="$root/scripts/living-brand-allowlist.tsv"
: > "$allow"
fail=0

check_pass() {
  local label="$1"
  if VERBS_LIVING_ROOT="$root" VERBS_BRAND_ALLOWLIST="$allow" \
      python3 scripts/lint-living-brand.py >/dev/null; then
    echo "PASS: $label"
  else
    echo "FAIL: $label"
    fail=1
  fi
}

check_fail() {
  local label="$1"
  if VERBS_LIVING_ROOT="$root" VERBS_BRAND_ALLOWLIST="$allow" \
      python3 scripts/lint-living-brand.py >/dev/null; then
    echo "FAIL: $label"
    fail=1
  else
    echo "PASS: $label"
  fi
}

printf '# Verbs\n\nHard-won ways of working.\n' > "$root/README.md"
check_pass "current identity passes"

printf '# Panda Verbs\n' > "$root/README.md"
check_fail "retired display name fails"

printf '# Panda\nVerbs\n' > "$root/README.md"
check_fail "split retired display name fails"

printf 'Clone panda-verbs.\n' > "$root/README.md"
check_fail "retired repository name fails"

printf '# Personal AI operator OS\n' > "$root/README.md"
check_fail "old hero fails"

printf 'Install pandastack@pandastack.\n' > "$root/README.md"
check_fail "old plugin id fails"

printf 'Run /pandastack:review.\n' > "$root/README.md"
check_fail "old namespace fails"

printf 'The pack has 3 documented compositions.\n' > "$root/README.md"
check_fail "retired lifecycle claim fails"

printf '# Verbs\n' > "$root/README.md"
mkdir -p "$root/skills/engineering/ship"
printf '%s\n' '- trigger `/ship knowledge note.md`' > "$root/skills/engineering/ship/eval.md"
check_fail "retired eval route fails"
rm "$root/skills/engineering/ship/eval.md"

printf 'Uninstall pandastack@pandastack during migration.\n' > "$root/README.md"
printf 'README\\.md\tpandastack@pandastack\tv3 migration\n' > "$allow"
check_pass "classified migration exception passes"

[ "$fail" -eq 0 ] && echo "OK: living-brand seeded cases all green"
exit "$fail"
