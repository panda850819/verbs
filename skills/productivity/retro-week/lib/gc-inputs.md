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

## GC classification catalogs (Phase 1.6)

Lookup tables for the Phase 1.6 classify steps. The skill keeps the steps and the recurrence gate hot; these catalogs load only when building the proposal table.

### 1h step 3 — feedback keyword → mechanism

```
filename / body keyword               → propose mechanism
─────────────────────────────────────────────────────────
"file format", "frontmatter", "yaml" → lint (PreToolUse:Write hook)
"voice", "language", "phrasing"      → CLAUDE.md rule line
"workflow", "before X", "after X"    → hook (settings.json)
"never X", "always X" + content       → skill update (anti-pattern table)
"second time", "Nth time"             → already covered by skill-gap rule, leave
                                        (do NOT propose — flag as already-mechanized)
recurring pattern across 3+ files     → propose new skill
universal rule, CC-project mem only   → promote to ~/.agents/memory/ (substrate;
                                        Codex + Hermes read it). git mv + update
                                        both MEMORY.md indexes. Exempt from the
                                        count>=2 gate — relocation, not a new
                                        mechanism. CC-local rule ≠ cross-CLI truth.
```

### 1h-2 step 3 — continue-failure reason → propose

```
reason             → propose
─────────────────────────────────────────────────────────
external-dep       → leave (real external dependency, can't auto)
preference         → if same pattern 3+ times → CLAUDE.md default
                     (e.g., "always X unless told otherwise")
judgment-call      → if same pattern 3+ times → skill rule or
                     anti-pattern entry in relevant skill
unknown            → flag as Lopopolo failure mode — skill-gap
                     candidate, propose investigation in interview
```
