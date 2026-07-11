#!/usr/bin/env bash
# Seeded proofs for eval verdict gating. Fixtures live in mktemp skills dirs and
# still use the repo scorecard/hash format, so the test exercises the real lint.
set -uo pipefail
cd "$(dirname "$0")/.."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

scorecard="skills/meta/writing-great-skills/SKILL.md"
scorecard_version="$(sed -n 's/^version:[[:space:]]*//p' "$scorecard" | head -1 | tr -d '"[:space:]')"
expected_rubric="writing-great-skills@$scorecard_version"

fail=0

write_fixture() {
  local root="$1" name="$2" top_verdict="$3" fail_axis="${4:-}" weak_axis="${5:-}"
  local skdir="$root/skills/meta/$name" skill_md hash
  mkdir -p "$skdir"
  skill_md="$skdir/SKILL.md"
  cat >"$skill_md" <<EOF
---
name: $name
description: Fixture skill for verdict lint testing.
---

# $name

This exact current sentence is present.
EOF
  hash="$(git hash-object "$skill_md")"
  cat >"$skdir/eval.md" <<EOF
---
type: skill-eval
skill: $name
bucket: meta
evaluated_skill_hash: $hash
evaluated_at: 2026-07-03
rubric: $expected_rubric
---

# Eval - $name

**Verdict: $top_verdict.** Fixture verdict for lint testing.

| Axis | Verdict | Evidence |
|---|---|---|
EOF
  while IFS= read -r axis; do
    local axis_verdict="pass"
    [ "$axis" = "$fail_axis" ] && axis_verdict="fail"
    [ "$axis" = "$weak_axis" ] && axis_verdict="weak"
    printf '| %s | %s | L7 - fixture evidence. |\n' "$axis" "$axis_verdict" >>"$skdir/eval.md"
  done < <(
    sed -n '/^## The scorecard$/,/^## /p' "$scorecard" |
      sed -n 's/^[0-9][0-9]*\. \*\*\([^*][^*]*\)\*\*.*/\1/p'
  )
}

expect_pass() {
  local label="$1" root="$2" name="$3" log
  log="$tmp/$label.log"
  if env PANDA_VERBS_LINT_SKILLS_DIR="$root/skills" bash scripts/lint-eval-fresh.sh "$name" >"$log" 2>&1; then
    printf 'ok    %s passing verdict passed\n' "$label"
  else
    printf 'FAIL  %s passing verdict failed\n' "$label"
    cat "$log"
    fail=1
  fi
}

expect_fail() {
  local label="$1" root="$2" name="$3" log
  log="$tmp/$label.log"
  if env PANDA_VERBS_LINT_SKILLS_DIR="$root/skills" bash scripts/lint-eval-fresh.sh "$name" >"$log" 2>&1; then
    printf 'FAIL  %s failing verdict unexpectedly passed\n' "$label"
    cat "$log"
    fail=1
  elif grep -q "FAIL: .*${name}.*/eval.md" "$log"; then
    printf 'ok    %s failing verdict failed as expected\n' "$label"
  else
    printf 'FAIL  %s failing verdict did not name the skill\n' "$label"
    cat "$log"
    fail=1
  fi
}

pass_root="$tmp/pass"
write_fixture "$pass_root" verdict-pass SOLID "" "Pruning"
expect_pass top-solid "$pass_root" verdict-pass

all_pass_root="$tmp/all-pass"
write_fixture "$all_pass_root" verdict-all-pass STRONG
expect_fail all-pass "$all_pass_root" verdict-all-pass

weak_root="$tmp/weak"
write_fixture "$weak_root" verdict-weak WEAK
expect_fail top-weak "$weak_root" verdict-weak

axis_root="$tmp/axis"
write_fixture "$axis_root" verdict-axis SOLID "Pruning"
expect_fail axis-fail "$axis_root" verdict-axis

if [ "$fail" -ne 0 ]; then
  echo "lint-eval-verdict-test: one or more seeded checks failed"
  exit 1
fi

echo "lint-eval-verdict-test: all seeded verdict checks behaved as expected"
