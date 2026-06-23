#!/usr/bin/env bash
# tests/drive-status.sh — drive-pulse --status renders the VALUE scoreboard (PRO-70):
# how many real backlog issues the loop autonomously BUILT + merged, how many reached main,
# how many shipped, the human-revert tally, and the external-vs-self split. Read-only and
# computed from the ledger + real git ancestry — never a fabricated number.
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$repo_root/scripts/drive-pulse"
fail=0
pass(){ echo "PASS: $1"; }
fl(){ echo "FAIL: $1"; fail=1; }
J(){ echo "$2" | python3 -c "import json,sys;r=json.load(sys.stdin);sys.exit(0 if ($1) else 1)"; }

export PSDRIVE_AUTONOMY_CONFIG=/dev/null      # deterministic: no build_auto projects unless a case overrides
export PSDRIVE_HOME_PROJECT=pandastack

mkrepo(){ # $1=dir — git repo with a `main` branch and one base commit
  git -C "$1" init -q; git -C "$1" config user.email t@t.t; git -C "$1" config user.name t
  echo base > "$1/base.txt"; git -C "$1" add -A; git -C "$1" commit -qm base; git -C "$1" branch -M main
}

# ---------- 1. BUILD+merge to integration, no --repo → distinct 1, promote UNCHECKED ----------
l1="$(mktemp)"
printf '{"ts":"2026-06-22T13:00:00Z","executed":[{"id":"PRO-68","project":"pandastack","phase":"BUILD","verdict":"PASS","merged":"psdrive/integration","merged_sha":"deadbeef","verify_ran":true,"verify_ok":true}]}\n' > "$l1"
o="$("$S" "$l1" --status --now 2026-06-23 --json 2>&1)"
J "r['autonomous_build_merged_distinct']==1 and r['autonomous_build_merged_ids']==['PRO-68']" "$o" \
  && pass "distinct BUILD merge = 1 (PRO-68)" || fl "distinct wrong: $o"
J "r['merged_to_main_checked']==False and r['ship_count']==0" "$o" \
  && pass "no --repo → promote unchecked, ship 0" || fl "unchecked/ship wrong: $o"
J "r['token_spend'] is None" "$o" && pass "token spend NO DATA (null)" || fl "token not null: $o"
# a read-only PLAN proposal must NOT count as a build
l1b="$(mktemp)"
printf '{"ts":"2026-06-22T13:00:00Z","executed":[{"id":"PRO-53","project":"pandastack","phase":"PLAN","verdict":"PASS","advance":"a"}]}\n' > "$l1b"
o="$("$S" "$l1b" --status --now 2026-06-23 --json 2>&1)"
J "r['autonomous_build_merged_distinct']==0 and r['ship_count']==0" "$o" \
  && pass "PLAN proposal is not a build" || fl "PLAN counted as build: $o"

# ---------- 2. real repo: built sha on integration only → merged_to_main 0 (checked) ----------
r="$(mktemp -d)"; mkrepo "$r"
git -C "$r" checkout -q -b psdrive/integration
echo f68 > "$r/f68.txt"; git -C "$r" add -A; git -C "$r" commit -qm "PRO-68 build"
SHA68="$(git -C "$r" rev-parse HEAD)"
git -C "$r" checkout -q main
l2="$(mktemp)"
printf '{"ts":"2026-06-22T13:00:00Z","executed":[{"id":"PRO-68","project":"pandastack","phase":"BUILD","verdict":"PASS","merged":"psdrive/integration","merged_sha":"%s","verify_ran":true,"verify_ok":true}]}\n' "$SHA68" > "$l2"
o="$("$S" "$l2" --status --repo "$r" --now 2026-06-23 --json 2>&1)"
J "r['merged_to_main']==0 and r['merged_to_main_checked']==True and r['net_shipped']==0" "$o" \
  && pass "build on integration only → merged_to_main 0 (checked)" || fl "promote-check wrong: $o"
J "r['external_net_shipped']==0" "$o" && pass "home-project build is not external" || fl "external wrong: $o"

# ---------- 3. promote the build onto main → merged_to_main 1, net_shipped 1 ----------
git -C "$r" merge -q --no-ff psdrive/integration -m "promote integration -> main"
o="$("$S" "$l2" --status --repo "$r" --now 2026-06-23 --json 2>&1)"
J "r['merged_to_main']==1 and r['merged_to_main_ids']==['PRO-68'] and r['net_shipped']==1" "$o" \
  && pass "promoted to main → merged_to_main 1, net_shipped 1" || fl "promote wrong: $o"
J "r['external_net_shipped']==0" "$o" && pass "promoted home build still not external" || fl "external after promote wrong: $o"

# ---------- 4. external: a murmur-project build promoted to main → external_net_shipped 1 ----------
git -C "$r" checkout -q psdrive/integration
echo fmur > "$r/fmur.txt"; git -C "$r" add -A; git -C "$r" commit -qm "PRO-9 murmur build"
SHAM="$(git -C "$r" rev-parse HEAD)"
git -C "$r" checkout -q main; git -C "$r" merge -q --no-ff psdrive/integration -m "promote 2"
l4="$(mktemp)"
{
  printf '{"ts":"2026-06-22T13:00:00Z","executed":[{"id":"PRO-68","project":"pandastack","phase":"BUILD","verdict":"PASS","merged":"i","merged_sha":"%s"}]}\n' "$SHA68"
  printf '{"ts":"2026-06-22T14:00:00Z","executed":[{"id":"PRO-9","project":"murmur","phase":"BUILD","verdict":"PASS","merged":"i","merged_sha":"%s"}]}\n' "$SHAM"
} > "$l4"
o="$("$S" "$l4" --status --repo "$r" --now 2026-06-23 --json 2>&1)"
J "r['merged_to_main']==2 and r['external_net_shipped']==1 and r['external_built_ids']==['PRO-9']" "$o" \
  && pass "murmur build is external (external_net_shipped 1, PRO-9)" || fl "external murmur wrong: $o"

# ---------- 5. human revert of the murmur build on main → its net-ship drops, external_net 0 ----------
git -C "$r" revert --no-edit "$SHAM" >/dev/null
o="$("$S" "$l4" --status --repo "$r" --now 2026-06-23 --json 2>&1)"
J "r['reverts']['reverted']>=1 and r['net_shipped']==1 and r['net_shipped_ids']==['PRO-68'] and r['external_net_shipped']==0" "$o" \
  && pass "human revert of murmur build → net_shipped 1 (PRO-68 only), external 0" || fl "revert handling wrong: $o"

# ---------- 6. build_auto projects read from the autonomy config ----------
cfg="$(mktemp)"; printf '{"murmur":{"build_auto":true},"foo":{"build_auto":false}}' > "$cfg"
o="$(PSDRIVE_AUTONOMY_CONFIG="$cfg" "$S" "$l4" --status --repo "$r" --now 2026-06-23 --json 2>&1)"
J "r['build_auto_projects']==['murmur']" "$o" && pass "build_auto projects read from config" || fl "build_auto config wrong: $o"

# ---------- 8. robustness: a missing sha object stays "not promoted", board still checked ----------
l8="$(mktemp)"
printf '{"ts":"2026-06-22T13:00:00Z","executed":[{"id":"PRO-99","project":"murmur","phase":"BUILD","verdict":"PASS","merged":"i","merged_sha":"cafebabecafebabecafebabecafebabecafebabe"}]}\n' > "$l8"
o="$("$S" "$l8" --status --repo "$r" --now 2026-06-23 --json 2>&1)"
J "r['merged_to_main_checked']==True and r['merged_to_main']==0 and r['autonomous_build_merged_distinct']==1" "$o" \
  && pass "missing sha object → not-promoted, board still checked (not blanked)" || fl "missing-sha robustness wrong: $o"
# a non-existent --main-branch is unreliable → unchecked, not a false 0
o="$("$S" "$l8" --status --repo "$r" --main-branch no-such-branch --now 2026-06-23 --json 2>&1)"
J "r['merged_to_main_checked']==False" "$o" \
  && pass "bad --main-branch → promote unchecked (honest, not false 0)" || fl "bad-branch handling wrong: $o"

# ---------- 7. text render: scoreboard header + token NO DATA + verdict mix ----------
txt="$("$S" "$l4" --status --repo "$r" --now 2026-06-23 2>&1)"
grep -q "value scoreboard" <<<"$txt" && pass "text: scoreboard header present" || fl "header missing"
grep -q "NO DATA" <<<"$txt" && pass "text: token NO DATA rendered, not faked" || fl "NO DATA missing"
grep -q "verdict mix" <<<"$txt" && pass "text: verdict mix present" || fl "verdict mix missing"

[ "$fail" -eq 0 ] && echo "OK: drive-status all green" || echo "FAILURES present"
exit "$fail"
