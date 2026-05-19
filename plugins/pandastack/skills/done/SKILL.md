---
name: done
description: Save session context, summarize work, persist memory at session end. Triggers on "/done", "session done", "wrap up".
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
version: "3.2.0"
user-invocable: true
---

# /done — Session Closer

Four steps. Goal: **finish in 1-2 minutes for routine sessions, 3-4 minutes when value scan finds something**. Most sessions end at Step 1 + Step 4.

- Step 1: Save session MD + daily note sync (always)
- Step 2: Memory routing (most sessions skip)
- Step 3: Value scan (skip if session < 5 substantive turns or purely mechanical)
- Step 4: Commit handoff (skip if no git repo or working tree clean)

**Output language** (same binding idiom as the Response Discipline refs below): the report printed back to the user follows `~/.agents/AGENTS.md` § Language & Voice — conversation in Traditional Chinese, technical terms / paths / code / commands stay English inline. Written artifacts (session.md / daily note / memory) match the existing corpus of that artifact type, NOT auto-translated (session-doc corpus is English-dominant; daily-note n8n sections are Chinese-labeled and n8n-owned, never rewrite). English skill scaffolding does not make the report English.

## Step 1: Save Session MD

### Determine path & metadata

```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "no-git")
# Override priority: PANDASTACK_SESSION_DIR env var → git toplevel → personal-vault
if [ -n "$PANDASTACK_SESSION_DIR" ]; then
  SESSION_DIR="$PANDASTACK_SESSION_DIR"
elif git rev-parse --show-toplevel &>/dev/null; then
  SESSION_DIR="$(git rev-parse --show-toplevel)/docs/sessions"
else
  SESSION_DIR="<personal-vault>/docs/sessions"
fi
mkdir -p "$SESSION_DIR"
# Filename: YYYY-MM-DD-<slug>.md (slug = branch name or topic in kebab-case)
```

**Short or unfocused sessions** (under 10 turns, or no clear single topic): Write a minimal session doc — collapse "What happened" to 1-2 sentences, skip "Retrospective", keep "Current state" and "Follow-ups" only if actionable.

### Write session doc

```markdown
---
date: YYYY-MM-DD
branch: <branch-or-topic>
project: <repo-or-context>
tags: [coding-session, <project>]
---

# <branch-or-topic> — <date>

## What happened
[3-5 sentence narrative — shift handover style, not bullet lists]

## Retrospective
[What shifted in thinking, what was surprising, what was confirmed.
Skip if session was purely mechanical.]

## Current state
[Where things stopped. Be specific.]

## Captured during this session
[Back-links to vault/brain pages written or updated during this session, populated by the Capture survey sub-step. Only present when `PANDASTACK_CAPTURE_DIRS` is configured AND the survey returned non-empty results — otherwise omit the section entirely.]

## Follow-ups
[Only if P0/P1 actionable items exist. Most sessions have none — omit the section entirely.]
- [ ] [P0/P1 item with concrete action and owner/deadline if known]
```

**Follow-up routing** — do NOT leave follow-ups only in the session doc. Route them:
1. **P0/P1 items** → append to today's daily note under `## Action Items` (with source session link)
2. **Dev tasks** → suggest `gh issue create` — only create if user confirms
3. **Everything else** → drop it. If it's not P0/P1, it won't get done. Don't write it down.

If you maintain a separate vault search index, this is the natural point to refresh it for today's session and daily note. That refresh is your concern, not this skill's — `done` writes vault files and stops there.

### Sync to daily note

Daily note path: `<personal-vault>/Blog/_daily/YYYY-MM-DD.md`

Append a concise summary to today's daily note. If the daily note already has session content, merge — don't duplicate. Format:

```markdown
## Session: <topic>
- [2-3 bullet summary of key outcomes, decisions, or artifacts created]
```

If P0/P1 follow-ups were identified, also append them under `## Action Items` (create section if missing):

```markdown
## Action Items
- [ ] [P0] <action> — from [[YYYY-MM-DD-session-slug]]
```

If the daily note doesn't exist yet, create it with the n8n-aligned superset schema so a race-create with the Telegram Daily Collector workflow doesn't diverge:

```markdown
---
date: YYYY-MM-DD
status: draft
message_count: 0
tags: [daily]
---

# YYYY-MM-DD Daily Log

## 想法

## 連結收集

## 轉發

## Session: <topic>

- ...

## Action Items

- ...
```

Both n8n's `Telegram Daily Collector` workflow (Merge Content node, post-2026-05-03) and `/done` create with this exact shape, so independent creates produce structurally identical files that git auto-merges. Do NOT modify the n8n-owned sections (`想法` / `連結收集` / `轉發`) or `message_count` — those belong to the n8n write path.

### Capture survey (overlay-driven, opt-in)

Some users keep a **thinking layer** separate from the work narrative — a vault / second-brain repo with directories like raw thinking, learnings, atomic concepts. Mid-session writes there are worth back-linking from the session doc so future cross-session lookups can see "during this session you also captured X".

This sub-step is **opt-in** — runs only when overlay env vars are set. Default behavior: skip silently.

```bash
# PANDASTACK_CAPTURE_DIRS — comma-list of dirs (relative to the capture repo) to scan.
# PANDASTACK_CAPTURE_REPO — path to the repo containing those dirs.
#                          Defaults to the current git toplevel if unset.

if [ -n "$PANDASTACK_CAPTURE_DIRS" ]; then
  REPO="${PANDASTACK_CAPTURE_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
  if [ -n "$REPO" ]; then
    REGEX="^($(echo "$PANDASTACK_CAPTURE_DIRS" | tr ',' '|'))/"
    # Recent commits (autocommit-aware) + uncommitted writes
    {
      git -C "$REPO" log --since="4 hours ago" --name-only --pretty=format: 2>/dev/null
      git -C "$REPO" status --short 2>/dev/null | awk '{print $NF}'
    } | grep -E "$REGEX" | sort -u
  fi
fi
```

If the list is non-empty, render under `## Captured during this session` in the session doc, grouped by directory, one markdown link per file. **If empty (or vars unset), omit the section entirely** — silence > empty placeholder.

The 4-hour window is a heuristic; if sessions genuinely run longer, widen the `--since` argument via overlay. False positives (captures unrelated to this session) are acceptable cost — back-links are cheap, missing them is the failure mode.

**Panda's binding (example):** `PANDASTACK_CAPTURE_REPO=~/site/knowledge/brain`, `PANDASTACK_CAPTURE_DIRS=originals,learnings,concepts,ideas,personal`. Other users configure their own dirs; vanilla pandastack ships with neither set, so this sub-step is invisible by default.

---

## Step 2: Memory Routing (most sessions skip)

Only save things worth remembering across sessions. The auto-memory system in the system prompt has the routing rules — follow them. Skip if nothing new.

If you DID save memory entries, also note in the daily note's session block: `Memory: +N entries (user/feedback/project/reference)`.

---

## Step 3: Value Scan (skip if session < 5 substantive turns or purely mechanical)

This is the cross-session pattern surfacing layer. **Cheap-first ladder** — sub-checks run in stages; expensive checks gate on cheap signals. Output ONE consolidated block at the end. If nothing surfaces, skip the output entirely — silence is fine.

**Ladder (do not parallel-fan-out by default):**

1. **Always**: 3a (free, transcript scan — no tool calls)
2. **If 3a surfaces ≥1 item OR session > 10 substantive turns**: run 3b + 3c + 3d in parallel
3. **Else**: skip 3b/3c/3d, exit silent

Rationale: 3a is the cheap signal. The vault scans + feedback-log read in 3b–3d only fire when 3a surfaces something worth following up on, or when the session is large enough to warrant the spend. Aligns with `~/.agents/AGENTS.md` Behavioral Default "Cheap-first internal lookup".

### 3a. Surprises & validated assumptions

Scan the conversation for:
- Things the user said "yes exactly" / "對" / "確認" to that were non-obvious
- Things that surprised either side (errors that taught something, behavior that contradicted assumptions)
- Decisions made that close off a path

If ≥ 2 surface: include in output as `## Worth saving from this session`.

**For each bullet, tag a routing suggestion** using this table:

| Content type | Route to |
|---|---|
| Reusable debugging pattern (same shape recurs across codebases) | `<learnings_dir>/patterns/` |
| Pitfall the team hit and a "what to do instead" | `<learnings_dir>/pitfalls/` |
| Architecture decision with rationale (why this shape, not that) | `<learnings_dir>/architecture/` |
| Searchable technical fact, domain concept, externalizable knowledge | `knowledge/<area>/` |
| Tool recipe / CLI gotcha / external system pointer | `memory/reference_*.md` |
| Durable preference, how-we-work rule, validated style choice | `memory/feedback_*.md` |
| 3+ step repeatable workflow (even first strike) | `_staging/skill-*` (draft only) |
| Tactical meta-observation, one-session curiosity | drop |

`<learnings_dir>` resolves from the active overlay. Panda's binding: `docs/learnings/{patterns,pitfalls,architecture}/`. The patterns/pitfalls/architecture split is the codebase-level learning layer that survives across sessions; `knowledge/` is the externalizable substance layer (concepts that hold beyond this codebase).

Default to `drop` when in doubt — surfacing is already the baseline value. Only tag a route when the content is actually compound-worthy.

### 3b. Skill candidate detection (two-strike rule)

Apply `~/.claude/rules/skill-emergence.md`:
- Did this session execute a 3+ step repeatable workflow?
- Has a similar workflow been done before?
  ```bash
  # During pbrain transition: search both new + legacy locations
  rg -l "<keywords from workflow>" "${PANDASTACK_SESSION_DIR:-docs/sessions/}" docs/sessions/ 2>/dev/null | head -3
  ```
- If you find a prior session doing the same thing, surface: `## Skill candidate: <name>` with the concrete pattern (where it ran before, where it ran today).
- Do NOT auto-create the skill. Show the pattern, let user confirm.

### 3c. Past-pattern check (cross-session memory)

Scan recent session notes for the topic:
```bash
# During pbrain transition: search both new + legacy locations
rg -l "<2-5 keywords from this session's topic>" "${PANDASTACK_SESSION_DIR:-docs/sessions/}" docs/sessions/ 2>/dev/null | head -5
```

If results include sessions from > 7 days ago that look directly relevant:
- Surface as `## Past relevant sessions` with 1-line context per hit
- This is what makes the second brain valuable — not recall, surface
- Skip if all hits are from the last few days (already in working memory)

### 3d. Feedback drift check

Read `<personal-vault>/knowledge/personal/feedback-log.md` (skip if missing).

For each `## YYYY-MM-DD` heading in the file marked `status: active`:
- Compare its **下次怎麼避** action against this session's behavior
- If the session repeated a flagged pattern, surface as `## ⚠ Feedback drift detected` with:
  - which feedback entry
  - what happened in this session
  - quoted "下次怎麼避" line

This step exists to surface bad habits **at session end** so the operator sees them within minutes, not weekly.

### Step 3 output format

Only output a Step 3 block if at least one sub-check found something. Otherwise stay silent. Format:

```markdown
---

## Step 3: Value Scan

### Worth saving from this session
- [bullet] ... (reference to where it was discussed in transcript)
  → route: `knowledge/<area>/<slug>.md` | `memory/reference_*` | `memory/feedback_*` | `_staging/skill-*` | drop

Surface only — do not append a promotion menu prompt. The operator decides whether to promote and says so directly (`promote 1, 3`, `promote all`, etc.). Skill must NOT close the block with "Reply promote N,N or skip" or any variant — that's a 2-3 option menu, banned by `feedback_voice_rules.md` and `~/.agents/AGENTS.md` Response Discipline.

### Skill candidate: <name>
- Pattern: <one line>
- Prior instance: <session-slug or daily note ref>
- This session: <what triggered the second strike>

Surface only — operator says "draft it" if they want a draft. Do not close with "→ Want me to draft the skill?" — that is a yes/no menu, banned by Response Discipline.

### Past relevant sessions
- [[YYYY-MM-DD-slug]] — <one line of why it matters now>

### ⚠ Feedback drift detected
- Feedback from YYYY-MM-DD (source: ...): "<quoted action>"
- This session: <what happened that violated it>
- → Worth re-noting in feedback-log.md as a repeat occurrence
```

### Step 3 promotion follow-through

When the operator volunteers a promotion (`promote 1, 3` / `promote all` / `promote architecture items`), execute. No menu was sent; this is operator-initiated.

1. For each selected item:
   - **`<learnings_dir>/patterns/<slug>.md`** / **`<learnings_dir>/pitfalls/<slug>.md`** / **`<learnings_dir>/architecture/<slug>.md`** — write using `lib/learning-format.md` schema (frontmatter with `type`, `key`, `first_seen`, `last_seen`, `confidence`). The patterns/pitfalls/architecture split survives across sessions on this codebase; not everything that surfaces belongs in `knowledge/`.
   - **`knowledge/<area>/<slug>.md`** — draft a full note (frontmatter with `date`, `status: draft`, `last_human_review`, `tags`). Include content expanded from the bullet, not just a stub. Leave `verified` unset.
   - **`memory/reference_*.md` or `memory/feedback_*.md`** — write the file + append index line in `MEMORY.md`. Reference memories go live immediately; feedback memories are durable so draft carefully.
   - **`_staging/skill-*/SKILL.md`** — draft with frontmatter `status: draft, origin: done-promote, observed_count: 1`. Do NOT move to `skills/` — user mv's it when two-strike fires.
2. After writing, report paths and remind: "Review before commit. Skills stay in `_staging/` until you `mv`."
3. If operator does not mention promotion in the next turn, drop silently. Never re-ask.

Promotion is **draft-and-ask for knowledge/ + feedback**, auto-resolve for reference + staging skill (both reversible, per auto-resolver policy). Operator must initiate — Step 3 surfaces, never solicits.

---

## Step 4: Commit handoff (skip if no git repo or no diff)

`/done` is the session-end act. The artifacts it writes (session.md, daily-note updates, memory entries, optional learnings) plus any working-tree code changes from the session are the same commit unit. Propose a single commit; do not require the operator to remember.

### Detection

```bash
# Working tree has any change?
DIRTY=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
[ "$DIRTY" = "0" ] && exit_step_silently

# Categorize what's pending
SESSION_FILES=$(git status --short | grep -E "docs/sessions/|Blog/_daily/" | wc -l)
LEARNING_FILES=$(git status --short | grep -E "docs/learnings/" | wc -l)
MEMORY_FILES=$(git status --short | grep -E "/memory/" | wc -l)
CODE_FILES=$(($DIRTY - $SESSION_FILES - $LEARNING_FILES - $MEMORY_FILES))
```

### Single-commit proposal (default)

If everything pending is plausibly one logical unit (session-related), propose:

```
COMMIT PROPOSAL
─────────────────
{session_files} session/daily files
{learning_files} learnings
{memory_files} memory entries
{code_files}    code/config changes

Suggested message:
  {type}({scope}): {one-line summary from Step 1 narrative}

  {2-4 line body from Step 1 "What happened" narrative}

[approve]  git add + commit as-is
[edit]     change the message
[split]    multiple commits (see below)
[skip]     no commit, leave for later
```

### Multi-commit split (when `[split]` chosen or auto-detected)

Auto-detect when the diff straddles multiple logical units:

- Vault writes (session.md / daily note / memory) → 1 commit, type `chore(daily)` or `chore(sessions)`
- Learning files → 1 commit, type `docs(learnings)`
- Code changes → 1 or more commits, type `feat / fix / refactor` per file cluster

Propose each as a separate gate. Operator approves each.

### Auto-resolve scope

Per `~/.agents/AGENTS.md` Routing Principles, vault writes are auto-resolve scope. Code-repo writes are draft-and-ask. So:

| Pending change | Default action |
|---|---|
| Session.md / daily note / memory only | Propose commit, default `[approve]` (vault auto-resolve) |
| Learnings only | Propose commit, default `[approve]` (vault auto-resolve) |
| Code changes only | Propose commit, **wait for explicit approve** (no default-Y) |
| Mixed (vault + code) | Propose **split**, default `[split]` so vault auto-commits while code waits for approve |

### Skip when

- No git repo (working in a personal context outside any tracked dir)
- No diff (working tree clean)
- Operator says `/done quick` or `/done no-commit`
- Pre-commit hook expected to fail (e.g. lint not run yet — propose `/review` first instead)
- User on a protected branch (`main` / `master`) **AND** code changes present **AND** no PR workflow → escalate, don't auto-propose direct-to-main commit

### Anti-patterns

- ❌ Committing without showing the proposed message
- ❌ Auto-committing code changes (only vault auto-resolves)
- ❌ Bundling unrelated work into one commit just because they share session
- ❌ Skipping the commit step when artifacts are written and obviously belong together
- ❌ Asking "commit?" without drafting the message first (forces operator to think too much)
- ❌ Re-asking after `[skip]` — operator chose, drop the question

---

## Safety

| Situation | Action |
|-----------|--------|
| No git repo | Use conversation topic as slug, skip Step 4 |
| MEMORY.md > 190 lines | Slim down first |
| `rg` / vault scan fails | Skip 3b/3c silently, still run 3a/3d, surface as P1 follow-up |
| feedback-log.md missing | Skip 3d silently |
| Session < 5 substantive turns | Skip Step 3 entirely (still run Step 4 if diff exists) |
| Working tree clean | Skip Step 4 silently |

## When to skip Step 3 entirely

- Session was purely mechanical (rename files, run a command, single-purpose lookup)
- Session was a continuation of an active flow (Step 3 only fires at meaningful checkpoints)
- User explicitly says "/done quick" or "just save"
