# retro-week output formats

The print/write templates for the three large blocks. The skill keeps the
process steps and gates; the verbatim layout lives here.

## Phase 1.5 — 4-block brain synthesis (step 1f)

Print as:

```
=== BRAIN SYNTHESIS: $YEAR-W$WEEK_NUM (auto · awaiting validation) ===

EMERGING THESIS
你這週在 build 但還沒明講的觀點是: <one sentence — extract from the salient-pages cluster>
證據:
- [[slug-1]] — "<verbatim quote that hints at the thesis>"
- [[slug-2]] — "<verbatim quote that hints at the thesis>"
- [[slug-3]] — "<verbatim quote that hints at the thesis>"

CONTRADICTIONS
<for each contradiction candidate from the 1e query comparison, format as:>
- 新: [[slug-new, $DATE]] — "<quote>"
  舊: [[slug-old, $OLDER_DATE]] — "<quote>"
  衝突點: <one sentence>
  狀態: 待 user 在 Phase 2 決定 (重新想 / retire 舊的 / 兩者各管一段 context)

(If no anomalies surfaced, print: "沒有 surface 矛盾。可能 brain 還在累積、可能你這週都在同一條軌道上。")

KNOWLEDGE GAPS
本週 obsess 的 topic distribution: <topic-A: N pages, topic-B: M pages, ...>
但你 brain 完全沒有: <missing perspective inferred from gap analysis>
建議下週讀方向 (具體，不是書名): <direction>

(Discipline: do not invent specific books/articles. Just direction. This bar
applies everywhere a reading source could be named — KNOWLEDGE GAPS here, the
empty-week block, and every "Recommendation for Next Week". NO reading source
— book title / author / blog / talk / brain path — may be named unless it has
a vault basis (a slug/page that actually surfaced in the scan or gbrain
output). No basis → name a direction only, never a source.)

ONE ACTION
這週最高槓桿一件事 (從 brain 推，不是憑空):
<concrete action grounded in the 1e under-linked-hotspot gap>
槓桿來源: <which slugs / which pattern made this the highest-leverage>

===
```

## Phase 1.6 — GC sweep table (step 1h-3)

Format:

```
=== GC SWEEP: $YEAR-W$WEEK_NUM (auto · awaiting Phase 2) ===

RECENT CORRECTIONS (past 7d): N files
CONTINUE-FAILURES (past 7d):  N events across N projects

| source                                 | trigger                | count | propose                                  |
|----------------------------------------|------------------------|-------|------------------------------------------|
| feedback_no-wikilinks-in-h1            | brain page H1 with [[]]| 3x    | lint: PreToolUse:Write `^# .*\[\[`       |
| feedback_voice-rules                   | voice/phrasing slop    | 2x    | CLAUDE.md §voice line addition           |
| feedback_one-off-typo-fix             | single correction      | 1x    | leave (1x — stays as memory feedback)    |
| feedback_xxx                           | ...                    | 2x    | leave-alone (already linked to [[skill]])|
| continue-log                           | "commit now?" (5x)     | 5x    | CLAUDE.md default: auto-commit unless flag |
| continue-log                           | <unknown reason 3x>    | 3x    | investigate — Lopopolo failure mode      |

(propose cells obey the 1h step-5 recurrence gate.)

PATTERN ACROSS FILES
- N feedback files this week mention "<keyword>" → candidate new skill: <name>
  (or: no cross-file pattern detected)

ALREADY-MECHANIZED (no proposal needed)
- <list of files matching "second time" / "Nth time" rule — already covered>

===
```

Empty-week handling:

```
=== GC SWEEP: $YEAR-W$WEEK_NUM ===

RECENT CORRECTIONS (past 7d): 0 files
CONTINUE-FAILURES (past 7d):  0 events

System stable this week — no new corrections fed back, agent didn't have
to ask for nudges. Either:
  - Forcing functions are working
  - You weren't pushing edge cases
  - You weren't writing down corrections (check: did /done run this week?)
  - The agent isn't logging continue-failures (check careful skill is active)

(skipping proposal table)

===
```

## Phase 3 — final retro page (write to `brain/reflections/weekly/$YEAR-W$WEEK_NUM.md`)

```markdown
---
date: $SUNDAY
type: weekly-retro
week: $YEAR-W$WEEK_NUM
range: $MONDAY..$SUNDAY
status: complete
prep_source: $(basename "$PREP")
scan_data: true
---

# Weekly Retro $YEAR-W$WEEK_NUM ($MONDAY → $SUNDAY)

## Git Activity Summary
- [from Phase 1 scan: repos + commit counts + key deliverables]

## Learnings Health
- Total: N | New this week: N | Stale (90d+): N

## Decisions This Week
- [decision] — context, what was chosen, why (from interview)

## Validated Observations
- [observations user agreed with, with their nuance]

## Rejected / Reframed Observations
- [things I surfaced that user pushed back on — useful for next prep]

## Feedback Pattern Status
- [pattern X]: count N → N+1 / status changed to resolved / no recurrence
- (only list patterns discussed in interview)

## Recommendation for Next Week
> One concrete action — from the interview, not invented. Use the user's exact phrasing.
> No reading source (book / author / blog / talk / brain path) may be named here
> without a vault basis (a slug/page that surfaced in scan or gbrain). No basis →
> direction only, never a named source. Same bar as Phase 1.5 KNOWLEDGE GAPS.

## What I'm Sitting With
> User's open questions or unresolved tensions, in their words.

## Obsolete-yourself Candidate
> The manual work user named that should be a skill/agent/cron. Verbatim. Empty if none this week.

## GC Decisions (Garbage Collection Sweep)
> One row per Phase 1.6 proposal that user approved or rejected.
> Format: `[feedback file] → [mechanism] | decision: yes/no/defer | next: [/sprint topic if yes, reason if no, re-surface date if defer]`
> Empty if 7d window had no recent corrections.
```
