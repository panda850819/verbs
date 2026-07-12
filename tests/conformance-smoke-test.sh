#!/usr/bin/env bash
# Offline regression: requested-host absence must not be hidden by adapter tests.
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

mkdir -p "$tmp/adapter-root/hooks"
cp scripts/conformance-smoke.sh "$tmp/adapter-root/conformance-smoke.sh"
grep -Fq 'codex_args=(exec --sandbox read-only --json)' scripts/conformance-smoke.sh
if grep -Fq 'codex_args=(exec --ephemeral' scripts/conformance-smoke.sh; then
  echo "FAIL: Codex smoke must retain a transcript for Stop hooks" >&2
  exit 1
fi
cp hooks/session-start "$tmp/adapter-root/hooks/session-start"
if ! bash "$tmp/adapter-root/hooks/session-start" >"$tmp/adapter.out" 2>"$tmp/adapter.err"; then
  echo "FAIL: reference adapter trapped the session on a missing DISPATCH.md" >&2
  exit 1
fi
[ ! -s "$tmp/adapter.out" ]
grep -Fq "[verbs session-adapter] unavailable: missing DISPATCH.md; continuing without dispatch injection." "$tmp/adapter.err"

echo "OK: missing host stays red while the session adapter fails open visibly"
