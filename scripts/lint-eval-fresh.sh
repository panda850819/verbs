#!/usr/bin/env bash
# lint-eval-fresh.sh — every skill must carry an eval.md, and that eval.md must
# have been generated against the CURRENT SKILL.md. Each eval.md records the
# git blob hash of the SKILL.md it scored (evaluated_skill_hash); this lint
# recomputes the hash and fails on missing or drifted evals. Turns per-skill
# eval files from silent sediment into a caught, fixable signal.
#
# Usage:
#   bash scripts/lint-eval-fresh.sh           # check every skill
#   bash scripts/lint-eval-fresh.sh <name>    # check one skill (exit 0/1)
#
# Skills live at skills/<bucket>/<skill>/. Fix a failure with /skill-eval <name>.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="${PANDASTACK_LINT_SKILLS_DIR:-$repo_root/skills}"
only="${1:-}"
scorecard="$repo_root/skills/meta/writing-great-skills/SKILL.md"
scorecard_version="$(sed -n 's/^version:[[:space:]]*//p' "$scorecard" | head -1 | tr -d '"[:space:]')"
expected_rubric="writing-great-skills@$scorecard_version"
scorecard_axes=()
while IFS= read -r axis; do
  scorecard_axes+=("$axis")
done < <(
  sed -n '/^## The scorecard$/,/^## /p' "$scorecard" |
    sed -n 's/^[0-9][0-9]*\. \*\*\([^*][^*]*\)\*\*.*/\1/p'
)

fail=0
checked=0
allowlisted=0
allowlist_summary=""

verdict_allowlist_reason() {
  case "$1" in
    skills/engineering/deepwiki)
      echo "pre-existing WEAK eval before issue #155; follow-up: prune and re-evaluate deepwiki"
      return 0
      ;;
  esac
  return 1
}

allowlist_or_fail() {
  local rel="$1" message="$2" reason
  if reason="$(verdict_allowlist_reason "${rel%/}")"; then
    echo "ALLOWLIST: $rel/eval.md $message — $reason"
    allowlisted=$((allowlisted + 1))
    allowlist_summary="${allowlist_summary}${rel%/} — ${reason}
"
  else
    echo "FAIL: $rel/eval.md $message"
    fail=1
  fi
}

while IFS= read -r skdir; do
  [ -n "$skdir" ] || continue
  name="$(basename "$skdir")"
  [ -z "$only" ] || [ "$name" = "$only" ] || continue
  checked=$((checked + 1))

  skill_md="$skdir/SKILL.md"
  eval_md="$skdir/eval.md"
  case "$skdir" in
    "$repo_root"/*) rel="${skdir#"$repo_root"/}" ;;
    *) rel="$skdir" ;;
  esac

  if [ ! -f "$eval_md" ]; then
    echo "FAIL: $rel/ has no eval.md  (run: /skill-eval $name)"
    fail=1
    continue
  fi

  current="$(git -C "$repo_root" hash-object "$skill_md")"
  recorded="$(sed -n 's/^evaluated_skill_hash:[[:space:]]*//p' "$eval_md" | head -1 | tr -d '[:space:]')"
  rubric="$(sed -n 's/^rubric:[[:space:]]*//p' "$eval_md" | head -1 | tr -d '[:space:]')"
  verdict="$(sed -n 's/^\*\*Verdict:[[:space:]]*\([A-Z][A-Z]*\)\..*/\1/p' "$eval_md" | head -1)"

  if [ -z "$recorded" ]; then
    echo "FAIL: $rel/eval.md missing evaluated_skill_hash"
    fail=1
  elif [ "$current" != "$recorded" ]; then
    echo "FAIL: $rel/ eval is stale — SKILL.md changed since eval (run: /skill-eval $name)"
    echo "       SKILL.md=$current  eval=$recorded"
    fail=1
  fi

  if [ -z "$rubric" ]; then
    echo "FAIL: $rel/eval.md missing rubric"
    fail=1
  elif [ "$rubric" != "$expected_rubric" ]; then
    echo "FAIL: $rel/eval.md rubric is stale — expected $expected_rubric, found $rubric"
    fail=1
  fi

  if [ -z "$verdict" ]; then
    allowlist_or_fail "$rel" "missing top-level verdict"
  elif [ "$verdict" = "WEAK" ]; then
    allowlist_or_fail "$rel" "has failing verdict: WEAK"
  elif [ "$verdict" != "STRONG" ] && [ "$verdict" != "SOLID" ]; then
    allowlist_or_fail "$rel" "has unknown verdict: $verdict"
  fi

  axis_fails="$(
    awk -F '|' '
      $0 ~ /^\|/ {
        gsub(/^[ \t]+|[ \t]+$/, "", $2)
        gsub(/^[ \t]+|[ \t]+$/, "", $3)
        if ($3 == "fail") print $2
      }
    ' "$eval_md"
  )"
  if [ -n "$axis_fails" ]; then
    while IFS= read -r axis; do
      [ -n "$axis" ] || continue
      allowlist_or_fail "$rel" "has failing axis verdict: $axis"
    done <<< "$axis_fails"
  fi

  for axis in "${scorecard_axes[@]}"; do
    if ! grep -Fq "| $axis |" "$eval_md"; then
      echo "FAIL: $rel/eval.md missing scorecard axis: $axis"
      fail=1
    fi
  done
done <<< "$(find "$skills_dir" -mindepth 2 -maxdepth 2 -type d ! -path '*/.archive/*' ! -path '*/_deprecated/*' | sort)"

if [ -n "$only" ] && [ "$checked" -eq 0 ]; then
  echo "FAIL: no skill named '$only' under skills/"
  exit 1
fi

# A skills dir that resolves to zero skills (typo'd PANDASTACK_LINT_SKILLS_DIR,
# deleted fixture) must never produce a green gate.
if [ "$checked" -eq 0 ]; then
  echo "FAIL: no skills found under $skills_dir — refusing to pass an empty gate"
  exit 1
fi

if [ "$fail" -eq 0 ]; then
  echo "OK: all $checked skill eval(s) fresh (hash + $expected_rubric axes match current scorecard)."
  if [ "$allowlisted" -ne 0 ]; then
    echo "FOLLOW-UP: $allowlisted eval verdict allowlist item(s):"
    printf '%s' "$allowlist_summary" | sed '/^$/d; s/^/FOLLOW-UP: /'
  fi
fi
exit "$fail"
