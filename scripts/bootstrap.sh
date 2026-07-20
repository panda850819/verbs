#!/usr/bin/env bash
# verbs/scripts/bootstrap.sh
#
# Report-only: surfaces what's ready to run, what needs a public CLI, and
# what install command to run. Reads manifest.toml as the single source of
# truth. Does NOT mutate ~/.claude or ~/.codex.
#
# Usage:
#   bash scripts/bootstrap.sh              # report only
#   bash scripts/bootstrap.sh --claude     # + Claude Code install commands
#   bash scripts/bootstrap.sh --codex      # + Codex CLI install commands

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${REPO_ROOT}/manifest.toml"
printf -v QUOTED_REPO_ROOT '%q' "$REPO_ROOT"

if [ ! -f "$MANIFEST" ]; then
  echo "FATAL: manifest.toml not found at $MANIFEST" >&2
  exit 1
fi

ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }

echo
echo "Verbs bootstrap"
echo "===================="
echo "Repo:     $REPO_ROOT"
echo "Manifest: $MANIFEST"
echo

# Read core and ext skill names directly from manifest
core_skills=$(grep -B1 '^tier = "core"' "$MANIFEST" \
  | grep '^\[skill\.' \
  | sed -E 's|^\[skill\.||; s|\]$||' \
  | sort)

core_count=$(echo "$core_skills" | wc -l | tr -d ' ')

# --------------------------------------------------
# Core skills (markdown-only, ready now)
# --------------------------------------------------
echo "[1/3] Core skills (markdown-only)"
ok "$core_count skills available without pack-managed optional CLIs"
echo "      Host capabilities may still gate use (for example, QA needs browser automation)."
echo "$core_skills" | awk '{ printf "      /%-20s", $0; if (NR % 3 == 0) print "" } END { if (NR % 3 != 0) print "" }'
echo

# --------------------------------------------------
# Ext skills (public CLI dependencies)
# --------------------------------------------------
echo "[2/3] Extension skills (public CLI install)"
printf "      %-18s %-9s %s\n" "Skill" "Status" "Install"
printf "      %-18s %-9s %s\n" "-----" "------" "-------"

check_cmd() { command -v "$1" >/dev/null 2>&1; }

ext_check() {
  local skill="$1"; local cmd="$2"; local install="$3"
  if check_cmd "$cmd"; then
    printf "      %-18s \033[32m%-9s\033[0m %s\n" "$skill" "ready" "(installed)"
  else
    printf "      %-18s \033[33m%-9s\033[0m %s\n" "$skill" "missing" "$install"
  fi
}

version_ge() {
  awk -v have="$1" -v need="$2" 'BEGIN {
    nh = split(have, h, "."); nn = split(need, n, "."); max = nh > nn ? nh : nn
    for (i = 1; i <= max; i++) {
      hv = h[i] + 0; nv = n[i] + 0
      if (hv > nv) exit 0
      if (hv < nv) exit 1
    }
    exit 0
  }'
}

ext_check_version() {
  local skill="$1" cmd="$2" minimum="$3" install="$4" have
  if ! check_cmd "$cmd"; then
    printf "      %-18s \033[33m%-9s\033[0m %s\n" "$skill" "missing" "$install"
    return
  fi
  have="$("$cmd" --version 2>/dev/null | grep -Eo '[0-9]+(\.[0-9]+){2}' | head -1 || true)"
  if [ -z "$have" ] || ! version_ge "$have" "$minimum"; then
    printf "      %-18s \033[33m%-9s\033[0m need >=%s, found %s; %s\n" \
      "$skill" "outdated" "$minimum" "${have:-unparseable}" "$install"
    return
  fi
  printf "      %-18s \033[32m%-9s\033[0m %s\n" "$skill" "ready" "(installed $have)"
}

ext_check "ship"           "gh"            "brew install gh"
ext_check_version "handover/codex" "codex"  "0.144.1" "codex update"
ext_check_version "handover/claude" "claude" "2.1.206" "claude update"
ext_check_version "advisor/codex"  "codex"  "0.144.1" "codex update"
ext_check_version "advisor/claude" "claude" "2.1.206" "claude update"
ext_check "harness-slim/codex"     "codex"          "install Codex CLI"
ext_check "harness-slim/claude"    "claude"         "install Claude Code"

echo

# --------------------------------------------------
# Host install commands
# --------------------------------------------------
echo "[3/3] Host install"
case "${1:-}" in
  --claude)
    cat <<EOF
  Run in a shell:
    claude plugin validate $QUOTED_REPO_ROOT
    claude plugin marketplace add $QUOTED_REPO_ROOT --scope user
    claude plugin install verbs@verbs --scope user
  Then run /reload-plugins in Claude Code.
EOF
    ;;
  --codex)
    cat <<EOF
  Run in a shell, then restart Codex:
    codex plugin marketplace add $QUOTED_REPO_ROOT --json
    codex plugin add verbs@verbs --json
EOF
    ;;
  *)
    cat <<EOF
  Pick a host:
    Claude Code:  bash scripts/bootstrap.sh --claude
    Codex CLI:    bash scripts/bootstrap.sh --codex
    Hermes:       see docs/ADDING_A_HOST.md (manual symlink into ~/.hermes/skills/)
EOF
    ;;
esac

echo
echo "Done."
