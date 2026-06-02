#!/usr/bin/env bash
# Browser integration harness for the qa + agent-browser skills.
#
# These two skills scored 'needs-integration' in the non-A/B eval: their value
# is a LIVE browser side-effect (navigate, interact, DOM/a11y assert, screenshot)
# that paper A/B cannot reach. This runs the real agent-browser CLI against a
# known fixture and asserts on actual side-effects — the correct axis for them.
#
# Usage: ./run.sh   (exit 0 = all assertions passed, 3 = no browser available)
# Requires: agent-browser on PATH + a runnable browser (`agent-browser doctor`).
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
FIX="file://$DIR/fixture.html"
SHOT="$DIR/.shot.png"
S="pandastack-bi-eval"
PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1 (got: ${2:-})"; FAIL=$((FAIL+1)); }
# eval reads DOM in the persistent session; strip surrounding JSON quotes + CR.
ev(){ agent-browser --session "$S" eval "$1" 2>/dev/null | tr -d '"\r'; }

if ! agent-browser doctor >/dev/null 2>&1; then
  echo "SKIP: agent-browser doctor failed — no runnable browser on this host."
  echo "Harness is correct but needs a browser-capable environment. Not a skill failure."
  exit 3
fi

agent-browser --session "$S" open "$FIX" >/dev/null 2>&1

# 1. Initial DOM state read
T=$(ev "document.getElementById('counter').textContent")
[ "$T" = "Counter: 0" ] && ok "initial counter text" || no "initial counter text" "$T"

# 2. Click side-effect mutates DOM
agent-browser --session "$S" click "#inc" >/dev/null 2>&1
T=$(ev "document.getElementById('counter').textContent")
[ "$T" = "Counter: 1" ] && ok "click increments counter" || no "click increments counter" "$T"

# 3. Form input side-effect
agent-browser --session "$S" fill "#name" "Panda" >/dev/null 2>&1
T=$(ev "document.getElementById('greeting').textContent")
[ "$T" = "Hello, Panda" ] && ok "input updates greeting" || no "input updates greeting" "$T"

# 4. Screenshot artifact is produced and non-empty
agent-browser --session "$S" screenshot "$SHOT" >/dev/null 2>&1
[ -s "$SHOT" ] && ok "screenshot artifact created" || no "screenshot artifact created" "missing/empty"

agent-browser --session "$S" close >/dev/null 2>&1
rm -f "$SHOT"
echo "browser-integration: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
