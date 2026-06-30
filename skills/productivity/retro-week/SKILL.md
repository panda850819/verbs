---
name: retro-week
description: Five-phase weekly retro that scans the week (git + brain + cross-runtime GC sweep), conducts a gated one-question-at-a-time interview, and writes the final retro to brain/reflections/weekly/. Triggers on "/retro-week" or "weekly retro/review".
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
user-invocable: true
tags: [retro, weekly, reflection]
related_skills: [retro-month, ship]
source: manual
---

# /retro-week — Interactive Weekly Retro

Multi-phase flow:
- **Phase 1 (Auto-scan)** — run git log, learnings health, daily note highlights; produce a raw scan block
- **Phase 1.5 (Brain synthesis)** — auto-generated thesis / contradictions / gaps from gbrain (skipped if gbrain absent)
- **Phase 1.6 (GC sweep)** — scan past 7d `memory/feedback_*.md` across all `~/.claude/projects/*/memory/`, propose categorical fixes (lint / hook / skill / CLAUDE.md rule). Inspired by Lopopolo OpenAI Garbage Collection Day — convert observed slop into mechanism so it can't recur.
- **Phase 2 (Interview)** — show raw scan + synthesis + GC proposals to user, conduct interview ONE question at a time
- **Phase 3 (Write)** — write final retro to brain/reflections/weekly/

**Data source = the BRAIN, not the retired obsidian-vault.** All Phase 1 / 1.5 / 1.6 raw-data gathering is done by the shared, runtime-agnostic engine so Claude / Codex / Hermes all produce the same brief:

```bash
# Engine path: the pandastack checkout by default; the plugin root when installed via /plugin.
RETRO_SCAN="$HOME/site/skills/pandastack/scripts/retro-scan.sh"
[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && RETRO_SCAN="$CLAUDE_PLUGIN_ROOT/scripts/retro-scan.sh"
bash "$RETRO_SCAN" week
# → prints the prep-brief path it wrote: $BRAIN/inbox/retros/<date>-retro-week-prep.md when a
#   brain exists, else ./.pandastack/retros/. Override brain location with PANDASTACK_BRAIN;
#   see scripts/retro-scan.sh header for all env knobs.
```

Run standalone OR after a Hermes cron has already pre-generated the brief (same script, same output path). Then read that brief and print a compressed scan block to the user before Phase 2.

---

## Phase 1: Auto-scan (raw data, no interpretation)

Run the shared engine (above), then read its output. The engine already covers: git activity (brain + ~/site repos), learnings health, recent brain pages (sessions/decisions/reflections), gbrain synthesis, and the cross-runtime GC sweep. Print the brief's raw blocks to the user. What each block gathers and the manual fallback if the engine is unavailable → [`skills/productivity/retro-week/lib/scan-blocks.md`](skills/productivity/retro-week/lib/scan-blocks.md).

### 1d. Print raw scan block

Format as:

```
=== WEEK SCAN: $YEAR-W$WEEK_NUM ===

GIT ACTIVITY (past 7 days)
[repo: brain]           N commits
[repo: ...]             N commits
Key deliverables: ...

LEARNINGS HEALTH
Total: N | New this week: N | Stale (90d+): N

DAILY NOTE HIGHLIGHTS ($SINCE_DATE → today)
[list of closed action items + P0 events + decisions from daily notes]

===
```

Then say: **"掃完了。要開始 brain synthesis 嗎？"** — wait for user.

---

## Phase 1.5: Brain Synthesis (auto-generated, awaiting user validation)

Skip entirely if `gbrain` CLI is not on PATH. Print `(brain synthesis unavailable: gbrain not installed)` and proceed to Phase 2.

This is the brain looking at itself across 7 days. It is **auto-generated** — Phase 2 interview is where the user accepts / rejects each finding. Never auto-write recommendations from this section.

### 1e. Pull synthesis inputs (git-derived hotspots + real gbrain query)

Only `gbrain query` / `search` / `list` exist; salience, anomalies, and topic stats are DERIVED, not fetched.

```bash
SINCE_7D=$(date -v-7d +%Y-%m-%d)

# Hotspot pages this week (commit frequency = salience proxy) — input for THESIS
git -C "${PANDASTACK_BRAIN:-$HOME/site/knowledge/brain}" log --since="$SINCE_7D" --name-only --pretty=format: \
  | grep '\.md$' | sort | uniq -c | sort -rn | head -20

# Per top-3 hotspot TOPIC, pull older brain context — input for CONTRADICTIONS
# (compare returned older pages against this week's framing; a conflict you can
# quote from both sides = a contradiction candidate)
gbrain query "<hotspot topic>"

# Topic distribution — input for KNOWLEDGE GAPS
# derive from the hotspot list's directory prefixes (concepts/ vs projects/ vs
# people/ vs learnings/ ...); no dedicated command, count by prefix

# Under-linked hotspots — input for ONE ACTION
# a page hot in git but thin in `gbrain query "<its topic>"` results is
# under-connected; that gap is the action candidate
```

### 1f. Generate 4-block synthesis

Print the 4-block synthesis (EMERGING THESIS / CONTRADICTIONS / KNOWLEDGE GAPS / ONE ACTION). Verbatim layout → [`skills/productivity/retro-week/lib/output-formats.md`](skills/productivity/retro-week/lib/output-formats.md) (Phase 1.5 section).

**Reading-source discipline (load-bearing, applies here + every "next week" recommendation):** do not invent specific books/articles. NO reading source — book title / author / blog / talk / brain path — may be named unless it has a vault basis (a slug/page that actually surfaced in the scan or gbrain output). No basis → name a direction only, never a source.

Then say: **"synthesis 出來了。要繼續看 prep brief 還是直接進 interview？"** — wait for user.

User has 3 options:
- "進 interview" → go to Phase 2 with synthesis as starting questions
- "重來" → re-run Phase 1.5 with different gbrain queries (user can specify focus)
- "skip synthesis" → drop the synthesis block, run plain Phase 2 from raw scan only

---

## Phase 1.6: Garbage Collection Sweep (skill-gap detection)

> Origin: [[brain/media/videos/lopopolo-harness-engineering-talk-personalized|Lopopolo, OpenAI 2026-05]] — "Take every bit of slop we had observed over the course of the week that was making a PR difficult to merge and figure out ways to **categorically eliminate** it from ever happening." Solo-operator translation: every `memory/feedback_*.md` file is evidence that a forcing function did NOT fire. GC mode proposes converting recurring corrections into mechanism (lint / hook / skill / CLAUDE.md rule) so the same correction is not needed again.

**Discipline (load-bearing):** Phase 1.6 only **proposes**. Never auto-write a lint / hook / skill change. Each proposal becomes a discussion item in Phase 2 interview; user decides yes / no / defer.

### 1g. Pull GC inputs

The engine's GC-sweep block already lists recent tri-runtime feedback. Pull the same inputs here only when running standalone (no engine brief). Shell-portability rationale (`-mtime -7` vs process-sub, zsh/bash word-split) and the dispatch-miss / pitfall fuel lineage → [`skills/productivity/retro-week/lib/gc-inputs.md`](skills/productivity/retro-week/lib/gc-inputs.md).

```bash
# Tri-runtime feedback files touched in the past 7d (one find per memory layer).
RECENT_FEEDBACK=$( { \
  find "$HOME/.claude/projects" -mindepth 3 -maxdepth 3 -path "*/memory/feedback_*.md" -mtime -7 2>/dev/null; \
  find "$HOME/.agents/memory" -name "feedback_*.md" -mtime -7 2>/dev/null; \
  find "$HOME/.hermes/memories" -name "*.md" -mtime -7 2>/dev/null; } )

# Continue-failure logs + past-7d events (path prefix preserved).
CONTINUE_LOGS=$(find "$HOME/.claude/projects" -mindepth 3 -maxdepth 3 \
  -path "*/memory/log_continue-failures.md" 2>/dev/null)
RECENT_CONTINUE_EVENTS=$(SINCE=$(date -v-7d +%Y-%m-%d); \
  for log in $CONTINUE_LOGS; do \
    awk -v since="$SINCE" -v src="$log" \
      '$1 >= since { print src ":" $0 }' "$log" 2>/dev/null; \
  done)

# Compound-loop GC fuel: dispatch misses + fresh pitfalls (see skills/productivity/retro-week/lib/gc-inputs.md).
DISPATCH_MISSES=$(tail -n 50 "$HOME/.agents/memory/dispatch-miss.log" 2>/dev/null)
RECENT_PITFALLS=$(find "${PANDASTACK_BRAIN:-$HOME/site/knowledge/brain}/learnings/pitfalls" -name "*.md" -mtime -7 2>/dev/null)
```

### 1h. Build GC proposal table

For each file in `RECENT_FEEDBACK`:

1. **Extract `name:` and `description:`** from frontmatter — the rule headline
2. **Extract `Why:` line and `How to apply:` line** from body (per CLAUDE.md feedback memory schema) — the trigger context
3. **Classify trigger surface** by keyword heuristic:

   Catalog (filename / body keyword → mechanism): [`skills/productivity/retro-week/lib/gc-inputs.md`](skills/productivity/retro-week/lib/gc-inputs.md).

4. **Cross-check MEMORY.md** — if the feedback is already indexed, mark `indexed:yes` (passive). If body has a `[[wikilink]]` to an existing skill, mark `linked:<skill>` (already partially mechanized).
5. **Recurrence gate (load-bearing)** — count how many times this correction's pattern has occurred (distinct feedback files + any `count:`/recurrence marker in the body + matching continue-log events). A mechanism proposal (lint / hook / skill / CLAUDE.md rule) may ONLY be emitted to the table when `count >= 2`. A single occurrence (count == 1, no pattern signal) does NOT get a `propose` cell — render its row with `propose: leave (1x — stays as memory feedback)`. One-off corrections never become mechanisms; only recurrence justifies a forcing function.

### 1h-2. Process continue-failure events

For each line in `RECENT_CONTINUE_EVENTS`:

1. Parse out the **question text** and **reason** (last `|`-delimited field: `external-dep` / `preference` / `judgment-call` / `unknown`). **Strip surrounding quotes** before grouping — the `careful` writer wraps the question in `"..."`, so apply `gsub(/^[ ]*"|"[ ]*$/, "", question)` (or equivalent) so that `"commit?"` and `commit?` collapse to the same pattern even if writer drift produces unquoted entries.
2. **Group by question pattern** — collapse near-duplicate questions ("commit?" / "ship?" / "push now?") into a single pattern
3. Classify by reason:

   Catalog (reason → propose): [`skills/productivity/retro-week/lib/gc-inputs.md`](skills/productivity/retro-week/lib/gc-inputs.md).

Output rows for the GC table use this column shape: `[continue-log] | <question pattern> (<count>x) | <propose>`.

### 1h-3. Process compound-loop GC fuel (PRO-42 / PRO-40)

The dispatch log and fresh pitfalls are the routing + record halves of the same
"a forcing function did not fire" signal. Feed them into the same table:

1. **`DISPATCH_MISSES`** — each line (`date | runtime | signal | skill`) is a task where a
   skill should have fired but didn't. Group by `skill`; `count >= 2` for the same skill →
   propose tightening that skill's trigger / its dispatch-table row.
2. **`RECENT_PITFALLS`** — a pitfall recorded this week with `recurrence >= 2` but still no
   rule / test / skill edit → propose the promotion (the un-ratcheted record). A fresh 1x
   pitfall stays as record.

Same recurrence gate and propose-only discipline apply.

Print the GC sweep table (RECENT CORRECTIONS / CONTINUE-FAILURES counts, the propose table, PATTERN ACROSS FILES, ALREADY-MECHANIZED), or the empty-week block when the 7d window has 0 files / 0 events. Verbatim layouts → [`skills/productivity/retro-week/lib/output-formats.md`](skills/productivity/retro-week/lib/output-formats.md) (Phase 1.6 section). Propose cells obey the 1h step-5 recurrence gate.

Then say: **"GC sweep 完了。Phase 2 會把每個 proposal 變成 yes/no/defer 問題。準備好聊嗎？"** — wait for user.

### 1j. Discipline — what NOT to do here

- ❌ Do NOT write any lint / hook / skill file in Phase 1.6 — proposals only
- ❌ Do NOT propose mechanisms for one-off corrections — the 1h step-5 recurrence gate is the enforcement.
- ❌ Do NOT propose duplicating an already-linked mechanism — check `linked:<skill>` first
- ❌ Do NOT silently skip the table when 7d window is empty — print empty-week block so user sees the discipline ran

---

## Phase 2: Interview (conversation, not template)

### Step 2a: Locate the prep brief

```bash
WEEK_NUM=$(date +%V)
YEAR=$(date +%Y)
TODAY=$(date +%Y-%m-%d)
# Engine writes prep to $BRAIN/inbox/retros (or ./.pandastack/retros when no brain). Check both.
BRAIN="${PANDASTACK_BRAIN:-$HOME/site/knowledge/brain}"
PREP=$(ls -t "${PANDASTACK_RETRO_OUT:-$BRAIN/inbox/retros}/"*-retro-week-prep.md ./.pandastack/retros/*-retro-week-prep.md 2>/dev/null | head -1)
```

If prep file exists: read and print a compressed summary (Traditional Chinese, max 30 lines):
- Action items closed/open ratio
- Top 3 sessions of the week
- Candidate observations (verbatim from prep)
- Open questions (verbatim from prep)
- Active feedback patterns to cross-check

If prep file missing: use Phase 1 raw scan block as the data source instead. Skip straight to interview using scan observations as starting questions.

End with: **"準備好聊嗎？"** — wait for user.

### Step 2b: Interview flow

Walk through open questions ONE AT A TIME. Don't dump all questions at once.

For each question:
- State the question
- Cite relevant data from scan/prep ("我看到 X，所以想問...")
- Wait for user's actual answer
- Push back if answer is hand-wavy ("具體是哪一個？")
- Capture user's exact words verbatim — don't paraphrase aggressively

For each candidate observation (from prep OR from Phase 1 scan anomalies):
- "我注意到 [observation]。對嗎？還是我看錯了？"
- Wait for user
- If user disagrees: drop, don't argue
- If user agrees: ask "這是個 pattern 還是這週的特殊情況？"

For active feedback patterns (from the prep brief's cross-check list / `RECENT_FEEDBACK` files):
- "feedback 裡有 [pattern] 從 [date]，這週你覺得有再出現嗎？"
- If yes: note the recurrence for the Phase-3 Feedback Pattern Status section (count is derived from distinct `memory/feedback_*.md` files, not a hand-kept counter)
- If user thinks pattern resolved: ask if status should change to `resolved`

### GC proposal review (one pass through Phase 1.6 table)

For each row in the GC sweep proposal table (Phase 1.6):

- Cite: "GC sweep 提了 [feedback file] → propose [mechanism]. 要 action 嗎？"
- Three options: **yes** / **no** / **defer**
  - **yes**: capture as TODO in retro output (Phase 3 GC Decisions section). Do NOT auto-write the lint / hook / skill in this skill — user runs `/sprint` separately for each approved mechanism
  - **no**: capture decision + reason ("這條 feedback 留在 memory 就好，不值得升級成 lint")
  - **defer**: re-surface next week
- If user wants to discuss the underlying feedback (not just yes/no on mechanism), follow them — the slop story matters more than the proposal

If 7d window was empty (no proposals): skip this section entirely, do not invent.

### Obsolete-yourself check (one question, always ask)

Ask exactly once at the end of the interview:

> **「這週有哪件事我還在手動做，但其實該是 skill/agent/cron 的工作？」**

- If user names something: capture verbatim, flag whether it's already a two-strike candidate for `skill-discovery`
- If user says "沒有" / "想不到": accept, don't push. Negative weeks are data.
- Do NOT auto-create skills from the answer — just capture. Two-strike rule still applies.

---

## Phase 3: Write final retro

After interview, write `$OUT_DIR/$YEAR-W$WEEK_NUM.md` (the brain when present, else local `docs/retros/weekly/`). Full page template (frontmatter + all sections: Git Activity, Learnings Health, Decisions, Validated/Rejected Observations, Feedback Pattern Status, Recommendation, What I'm Sitting With, Obsolete-yourself Candidate, GC Decisions) → [`skills/productivity/retro-week/lib/output-formats.md`](skills/productivity/retro-week/lib/output-formats.md) (Phase 3 section). Recommendation for Next Week obeys the same reading-source discipline as Phase 1.5 (no named source without a vault basis).

Pick the output dir before writing — write into the brain when one exists, else a local fallback so a brain-less install doesn't fabricate the author's tree:

```bash
BRAIN="${PANDASTACK_BRAIN:-$HOME/site/knowledge/brain}"
if [ -d "$BRAIN" ]; then OUT_DIR="$BRAIN/reflections/weekly"; else OUT_DIR="docs/retros/weekly"; fi
mkdir -p "$OUT_DIR"
```

### Step 3b: Updates to other files

- Pattern recurrence + status changes are recorded in the retro page's Feedback Pattern Status section; if the user marked a pattern `resolved`, update that status in the source `memory/feedback_*.md` file (use `Edit`, don't rewrite)
- Update prep brief frontmatter `status: complete` if prep file exists
- Do NOT manually git commit/push — the brain's `com.pbrain.autocommit` (every 15 min) commits, pushes, and embeds. Just write the file.

---

## Rules

- This is a **conversation**, not a template fill. If the user wants to talk about something not in the prep, follow them.
- Phase 1 data is raw input — don't interpret it before the interview. Let user validate.
- Don't invent observations. Only validate what's in prep/scan, or surface what user says.
- Keep the interview under 15 minutes — if it's running long, ask user "繼續還是先停在這裡？"
- If user says "短版" or "快速版": still run Phase 1 fully, then skip interview, write retro directly from scan + prep with minimal commentary
- **Never auto-write recommendations** — every recommendation must trace to a user statement during interview
