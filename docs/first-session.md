# First session — a 15-minute guided run

New to pandastack? Run this once. Assumes you've installed the plugin (README § Install) and you're in Claude Code (or Codex).

## 0. Where you are (1 min)

Skills write into your **current directory** — any writable repo or vault, not only an Obsidian vault. Work dirs (`Inbox/`, `docs/briefs/` …) are created on first write; you don't pre-make them.

The one thing a flow skill needs is an **identity contract**: `~/.agents/AGENTS.md`, a project `./CLAUDE.md`, or `./AGENTS.md`. Have none? Run `/pandastack:init` inside a git repo to create a `CLAUDE.md`. A flow skill aborts only on (a) no contract, or (b) an unwritable cwd — everything else degrades with a one-line note.

## 1. Bring a real problem to office hours (5 min)

`cd` into a repo or scratch dir, then:

```
/office-hours --quick "<a real, specific problem you're chewing on>"
```

Not a hypothetical — a real one. `office-hours` challenges your premise one question at a time, forces 2-3 named alternatives, and writes a brief to `docs/briefs/`. You walk in with a fuzzy idea and leave with a written brief. Read the brief it prints — that's the core loop.

## 2. (optional) Execute the brief (5 min)

If the brief routes to build work, run the plan it named:

```
/sprint --plan <the-slug-it-printed>
```

`sprint` runs a focused execution loop and ends in one of four terminal states: **SHIPPED / PAUSED / FAILED / ABORTED_BY_USER**. PAUSED is a legitimate stop, not a failure.

## 3. (optional) Close a note (2 min)

On a finished note in your vault:

```
/ship knowledge <path>
```

This extracts any reusable learning and files it. It never writes to external systems.

## What "done" looks like

- **office-hours** → a brief file in `docs/briefs/` ending with a "Next skill (recommended)" line.
- **sprint** → a printed terminal state (SHIPPED/PAUSED/FAILED/ABORTED_BY_USER), not a vibe.
- Each run opens with a **capability-probe** block telling you what's available. Ext CLIs you haven't installed show as a one-line install hint, not an error.

## If a skill aborts

Only two things hard-stop a flow skill: **no identity contract** (run `/pandastack:init`) or an **unwritable cwd** (`cd` somewhere writable). Everything else degrades. See README § Install for the tier model.

## Next

- README § Skills — the full catalog by bucket.
- `RESOLVER.md` — "which skill for X" routing.
