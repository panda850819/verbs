# Installing pandastack for Codex

Enable pandastack skills in Codex via native skill discovery. Just clone and symlink.

## Prerequisites

- Git
- Codex CLI

## Installation

1. **Clone the pandastack repository:**
   ```bash
   git clone https://github.com/panda850819/pandastack.git ~/.codex/pandastack
   ```

2. **Create the skills symlink:**
   ```bash
   ln -s ~/.codex/pandastack/plugins/pandastack/skills ~/.codex/skills/pandastack
   ```

   This points Codex's native skill discovery (`$CODEX_HOME/skills/`) at the pandastack skill directory. Tested with Codex CLI 0.124.0.

   **Windows (PowerShell):**
   ```powershell
   cmd /c mklink /J "$env:USERPROFILE\.codex\skills\pandastack" "$env:USERPROFILE\.codex\pandastack\plugins\pandastack\skills"
   ```

3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

## Optional: private overlay

Pandastack's `using-pandastack` skill supports a private overlay that adds personal vault paths, private skill triggers, and active experiment windows. To enable:

```bash
export PANDASTACK_OVERLAY=$HOME/.agents/overlays/using-pandastack.md
```

The SessionStart hook appends the overlay file to the public contract. If the overlay is missing, the public contract still works on its own.

## Verify

```bash
ls -la ~/.codex/skills/pandastack
codex exec --skip-git-repo-check 'List the pandastack skills you can see.'
```

You should see a symlink pointing to your pandastack skills directory, and Codex should enumerate 26 skills as `pandastack:<name>`.

## Updating

```bash
cd ~/.codex/pandastack && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.codex/skills/pandastack
```

Optionally delete the clone: `rm -rf ~/.codex/pandastack`.

## Cross-CLI compatibility

Pandastack is designed Claude-Code-first but the lifecycle skills are CLI-agnostic. Compatibility breakdown:

- **Fully portable** (no CLI-specific tools): `careful`, `ship` (git / knowledge modes incl. decision-note variant), `review`, `checkpoint`, `write`, `grill`, `init`, `freeze`, `office-hours`, `dojo`, `sprint`, `boardroom`, `gatekeeper`, plus the 5 personas (`ceo`, `eng-lead`, `design-lead`, `ops-lead`, `product-lead`)
- **Needs Codex tool mapping** (uses `Skill` / `Agent` / subagent dispatch): see `skills/using-pandastack/references/codex-tools.md`
- **Local-environment-bound** (depends on local CLIs): `qa` (npm `agent-browser`), `deepwiki` (curl + jq). These will fail with clear "command not found" errors if dependencies are missing — that's intentional, not a bug.

Personal-tier skills (`bird`, `brief-morning`, `evening-distill`, `curate-feeds`) and Notion / Slack ops moved to the personal overlay (`~/.agents/skills/`) or to Claude.ai MCP servers in v2.2.0 — see `RESOLVER.md` § "v2.2.0 cut summary".

If you want to use only the portable subset, you can symlink individual skill directories instead of the whole `skills/` folder.
