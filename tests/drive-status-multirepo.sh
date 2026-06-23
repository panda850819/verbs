#!/usr/bin/env bash
# tests/drive-status-multirepo.sh — the value scoreboard resolves each built issue against
# ITS OWN project's repo (PRO-72). Two projects in two repos, each promoted to its own main:
# per-project resolution counts BOTH; a single --repo counts only the one it points at (the
# old blind spot that false-FREEZEs the kill-line). cwd-relative (PRO-71 contract).
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$repo_root/scripts/drive-pulse"
fail=0
pass(){ echo "PASS: $1"; }
fl(){ echo "FAIL: $1"; fail=1; }
J(){ echo "$2" | python3 -c "import json,sys;r=json.load(sys.stdin);sys.exit(0 if ($1) else 1)"; }
export PSDRIVE_AUTONOMY_CONFIG=/dev/null
export PSDRIVE_HOME_PROJECT=pandastack

mkrepo(){ git -C "$1" init -q; git -C "$1" config user.email t@t.t; git -C "$1" config user.name t
  echo base > "$1/b.txt"; git -C "$1" add -A; git -C "$1" commit -qm base; git -C "$1" branch -M main; }
build_and_promote(){ # $1=repo $2=file -> echoes the build sha (now on main)
  git -C "$1" checkout -q -b psdrive/integration
  echo x > "$1/$2"; git -C "$1" add -A; git -C "$1" commit -qm "build $2"
  local sha; sha="$(git -C "$1" rev-parse HEAD)"
  git -C "$1" checkout -q main; git -C "$1" merge -q --no-ff psdrive/integration -m promote
  echo "$sha"; }

A="$(mktemp -d)"; mkrepo "$A"; SA="$(build_and_promote "$A" fa.txt)"
B="$(mktemp -d)"; mkrepo "$B"; SB="$(build_and_promote "$B" fb.txt)"

log="$(mktemp)"
{
  printf '{"ts":"2026-06-22T10:00:00Z","executed":[{"id":"ALPHA-1","project":"alpha","phase":"BUILD","verdict":"PASS","merged":"i","merged_sha":"%s"}]}\n' "$SA"
  printf '{"ts":"2026-06-22T11:00:00Z","executed":[{"id":"BETA-1","project":"beta","phase":"BUILD","verdict":"PASS","merged":"i","merged_sha":"%s"}]}\n' "$SB"
} > "$log"
cfg="$(mktemp)"; printf '{"alpha":"%s","beta":"%s"}' "$A" "$B" > "$cfg"

# --- per-project resolution: both builds promoted in their OWN repos -> both count ---
o="$(PSDRIVE_PROJECTS_CONFIG="$cfg" "$S" "$log" --status --now 2026-06-23 --json 2>&1)"
J "r['autonomous_build_merged_distinct']==2" "$o" && pass "two builds counted" || fl "build count: $o"
J "r['merged_to_main']==2 and sorted(r['merged_to_main_ids'])==['ALPHA-1','BETA-1']" "$o" \
  && pass "both promoted, each resolved to its own repo" || fl "per-repo promote wrong: $o"
J "r['external_net_shipped']==2 and sorted(r['external_built_ids'])==['ALPHA-1','BETA-1']" "$o" \
  && pass "external_net_shipped=2 across repos" || fl "external wrong: $o"
J "r['merged_to_main_checked']==True" "$o" && pass "all project repos resolved -> checked" || fl "checked wrong: $o"

# --- the old blind spot: a single --repo (A) only sees A's sha; B's promotion is invisible ---
o2="$(PSDRIVE_PROJECTS_CONFIG=/dev/null "$S" "$log" --status --repo "$A" --now 2026-06-23 --json 2>&1)"
J "r['merged_to_main']==1 and r['merged_to_main_ids']==['ALPHA-1']" "$o2" \
  && pass "single --repo A misses BETA-1 (the PRO-72 bug this fix removes)" || fl "single-repo control: $o2"

# --- config override resolves a real-looking project name to a fixture (no real-repo leak) ---
cfg2="$(mktemp)"; printf '{"pandastack":"%s"}' "$A" > "$cfg2"
log2="$(mktemp)"; printf '{"ts":"2026-06-22T10:00:00Z","executed":[{"id":"PS-1","project":"pandastack","phase":"BUILD","verdict":"PASS","merged":"i","merged_sha":"%s"}]}\n' "$SA" > "$log2"
o3="$(PSDRIVE_PROJECTS_CONFIG="$cfg2" "$S" "$log2" --status --now 2026-06-23 --json 2>&1)"
J "r['merged_to_main']==1 and r['merged_to_main_ids']==['PS-1']" "$o3" \
  && pass "config override routes 'pandastack' to the fixture repo" || fl "config override wrong: $o3"

[ "$fail" -eq 0 ] && echo "OK: drive-status-multirepo all green" || echo "FAILURES present"
exit "$fail"
