---
name: inbox-triage
version: 0.1.0-draft
description: |
  Weekly Inbox/ hygiene. Buckets stale .md files by category (briefs / grills / proposals / asides / topical research / handovers), proposes mv targets, archives 30d-untouched untouched-and-unreferenced files. Report-and-confirm — never auto-deletes.

  Trigger on: /inbox-triage, "clean inbox", "整理 inbox", scheduled weekly cron (suggested Sat 09:00).
  Skip when: a single Inbox file needs handling (just mv it manually).
tags: [vault, hygiene, weekly, inbox]
related_skills: [ship]
source: manual-draft
status: staging
origin: |
  2026-05-04 — Inbox 累積 48 個 .md 觸發。Inbox/ 是 vault 整理的盲區，
  每月會堆積 codex-brief / grill artifact / proposal / aside stub / topical research，
  沒有 ritual 就會永遠在那。Two-strike: Panda 之前手動清過至少兩次。
---

# Inbox Triage

Weekly broom for `Inbox/`. Categorizes stale files, proposes destinations, executes after confirm.

**Vault-only. Never deletes.** Worst case = `mv` to `Inbox/_archive-extracts/<YYYY-MM>/`.

## Anti-ceremony rule

Default: dry-run. Print bucketed plan, ask `[y/N]` once, then execute everything approved in one batch.

Skip the per-file question loop. If user wants finer control, they pass `--interactive`.

---

## Stage 1: Survey

```bash
cd ~/site/knowledge/obsidian-vault
INBOX=Inbox
TODAY=$(date +%Y-%m-%d)
CUTOFF_DAYS=${CUTOFF_DAYS:-30}
```

Scan only top-level `Inbox/*.md` (subdirs `feeds/`, `cron-reports/`, `ship-log/`, `ship-proposals/`, `legacy-knowledge*/`, `_archive-extracts/`, `X Bookmarks/` are out of scope — they have own lifecycle).

Bucket each `.md` by filename pattern + age + reference count:

| Bucket | Pattern | Default action |
|---|---|---|
| Codex/Sonnet brief | `codex-brief-*` / `sonnet-brief-*` | If task shipped (referenced in any `docs/sessions/` file) → mv to `docs/sessions/_briefs/YYYY-MM/`. Else keep. |
| Grill artifact | `grill-*` | If decision logged in any `docs/sessions/` → mv to `docs/sessions/_grills/YYYY-MM/`. Else keep. |
| Proposal / PRD | `prd-*` / `proposal-*` | Move to `Inbox/ship-proposals/` (consolidate outbox). |
| Aside stub | `*-aside-*` | If `source:` slug published AND status: stub → keep until promote. If > 60 days → mv to `_archive-extracts/`. |
| Architecture note | `*-architecture-*` / `*-flows-*` / `*-vs-*` | If referenced from `knowledge/` or `docs/sessions/` → keep. Else flag for `/knowledge promote` decision. |
| Handover / next | `handover-*` / `*-next.md` | If date > 7 days → mv to `_archive-extracts/`. Handover is short-lived. |
| Topical research batch | matched on `tags` frontmatter or filename theme cluster (≥3 files same theme) | Flag entire cluster for `/knowledge promote` (rewrite as own-voice notes) or `_archive`. Don't auto-decide. |
| Dogfood / scheduled-reviews / cron-reports | known names | Keep, active operational state. |
| Other (uncategorized > 30 days) | anything else aged out, never grep-referenced | Flag for review. |

**Reference check** (before any "untouched + unreferenced" verdict):
```bash
slug=$(basename "$f" .md)
ref_count=$(grep -rl --include="*.md" "$slug" knowledge/ docs/ Blog/ 2>/dev/null | wc -l)
```
If `ref_count > 0`, never auto-archive — it's a live reference.

**Age**:
```bash
age_days=$(( ($(date +%s) - $(stat -f %m "$f")) / 86400 ))
```

## Stage 2: Show plan

```
=== Inbox triage @ <TODAY> ===
Total Inbox/*.md: N
Aged > $CUTOFF_DAYS days: M
Will move: P
Will keep + flag: Q

== Buckets ==

[Codex briefs — 12 files, all 2026-05-03]
  → mv to docs/sessions/_briefs/2026-05/
  - codex-brief-2026-05-03-A-gbrain-ollama.md          [shipped, ref=2]
  - codex-brief-2026-05-03-C-pdctx-switch.md           [shipped, ref=3]
  ... (10 more)

[Grills — 3 files, 2026-04-30 to 2026-05-01]
  → mv to docs/sessions/_grills/2026-04+05/
  - grill-q-a-dashboard-scope-2026-05-01.md            [decision logged]
  - grill-q-b-path-e-vs-companyos-2026-05-01.md        [decision logged]
  - grill-pdctx-batch-5-mcp-allowlist-2026-04-30.md    [decision logged]

[Proposals — 2 files]
  → mv to Inbox/ship-proposals/
  - proposal-gbrain-error-disambiguation-2026-05-03.md
  - proposal-gbrain-sync-hardening-2026-05-03.md

[Architecture — 4 files]
  ⚠ Flag for /knowledge promote decision (don't auto-mv):
  - pandastack-architecture-2026-05-03.md
  - gstack-vs-pandastack-arch-2026-05-03.md
  - pandastack-v1-consolidation-flows-2026-04-29.md
  - pandastack-p1-and-hermes-pa-plan-2026-05-03.md

[Handover — 1 file, 2 days old]
  Keep (< 7 days)
  - handover-2026-05-02-next.md

[Topical cluster: real-estate (7 files, 2026-03-27)]
  ⚠ Aged 38 days, frontmatter tags=[real-estate, research], never referenced
  Flag for human decision:
   1) /knowledge promote each → personal voice notes in knowledge/finance/
   2) mv whole cluster to _archive-extracts/2026-03/
   3) Keep (still building)

[Aside stubs — 4 files (just created)]
  Keep (status: stub, source published 2026-05-03)

[Active operational]
  Keep:
  - dogfood-pandastack-v1.md
  - distill-queue.md
  - scheduled-reviews.md
  - feedback-log.md
  - inbox.base
  - claude-skills-repo-future-2026-04-29.md (still relevant)
  - skill-inventory-2026-04-29.md
  - mattpocock-skills-loop-analysis-2026-04-20.md
  - session-tagger-design-2026-04-28.md
  - browser-automation-stealth-qa-comparison-2026-05-01.md
  - prd-panda-vault-evals-2026-05-03.md
  - pandastack-architecture-2026-05-03.html

[Uncategorized aged]
  ⚠ Flag for review:
  - gbrain-chunker-stall-2026-05-02.md (ref=0, age=2d, recent — likely keep)

== Plan summary ==
- mv: 17 files (briefs + grills + proposals)
- flag for human: 11 files (real-estate cluster + architecture + 1 uncategorized)
- keep: 14 files

Approve all moves? [y/N/i (interactive)]
```

## Stage 3: Execute

On `y`:
- Create target dirs (`docs/sessions/_briefs/YYYY-MM/`, `_grills/YYYY-MM/`, `_archive-extracts/YYYY-MM/`).
- `git mv` each approved file (fall back to `mv` if cross-repo).
- Print one-line per move.

On `i` (interactive):
- For each bucket, show files, ask `[y/N/skip-bucket]`.

On `N`:
- Exit. Write to `Inbox/ship-log/<TODAY>.md`:
  ```
  ## /inbox-triage @ HH:MM (DRY-RUN)
  - surveyed: N files
  - would move: P
  - would flag: Q
  - declined to execute
  ```

## Stage 4: Report

Append to `Inbox/ship-log/<TODAY>.md`:

```
## /inbox-triage @ HH:MM

- Surveyed: N
- Moved: P
  - codex briefs → docs/sessions/_briefs/YYYY-MM/
  - grill artifacts → docs/sessions/_grills/YYYY-MM/
  - proposals → Inbox/ship-proposals/
- Flagged for human:
  - real-estate cluster (7) — decide promote vs archive
  - architecture notes (4) — /knowledge promote candidates
- Inbox/*.md count: <before> → <after>
- Next triage suggested: <TODAY + 7 days>
```

## Failure modes

| 症狀 | 處理 |
|---|---|
| Target dir doesn't exist | mkdir -p, then mv |
| `git mv` fails (untracked) | mv, warn |
| File matches multiple buckets | First match wins (order: aside > brief > grill > proposal > architecture > handover > topical > other) |
| Reference grep returns false positive (slug appears in unrelated context) | User can pass `--no-ref-check` to skip; default is conservative-keep |
| > 50 files to move | Print summary count per bucket, not full per-file list, before asking |

## Cron suggestion

```bash
# ~/Library/LaunchAgents/com.panda.inbox-triage.plist
# Saturday 09:00
0 9 * * 6 cd ~/site/knowledge/obsidian-vault && pdctx call personal:writer "/inbox-triage --dry-run > Inbox/cron-reports/$(date +%Y-%m-%d)-inbox-triage.md"
```

Dry-run mode writes the plan to `Inbox/cron-reports/`. Panda walks the `[ ]` items manually and re-runs `/inbox-triage` (without `--dry-run`) to execute approved items.

## Why this is a skill, not just a shell script

- **Decision routing**: bucketing is heuristic (filename + age + reference + frontmatter), but each rule has exceptions. Needs LLM judgment.
- **Topic clustering**: detecting the "real-estate cluster" or any other ad-hoc topical batch (≥3 files same theme) needs reading frontmatter + filename semantically.
- **`/knowledge promote` flagging**: deciding which architecture notes are promote-candidates vs archive-candidates needs reading content briefly.
- **Pure script alternative would be**: `find Inbox -mtime +30 -name "codex-brief-*" -exec git mv {} _archive/ \;` — works for the easy 60%, misses the 40% that matter.

## Two-strike origin

Strike 1: 2026-04-29 manual cleanup of skill-discovery / pandastack pre-v1 artifacts in Inbox.
Strike 2: 2026-05-04 Panda asks "Inbox 裡頭有很多東西我該怎麼清" during `/ship write` Stage 3.

## Status

`version: 0.1.0-draft` — activated 2026-05-04. Dogfood 1 real run before bumping to `0.1.0`.
