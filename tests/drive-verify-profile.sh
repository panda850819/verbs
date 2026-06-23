#!/usr/bin/env bash
# tests/drive-verify-profile.sh — PRO-73: an acceptance block may declare the sensor
# LAYERS its verify covers (`layers: typecheck, test`), ordered cheapest-first. The layers
# line is METADATA: PRO-74 (granularity) / PRO-75 (coverage) read it; it is stripped from
# the runnable body before materialization so it never runs as a shell command.
# Fail-closed: a layers-only declaration with no real check is NOT runnable — it surfaces
# as needs-spec, never a silent model-PASS.
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root/scripts" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pslib
ok = True
def chk(cond, label):
    global ok
    print(("PASS: " if cond else "FAIL: ") + label)
    ok = ok and bool(cond)

LAYERED     = '```acceptance\nlayers: typecheck, test\nnpm run typecheck && npm test\n```'
LAYERS_ONLY = '```acceptance\nlayers: typecheck, test\n```'
PLAIN       = '```acceptance\nbin/x tests/fixtures/clean && grep -q ok out\n```'

# 1. layers declaration parsed (ordered + lowercased); plain block has none
chk(pslib.acceptance_layers(LAYERED) == ["typecheck", "test"], "layers: line parsed -> ['typecheck','test']")
chk(pslib.acceptance_layers(PLAIN) == [], "no layers: line -> []")

# 2. body strips the layers: line; a plain block is unchanged (backward compat)
chk(pslib.acceptance_body(LAYERED) == "npm run typecheck && npm test", "acceptance_body strips the layers: declaration")
chk(pslib.acceptance_body(PLAIN) == "bin/x tests/fixtures/clean && grep -q ok out", "no layers: line -> body == block")

# 3. fail-closed: a layers-only card has no runnable check -> NOT runnable -> needs-spec
chk(not pslib.acceptance_runnable(LAYERS_ONLY), "layers-only (no command) -> NOT runnable (fail-closed)")
chk(pslib.acceptance_runnable(LAYERED), "layers + real command -> runnable")
gap = pslib.readiness_gap("Building", "## Goal x\n## Context y\n" + LAYERS_ONLY)
chk(gap is not None and "acceptance" in gap, "layers-only Building card -> needs-spec (not auto-built)")
chk(pslib.readiness_gap("Building", "## Goal x\n## Context y\n" + LAYERED) is None,
    "layered + command Building card passes readiness")

# 4. materialized verify.sh runs the real cheapest-first commands, never the layers: metadata
mat = pslib.harden_verify(pslib.acceptance_body(LAYERED))
chk("layers:" not in mat, "materialized verify.sh excludes the layers: metadata line")
chk("npm run typecheck && npm test" in mat, "materialized verify.sh contains the real cheapest-first commands")
chk("set -euo pipefail" in mat, "materialized verify.sh is strict (cheapest-first, fail-fast on first red)")

sys.exit(0 if ok else 1)
PY
rc=$?
[ "$rc" -eq 0 ] && echo "OK: drive-verify-profile all green" || echo "FAILURES present"
exit "$rc"
