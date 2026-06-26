#!/usr/bin/env bash
# verify-deploy-proof.sh — code-level enforcement of verify-the-test-loop Rule 1.
#
# Nisi principle: enforce, don't instruct. The prose rule "prove the artifact
# embeds this change before asking a human to test it" is skippable. This script
# makes it a gate: non-zero exit = do NOT ask the human to test, the bug is the
# pipeline. Called by sprint (Stage 5/6), ship, eng-lead before declaring SHIPPED.
#
# Usage:
#   verify-deploy-proof.sh <artifact> [--src DIR] [--marker STRING]
#
#   <artifact>        the built/deployed file the human will exercise
#   --src DIR         fail if any source file under DIR is newer than artifact
#   --marker STRING   fail unless STRING is present in the artifact (a unique
#                     symbol/constant from THIS change; add a temp one if needed)
#
# Exit: 0 proof holds · 1 artifact missing · 2 marker absent (stale/wrong build)
#       · 3 source newer than artifact (stale build)
set -euo pipefail

ART="${1:-}"; shift || true
SRC=""; MARKER=""; MARKER_GIVEN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --src) [ $# -ge 2 ] || { echo "missing value for --src" >&2; exit 64; }; SRC="$2"; shift 2 ;;
    --marker) [ $# -ge 2 ] || { echo "missing value for --marker" >&2; exit 64; }; MARKER="$2"; MARKER_GIVEN=1; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done

# An empty marker would match every file (false green) — reject it.
[ "$MARKER_GIVEN" = 1 ] && [ -z "$MARKER" ] && { echo "DEPLOY-PROOF FAIL: --marker was given but empty." >&2; exit 64; }

if [ -z "$ART" ] || [ ! -f "$ART" ]; then
  echo "DEPLOY-PROOF FAIL: artifact '$ART' is not a regular file. Nothing was built (or it's a dir) — fix the pipeline, do not ask anyone to test." >&2
  exit 1
fi

if [ "$MARKER_GIVEN" = 1 ]; then
  # -F: marker is a literal string, not a regex (a stale artifact must not
  # falsely pass because the marker happens to regex-match old content).
  if ! grep -qaF -- "$MARKER" "$ART" 2>/dev/null; then
    echo "DEPLOY-PROOF FAIL: marker '$MARKER' not in '$ART'. Artifact is stale or the wrong file — this change is NOT deployed. Fix the build/deploy, do not ask anyone to test." >&2
    exit 2
  fi
fi

if [ -n "$SRC" ]; then
  NEWER=$(find "$SRC" -type f -newer "$ART" 2>/dev/null | head -5 || true)
  if [ -n "$NEWER" ]; then
    echo "DEPLOY-PROOF FAIL: source newer than artifact — stale build. Offending files:" >&2
    echo "$NEWER" >&2
    echo "Rebuild (prefer clean build), then re-verify." >&2
    exit 3
  fi
fi

echo "DEPLOY-PROOF OK: '$ART'${MARKER:+ contains marker '$MARKER'}${SRC:+, no source under '$SRC' newer than it}. Safe to ask a human to test."
exit 0
