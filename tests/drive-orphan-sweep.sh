#!/usr/bin/env bash
# tests/drive-orphan-sweep.sh — PRO-67: the queue-aware orphan sweep retires a psdrive/<ISSUE>
# branch ONLY when its work has landed (reachable from the default branch or integration) AND
# its issue is no longer an active queue item. It must keep an active issue's branch (else the
# next tick re-merges it) and an unmerged branch (its work isn't preserved → data loss).
set -uo pipefail
export PSDRIVE_TEST=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
fail=0
ok() { echo "PASS: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

bexists() { git -C "$1" rev-parse --verify -q "psdrive/$2" >/dev/null 2>&1; }

r="$(mktemp -d)"
git -C "$r" init -q -b main
git -C "$r" config user.email t@t.t; git -C "$r" config user.name t
echo seed > "$r/seed.txt"; git -C "$r" add -A; git -C "$r" commit -qm seed >/dev/null
seed="$(git -C "$r" rev-parse HEAD)"
git -C "$r" branch psdrive/integration "$seed"

land_into() {  # <id> <target-branch>
  git -C "$r" branch "psdrive/$1" "$seed"
  git -C "$r" checkout -q "psdrive/$1"; echo "$1" > "$r/$1.txt"; git -C "$r" add -A; git -C "$r" commit -qm "$1" >/dev/null
  git -C "$r" checkout -q "$2"; git -C "$r" merge -q --no-ff --no-edit "psdrive/$1" >/dev/null
}
land_into ACTIVE-1 psdrive/integration     # landed in integration, issue still active
land_into DONE-1   psdrive/integration     # landed in integration, issue gone
land_into MAIN-1   main                     # landed in main via a human PR, issue gone
# UNMERGED-1: a real commit, not merged anywhere → work NOT preserved
git -C "$r" branch psdrive/UNMERGED-1 "$seed"
git -C "$r" checkout -q psdrive/UNMERGED-1; echo u > "$r/u.txt"; git -C "$r" add -A; git -C "$r" commit -qm u >/dev/null
git -C "$r" checkout -q main                 # driver runs reconcile with the repo on its default branch

retired="$(PSDRIVE_TEST=1 python3 - "$D" "$r" ACTIVE-1 <<'PY'
import sys, json, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
print(json.dumps(sorted(m.reconcile_orphan_branches(sys.argv[2], set(sys.argv[3:])))))
PY
)"

echo "$retired" | grep -q 'psdrive/DONE-1' && ok "landed + inactive (integration) → retired" || bad "DONE-1 not retired: $retired"
echo "$retired" | grep -q 'psdrive/MAIN-1' && ok "landed + inactive (main, human PR) → retired" || bad "MAIN-1 not retired: $retired"
bexists "$r" ACTIVE-1 && ok "landed but ACTIVE issue → branch kept (no re-merge)" || bad "retired an active issue's branch"
bexists "$r" UNMERGED-1 && ok "unmerged branch → kept (no data loss)" || bad "retired an unmerged branch (lost work)"
git -C "$r" rev-parse --verify -q psdrive/integration >/dev/null 2>&1 && ok "integration branch never swept" || bad "swept the integration branch"
echo "$retired" | grep -q 'UNMERGED-1\|ACTIVE-1' && bad "swept a kept branch: $retired" || ok "only the two orphans retired"

[ "$fail" -eq 0 ] && echo "OK: drive-orphan-sweep all green" || echo "FAILURES present"
exit "$fail"
