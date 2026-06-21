#!/usr/bin/env bash
# tests/drive-merge-router.sh — T03 blast×verifiability router + integration auto-merge.
#
# Asserts the boundary-#1 rules: auto-merge is gated OFF by default; only a low-blast,
# machine-lane (host-verify actually ran), host-verified-green build merges, and only
# into the integration branch (never main, never pushed); high-blast / no-host-verify
# keep the branch for a human PR; a non-clean merge is aborted (no half-merge) → gate.
# Pure logic + throwaway git repos; no network, no Linear, no codex. PSDRIVE_TEST=1.
set -uo pipefail
export PSDRIVE_TEST=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
export PSDRIVE_WORKER_JOB_ROOT="$(mktemp -d)"
fail=0
ok() { echo "PASS: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

pol="$(mktemp)"
cat > "$pol" <<'POL'
**/migrations/**
**/secrets/**
**/*.env
scripts/pandastack-drive
POL

jget() { echo "$1" | python3 -c "import json,sys;print(json.load(sys.stdin).get('$2'))"; }

fresh_repo() {
  local r; r="$(mktemp -d)"
  git -C "$r" init -q
  git -C "$r" config user.email t@t.t; git -C "$r" config user.name t
  echo seed > "$r/seed.txt"; git -C "$r" add -A; git -C "$r" commit -qm seed >/dev/null
  echo "$r"
}

run_build() {  # <repo> <id> <merge_auto 1|0> <acceptance> <stub_file>
  PSDRIVE_TEST=1 PSDRIVE_BUILD_STUB=PASS PSDRIVE_BUILD_STUB_FILE="$5" PSDRIVE_BLAST_POLICY="$pol" \
    python3 - "$D" "$1" "$2" "$3" "$4" <<'PY'
import sys, json, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
acc = sys.argv[5]
desc = ("Goal: x\nContext: y\n```acceptance\n" + acc + "\n```\n") if acc else "Goal: x\nContext: y\n"
x = {"id": sys.argv[3], "project": "t", "repo": sys.argv[2], "title": "t", "next": "BUILD",
     "to_state": "Verifying", "build": True, "desc": desc}
r = m.exec_build(x, merge_auto=(sys.argv[4] == "1"))
print(json.dumps({"merged": r.get("merged"), "blast": r.get("blast"), "verdict": r.get("verdict"),
                  "merge_skip": r.get("merge_skip"), "gate": r.get("gate")}))
PY
}

# ---------- 0. flag gating: --merge-auto triple-gated + capped at --max 1 pre-graduation ----------
# capture (not pipe) so argparse's exit-2 under `set -o pipefail` doesn't mask the grep
g0="$(PSDRIVE_TEST=1 "$D" --execute --merge-auto 2>&1)"
echo "$g0" | grep -q "requires --build-auto" \
  && ok "--merge-auto alone errors (needs --build-auto --only)" || bad "--merge-auto not gated: $g0"
g1="$(PSDRIVE_TEST=1 "$D" --execute --merge-auto --build-auto --only t --max 2 2>&1)"
echo "$g1" | grep -q "caps --max at 1" \
  && ok "--merge-auto --max 2 errors (one attributable merge per tick)" || bad "max-cap not enforced: $g1"

# ---------- 1. classify_blast: 3 high fixtures + low + default-deny ----------
PSDRIVE_TEST=1 python3 - "$D" <<'PY'
import sys, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
pats = ["**/migrations/**", "**/secrets/**", "**/*.env", "scripts/pandastack-drive"]
cases = {
  "nested-migration": (["app/db/migrations/001_init.sql"], "high"),
  "rename-out-of-auth": (["src/util.py", "infra/secrets/leak.txt"], "high"),  # rename old+new, new is high
  "deletion-of-driver": (["scripts/pandastack-drive"], "high"),
  "top-level-migration": (["migrations/x.sql"], "high"),
  "ordinary-low": (["src/utils/helper.py", "README.md"], "low"),
}
for name, (paths, want) in cases.items():
    got, _ = m.classify_blast(paths, pats)
    assert got == want, (name, paths, got, want)
assert m.classify_blast([], pats)[0] == "high", "empty diff must be high (default-deny)"
assert m.classify_blast(["x"], None)[0] == "high", "unreadable policy must be high (default-deny)"
print("PASS: classify_blast — 3 high fixtures + low + default-deny (empty/None)")
PY
[ $? -eq 0 ] || bad "classify_blast unit"

# ---------- 2. git_diff_paths: rename old+new, deletion, add ----------
gr="$(fresh_repo)"
echo "old content" > "$gr/old.txt"; echo "del me" > "$gr/gone.txt"
git -C "$gr" add -A; git -C "$gr" commit -qm pre >/dev/null
base2="$(git -C "$gr" rev-parse HEAD)"
git -C "$gr" mv old.txt new.txt; git -C "$gr" rm -q gone.txt; echo hi > "$gr/added.txt"
git -C "$gr" add -A; git -C "$gr" commit -qm change >/dev/null
paths="$(PSDRIVE_TEST=1 python3 - "$D" "$gr" "$base2" <<'PY'
import sys, json, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
print(json.dumps(sorted(m.git_diff_paths(sys.argv[2], sys.argv[3], "HEAD"))))
PY
)"
echo "$paths" | python3 -c '
import json,sys
p=set(json.load(sys.stdin))
assert {"old.txt","new.txt","gone.txt","added.txt"} <= p, p
print("PASS: git_diff_paths captures rename old+new, deletion, add")
' || bad "git_diff_paths"

# ---------- 3. gated OFF (no --merge-auto): low-blast NOT merged, branch kept ----------
rA="$(fresh_repo)"
o="$(run_build "$rA" GO-1 0 "test -f .psdrive-stub" ".psdrive-stub")"
[ "$(jget "$o" merged)" = "None" ] && ok "gated OFF → not merged" || bad "gated OFF merged anyway: $o"
git -C "$rA" rev-parse --verify -q psdrive/integration >/dev/null 2>&1 && bad "gated OFF created integration" || ok "gated OFF → no integration branch"
git -C "$rA" rev-parse --verify -q psdrive/GO-1 >/dev/null 2>&1 && ok "gated OFF → branch kept for PR" || bad "gated OFF lost the branch"

# ---------- 4. --merge-auto low-blast → merged into integration, main untouched ----------
rB="$(fresh_repo)"
mref="$(git -C "$rB" symbolic-ref --short HEAD)"
mbefore="$(git -C "$rB" rev-parse HEAD)"
o="$(run_build "$rB" LO-1 1 "test -f .psdrive-stub" ".psdrive-stub")"
[ "$(jget "$o" merged)" = "psdrive/integration" ] && ok "low-blast → merged into integration" || bad "low-blast not merged: $o"
[ "$(jget "$o" blast)" = "low" ] && ok "low-blast classified low" || bad "blast wrong: $o"
git -C "$rB" cat-file -e psdrive/integration:.psdrive-stub 2>/dev/null && ok "integration holds the change" || bad "integration missing the change"
[ "$(git -C "$rB" rev-parse "$mref")" = "$mbefore" ] && ok "main HEAD unchanged" || bad "main HEAD moved (must never touch main)"
git -C "$rB" cat-file -e "$mref:.psdrive-stub" 2>/dev/null && bad "main got the change (must never merge main)" || ok "main does not hold the change"
[ -z "$(git -C "$rB" remote)" ] && ok "no remote → driver never pushed" || bad "unexpected remote (push path)"
[ "$(git -C "$rB" worktree list | wc -l | tr -d ' ')" = "1" ] && ok "no stray worktrees after merge" || bad "stray worktree left"

# ---------- 5. --merge-auto high-blast → NOT merged, branch kept for PR ----------
rC="$(fresh_repo)"
o="$(run_build "$rC" HI-1 1 "test -f migrations/x.sql" "migrations/x.sql")"
[ "$(jget "$o" merged)" = "None" ] && ok "high-blast → not merged" || bad "high-blast merged: $o"
[ "$(jget "$o" blast)" = "high" ] && ok "high-blast classified high" || bad "blast wrong: $o"
git -C "$rC" rev-parse --verify -q psdrive/integration >/dev/null 2>&1 && bad "high-blast created integration" || ok "high-blast → no integration"
git -C "$rC" rev-parse --verify -q psdrive/HI-1 >/dev/null 2>&1 && ok "high-blast → branch kept for PR" || bad "high-blast lost the branch"

# ---------- 6. F-M: low-blast PASS without host-verify → NOT merged (machine-lane gate) ----------
rD="$(fresh_repo)"
o="$(run_build "$rD" FM-1 1 "" ".psdrive-stub")"   # no acceptance ⇒ no host-verify ran
[ "$(jget "$o" merged)" = "None" ] && ok "no-host-verify → not merged (F-M)" || bad "merged without host-verify: $o"
echo "$o" | grep -q "machine-lane" && ok "merge_skip cites machine-lane gate" || bad "F-M reason missing: $o"

# ---------- 7. non-clean merge → aborted (no half-merge) → gate ----------
rE="$(fresh_repo)"
base="$(git -C "$rE" rev-parse HEAD)"
git -C "$rE" checkout -q -b psdrive/integration; echo integ > "$rE/seed.txt"; git -C "$rE" commit -qam integ >/dev/null
git -C "$rE" checkout -q -b psdrive/FEAT "$base"; echo feat > "$rE/seed.txt"; git -C "$rE" commit -qam feat >/dev/null
git -C "$rE" checkout -q "$base"   # detach so integration is free to be worktree-checked-out
o="$(PSDRIVE_TEST=1 python3 - "$D" "$rE" "$base" <<'PY'
import sys, json, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
print(json.dumps(m.merge_to_integration(sys.argv[2], "psdrive/FEAT", sys.argv[3])))
PY
)"
[ "$(jget "$o" merged)" = "False" ] && ok "conflict → not merged" || bad "conflict merged anyway: $o"
[ "$(jget "$o" gate)" = "True" ] && ok "conflict → gated for human" || bad "conflict not gated: $o"
[ "$(git -C "$rE" show psdrive/integration:seed.txt)" = "integ" ] && ok "integration not half-merged (aborted clean)" || bad "integration left in a half-merged state"
[ "$(git -C "$rE" worktree list | wc -l | tr -d ' ')" = "1" ] && ok "conflict path leaves no stray worktree" || bad "stray worktree after abort"

# ---------- 8. self-heal: an orphaned integration worktree (crashed tick) doesn't wedge merges ----------
rF="$(fresh_repo)"
baseF="$(git -C "$rF" rev-parse HEAD)"
git -C "$rF" checkout -q -b psdrive/FEAT; echo feat > "$rF/feat.txt"; git -C "$rF" add -A; git -C "$rF" commit -qm feat >/dev/null
git -C "$rF" checkout -q "$baseF"
orph="$(mktemp -u)"                                   # a crashed tick: register integration to a dir, then lose it
git -C "$rF" worktree add -q "$orph" -b psdrive/integration "$baseF" >/dev/null 2>&1
rm -rf "$orph"                                        # dir gone, stale registration remains → naive add would fail
o="$(PSDRIVE_TEST=1 python3 - "$D" "$rF" "$baseF" <<'PY'
import sys, json, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("psdrive", loader)); loader.exec_module(m)
print(json.dumps(m.merge_to_integration(sys.argv[2], "psdrive/FEAT", sys.argv[3])))
PY
)"
[ "$(jget "$o" merged)" = "True" ] && ok "orphaned integration worktree pruned → merge self-heals" || bad "crashed-tick orphan wedged the merge: $o"
git -C "$rF" cat-file -e psdrive/integration:feat.txt 2>/dev/null && ok "self-healed merge carried the change" || bad "self-healed merge missing change"

[ "$fail" -eq 0 ] && echo "OK: drive-merge-router all green" || echo "FAILURES present"
exit "$fail"
