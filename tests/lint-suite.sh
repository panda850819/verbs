#!/usr/bin/env bash
# tests/lint-suite.sh — gate the offline structural linters that live in
# scripts/ (issue #124). run-all.sh globs tests/*.sh, so none of these were
# ever invoked by the suite; CI never saw them. Dropping this wrapper under
# tests/ wires them into the blocking gate without touching ci.yml.
#
# Every linter here is offline by design (no network, no secrets, no LLM) and
# exits nonzero on drift. This wrapper runs them all and aggregates, so one
# failure does not mask the rest, then exits nonzero if any failed.
#
# conformance-smoke.sh: only its `hook` subtarget runs here. That subtarget is
# offline — it verifies hooks/session-start emits valid JSON per envelope. Its
# claude/codex host probes make real LLM calls and need host CLIs absent from a
# clean CI checkout, so they are deliberately excluded (suite is offline).
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
run() {
  local label="$1"; shift
  local rc
  "$@"; rc=$?
  if [ "$rc" -eq 0 ]; then
    printf 'ok    %s\n' "$label"
  else
    printf 'FAIL  %s (exit %s)\n' "$label" "$rc"
    fail=1
  fi
}

run lint-manifest-sync    bash    scripts/lint-manifest-sync.sh
run lint-eval-fresh       bash    scripts/lint-eval-fresh.sh
run lint-refs-resolve     python3 scripts/lint-refs-resolve.py
run lint-reads-block      python3 scripts/lint-reads-block.py
run lint-meta-sync        python3 scripts/lint-meta-sync.py
run lint-eval-quotes      python3 scripts/lint-eval-quotes.py
run conformance-smoke:hook bash   scripts/conformance-smoke.sh hook

if [ "$fail" -ne 0 ]; then
  echo "lint-suite: one or more offline linters failed"
  exit 1
fi
echo "lint-suite: all offline linters passed"
exit 0
