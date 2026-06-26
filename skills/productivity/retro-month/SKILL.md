---
name: retro-month
description: Interactive monthly retro — read the prep brief, conduct strategic interview, decide on project memory updates, write final retro. Triggers on "/retro-month", "monthly retro", "monthly review".
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
user-invocable: true
tags: [retro, monthly, reflection, strategy]
related_skills: [retro-week]
source: manual
---

# /retro-month — Interactive Monthly Retro

Three-phase flow:
- **Phase 1 (Auto-scan)** — git log 30 days, learnings health, reference last 4 retro-week files; produce a raw scan block
- **Phase 2 (Interview)** — strategic conversation ONE question at a time using scan + prep as data
- **Phase 3 (Write)** — write final retro to brain/reflections/monthly/

**Data source = the BRAIN, not the retired obsidian-vault.** Phase 1 raw-data gathering is done by the shared, runtime-agnostic engine so Claude / Codex / Hermes all produce the same brief:

```bash
bash ~/site/skills/pandastack/scripts/retro-scan.sh month
# → writes brain/inbox/retros/<date>-retro-month-prep.md and prints its path
```

Run standalone OR after a Hermes cron has pre-generated the brief. Then read it and print a compressed scan block before Phase 2.

---

## Phase 1: Auto-scan (raw data, no interpretation)

Run the shared engine (above), then read its output. It covers git activity (brain + ~/site repos, past 30d), learnings health, recent brain pages, gbrain synthesis, and the cross-runtime GC sweep. The sub-sections below document what it gathers.

### 1a. Git activity (past 30 days)

Engine runs `git log` over the brain repo and every `~/site/{skills,apps,cli,trading}/*` repo. Summarize total commits + key deliverables by repo.

### 1b. Learnings health — past 30 days

```bash
LEARNINGS_DIR="$HOME/site/knowledge/brain/learnings"
# Count total
ls "$LEARNINGS_DIR"/*.md 2>/dev/null | wc -l
# Count new this month
find "$LEARNINGS_DIR" -name "*.md" -newer <(date -v-30d +%Y-%m-%d) 2>/dev/null | wc -l
# Stale (90d+ not modified)
find "$LEARNINGS_DIR" -name "*.md" -not -newer <(date -v-90d +%Y-%m-%d) 2>/dev/null | wc -l
```

If `$LEARNINGS_DIR` not found: note "learnings/ dir not found — skip" and continue.

### 1c. Reference last 4 retro-week files

```bash
RETRO_WEEKLY="$HOME/site/knowledge/brain/reflections/weekly"
ls "$RETRO_WEEKLY"/*.md 2>/dev/null | sort -r | head -4
```

For each found file, extract:
- `## Recommendation for Next Week` section (one line)
- `## Obsolete-yourself Candidate` section (one line)
- `## What I'm Sitting With` section (one line)

If `brain/reflections/weekly/` is empty (no weekly retros run yet this month), note "no weekly retros to reference, scan-only month" and continue.

### 1d. Print raw scan block

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

Then say: **"掃完了。要開始月度 interview 嗎？"** — wait for user.

---

## Phase 2: Locate prep brief + strategic interview

### Step 2a: Locate the prep brief

```bash
LAST_MONTH=$(date -v-1m +%Y-%m)
# Engine (and any Hermes cron) writes prep to brain/inbox/retros/$DATE-retro-month-prep.md
PREP=$(ls -t "$HOME/site/knowledge/brain/inbox/retros/"*-retro-month-prep.md 2>/dev/null | head -1)
```

If prep file exists: print compressed summary in Traditional Chinese, max 40 lines:
- Weekly retros included (with any gaps flagged)
- me.md goals (verbatim)
- Drift candidates (top 3)
- Strategic questions
- Active feedback patterns

If prep file missing: use Phase 1 raw scan block (git activity + learnings health + 4-week summaries) as the data source. Skip to interview using scan anomalies and weekly-retro patterns as starting questions.

End with: **"準備好做這個月的 retro 嗎？"** — wait.

### Step 2b: Interview — strategic, not tactical

Walk through layers ONE QUESTION AT A TIME.

**2b-i. Goal alignment**
For each goal in me.md:
- "目標 [X] 這個月有進展嗎？"
- Cite supporting/contradicting evidence from scan/prep
- Capture user's verdict: progressed / drifted / stalled / no longer relevant
- If user says "no longer relevant": flag for me.md update at end

**2b-ii. Drift candidates**
For each candidate strategic drift (from prep, OR anomalies surfaced in Phase 1 weekly-retro patterns):
- "掃描結果看起來 [drift]，你的解讀是什麼？"
- If user agrees: ask "策略要修還是接受？"
- If user disagrees: drop, capture why

**2b-iii. Project memory updates**
For each `project_*.md` flagged in prep as possibly stale:
- Read the file, show user the relevant lines
- Ask: "這還是真的嗎？要 update / supersede / archive？"
- Apply user's decision via `Edit` tool — don't rewrite, just patch the relevant section
- Always preserve the `Why:` and `How to apply:` lines unless user explicitly says otherwise

**2b-iv. Feedback patterns review**
For each `status: active` pattern in feedback-log.md:
- Show count delta this month (cross-reference weekly retro pattern counts)
- Ask: "這個月還在嗎？還算 active 嗎？"
- Update via `Edit` tool

**2b-v. Skill drift / commodity check (one question, always ask)**

> **「哪個我現在還在依賴的技能或流程，6 個月後會變 commodity？如果會，我有沒有在用它買時間去建下一層？」**

- Capture user's answer verbatim — including "想不到" or "沒有"
- If user names commodity-drift + no replacement building: flag as open strategic question in Phase 3 output
- Do NOT prescribe action. This is surfacing, not planning.

---

## Phase 3: Write final retro

Ensure output directory exists:

```bash
mkdir -p "$HOME/site/knowledge/brain/reflections/monthly"
```

Write `brain/reflections/monthly/$YEAR-$MONTH.md` (brain, not vault):

```markdown
---
date: $LAST_DAY
type: monthly-retro
month: $YEAR-$MONTH
range: $FIRST_DAY..$LAST_DAY
status: complete
prep_source: $(basename "$PREP")
scan_data: true
weekly_retros_referenced: [W$N, W$N-1, W$N-2, W$N-3]
---

# Monthly Retro $YEAR-$MONTH

## Git Activity Summary (30 days)
- [from Phase 1 scan: repos + commit counts]

## Learnings Health
- Total: N | New this month: N | Stale (90d+): N

## Weekly Retro Thread
- W[N]: [one-line recommendation + open question from that week's retro]
- W[N-1]: ...
- W[N-2]: ...
- W[N-3]: ...

## Goal Status (vs me.md)
- Goal A: [verdict from interview] — evidence + user's words
- ...

## Strategic Decisions This Month
- [decision] — context + downstream

## Drift Acknowledged or Rejected
- Acknowledged: [drift] → action: [修 / 接受]
- Rejected: [drift] → why user disagreed

## Project Memory Updates Applied
- `project_X.md`: [updated / superseded / archived] — what changed

## Feedback Patterns Status
- [pattern]: active (count: N) / resolved / archived

## Operating System Health
- Vault notes: N (Δ ±M)
- Cron health: list any failures
- Intake-to-knowledge promotion rate: P/N

## What Got 2x Better
> User's answer — verbatim.

## Strategic Shift for Next Month
> One shift, in user's words. Not a list.

## Commodity-drift Watch
> Skill or process user named as commoditizing in 6 months, plus whether a replacement is being built. Verbatim. Empty if none.

## Open Strategic Question
> What user is sitting with going into next month.
```

### Step 3b: Updates to other files

- Apply project memory edits (already done during interview; verify here)
- Update feedback-log.md status changes
- If goals in me.md need update: ask user to confirm new wording, then edit `<memory-dir>/user_*.md` accordingly, then run the user's `me.md` rebuild command (e.g. `bash ~/.claude/scripts/build-me.sh` if such a script exists in the harness)
- Update prep brief frontmatter `status: complete` if prep file exists
- Do NOT manually git commit/push — the brain's `com.pbrain.autocommit` (every 15 min) commits, pushes, and embeds.

---

## Rules

- This is **strategic conversation** — don't speed-run. If user wants to talk for 30+ minutes about one goal, that's the right outcome.
- Phase 1 data is raw input — don't interpret before interview. Let user validate.
- Project memory updates: prefer **append + supersede** over **delete + rewrite**. Use `Edit` with frontmatter `superseded: $LAST_DAY` plus a new entry, not overwriting.
- Never invent strategic shifts. They must trace to user statements.
- If user says "短版" or "skip": still run Phase 1 fully, still ask goal-alignment questions (2b-i) at minimum — those are load-bearing. Skip 2b-ii through 2b-iv only.
- If interview reveals a contradiction with the user's CLAUDE.md / AGENTS.md rules or `user_*.md` memories, surface it explicitly: "這跟 X 規則衝突，要改規則還是改行為？"
