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
SRC=""; MARKER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --src) SRC="$2"; shift 2 ;;
    --marker) MARKER="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done

if [ -z "$ART" ] || [ ! -e "$ART" ]; then
  echo "DEPLOY-PROOF FAIL: artifact '$ART' does not exist. Nothing was built — fix the pipeline, do not ask anyone to test." >&2
  exit 1
fi

if [ -n "$MARKER" ]; then
  if ! grep -qa -- "$MARKER" "$ART" 2>/dev/null; then
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
