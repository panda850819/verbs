#!/usr/bin/env bash
# spike-88-repro.sh — evidence bundle + live-check plan for the Fork B inverted spike (#88).
#
# Inverted layout: real skills stay flat in plugins/pandastack/skills/<name>/ (untouched);
# a browsable category tree is additive symlinks plugins/pandastack/skills-cat/<cat>/<name>
#   -> ../../skills/<name>.
#
# Default mode (no args) is DRY / read-only: it runs every check that does NOT mutate global
# install state, and prints the exact manual steps + global paths for the one irreducibly-live
# check (Claude discovery scope). Nothing here writes outside this repo worktree.
#
# Usage:
#   bash scripts/spike-88-repro.sh            # dry/read-only evidence bundle + live plan
#   bash scripts/spike-88-repro.sh --codex    # ALSO run the isolated Codex live check (needs codex CLI)
#
# It never touches ~/.claude or ~/.codex. The --codex path uses a throwaway temp dir only.

set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="$repo_root/plugins/pandastack"
skill="sprint"            # spike skill
cat_dir="doing"          # its category
pass=0; fail=0
ok(){ echo "  PASS: $1"; pass=$((pass+1)); }
no(){ echo "  FAIL: $1"; fail=$((fail+1)); }

echo "== Fork B inverted spike #88 — evidence bundle (read-only) =="

echo "[1] layout: real skill flat + category symlink view"
[ -f "$plugin/skills/$skill/SKILL.md" ] && [ ! -L "$plugin/skills/$skill" ] \
  && ok "skills/$skill is a real dir (untouched)" || no "skills/$skill not a real dir"
[ -L "$plugin/skills-cat/$cat_dir/$skill" ] \
  && ok "skills-cat/$cat_dir/$skill is a symlink" || no "skills-cat view missing"

echo "[2] relative-path contract via the category view"
[ -f "$plugin/skills-cat/$cat_dir/$skill/SKILL.md" ] \
  && ok "SKILL.md readable through view" || no "SKILL.md not readable through view"
sub="$(find -L "$plugin/skills-cat/$cat_dir/$skill" -type f -name '*.md' ! -name SKILL.md | head -1)"
[ -n "$sub" ] && ok "sub-file readable through view ($(basename "$sub"))" || no "no sub-file via view"
# ../../lib resolves from the REAL flat path (unchanged baseline)
libref="$(grep -rhoE '\.\./\.\./lib/[a-z0-9-]+\.md' "$plugin/skills/$skill/SKILL.md" | head -1 || true)"
if [ -n "$libref" ]; then
  [ -f "$plugin/skills/$skill/$libref" ] \
    && ok "../../lib ref resolves from real flat path ($libref)" || no "../../lib ref broken"
else echo "  (note: $skill has no ../../lib ref; 10/26 skills do — inverted keeps them flat → safe)"; fi

echo "[3] lint + hook (inverted needs NO lint change)"
bash "$repo_root/scripts/lint-manifest-sync.sh" >/dev/null 2>&1 && ok "lint-manifest-sync green" || no "lint failed"
bash "$repo_root/scripts/conformance-smoke.sh" hook >/dev/null 2>&1 && ok "conformance-smoke hook PASS" || no "hook failed"

echo "[4] distribution: symlink view survives the artifact path"
tmp="$(mktemp -d)"
git -C "$repo_root" archive --format=tar HEAD plugins/pandastack/skills-cat | tar -xf - -C "$tmp" 2>/dev/null || true
[ -L "$tmp/plugins/pandastack/skills-cat/$cat_dir/$skill" ] \
  && ok "git archive preserves the category symlink" || echo "  (note: symlink not in archive — commit skills-cat first)"

echo "[5] double-load risk characterization (static)"
direct=$(find "$plugin/skills" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) -name "$skill" | wc -l | tr -d ' ')
recursive=$(find -L "$plugin" -name SKILL.md -path "*/$skill/*" 2>/dev/null | wc -l | tr -d ' ')
echo "  - 'skills/<name>' (Claude convention + Codex bootstrap symlinks skills/ only): $skill seen ${direct}x → no double-load"
echo "  - whole-plugin recursive '<plugin>/**/SKILL.md': $skill seen ${recursive}x (skills/ + skills-cat/ via symlink) → WOULD double-load"
echo "  - Codex: bootstrap symlinks plugins/pandastack/skills (NOT the plugin root) → skills-cat invisible → no double-load by design"
echo "  - Claude #1 'discovers sprint': TRUE by status quo (skills/sprint untouched, loads today)"

echo
echo "== ONE irreducibly-live question (needs a real Claude reload; cannot self-test from a running session) =="
echo "  Q: does Claude Code plugin discovery scan ONLY <plugin>/skills/* (clean) or the whole plugin"
echo "     recursively (would also load skills-cat/.../SKILL.md via symlink → duplicate)?"
echo "  Manual repro (touches global state — listed explicitly, run by Panda or a fresh session):"
echo "   1. Make this branch the active plugin source. Global path involved:"
echo "        ~/.claude/plugins/cache/pandastack/pandastack/<ver>/   (or point the directory marketplace at this worktree)"
echo "   2. Start a fresh Claude session; check the skill list for 'pandastack:sprint'."
echo "        PASS = appears exactly once.  FAIL = appears twice (double-load) → fix: move skills-cat"
echo "        outside the discovered root, or add a discovery ignore."
echo "  If discovery is whole-plugin-recursive, the fix is cheap and local; it does not change the B1 verdict."

if [ "${1:-}" = "--codex" ]; then
  echo
  echo "== --codex: isolated Codex live check (throwaway temp HOME, no ~/.codex mutation) =="
  if ! command -v codex >/dev/null 2>&1; then echo "  SKIP: codex CLI not found"; else
    th="$(mktemp -d)"; mkdir -p "$th/.codex/skills"
    ln -s "$plugin/skills" "$th/.codex/skills/pandastack"
    echo "  temp HOME=$th ; codex skills -> worktree skills/ (skills-cat NOT linked = matches bootstrap design)"
    out="$(HOME="$th" codex exec --skip-git-repo-check 'List your available skills names, one per line.' 2>&1 || true)"
    n=$(printf '%s\n' "$out" | grep -ci "\b$skill\b" || true)
    echo "  '$skill' mentioned ${n}x by codex (expect >=1, not duplicated)"
  fi
fi

echo
echo "== summary: $pass pass / $fail fail (static); live double-load = pending manual reload =="
[ "$fail" -eq 0 ]
