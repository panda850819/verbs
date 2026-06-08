---
name: work-ship
version: 0.1.0
status: draft
origin: manual
description: |
  Close the loop on a work topic — vault-side only. Three-stage pipeline:
  Close (decision log + ship-proposal draft) → Extract (decision / cycle waste
  / counterfactual / scope) → Backflow (work-vault SOP, personal knowledge if
  generalizable, skill candidate, feedback log). External system updates
  (Notion / Jira / Linear) are written as markdown proposals to
  Inbox/ship-proposals/ for the user to push manually — this skill never calls
  external APIs.
  Trigger: /work-ship <topic>, "ship this topic", "close out <topic>",
  "decision made on <topic>".
tags: [work, lifecycle, ship]
related_skills: [ship, retro-week, retro-month]
---

# /work-ship

Close a work topic's lifecycle: an issue, decision, project, or proposal that has reached resolution. Pass the topic identifier as `$ARGUMENTS` — Notion page URL/ID, Jira/Linear ticket key, work-vault file path, or free-text topic name.

## Scope: vault-only

This skill **never writes to Notion, Jira, Linear, Slack, or any external system**. All output lands in the vault:

- `<work-vault>/decisions/` — decision log (SSOT for the decision itself)
- `<work-vault>/sop/` — SOP drafts
- `<personal-vault>/Inbox/ship-proposals/` — markdown drafts of what to update in Notion / Jira / Linear (you push them manually later by walking the `[ ]` items)
- `<personal-vault>/Inbox/ship-log/` — audit log

Why: external mutations on team-visible systems should never be silent. Drafting to vault first means you can review the proposed update, edit wording, and push when ready — or not push at all.

## Anti-ceremony rule

Default to **Close-only** (Stage 1) unless user opts into full ship, OR Stage 1 detects a Backflow trigger (reusable pattern / generalizable principle / repeat pattern / high-cost lesson).

Open question:

> 「Close-only 還是完整 ship（Close + Extract + Backflow）？」

Default Close-only.

Extract returning empty is valid. Don't force outputs.

---

## Stage 1: Close (mechanic, vault-only)

### 1.1 Identify the topic

Resolve `$ARGUMENTS` to a canonical reference:

- Notion page URL/ID (read-only — only fetch metadata for the proposal)
- Jira/Linear ticket key (read-only — only fetch summary for the proposal)
- work-vault file path
- Or just a free-text topic name

If multiple references span the same topic, pick the canonical Notion page (or work-vault file if no Notion exists). Other references go into the proposal as cross-links.

### 1.2 Gather resolution input

Ask user:

- **Decision / outcome** (one paragraph)
- **Date resolved** (default today)
- **Scope domain**: `yei` / other
- **External references**: Notion page URL, Jira/Linear ticket keys (paste-in, optional)

### 1.3 Write decision log to work-vault

Create `<work-vault>/decisions/<YYYY-MM-DD>-<topic-slug>.md`:

```markdown
---
date: YYYY-MM-DD
domain: yei | other
topic: <short title>
notion_page: <url or null>
related_tickets: [<jira/linear keys>]
status: resolved
---

## Decision
<one paragraph from user>

## Why
<rationale, constraints, alternatives considered>

## Cycle
<how many rounds / how long / what slowed it down — fill from Stage 2 if running full ship>
```

This is the **work-vault SSOT** for the decision. Notion can change, this doesn't.

### 1.4 Write ship proposal (replaces direct Notion / Jira / Linear writes)

Create `Inbox/ship-proposals/<YYYY-MM-DD>-<topic-slug>.md`:

```markdown
---
status: pending-manual-push
topic: <topic>
domain: yei | other
decision_log: ../../../../work-vault/decisions/<file>.md
created: <YYYY-MM-DD>
---

## Notion update (manual)

Page: <url>

- [ ] Set Status: Resolved (or domain equivalent)
- [ ] Append Resolution section:

> <draft summary text — 2-3 paragraphs based on user's Decision input>

- [ ] Tag: resolved-YYYY-MM

## Jira tickets to close (manual)

- [ ] YEI-XXX: transition to Done. Comment:
  > Resolved via <decision log link>. See <notion link> for context.

(repeat per ticket)

## Linear issues to close (manual)

- [ ] ABY-XXX: status → Done. Comment:
  > Resolved via <decision log link>. See <notion link> for context.

(repeat per issue)

## Slack notification (manual, optional)

Channel: <#channel-guess based on domain>
Draft message:
> <one-line resolution summary + link to Notion / decision log>
```

**Important**: this file uses `[ ]` checkboxes so the user (or a future Claude session with explicit external-write authorization) can walk through pushes one-by-one. This skill never executes external pushes.

### 1.5 Show & Confirm (gate)

Before stopping or moving to Stage 2, show user **everything that was just written**, with the ship-proposal contents in full so they know exactly what would be pushed externally:

```
=== /work-ship 完成（vault 已更新，外部系統未動）===

Close 完成: <topic>
  Decision log: work-vault/decisions/<file>
  Ship proposal: Inbox/ship-proposals/<file> (pending manual push)
  Backflow triggers detected:
    - reusable SOP candidate? <yes/no>
    - generalizable principle? <yes/no>
    - repeat pattern (similar topic in last 90 days)? <yes/no>
    - high-cost lesson? <yes/no>

== 已寫入 ==
1. work-vault/decisions/<YYYY-MM-DD>-<slug>.md (NEW)
   <full file contents>

2. Inbox/ship-proposals/<YYYY-MM-DD>-<slug>.md (NEW)
   <full file contents — show every [ ] checkbox so user can review before any push>

== 接下來 ==
- 兩個 vault 檔已寫入，Notion / Jira / Linear / Slack 完全沒動
- Ship proposal 是 [ ] checkbox 格式，你可以：
  a) 自己看著它手動操作
  b) 直接編輯這個檔案調整措辭
  c) 等需要時用 /notion / /slack 走一遍 push 流程
  d) 什麼都不做
- 要繼續 Stage 2 (Extract) + Stage 3 (Backflow) 嗎？[y/N]
```

If user says no / stops here, write ship-log entry and exit. Tell user to walk the proposal manually when ready to push.

If no Backflow triggers AND Close-only, default stop. Don't ask Stage 2 question.

---

## Stage 2: Extract (semantic)

Four questions:

1. **最終決策 + rationale 一段話？** (對自己誠實的版本，可能比 1.2 對外版本更直白)
2. **跑了幾個 cycle 才收斂？哪些是浪費？** (浪費 = 重複討論 / 等待 / 重做。具體點名)
3. **反事實：如果重來一次最快路徑是什麼？** (這個是真正的 learning gold)
4. **Work-specific 還是 generalizable？** (work-specific → 只進 work-vault；generalizable → 還要進 personal knowledge，但要先 de-sensitive)

Backfill answers into the decision log's "Cycle" section if user is OK with it.

---

## Stage 3: Backflow (vault-only system update)

| 條件 | 動作 | 落點 |
|---|---|---|
| Q4 = work-specific AND topic has reusable workflow | Draft SOP at `work-vault/sop/<slug>.md` from Q3 (反事實最快路徑就是 SOP 草稿) | `work-vault/sop/` |
| Q4 = generalizable AND can be de-sensitive | Draft note at `knowledge/<domain>/<slug>.md` — STRIP 公司名 / 人名 / $ / ticker / 內部代號 | `knowledge/<domain>/` |
| Q2 cycle waste = pitfall pattern (反覆撞同一個錯) OR Q3 反事實揭露 architecture decision | Draft `docs/learnings/<category>/<slug>.md` (categories: patterns / pitfalls / architecture). Format: 問題 / 失敗嘗試 / root cause / 修正 / 下次怎麼避免。 | `docs/learnings/<category>/` |
| Repeat pattern detected (similar topic in `decisions/` past 90d) AND ≥2 occurrences | Draft skill candidate at `~/.claude/skills/_staging/<auto-name>/SKILL.md` (two-strike rule per `rules/skill-emergence.md`) | `_staging/` |
| Q3 reveals high-cost mistake (cycle waste > 3 rounds OR delayed by ambiguity) | Draft entry to `knowledge/personal/feedback-log.md` under "Active Patterns" | feedback-log |
| Q3 reveals new heuristic for similar topics | Draft addition to user memory `feedback_*` or `project_*` | memory (vault path) |
| Topic was a Bob (CEO) decision OR strategy memo | Add entry to `work-vault/strategy-decisions/_index.md` index for retro-month visibility | work-vault |

**All vault-internal**. de-sensitive when crossing `work-vault → personal knowledge/` — strip first, user reviews. Diff + confirm for every backflow write.

---

## Output

Append to `Inbox/ship-log/YYYY-MM-DD.md`:

```markdown
## /work-ship <topic> @ HH:MM

- Domain: yei | other
- Close (vault-side):
  - Decision log: <work-vault path>
  - Ship proposal: <Inbox path> (manual push pending)
- Extract: <empty | 4-answer summary>
- Backflow:
  - <action> → <落點>
- Triggers: [<list>]
- Cycle waste: <Q2 summary> (high / medium / low)
- External pushes pending: Notion ✗, Jira ✗, Linear ✗ (walk proposal manually)
```

retro-month reads this to compute "topics shipped per month" and "cycle waste trend".

---

## Failure modes

| 症狀 | 處理 |
|---|---|
| Topic spans multiple Notion pages, no canonical | Ask user to pick canonical, others get cross-referenced in the ship proposal |
| Notion page URL given but unreachable (auth / private) | Skip the read; record raw URL in proposal — user has access when pushing |
| User can't articulate a 反事實 in Q3 | That's a signal the topic was too tangled to learn from. Log `extract: tangled` and skip Stage 3 backflow — but still capture in feedback log if Q2 cycle waste was high |
| de-sensitive draft still contains internals | Block the personal-knowledge backflow, ask user to manually rewrite |
| Ship proposal already exists for this topic | Append `-v2` to filename, don't overwrite |

---

## Future use

The point of `/work-ship` is not to mark Notion green. The point is:

1. **work-vault SOP grows** — onboarding for new ops hires gets 10× cheaper. Each ship adds one row of institutional memory.
2. **Decision log is greppable** — same topic comes back, `rg "<keyword>" work-vault/decisions/` shows you the last 3 times this came up and what was decided.
3. **Personal knowledge gets work-tested principles** — only generalizable, de-sensitive lessons cross over. This is the L2 → L3 bridge your memory keeps pointing at.
4. **retro-month metric** — `cycle waste trend` is a leading indicator. Flat over 3 months = not learning.
5. **Skill emergence** — work-ship is one of the highest-signal sources for skill-discovery. Repeat patterns surface here first.
6. **Ship proposals are reviewable** — you push to Notion / Jira / Linear manually only after reading what's about to be sent. No silent team-visible mutations.

Without ship, work happens but doesn't compound. With ship, every resolved topic makes the next one cheaper — and nothing escapes the vault until you say so.
