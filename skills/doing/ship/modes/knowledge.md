# Ship — knowledge mode

Close a knowledge or decision note's lifecycle. Triggered by `/ship knowledge <path>` or `/ship <path>` where `<path>` is under `knowledge/` or any `decisions/` directory (work-topic close, replaces v2.1 `/work-ship`).

Run from vault root. Pass the note path as `$ARGUMENTS`. If empty, ask.

## Path validation (gate)

```bash
NOTE="$ARGUMENTS"
[ -z "$NOTE" ] && echo "需要 note path" && exit 1
[ ! -f "$NOTE" ] && echo "note 不存在: $NOTE" && exit 1
case "$NOTE" in
  knowledge/*|*/knowledge/*) VARIANT=knowledge ;;
  decisions/*|*/decisions/*) VARIANT=decision ;;
  *)
    echo "錯誤：knowledge mode 只處理 knowledge/ 或 decisions/ 內 note"
    echo "  - Inbox/legacy-knowledge/ → 先 promote 到 knowledge/"
    exit 1
    ;;
esac
```

Reject paths under `Inbox/`, `Blog/`, `_archive/`, `docs/`. Substance authorship discipline: only Panda-authored knowledge or decision notes earn ship lifecycle.

**Variant routing**: if path matches `decisions/`, the skill runs the **decision-note variant** (Stage 1 also writes an `Inbox/ship-proposals/` file for manual external push; Stage 2 questions ask decision/cycle/counterfactual/scope instead of problem/type/principle). See `## Decision-note variant` section below for the full delta.

## Scope: vault-only

Knowledge mode **never writes to external systems** (Notion / Jira / Linear / Slack / X / GitHub). Every mutation lands inside the Obsidian vault directory tree. External proposals go to `Inbox/ship-proposals/` for manual push.

## Anti-ceremony rule

Default to **Close-only** (Stage 1) unless user opts into Extract / Backflow, OR Stage 1 detects a Backflow trigger (3+ citations, work-problem solve, repeat source).

Open with one question:

> 「Close-only 還是完整 ship（Close + Extract + Backflow）？」

Default to Close-only on no answer. Skip on `--full` / `--close-only`.

If Extract returns "no new insight" — that is valid. Don't force three answers.

---

## Stage 1: Close (mechanic)

### 1.1 Read the note

Read frontmatter and body. Extract: `date`, `type`, `source`, `tags`, existing `verified`, `last_human_review`, `used_in`.

### 1.2 Update frontmatter

Set:
- `verified: true`
- `last_human_review: <today YYYY-MM-DD>`

Append to `used_in:` (create if missing) — ask user one line:

> 「這個 note 是在什麼 context 被用到？(blog post / work decision / 引用 to another note / 其他)」

Record as: `- {context}: {short description} ({YYYY-MM-DD})`.

If user skips, set `used_in_review_only: true` instead.

### 1.3 Source-quality signal

If the note has a `source:` URL, append to `Inbox/feeds/source-quality.json`:

```json
{ "url": "<source>", "note": "<note path>", "signal": "shipped", "ts": "<ISO8601>" }
```

Create file if missing. curate-feeds reads this on next run.

### 1.4 Detect Backflow triggers

Scan and report:

- **Citation count**: `rg -l "\[\[$(basename "$NOTE" .md)\]\]" knowledge/ Blog/ | wc -l`
- **Solved a work problem?**: check `used_in` for keywords `work`, `yei`, or note tags
- **Repeat source domain**: count notes sharing this `source:` domain

### 1.5 Show & Confirm (gate)

Print everything written, including diffs:

```
=== /ship knowledge 完成（vault 已更新）===

Close 完成: <note path>
  citations: N
  used_in: <latest entry>
  source domain count: M
  Backflow triggers detected: [<list>]

== 已寫入 ==
1. <note path> (frontmatter)
   diff:
   + verified: true
   + last_human_review: <YYYY-MM-DD>
   + used_in:
   +   - <context>: <description> (<date>)

2. Inbox/feeds/source-quality.json (appended)

== 接下來 ==
- vault 已更新，外部系統未動
- 要繼續 Stage 2 (Extract) + Stage 3 (Backflow) 嗎？[y/N]
```

If user stops here, write ship-log entry and exit.

If no Backflow triggers AND Close-only at start, default stop, no Stage 2 question.

---

## Stage 2: Extract (semantic)

Run only on full ship OR when Stage 1 detected a trigger.

Three questions, one at a time. Allow skip.

1. **解了什麼具體問題？** (一句話。空話 reject)
2. **這是哪一類知識？** (framework / case / data / playbook / model / heuristic)
3. **有沒有 generalizable principle 可以抽出？**

Store for Stage 3. If all skipped, log `extract: empty` and skip Stage 3.

---

## Stage 3: Backflow (system update)

Routing table. Multiple rows can fire.

| 條件 | 動作 | 落點 |
|---|---|---|
| Q3 produced a generalizable principle | Draft `~/.claude/rules/<slug>.md` proposal (show diff, ask) | `~/.claude/rules/` |
| Q1 = debug pattern / pitfall / architecture decision | Draft `docs/learnings/<category>/<slug>.md` (categories: patterns / pitfalls / architecture) | `docs/learnings/` |
| citation count ≥3 AND knowledge type = framework/playbook | Add entry to `knowledge/<domain>/_index.md` "Frequently referenced" | `_index.md` |
| Q1 names a work problem AND principle is reusable | Draft SOP candidate at `<work-vault>/sop/<slug>.md` (de-sensitive) | `work-vault/sop/` |
| source domain has ≥3 shipped notes | Append to `Inbox/feeds/source-quality.json` with `signal: high-quality-source` | feed-curator data |
| Q2 = heuristic AND principle short (<200 chars) | Draft addition to memory `feedback_*` or `project_*` | `<memory-dir>` |

**Critical**: Stage 3 NEVER writes destructively without diff + confirm.

**Quote gate (no phantom quotes)**: before writing ANY drafted learning / SOP / rule, every verbatim quote (「...」 / "...") and every `[Source: <file>]` attribution in it MUST be verified greppable in the cited source: `grep -F "<a distinctive substring of the quote>" <cited-source-path>`. If it does not match, do NOT write it as a quote — paraphrase without quotation marks, or drop the attribution. Reconstructing a quote from session/context memory instead of grepping the real source is the exact failure this gate prevents (audited 2026-05-30: backflow had been fabricating verbatim quotes attributed to non-existent sessions).

---

## Output

Append to `Inbox/ship-log/YYYY-MM-DD.md`:

```markdown
## /ship knowledge <note-path> @ HH:MM

- Close: ✓ (verified, last_human_review, used_in: <context>)
- Extract: <empty | 3 answers summary>
- Backflow:
  - <action> → <落點>
- Triggers: [<list>]
- Citations: N
```

retro-week / retro-month read this for "knowledge ship rate".

---

## Failure modes

| 症狀 | 處理 |
|---|---|
| Note path doesn't exist | Abort, suggest `rg -l "<keywords>" knowledge/` to find it |
| Already verified within 30 days | Ask "重新 ship 嗎？" |
| `source-quality.json` malformed | Backup to `.bak`, recreate |
| `_index.md` missing for domain | Create skeleton |
| User aborts mid-Stage-3 | Stage 1 mutations stay; Stage 3 proposals discarded |

---

## Decision-note variant (work-topic close)

Triggered when `$NOTE` matches `decisions/`. Replaces the v2.1 `/work-ship` skill.

The skill **never writes to Notion / Jira / Linear / Slack / X / GitHub**. External-system updates are drafted as markdown proposals to `Inbox/ship-proposals/<YYYY-MM-DD>-<slug>.md` for the user to walk manually. This is intentional: external mutations on team-visible systems should never be silent — see `~/.agents/AGENTS.md` rule "external-mutation-is-proposal".

### Stage 1 — Close (decision-specific)

In addition to base Stage 1 (frontmatter update + source-quality signal):

1. **Read decision frontmatter**: `date`, `domain` (yei / other), `topic`, `notion_page`, `related_tickets`, `status`. If missing, ask user to fill.
2. **Write ship proposal** at `Inbox/ship-proposals/<YYYY-MM-DD>-<topic-slug>.md` with `[ ]` checkboxes per external system:

   ```markdown
   ---
   status: pending-manual-push
   topic: <topic>
   domain: <domain>
   decision_log: <decision note path>
   created: <YYYY-MM-DD>
   ---

   ## Notion update (manual)
   - [ ] Set Status: Resolved
   - [ ] Append Resolution section: <draft 2-3 paragraphs>
   - [ ] Tag: resolved-YYYY-MM

   ## Jira / Linear tickets to close (manual)
   - [ ] <ticket>: transition to Done. Comment: > Resolved via <decision log>.

   ## Slack notification (manual, optional)
   Channel: <#guess based on domain>
   - [ ] Draft message: > <one-line summary + link>
   ```

3. **Show & Confirm gate**: print decision log + ship-proposal in full so user reviews before any external push.

### Stage 2 — Extract (decision-specific questions)

Replace the 3 knowledge questions with 4 decision questions:

1. **最終決策 + rationale 一段話？** (對自己誠實的版本，可能比 1.2 對外版本更直白)
2. **跑了幾個 cycle 才收斂？哪些是浪費？** (浪費 = 重複討論 / 等待 / 重做)
3. **反事實：如果重來一次最快路徑是什麼？** (這個是真正的 learning gold)
4. **Work-specific 還是 generalizable？** (work-specific → 只進 work-vault；generalizable → 還要進 personal knowledge，de-sensitive 後)

Backfill answers into the decision note's "Cycle" section.

### Stage 3 — Backflow (decision-specific routing)

Add these rows to the base routing table:

| 條件 | 動作 | 落點 |
|---|---|---|
| Q4 = work-specific AND topic has reusable workflow | Draft SOP from Q3 (反事實最快路徑) | `<work-vault>/sop/<slug>.md` |
| Q4 = generalizable AND principle survives de-sensitive | Draft personal knowledge from Q3 | `knowledge/<domain>/<slug>.md` |
| Q3 names a recurring failure mode | Draft pitfall entry | `docs/learnings/pitfalls/<slug>.md` |
| Topic surfaced 3rd+ similar work problem in 90 days | Draft skill candidate proposal | `Inbox/skill-candidates/<slug>.md` |

### Output (ship-log entry)

Append to `Inbox/ship-log/YYYY-MM-DD.md` with `type: decision` (instead of `knowledge`):

```markdown
## /ship knowledge <decision-path> @ HH:MM
- type: decision
- domain: <domain>
- Close: ✓ (decision log + ship-proposal)
- Ship proposal: <path> (pending manual push)
- Extract: <empty | 4 answers summary>
- Backflow:
  - <action> → <落點>
```

### Why this lives in `/ship knowledge` not its own skill

A decision page IS a knowledge note about a decision. The shape (frontmatter + body + cross-link) is identical; only the Extract questions and one Stage 1 side-effect (ship-proposal generation) differ. v2.1 `/work-ship` was a separate skill; v2.2 folds it in as a variant to reduce surface area.
