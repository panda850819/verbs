#!/usr/bin/env bash
# tests/drive-promote.sh — PRO-64 (T05a): manual, LOCAL promote of psdrive/integration → main.
# Fast-forwards main when it lies behind integration; when main has diverged, REFRESHES
# integration toward main by MERGING main in (keeps auto-merge SHAs reachable, never resets)
# then fast-forwards. Never pushes. Fails closed on a dirty tree / missing integration.
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
P="$repo_root/scripts/drive-promote"
fail=0
ok() { echo "PASS: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

# repo with integration = main + one landed commit (capture that commit's sha)
mkrepo() {
  local r; r="$(mktemp -d)"
  git -C "$r" init -q -b main; git -C "$r" config user.email t@t.t; git -C "$r" config user.name t
  echo seed > "$r/seed.txt"; git -C "$r" add -A; git -C "$r" commit -qm seed >/dev/null
  git -C "$r" branch psdrive/integration; git -C "$r" checkout -q psdrive/integration
  echo work1 > "$r/work1.txt"; git -C "$r" add -A; git -C "$r" commit -qm work1 >/dev/null
  git -C "$r" checkout -q main
  echo "$r"
}
has() { git -C "$1" cat-file -e "$2:$3" 2>/dev/null; }
anc() { git -C "$1" merge-base --is-ancestor "$2" main 2>/dev/null; }

# ---------- 1. main behind integration → fast-forward promote (local) ----------
r="$(mkrepo)"; sha1="$(git -C "$r" rev-parse psdrive/integration)"
out="$("$P" --repo "$r" 2>&1)"; rc=$?
[ $rc -eq 0 ] && ok "ff promote succeeds" || bad "ff promote failed: $out"
[ "$(git -C "$r" rev-parse main)" = "$(git -C "$r" rev-parse psdrive/integration)" ] && ok "main == integration after promote" || bad "main not advanced to integration"
has "$r" main work1.txt && ok "promoted work is on main" || bad "work missing from main"
anc "$r" "$sha1" && ok "auto-merge SHA reachable from main (streak preserved)" || bad "auto-merge SHA orphaned"
[ -z "$(git -C "$r" remote)" ] && ok "no remote — promote is purely local (never pushed)" || bad "a remote was contacted"

# ---------- 2. main diverged → refresh (merge main in) + ff; both lines preserved ----------
r="$(mkrepo)"
git -C "$r" checkout -q main; echo mainwork > "$r/mainwork.txt"; git -C "$r" add -A; git -C "$r" commit -qm mainwork >/dev/null
out="$("$P" --repo "$r" 2>&1)"; rc=$?
[ $rc -eq 0 ] && ok "diverged promote succeeds (refresh + ff)" || bad "diverged promote failed: $out"
has "$r" main work1.txt && has "$r" main mainwork.txt && ok "main carries BOTH the auto-merge and main's own commit" || bad "diverged promote dropped a line"
[ "$(git -C "$r" rev-parse main)" = "$(git -C "$r" rev-parse psdrive/integration)" ] && ok "main == integration after diverged promote" || bad "main != integration after refresh+ff"

# ---------- 3. dirty worktree → refuse, change nothing ----------
r="$(mkrepo)"; before="$(git -C "$r" rev-parse main)"
echo dirty >> "$r/seed.txt"
out="$("$P" --repo "$r" 2>&1)"; rc=$?
{ [ $rc -ne 0 ] && [ "$(git -C "$r" rev-parse main)" = "$before" ]; } && ok "dirty worktree → refused, main unchanged" || bad "promoted over a dirty tree: $out"

# ---------- 4. nothing to promote (main == integration) → no-op ----------
r="$(mkrepo)"; "$P" --repo "$r" >/dev/null 2>&1   # first promote makes them equal
out="$("$P" --repo "$r" 2>&1)"; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q "nothing to promote" && ok "already-promoted → no-op exit 0" || bad "second promote not a clean no-op: $out"

# ---------- 5. dry-run changes nothing ----------
r="$(mkrepo)"; before="$(git -C "$r" rev-parse main)"
out="$("$P" --repo "$r" --dry-run 2>&1)"
{ echo "$out" | grep -qi "dry-run" && [ "$(git -C "$r" rev-parse main)" = "$before" ]; } && ok "--dry-run reports + changes nothing" || bad "dry-run mutated state: $out"

[ "$fail" -eq 0 ] && echo "OK: drive-promote all green" || echo "FAILURES present"
exit "$fail"
