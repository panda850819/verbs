# Phase 1 scan blocks — what the engine gathers (manual fallback)

`retro-scan.sh month` produces all of these. This ref documents what each block
holds for transparency, and the manual commands to run if the engine is
unavailable. The skill's Phase 1 reads the engine's brief; only fall back here
if `retro-scan.sh` cannot run.

### 1a. Git activity (past 30 days)

Engine runs `git log` over the brain repo and every `~/site/{skills,apps,cli,trading}/*` repo. Summarize: total commits + key deliverables by repo.

### 1b. Learnings health — `brain/learnings/`

Engine counts total / new-this-month / stale(90d+) under `$HOME/site/knowledge/brain/learnings/`. If missing, it notes "learnings/ not found — skip". Manual fallback:

```bash
LEARNINGS_DIR="$HOME/site/knowledge/brain/learnings"
ls "$LEARNINGS_DIR"/*.md 2>/dev/null | wc -l                                          # total
find "$LEARNINGS_DIR" -name "*.md" -newer <(date -v-30d +%Y-%m-%d) 2>/dev/null | wc -l # new this month
find "$LEARNINGS_DIR" -name "*.md" -not -newer <(date -v-90d +%Y-%m-%d) 2>/dev/null | wc -l # stale 90d+
```

### 1c. Recent brain pages + activity hotspots — past 30 days

Engine lists recently-touched pages under `brain/sessions`, `brain/decisions`, `brain/reflections/daily`, `brain/plans`, `brain/projects`, then a git-derived hotspot list (top pages by commit frequency). Semantic synthesis happens in the interview layer, not here.

### 1d. GC sweep + inbox drain

Engine sweeps recent `feedback_*.md` across all three runtimes (Claude / substrate / Hermes) and prints unfiled transcript-ingest distill counts. Each feedback file = a forcing function that did not fire; the interview decides which become mechanism.

### Reference last 4 retro-week files (month-only)

```bash
RETRO_WEEKLY="$HOME/site/knowledge/brain/reflections/weekly"
ls "$RETRO_WEEKLY"/*.md 2>/dev/null | sort -r | head -4
```

For each found file, extract its `## Recommendation for Next Week`, `## Obsolete-yourself Candidate`, and `## What I'm Sitting With` sections (one line each). If `brain/reflections/weekly/` is empty (no weekly retros this month), note "no weekly retros to reference, scan-only month" and continue — but the interview floor (Phase 2b-i) still runs on me.md goals.

### Raw scan block format

```
=== MONTH SCAN: $YEAR-$MONTH ===

GIT ACTIVITY (past 30 days)
[repo: brain]           N commits
[repo: ...]             N commits

LEARNINGS HEALTH
Total: N | New this month: N | Stale (90d+): N

LAST 4 WEEKLY RETRO SUMMARIES
W[N]: Recommendation: ... | Open: ... | Obsolete-candidate: ...
W[N-1]: ...
W[N-2]: ...
W[N-3]: ...

===
```
