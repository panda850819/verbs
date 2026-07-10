#!/usr/bin/env bash
# Stable plugin hook path. Runtime/policy logic lives in the shared Python
# normalizer so Claude Code and Codex cannot drift into separate parsers.
set -euo pipefail

HOOK_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec python3 "$HOOK_DIR/runtime_events.py" ticket-gate
