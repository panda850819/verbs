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

# Non-deterministic / external-dependency tests, excluded from the blocking gate.
# skills-sh-installer-external.sh fetches a pinned npm CLI and is executed as
# explicit release evidence; the blocking suite keeps its offline contract.
# NB: the scripts/ semantic linters run offline via tests/lint-suite.sh, which
# invokes only conformance-smoke.sh's offline `adapter` subtarget; host probes
# run only in explicit installer/release evidence. The pinned npm installer
# proof below is the only quarantined test.
EXCLUDE="skills-sh-installer-external.sh"

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
