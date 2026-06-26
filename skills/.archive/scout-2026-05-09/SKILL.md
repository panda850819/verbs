---
name: scout
aliases: [harness-survey]
description: |
  Reconnoiter public ecosystem (GitHub repos, public SKILL.md, public AGENTS.md) for
  harness/skill patterns worth importing. 6 phases: search → fetch READMEs →
  triage with vault dedup → deep-read top picks → distill to substrate diff →
  execute approved subset.
  Trigger on /scout, /harness-survey (alias), "scout the ecosystem", "look at someone
  else's harness for inspiration", or when own harness layer is stuck and needs
  external perspective.
  Skip when: already know exactly what to copy (just do it), or query is
  internal vault content (search the vault directly).
status: active
origin: done-promote
activated: 2026-05-04
observed_count: 2
observed_at:
  - 2026-04-18  # harness-architecture-instinct-loop session — surveyed ECC 159 + 4-5 public Claude Code harnesses → Instinct Loop substrate
  - 2026-05-03  # gstack-distillation-substrate-patches session — surveyed 30+ gstack/gbrain repos + 2 flagship SKILL.md → grill/review/AGENTS.md v0.6.0
reads:
  - vault: knowledge/**
  - vault: docs/learnings/**
  - vault: docs/sessions/**
  - cli: gh
writes:
  - vault: docs/sessions/YYYY-MM-DD-<topic>-survey.md
  - vault: Inbox/ship-proposals/*.md
  - cli: stdout
forbids:
  - cli: gh repo create
  - cli: git push
domain: shared
classification: hybrid
---

# Harness Survey

Mine the public ecosystem for harness / skill / framework patterns worth importing. Bound exploration cost; force layer-aware triage; output a substrate diff candidate list, not a 1000-line summary.

## When to use

- Someone you respect retweeted / shipped a new harness or skill cluster (Garry Tan / Boris / obra / rauchg / etc)
- Your own harness layer is stuck (review skill bloated / skill auto-routing pain / persona overlap) and you want external calibration
- Need to find DeFi-ops / trading-skill / domain-specific framework template (pattern transfers — not limited to harness)

## When to skip

- Already know which repo to read — `gh api` directly + skip the survey overhead
- Internal vault search — read `knowledge/` / `docs/sessions/` directly
- Domain-specific narrow query without public ecosystem (e.g. "how does our internal treasury process work" — internal only)

## Pre-check (cheap-first)

Before launching the survey, scan your own vault once for the topic:

```bash
rg -l "<topic>" knowledge/ docs/sessions/ docs/learnings/ | head -5
ls knowledge/ docs/sessions/ | rg -i "<topic>" | head -5
```

If vault already has a recent (< 30 days) survey or strong related note, surface it and ask user: "你 N 天前已經survey過 [[<note>]]，要重做還是基於它擴充？" Skip the survey if user picks "基於它擴充" — go straight to Phase 5 with that note as input.

## Phase 1: Search

```bash
gh search repos "<topic>" --limit 30 --json name,owner,description,stargazersCount,url,updatedAt \
  --jq 'sort_by(-.stargazersCount) | .[] | "\(.stargazersCount)★ \(.owner.login)/\(.name) - \(.description // "no desc") [updated: \(.updatedAt)]"'
```

Optional second pass with related search terms (synonyms / forks / variants) if first pass < 10 hits.

Filter rules:
- Updated > 12 months ago and stars < 50 → likely abandoned, drop
- Star count is a weak signal; description quality + updatedAt + owner reputation override
- Same owner with 5+ repos in the result → list once, not 5 times

Output: ranked list with stars + 1-line description. Show user; user can drop obvious noise before Phase 2.

## Phase 2: Fetch READMEs (top 5-10)

```bash
gh api repos/<owner>/<name>/readme --jq '.content' | base64 -d | head -150
```

Cap at 150 lines per README (most signal is in the first 100). For 5-10 repos in parallel via single message multi-tool. Don't deepwiki at this stage — too slow per repo, defer to Phase 4 when the candidate list is short.

## Phase 3: Triage (vault dedup + gap match)

For each candidate from Phase 2:

1. **Vault dedup check** (one ripgrep per candidate):
   ```bash
   rg -l -i "<candidate's distinctive feature keywords>" knowledge/ Inbox/ | head -5
   ```
   If vault has a note covering the same pattern → tag `[ALREADY_KNOW]`, link the note, drop from further consideration.

2. **Layer-aware mapping** (mandatory — feedback-log 2026-05-01 rule):
   List your own architecture layers BEFORE mapping. The point is to force candidates into your layer split rather than dump them at the closest bucket. Typical multi-CLI harness layers look like:
   - Tier 1 substrate (identity / voice / routing — agent-agnostic)
   - Tier 2 runtime shims (Claude / Codex / Gemini dotdir specific)
   - Tier 3 schedulers (cron / launchd / Hermes / native)
   - skill content (markdown + scripts)
   - lib modules (shared structure across skills)

   For each candidate, tag which layer it lands in. **Reject any candidate that wants to flatten across layers (cargo-cult).**

3. **ROI tag**:
   - `[STEAL_DIRECT]` — fits cleanly into one of your layers, ROI obvious
   - `[STEAL_ADAPTED]` — concept is good but needs reshaping for your layer split
   - `[NICE_TO_KNOW]` — read for context, no immediate action
   - `[SKIP]` — domain-mismatch / cargo-cult / already covered

Output: 2-column table (candidate ↔ your layer + ROI tag). User confirms list before Phase 4.

## Phase 4: Deep-read (top 3-5)

For each `[STEAL_DIRECT]` and `[STEAL_ADAPTED]`:

```bash
# Full SKILL.md / canonical file
gh api repos/<owner>/<name>/contents/<path> --jq '.content' | base64 -d > /tmp/<repo>-<file>.md
wc -l /tmp/<repo>-<file>.md
```

Read in full. If file > 800 lines (gstack-style bloat), grep section headers first to navigate, don't read linearly.

For each deep-read candidate, extract:
- The mechanism (what does it actually do)
- The discipline (anti-pattern it prevents — usually only visible in retro-residue language like "STOP rule" / "anti-skip")
- The bloat (what 80% of the file is doing that you don't need)

## Phase 5: Distill to substrate diff

For each `[STEAL_DIRECT]` / `[STEAL_ADAPTED]`:

```
Pattern: <one line>
Source: <repo>/<file>:<line range>
Lands in: <your layer>
Concrete diff:
  File: <abs path>
  Before: <quote actual current content, grep-verified>
  After:  <proposed replacement>
Rationale: <one line tied to specific gap or feedback-log entry>
```

**Quote discipline (No phantom quotes rule):** every "Before:" must be `grep -F` verifiable in your file; every "Source:" must be `grep -F` verifiable in the cited external file. Don't reconstruct from memory.

Cap: 5-7 patches max per survey. If more candidates qualify, present in priority order with explicit `[NEXT_BATCH]` tag for the rest.

## Phase 6: Execute (user-approved batches)

User picks which patches to execute now. For each approved:

1. Read target file (mandatory, even if "just edited it") — verify "Before:" still matches
2. Edit / Write / Bash (rm/mv for deletions)
3. Bump version + changelog if substrate-level (`~/.agents/_changelog.md`, `pandastack/CHANGELOG.md`)
4. Print summary: file paths touched + line counts changed

Park rejected / next-batch patches in a session note: `docs/sessions/YYYY-MM-DD-<topic>-survey.md` with full Phase 5 distill block. Future you (or `pandastack:retro-week`) can pick them up.

## Output

```markdown
## Harness Survey: <topic> — <date>

### Surveyed
- N repos (Phase 1)
- M READMEs read (Phase 2)
- K full files deep-read (Phase 4)

### Vault dedup
- [[<existing note>]] — already covers <pattern>, skipped <repo>

### Patches executed (Phase 6)
- <file>: <one line> — source <repo>/<file>:<line>

### Patches parked (next batch)
- <pattern>: <one line> — see Phase 5 block in this session note

### Cargo-cult rejections (won't import)
- <repo>'s <feature>: <reason — usually layer mismatch>
```

Save to `docs/sessions/YYYY-MM-DD-<topic>-survey.md`. If patches affect external systems (work Notion / shared protocol repos / production infra), draft `Inbox/ship-proposals/*.md` for manual push instead of auto-pushing.

## Anti-patterns

- ❌ Skipping the layer-aware mapping in Phase 3 (cargo-cult risk — feedback-log 2026-05-01)
- ❌ Reading 1000-line SKILL.md linearly without grep-navigating headers
- ❌ Importing 12 patches in one session — 5-7 cap, rest park
- ❌ Quoting "Before:" without `grep -F` verifying (No phantom quotes rule)
- ❌ Auto-pushing patches that touch external systems (work Notion / shared protocol repos / production infra)
- ❌ Treating star count as primary signal — description quality + updatedAt + owner reputation override

## Relationship to other skills

- **`pandastack:knowledge`** — internal vault content. This skill is external ecosystem.
- **`pandastack:office-hours`** — runs AFTER this skill if a patch raises scope questions worth a structured brief.
- **`pandastack:review`** — runs AFTER Phase 6 if patches touch reviewable surface.
- **`pandastack:work-ship`** — for work-domain patches that need ship proposal to Notion/Linear.
- **`pandastack:retro-week`** — picks up `[NEXT_BATCH]` parked patches when retro fires.

## Origin

Two-strike promoted via `/done` Step 3b on 2026-05-04. Prior strikes:
- 2026-04-18 — `harness-architecture-instinct-loop` session (ECC 159 + Claude Code harness survey → Instinct Loop substrate)
- 2026-05-03 — `gstack-distillation-substrate-patches` session (gstack/gbrain ecosystem → AGENTS.md v0.6.0 + pandastack skill patches)
