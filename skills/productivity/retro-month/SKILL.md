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

Run the shared engine (above), then read its output. The engine is the single source of truth for what gets gathered: git activity (brain + ~/site repos, past 30d), learnings health, recent brain pages + git-derived hotspots, the cross-runtime GC sweep, and the inbox-drain counts. Print the brief's raw blocks to the user, plus the last-4 weekly-retro summaries. What each block holds, the manual fallback if the engine is unavailable, and the weekly-retro reference commands → [`skills/productivity/retro-month/lib/scan-blocks.md`](skills/productivity/retro-month/lib/scan-blocks.md).

Then say: **"掃完了。要開始月度 interview 嗎？"** — wait for user.

---

## Phase 2: Locate prep brief + strategic interview

### Step 2a: Locate the prep brief

```bash
LAST_MONTH=$(date -v-1m +%Y-%m)
# Engine (and any Hermes cron) writes prep to brain/inbox/retros/$DATE-retro-month-prep.md
PREP=$(ls -t "$HOME/site/knowledge/brain/inbox/retros/"*-retro-month-prep.md 2>/dev/null | head -1)
```

If prep file exists: print a compressed summary in Traditional Chinese, max 40 lines, of the engine's real sections:
- Git activity (commits by repo)
- Learnings health (total / new this month / stale 90d+)
- Recent brain pages + activity hotspots
- GC sweep (recent tri-runtime feedback files)
- Inbox drain (unfiled transcript-ingest distill counts)
- Last 4 weekly-retro summaries (flag any gaps)

The engine emits raw data only — me.md goals, drift candidates, and feedback-pattern status are surfaced in the interview, not the brief. If prep file missing: use the Phase 1 raw scan block as the data source, with scan anomalies and weekly-retro patterns as starting questions.

End with: **"準備好做這個月的 retro 嗎？"** — wait. Either branch, the interview floor (2b-i) still runs.

### Step 2b: Interview — strategic, not tactical

Walk through layers ONE QUESTION AT A TIME. **Completion floor (every branch, including scan-only and 短版): 2b-i goal-alignment is asked for each me.md goal and the user's verdict captured. A run that produced only the scan with no goal-alignment answers is not done.**

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

Write `brain/reflections/monthly/$YEAR-$MONTH.md` (brain, not vault). Full output template (frontmatter + every section) → [`skills/productivity/retro-month/lib/retro-template.md`](skills/productivity/retro-month/lib/retro-template.md). Every section traces to interview answers or Phase 1 scan — never invent.

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
