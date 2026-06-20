#!/usr/bin/env bash
# tests/verify-strict.sh — F-B: a materialized verify script runs under strict mode,
# so a real assertion that fails mid-script is not masked by a trailing success
# (the `grep -q X` then `echo done` -> exit 0 false-green). (PRO-38 / review F-B)
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$repo_root/scripts/pandastack-drive"
fail=0
tmp="$(mktemp -d)"

harden() {  # harden <raw-acceptance> -> prints the materialized verify.sh
  PSDRIVE_TEST=1 python3 - "$D" "$1" <<'PY'
import sys, importlib.util
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("psdrive", sys.argv[1])
spec = importlib.util.spec_from_loader("psdrive", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
sys.stdout.write(m.harden_verify(sys.argv[2]))
PY
}

pass(){ echo "PASS: $1"; }
fl(){ echo "FAIL: $1"; fail=1; }

# (1) the bug case: a failing first line followed by a trailing echo. Without
#     strict mode this exits 0; hardened, set -e catches the grep failure.
harden $'grep -q NEVER_PRESENT_XYZ /etc/hosts\necho done' > "$tmp/v1.sh"
if bash "$tmp/v1.sh" >/dev/null 2>&1; then
  fl "failing-first-line masked (exit 0) — strict mode not applied"
else
  pass "failing-first-line + trailing echo -> non-zero (strict caught it)"
fi
grep -q "set -euo pipefail" "$tmp/v1.sh" && pass "strict prelude injected" || fl "no prelude"

# (2) a genuinely passing acceptance still exits 0 under strict mode
harden $'true\necho ok' > "$tmp/v2.sh"
bash "$tmp/v2.sh" >/dev/null 2>&1 && pass "passing acceptance still exits 0 under strict" || fl "strict broke a passing acceptance"

# (3) author shebang preserved, strict still forced after it
harden $'#!/bin/bash\ngrep -q NEVER_PRESENT_XYZ /etc/hosts' > "$tmp/v3.sh"
{ head -1 "$tmp/v3.sh" | grep -q "#!/bin/bash"; } && grep -q "set -euo pipefail" "$tmp/v3.sh" \
  && pass "author shebang kept + strict injected after it" || fl "shebang/strict handling wrong"
bash "$tmp/v3.sh" >/dev/null 2>&1 && fl "shebang case: failure masked" || pass "shebang case: failure caught"

[ "$fail" -eq 0 ] && echo "OK: verify-strict all green" || echo "FAILURES present"
exit "$fail"
