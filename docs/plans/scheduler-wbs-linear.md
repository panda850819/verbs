---
slug: scheduler-wbs-linear
date: 2026-06-13
type: plan
source: office-hours
brief: docs/briefs/2026-06-13-scheduler-wbs-linear.md
execution: code
status: done
---

# WBS store + scheduler (Linear) — executable plan

> WHAT only. WHY 在 brief。per-task status DERIVED from git/checks at execute time.
> Walking skeleton：讓 pandastack scheduler 讀得出 Linear 的「今天最緊急」。
> 執行端（daemon/spawn）、HITL 完整實作是後續 phase，不在此 plan。

## Tasks

### scheduler-wbs-linear-T01 — 對接約定 doc
- scope: `plugins/pandastack/docs/linear-contract.md`（新檔）
- 內容：(a) pandastack 7-phase lifecycle ↔ Linear workflow states 映射表；(b) `needs_human` = 哪個 custom state/label（scheduler 認它就硬停）；(c) `acceptance_criteria` 在 Linear issue description 的約定格式（一個可 parse 的區塊，如 fenced ```acceptance```）；(d) 哪些 Linear states 算 active / terminal（抄 symphony 預設並對齊 pandastack）。
- acceptance: `plugins/pandastack/docs/linear-contract.md` 存在，且 grep 得到四個小節標題（lifecycle-map / needs-human / acceptance-format / active-terminal-states）。
- depends-on: none
- status: done

### scheduler-wbs-linear-T02 — reduce：讀 Linear 出「今天最緊急」
- scope: `scripts/pandastack-linear-reduce`（新檔，python3，零依賴外的 stdlib + Linear API via env token；先做純邏輯，輸入可用 fixture JSON 以便離線測）
- 行為：輸入 active issues（Linear API 或 fixture）→ 排除 blocked（blocked_by 非 terminal）→ 排除 needs_human state → stable-sort `priority DESC, created_at ASC`（抄 symphony §8.2）→ 輸出今天最緊急的 JSON 清單。
- acceptance: `bash tests/linear-reduce.sh` 綠 — 對一份 fixture（含 blocked / needs_human / 不同 priority 的 issues）斷言輸出順序正確且 blocked/needs_human 被排除。
- depends-on: scheduler-wbs-linear-T01
- status: done

### scheduler-wbs-linear-T03 — reduce 接真 Linear（讀取載體）
- scope: `scripts/pandastack-linear-reduce` 加一個 `--source linear` 模式，用 Linear API key（env `LINEAR_API_KEY`）拉 active issues 餵進 T02 的純邏輯。
- 注意：此 task 觸及「scheduler 讀 Linear 的載體」OPEN_QUESTION。先做最直接的 API-key 直打（symphony 模式），主-session-MCP 模式留待 Phase 1 載體決定。
- acceptance: 對使用者的 Linear test project 跑 `pandastack-linear-reduce --source linear --project <id>`，輸出非空且排序符合 T02 邏輯。需要使用者先在 Linear 建一個含 2-3 個 issue 的 test project（手動前置）。
- depends-on: scheduler-wbs-linear-T02
- status: done
- verified: 2026-06-14 against live personal Linear (Product team, temp test project, 8 issues). reduce 6/6 assertions green: priority sort, none-last, needs-human label gate, blocked-by-active, terminal exclusion, terminal-blocker-not-blocking. Custom-state `Needs Decision` gate NOT exercised live (Free plan blocks a dedicated Murmur team; same code path as label gate, covered by T02 fixture). Test data torn down after.

## Phase 1 (alpha) — shipped 2026-06-14: propose-only loop on Murmur dogfood

Smallest end-to-end slice that closes the loop with Panda as the dispatcher. No
unattended executor yet: the codex-invocation SSOT needs a foreground human confirm
for sandbox-escape, so auto-Codex is deferred to slice 2.

- **Linear Flow**: added `Needs Decision` (GATE) + `Verifying` (VERIFY) workflow
  states and the `needs-human` label to the Product team, so the hard gate is
  expressible live (the custom-state gate is now exercised, not just the label).
- **Murmur dogfood staged**: PRO-9 (dispatchable, has an `acceptance` block),
  PRO-10 (gated via Needs Decision), PRO-11 (blocked_by PRO-9). `reduce --source
  linear` buckets them correctly on the live project.
- **dispatcher** `~/.hermes/scripts/murmur_scheduler.sh` (read-only, zero LLM
  tokens): poll → reduce → surface the top dispatchable item + gated count as a
  Telegram proposal; empty → silent. Hosted as Hermes cron `murmur-scheduler`
  (no_agent, deliver=telegram, daily 09:00). Source backed up in `hermes-vault`.
- **writeback** `scripts/pandastack-linear-advance` — the ONE human-invoked Linear
  write: moves an issue forward one workflow state and appends a pandastack-state
  `phase_enter` event. Refuses a gated issue without `--force`.

Deferred to slice 2: auto-executor (foreground Claude `/handover` → `codex exec`),
aging/starvation guard, acceptance-block auto-verify. Promote trigger: carry one
Murmur issue Todo→Review by hand first.
