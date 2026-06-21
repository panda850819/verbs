#!/usr/bin/env bash
# PreToolUse ticket-gate guard — blocks Edit/Write/MultiEdit to a CODE file in a
# git code-repo when you are NOT on an issue-keyed worktree (branch like
# `feat/PRO-12-slug` / `fix/pro-7`). Lifts the ticket-gated-worktree rule from
# convention to structural enforcement. Mirrors pretooluse-destructive-guard.sh:
# PreToolUse, exit 2 to block, env bypass.
#
# FAIL-OPEN by design: anything ambiguous (tool not an editor, no file_path, not
# in a git repo, non-code extension, exempt path, parse error) is ALLOWED. A false
# block on the core edit path is worse than a missed gate; the only block path is
# the unambiguous one (a code file, in a git repo, off any issue-keyed branch).
#
# Carve-outs (always allowed): the brain repo and the live harness config trees
# (~/.agents, ~/.claude, ~/.codex) keep their auto-resolve / careful workflow.
# Bypass: PSTICKET_FORCE=1 or PANDA_FORCE=1 in the environment.
#
# This is a pandastack PLUGIN hook → runs under Claude Code and Codex alike. The
# decision is purely environmental (tool + path + repo branch); no active-skill
# signal is needed, so it works in interactive and headless contexts equally.
#
# Test offline (zero risk): bash tests/ticket-gate-guard-test.sh
set -euo pipefail

INPUT=$(cat)
TOOL=$(printf '%s' "$INPUT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null || true)
case "$TOOL" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac

# Bypass (env only — Edit/Write carry no command string for a trailing marker).
[ "${PSTICKET_FORCE:-}" = "1" ] && exit 0
[ "${PANDA_FORCE:-}" = "1" ] && exit 0

# HOME may be unset in headless/cron/launchd contexts; without it the carve-outs
# can't be computed, so fail open rather than crash under `set -u` or mis-gate.
[ -n "${HOME:-}" ] || exit 0

FP=$(printf '%s' "$INPUT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)
[ -n "$FP" ] || exit 0
ABS=$(python3 -c 'import os,sys;print(os.path.abspath(os.path.expanduser(sys.argv[1])))' "$FP" 2>/dev/null || true)
[ -n "$ABS" ] || exit 0

# Carve-outs: brain repo + harness config trees → always allowed.
case "$ABS" in
  "$HOME"/site/knowledge/brain/*|"$HOME"/.agents/*|"$HOME"/.claude/*|"$HOME"/.codex/*) exit 0 ;;
esac

# Only gate CODE files. Doc / config / unknown extensions → allowed (don't
# over-block; over-blocking trains operators to reflexively bypass — see PRO-52).
# Case-insensitive: macOS filesystems are case-insensitive, so .PY == .py.
ABS_LC=$(printf '%s' "$ABS" | tr '[:upper:]' '[:lower:]')
case "$ABS_LC" in
  *.py|*.sh|*.bash|*.zsh|*.js|*.mjs|*.cjs|*.ts|*.tsx|*.jsx|*.go|*.rs|*.rb|*.java|*.c|*.cc|*.cpp|*.h|*.hpp|*.swift|*.kt|*.php|*.lua|*.pl) ;;
  *) exit 0 ;;
esac

DIR=$(dirname "$ABS")
# Write may target a not-yet-existing directory; walk up to the deepest existing
# ancestor so the repo is still resolved (else a new-dir Write silently fails open).
while [ ! -d "$DIR" ] && [ "$DIR" != "/" ] && [ -n "$DIR" ]; do DIR=$(dirname "$DIR"); done
TOP=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$TOP" ] || exit 0   # not a git repo → not a branch/PR code repo → allowed

BR=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
# Fail open on no-branch states (detached HEAD mid-rebase / bisect / tag checkout,
# or empty) — unprovable as off-ticket, and the contract is fail-open on ambiguity.
case "$BR" in HEAD|"") exit 0 ;; esac
# Issue-keyed if the branch carries a <key>-<num> token anywhere at a start/slash
# boundary — covers feat/PRO-12-slug, Linear's username-prefixed panda-zeng/pro-51,
# digit-bearing keys (pro2-12), and nested namespacing — OR a GitHub number-led
# segment (42-fix). main / master / develop / scratch (no such token) → block.
printf '%s' "$BR" | grep -qiE '(^|/)[a-z][a-z0-9]*-[0-9]+|(^|/)[0-9]+-' && exit 0

# Code file, in a code repo, off any issue-keyed branch (default branch / ad-hoc) → block.
echo "BLOCKED by pandastack ticket-gate guard: code edit outside an issue-keyed worktree." >&2
echo "  file:   $ABS" >&2
echo "  branch: ${BR:-<unknown>}   repo: $TOP" >&2
echo "Code work belongs on a ticket-keyed worktree. Open one first, e.g.:" >&2
echo "  git -C \"$TOP\" worktree add -b feat/<key>-<slug> ../<key>-<slug> main" >&2
echo "Exempt: brain repo, ~/.agents|~/.claude|~/.codex. Bypass: PSTICKET_FORCE=1." >&2
exit 2
