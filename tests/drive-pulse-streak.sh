#!/usr/bin/env bash
# tests/drive-pulse-streak.sh — Goal A part-4 measurement: fake-green count + trust
# streak with human-revert disconfirm reset. Computed from the real ledger + the real
# integration git history; NOT a fabricated streak (no merges ⇒ streak 0).
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$repo_root/scripts/drive-pulse"
fail=0
pass(){ echo "PASS: $1"; }
fl(){ echo "FAIL: $1"; fail=1; }
sig() { echo "$1" | python3 -c "import json,sys;print(json.dumps(json.load(sys.stdin)['goal_signals']))"; }

# ---------- 1. clean ledger, no --repo → fake-green 0, raw streak counts merges ----------
l1="$(mktemp)"
for i in 1 2 3 4 5; do
  printf '{"ts":"2026-06-1%sT00:00:00Z","executed":[{"id":"LO-%s","verdict":"PASS","advance":"a","verify_required":true,"verify_ran":true,"verify_ok":true,"blast":"low","merged":"psdrive/integration","merged_sha":"sha%s"}]}\n' "$i" "$i" "$i" >> "$l1"
done
o="$(sig "$("$S" "$l1" --now 2026-06-20 --days 30 --json)")"
echo "$o" | python3 -c "import json,sys;r=json.load(sys.stdin);assert r['fake_green']==0 and r['trust_streak']==5 and r['merges_total']==5 and r['revert_checked']==False,r" \
  && pass "clean ledger → fake-green 0, raw streak 5 (revert-check skipped w/o --repo)" || fl "clean signals wrong: $o"

# ---------- 2. planted fake-green: PASS+merged+verify_required+NOT verify_ran → count 1 ----------
l2="$(mktemp)"
printf '{"ts":"2026-06-15T00:00:00Z","executed":[{"id":"OK","verdict":"PASS","advance":"a","verify_required":true,"verify_ran":true,"merged":"psdrive/integration","merged_sha":"s1"}]}\n' >> "$l2"
printf '{"ts":"2026-06-16T00:00:00Z","executed":[{"id":"BAD","verdict":"PASS","advance":"a","verify_required":true,"verify_ran":false,"merged":"psdrive/integration","merged_sha":"s2"}]}\n' >> "$l2"
o="$(sig "$("$S" "$l2" --now 2026-06-20 --days 30 --json)")"
echo "$o" | python3 -c "import json,sys;r=json.load(sys.stdin);assert r['fake_green']==1 and 'BAD' in r['fake_green_ids'],r" \
  && pass "planted fake-green detected (count 1, id BAD)" || fl "fake-green not detected: $o"

# ---------- 3. real repo + human git-revert of merge #3 → streak resets to 2 ----------
r3="$(mktemp -d)"
git -C "$r3" init -q; git -C "$r3" config user.email t@t.t; git -C "$r3" config user.name t
git -C "$r3" checkout -q -b psdrive/integration
declare -a SHAS
for i in 1 2 3 4 5; do
  echo "c$i" > "$r3/f$i.txt"; git -C "$r3" add -A; git -C "$r3" commit -qm "merge $i" >/dev/null
  SHAS[$i]="$(git -C "$r3" rev-parse HEAD)"
done
git -C "$r3" revert --no-edit "${SHAS[3]}" >/dev/null   # a human disconfirms merge #3
l3="$(mktemp)"
for i in 1 2 3 4 5; do
  printf '{"ts":"2026-06-0%sT00:00:00Z","executed":[{"id":"M-%s","verdict":"PASS","merged":"psdrive/integration","merged_sha":"%s","verify_required":true,"verify_ran":true}]}\n' "$i" "$i" "${SHAS[$i]}" >> "$l3"
done
o="$(sig "$("$S" "$l3" --repo "$r3" --now 2026-06-20 --days 60 --json)")"
echo "$o" | python3 -c "import json,sys;r=json.load(sys.stdin);assert r['revert_checked'] and r['reverts_seen']>=1 and r['trust_streak']==2,r" \
  && pass "human revert of merge #3 → disconfirm resets streak to 2 (#4,#5)" || fl "disconfirm reset wrong: $o"

# ---------- 4. SILENT rollback via `git branch -f` (no revert message) is caught ----------
# A revert-message grep alone would report a phantom 5/5 here; reachability catches it.
r4="$(mktemp -d)"
git -C "$r4" init -q; git -C "$r4" config user.email t@t.t; git -C "$r4" config user.name t
git -C "$r4" checkout -q -b psdrive/integration
declare -a S4
for i in 1 2 3 4 5; do
  echo "c$i" > "$r4/g$i.txt"; git -C "$r4" add -A; git -C "$r4" commit -qm "merge $i" >/dev/null
  S4[$i]="$(git -C "$r4" rev-parse HEAD)"
done
git -C "$r4" checkout -q --detach "${S4[5]}"            # free the branch ref so it can be force-moved
git -C "$r4" branch -f psdrive/integration "${S4[3]}"   # silent rollback: drop #4 and #5, no revert commit
l4="$(mktemp)"
for i in 1 2 3 4 5; do
  printf '{"ts":"2026-06-0%sT00:00:00Z","executed":[{"id":"M-%s","verdict":"PASS","merged":"psdrive/integration","merged_sha":"%s","verify_required":true,"verify_ran":true}]}\n' "$i" "$i" "${S4[$i]}" >> "$l4"
done
o="$(sig "$("$S" "$l4" --repo "$r4" --now 2026-06-20 --days 60 --json)")"
echo "$o" | python3 -c "import json,sys;r=json.load(sys.stdin);assert r['rolled_back']==2 and r['trust_streak']==0,r" \
  && pass "silent branch -f rollback of #4,#5 caught → rolled_back=2, streak=0 (no phantom)" || fl "silent rollback not caught: $o"

# text render shows the computed streak, not 'NO DATA'
txt="$("$S" "$l3" --repo "$r3" --now 2026-06-20 --days 60 2>&1)"
grep -q "trust streak" <<<"$txt" && grep -q "GOAL SIGNAL" <<<"$txt" && pass "text renders computed trust streak" || fl "text streak not rendered"
grep -q "NO DATA" <<<"$txt" && fl "stale NO DATA still rendered" || pass "no stale NO DATA marker"

[ "$fail" -eq 0 ] && echo "OK: drive-pulse-streak all green" || echo "FAILURES present"
exit "$fail"
