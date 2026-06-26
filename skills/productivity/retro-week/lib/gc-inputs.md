# Phase 1.6 GC inputs — shell portability + fuel lineage

Rationale behind the `1g. Pull GC inputs` block. The skill keeps the
assignments; the why lives here.

## Shell portability

- A single `find` walks all `~/.claude/projects/*/memory/` dirs in one pass.
- Use `-mtime -7` (BSD-compat). Do NOT use `-newer <(date ...)` because
  process-sub temp files have mtime = NOW, so the test never matches.
- Do NOT capture into a var and re-loop with `for d in $VAR` — zsh and bash
  word-split that expression differently and zsh treats it as one token.

## Tri-runtime memory layers

The `1g` block scans three memory layers (one `find` each), not just Claude Code:

- Claude Code → `~/.claude/projects/*/memory/`
- Substrate (Codex + all CLIs read it) → `~/.agents/memory/`
- Hermes → `~/.hermes/memories/`

## Continue-failure logs

Per the `careful` skill "Stopping discipline" — each line is one event where the
agent had to ask the user instead of resolving via tool calls. Format:
`DATE TIME | session | "question" | reason`.

## Compound-loop GC fuel (PRO-42 / PRO-40)

The `feedback_*.md` tables are nearly empty, so the converter would run on air.
Pull two streams that already carry signal:

- `DISPATCH_MISSES` — the dispatch miss log (a skill that should have fired but
  didn't), `~/.agents/memory/dispatch-miss.log`.
- `RECENT_PITFALLS` — the week's fresh pitfalls under
  `brain/learnings/pitfalls`, recorded but not yet promoted to a rule / test /
  skill edit.
