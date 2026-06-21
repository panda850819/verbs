#!/usr/bin/env bash
# tests/drive-disconfirm.sh — a human disconfirm reverts the merge AND records why, and
# drive-pulse both resets the streak and surfaces the reason (the learning loop).
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DC="$repo_root/scripts/drive-disconfirm"
PULSE="$repo_root/scripts/drive-pulse"
fail=0; ok(){ echo "PASS: $1"; }; bad(){ echo "FAIL: $1"; fail=1; }

# a real integration with one --no-ff merge commit
r="$(mktemp -d)"
git -C "$r" init -q; git -C "$r" config user.email t@t.t; git -C "$r" config user.name t
echo seed > "$r/seed.txt"; git -C "$r" add -A; git -C "$r" commit -qm seed >/dev/null
base="$(git -C "$r" rev-parse HEAD)"
git -C "$r" checkout -q -b psdrive/FEAT; echo feat > "$r/feat.txt"; git -C "$r" add -A; git -C "$r" commit -qm feat >/dev/null
git -C "$r" checkout -q -b psdrive/integration "$base"
git -C "$r" merge --no-ff --no-edit psdrive/FEAT >/dev/null
msha="$(git -C "$r" rev-parse HEAD)"
git -C "$r" checkout -q "$base"   # detach off integration so the tool can worktree it

dlog="$(mktemp)"
out="$(PSDRIVE_DISCONFIRM_LOG="$dlog" PSDRIVE_DISCONFIRM_NOW="2026-06-21T00:00:00Z" \
  python3 "$DC" "$msha" "acceptance was tautological" --class bad-acceptance --issue LO-7 --repo "$r" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "drive-disconfirm exits 0 ($out)" || bad "drive-disconfirm rc=$rc: $out"
ilog="$(git -C "$r" log psdrive/integration --format=%B)"   # capture (not pipe to grep -q under pipefail)
grep -q "This reverts commit $msha" <<<"$ilog" \
  && ok "merge commit reverted on integration (-m 1 handled)" || bad "merge not reverted"
{ grep -q "bad-acceptance" "$dlog" && grep -q "tautological" "$dlog" && grep -q "LO-7" "$dlog"; } \
  && ok "reason row logged (class + why + issue)" || bad "reason not logged: $(cat "$dlog")"

# drive-pulse: the revert resets the streak AND the reason is surfaced
log="$(mktemp)"
printf '{"ts":"2026-06-20T00:00:00Z","executed":[{"id":"LO-7","verdict":"PASS","merged":"psdrive/integration","merged_sha":"%s","verify_required":true,"verify_ran":true}]}\n' "$msha" > "$log"
sig="$(PSDRIVE_DISCONFIRM_LOG="$dlog" python3 "$PULSE" "$log" --repo "$r" --now 2026-06-25 --days 30 --json)"
echo "$sig" | python3 -c "
import json,sys
r=json.load(sys.stdin)['goal_signals']
assert r['trust_streak']==0, r
assert r['recent_disconfirms'] and r['recent_disconfirms'][-1]['class']=='bad-acceptance', r
assert r['recent_disconfirms'][-1]['why']=='acceptance was tautological', r
" && ok "drive-pulse: disconfirm reset streak to 0 + surfaced the reason" || bad "pulse signal wrong: $sig"

# --no-revert only logs, does not touch integration
before="$(git -C "$r" rev-parse psdrive/integration)"
PSDRIVE_DISCONFIRM_LOG="$dlog" python3 "$DC" "$msha" "log only" --no-revert --repo "$r" >/dev/null 2>&1
[ "$(git -C "$r" rev-parse psdrive/integration)" = "$before" ] && ok "--no-revert logs without touching integration" || bad "--no-revert moved integration"

[ "$fail" -eq 0 ] && echo "OK: drive-disconfirm all green" || echo "FAILURES present"
exit "$fail"
