#!/usr/bin/env bash
# tests/run-all.sh — run the deterministic Verbs test suite.
#
# The single canonical entrypoint for the suite, used by CI
# (.github/workflows/ci.yml) and runnable by hand. Each test file is self-
# contained (uses its own stubs, mktemp, and cleanup) and is
# offline by design — no network, no secrets, no real codex/LLM. Pass/fail is
# keyed on the test's EXIT CODE, never on stderr text (some tests print benign
# warnings to stderr while still exiting 0).
#
# Quarantine: tests that require network / secrets / an LLM are listed in EXCLUDE
# with a reason and run in a separate non-blocking lane (or not at all). Excluding
# is explicit and logged — never silently skipped, never weakened to fake-green.
#
# Usage: bash tests/run-all.sh            # run the blocking suite
#        VERBS_TEST_TIMEOUT=300 bash tests/run-all.sh
set -uo pipefail
cd "$(dirname "$0")/.."

# macOS still ships Python 3.9 while the manifest tooling uses stdlib tomllib
# (3.11+). Select one supported interpreter once, then put a temporary python3
# shim first in PATH so nested shell tests use the same runtime. An explicit
# VERBS_PYTHON wins and fails closed when it is unsupported.
select_python() {
  local candidate
  if [ -n "${VERBS_PYTHON:-}" ]; then
    candidates=("$VERBS_PYTHON")
  else
    candidates=(python3.14 python3.13 python3.12 python3.11 python3)
  fi
  for candidate in "${candidates[@]}"; do
    if command -v "$candidate" >/dev/null 2>&1 &&
       "$candidate" -c 'import sys, tomllib; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)' >/dev/null 2>&1; then
      resolved="$(command -v "$candidate")"
      case "$resolved" in
        /*) ;;
        *) resolved="$(cd "$(dirname "$resolved")" && pwd -P)/$(basename "$resolved")" ;;
      esac
      printf '%s\n' "$resolved"
      return 0
    fi
  done
  return 1
}

if ! PYTHON_BIN="$(select_python)"; then
  echo 'FAIL: tests require Python 3.11+ with stdlib tomllib; set VERBS_PYTHON' >&2
  exit 2
fi
if ! PYTHON_SHIM="$(mktemp -d "${TMPDIR:-/tmp}/verbs-python.XXXXXX")"; then
  echo 'FAIL: could not create Python runtime shim directory' >&2
  exit 2
fi
trap 'rm -rf "$PYTHON_SHIM"' EXIT
if ! ln -s "$PYTHON_BIN" "$PYTHON_SHIM/python3"; then
  echo 'FAIL: could not create Python runtime shim' >&2
  exit 2
fi
export PATH="$PYTHON_SHIM:$PATH"
printf 'Python runtime: %s\n' "$(python3 --version 2>&1)"
if [ "${VERBS_PYTHON_CHECK_ONLY:-0}" = "1" ]; then
  exit 0
fi

# Non-deterministic / external-dependency tests, excluded from the blocking gate.
# NB: host conformance probes require installed CLIs and real model calls, so
# they run only as explicit release evidence. Currently empty.
EXCLUDE=""

TIMEOUT="${VERBS_TEST_TIMEOUT:-${PANDA_VERBS_TEST_TIMEOUT:-240}}"
TO=""
if command -v timeout  >/dev/null 2>&1; then TO="timeout $TIMEOUT"
elif command -v gtimeout >/dev/null 2>&1; then TO="gtimeout $TIMEOUT"; fi

pass=0 fail=0 skip=0
fails=""
for f in tests/*.sh tests/*.py; do
  [ -e "$f" ] || continue
  base=$(basename "$f")
  [ "$base" = "run-all.sh" ] && continue
  case " $EXCLUDE " in *" $base "*) printf 'SKIP  %s (quarantined)\n' "$base"; skip=$((skip+1)); continue ;; esac
  case "$f" in *.py) runner=(python3 "$f") ;; *) runner=(bash "$f") ;; esac
  log="/tmp/verbs-test-$base.log"
  if $TO "${runner[@]}" >"$log" 2>&1; then
    printf 'PASS  %s\n' "$base"; pass=$((pass+1))
  else
    rc=$?
    printf 'FAIL  %s (exit %s)\n' "$base" "$rc"; fail=$((fail+1)); fails="$fails $base"
  fi
done

printf '\n== %d passed, %d failed, %d quarantined ==\n' "$pass" "$fail" "$skip"
if [ "$fail" != 0 ]; then
  printf 'failed:%s\n' "$fails"
  printf '(per-test output in /tmp/verbs-test-<name>.log)\n'
  exit 1
fi
