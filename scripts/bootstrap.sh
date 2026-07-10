#!/usr/bin/env bash
# pandastack/scripts/bootstrap.sh
#
# Fresh-install onboarding. Surfaces what runs out of the box, what needs a
# public install step, and what needs a private overlay. Reads manifest.toml
# as source of truth.
#
# Usage:
#   bash scripts/bootstrap.sh              # report only
#   bash scripts/bootstrap.sh --claude     # also print Claude Code install steps
#   bash scripts/bootstrap.sh --codex      # also print Codex CLI install steps
#
# This script does NOT mutate ~/.claude or ~/.codex. It tells you the commands
# to run; you run them. The install path itself is one line per host (see end).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${REPO_ROOT}/manifest.toml"

if [ ! -f "$MANIFEST" ]; then
  echo "FATAL: manifest.toml not found at $MANIFEST" >&2
  exit 1
fi

ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
miss() { printf "  \033[31m✗\033[0m %s\n" "$1"; }

echo
echo "pandastack bootstrap"
echo "===================="
echo "Repo:     $REPO_ROOT"
echo "Manifest: $MANIFEST"
echo

# ----------------------------------------------------------------------------
# 1) Substrate probe
# ----------------------------------------------------------------------------
echo "[1/4] Substrate"

if [ -f "$HOME/.agents/AGENTS.md" ]; then
  ok "~/.agents/AGENTS.md present"
else
  miss "~/.agents/AGENTS.md missing — capability-probe will ABORT on skills that load it"
  echo "      Fix: create ~/.agents/AGENTS.md (see README § Substrate)"
fi

echo

# ----------------------------------------------------------------------------
# 2) Core skills (always ready)
# ----------------------------------------------------------------------------
echo "[2/4] Core skills (markdown-only, ready now)"
# Read core skill names directly from manifest (single source of truth).
# grep -B1 catches the [skill.X] header above each `tier = "core"` line.
core_skills=$(grep -B1 '^tier = "core"' "$MANIFEST" \
  | grep '^\[skill\.' \
  | sed -E 's|^\[skill\.||; s|\]$||' \
  | sort)
core_count=$(echo "$core_skills" | wc -l | tr -d ' ')
ok "$core_count skills runnable on this clone with zero external CLI"
# Print in 3-column grid
echo "$core_skills" | awk '{ printf "      /%-22s", $0; if (NR % 3 == 0) print "" } END { if (NR % 3 != 0) print "" }'
echo

# ----------------------------------------------------------------------------
# 3) Extension skills (public install)
# ----------------------------------------------------------------------------
echo "[3/4] Extension skills (public CLI install)"
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

ext_check "agent-browser"  "agent-browser" "npm install -g agent-browser"
ext_check "deepwiki"       "curl"          "(curl + jq, usually preinstalled)"
ext_check "qa"             "agent-browser" "npm install -g agent-browser"
ext_check "ship"           "gh"            "brew install gh  (GitHub CLI, for the PR step)"
ext_check_version "handover"       "codex"  "0.144.1" "codex update"
ext_check_version "advisor/codex"  "codex"  "0.144.1" "codex update"
ext_check_version "advisor/claude" "claude" "2.1.206" "claude update"

echo

# ----------------------------------------------------------------------------
# 4) Personal skills (private overlay)
# ----------------------------------------------------------------------------
echo "[4/4] Personal skills (private overlay)"
if [ -d "$HOME/site/skills/pandastack-private" ] || [ -n "${PANDASTACK_PRIVATE:-}" ]; then
  ok "private overlay detected at $HOME/site/skills/pandastack-private"
  echo "      Unlocks: brief-morning, evening-distill, curate-feeds, bird,"
  echo "               chain-scout, misalignment, yei-alert-triage"
else
  warn "no private overlay (personal-tier skills hidden)"
  echo "      brief-morning, evening-distill, curate-feeds, bird (need gog / feed-server / bird CLIs)"
  echo "      chain-scout, misalignment, yei-alert-triage (work-specific)"
  echo "      pandastack-private is not currently published."
  echo
  echo "      For Notion / Slack ops: use Claude.ai Notion / Slack MCP via OAuth"
  echo "      (the public /notion and /slack skills were deleted in v2.2.0)."
fi

echo

# ----------------------------------------------------------------------------
# 5) Host install hint
# ----------------------------------------------------------------------------
echo "[Host install]"
case "${1:-}" in
  --claude)
    cat <<EOF
  Run inside Claude Code:
    /plugin marketplace add $REPO_ROOT
    /plugin install pandastack@pandastack
    /reload-plugins
  Then run /pandastack:init once in your project.
EOF
    ;;
  --codex)
    cat <<EOF
  Run in shell, then restart Codex CLI:
    mkdir -p \$HOME/.codex/skills
    ln -sfn $REPO_ROOT/skills \$HOME/.codex/skills/pandastack
EOF
    ;;
  *)
    cat <<EOF
  Pick a host:
    Claude Code:  bash scripts/bootstrap.sh --claude
    Codex CLI:    bash scripts/bootstrap.sh --codex
    Hermes:       see docs/HERMES.md (direct skill import into ~/.hermes/skills/)
EOF
    ;;
esac

echo
echo "Done."
