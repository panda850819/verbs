#!/usr/bin/env bash
# Offline regression: requested-host absence must stay red.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp/bin"
ln -s "$(command -v python3)" "$tmp/bin/python3"
ln -s "$(command -v dirname)" "$tmp/bin/dirname"

if PATH="$tmp/bin" /bin/bash scripts/conformance-smoke.sh claude \
    >"$tmp/out" 2>&1; then
  echo "FAIL: missing requested host produced a green conformance smoke" >&2
  exit 1
fi
grep -Fq "FAIL [claude]: claude CLI not on PATH" "$tmp/out"
grep -Fq "FAIL: no requested host was tested" "$tmp/out"
grep -Fq 'codex_args=(exec --sandbox read-only --json)' scripts/conformance-smoke.sh
if grep -qE 'hooks/session-start|--dangerously-bypass-hook-trust|run_adapter' \
    scripts/conformance-smoke.sh; then
  echo "FAIL: skills-only conformance smoke retains a runtime adapter" >&2
  exit 1
fi

echo "OK: missing host stays red and conformance is skills-only"
