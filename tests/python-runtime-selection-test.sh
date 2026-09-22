#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

runtime=$(python3 -c 'import os, sys; print(os.path.realpath(sys.executable))')
expected=$("$runtime" --version 2>&1)
relative=$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[1]))' "$runtime")
out=$(VERBS_PYTHON="$relative" VERBS_PYTHON_CHECK_ONLY=1 bash tests/run-all.sh)
case "$out" in
  *"Python runtime: $expected"*) ;;
  *) echo "FAIL: relative VERBS_PYTHON did not select $expected: $out" >&2; exit 1 ;;
esac

tmp=$(mktemp -d "${TMPDIR:-/tmp}/verbs-old-python.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/python-old" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" != "-c" ]; then exit 64; fi
exec "$runtime" -O -c 'import sys, types; sys.version_info = (3, 9, 0); sys.modules["tomllib"] = types.ModuleType("tomllib"); exec(compile(sys.argv[1], "<selector>", "exec"))' "\$2"
EOF
chmod +x "$tmp/python-old"

if VERBS_PYTHON="$tmp/python-old" VERBS_PYTHON_CHECK_ONLY=1 \
   bash tests/run-all.sh >"$tmp/out" 2>&1; then
  echo 'FAIL: optimized unsupported interpreter passed the selector' >&2
  exit 1
fi
grep -Fq 'tests require Python 3.11+' "$tmp/out"

echo 'python runtime selection: ok'
