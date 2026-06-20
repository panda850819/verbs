---
date: 2026-06-19
type: brief
source: office-hours
topic: PandaStack coding-agent 自主 loop：SHIP 自主層級 + DOD 上游化
tags: [brief, office-hours, endgame, autonomy, ship-gate, linear]
linear: PRO-30
---

# Coding-agent 自主 loop：該自動 merge 嗎，與閘往哪搬

## Problem

Endgame 是「PRD 鎖定 → AI 自主開發並持續 loop」。走進來時以為要決的是編排拓樸 (a) 單一主-context vs (b) MetaGPT multi-role。Grill 後發現那不是真問題：repo 現況沒有 MetaGPT pipeline（v1.1 已刪），真正的脊椎是 single-context driver + sprint，而 loop 至今一次都沒自主寫過 code（BUILD autonomy 寫好但 production 沒開）。真正卡住的決策是：**自主到哪一格、用什麼換掉故意設的 human gate**。

## Original premise

「用 office-hours/grill 或寫好 PRD、設好 Task Goal，理論上就能自主跑」；瓶頸是 Codex quota，所以想另開一條 Claude Code cron 當 worker。

## Revised premise (after grill)

1. 「設好 Goal 就自主跑」是設計**意圖**不是現實 —— 跟 backend 是 Codex 還是 Claude 無關。缺的是 autonomous **advancement**（每次 phase 前進今天都是手動 `pandastack-linear-advance`）。
2. 「誰寫 code」(quota/backend) 和「誰推 phase / 誰蓋 merge」(autonomy) 是**兩條正交軸**。Claude-cron 只換了第一條，完全沒碰第二條 —— 而 P0 缺口全在第二條。
3. 「loop 自己過 GATE/SHIP」是**更難、更危險、要額外動工**的路（拆掉設計故意放的閘）。系統現況本來就是「driver 從不 push、PASS 只開 PR」= 人類 merge，差一個 flag 沒開。
4. 真實要求不是「拿掉人類」，是「merge 那一刻證據夠不夠 30 秒判斷結果合乎意圖」。誰按扳機次要。
5. **人類判斷沒被刪，是從 merge 端搬到 DEFINE 端**：槓桿點是 DOD/acceptance 撰寫品質 + 機器可驗，不是 merge 自動化。

Premise still load-bearing: **partial** — 原 (a)/(b) premise 作廢；新 premise（autonomy 分級 + DOD 上游化）成為主軸。

## Alternatives considered

分流維度：blast-radius（碰不碰 DB/金流/trust 邊界） × acceptance 可驗性（機器可驗 vs 人眼）。

- A: 提案者暖機 — loop 只提 issue / 寫 plan 不寫 code，測「挑對工作」的判斷力 — **Add**（2 週暖機）
- B: 證據包 PR + 人類 merge — loop 開 PR 並打包 test 輸出/截圖/diff，人類 30 秒蓋章；系統現況就在這格，差真 verify + 開 flag — **Add**（rung-0 operating mode）
- C: 低-blast × 機器可驗 子集自主 merge 進 integration branch，main 永遠人類批次 promote — **Add**（設計目標）
- D: loop 自主 merge 進 main — 用幾分鐘便利換無上限下行風險 — **Reject**（solo dev 無吞吐量理由拆最後一道閘）

## Chosen approach

**B 為 operating mode + per-task blast×可驗性 router 自動化 (低-blast × 機器可驗) 子集到 integration branch (C-subset)；main 維持人類 promote；A 暖機 2 週。** 人類注意力從 merge 蓋章移到 DOD/acceptance 撰寫。D（自主 merge main）Reject。

Executable plan: docs/plans/coding-agent-autonomy-rungs.md

## Scope

In:
- 真 VERIFY（runnable test/CI，取代 model 自我回報）
- PRD → 每張卡 {機器可驗 acceptance + blast_radius tag} 分解步驟
- blast×可驗性 router + integration-branch 自主 merge（低-blast 子集）
- 證據包進 PR（verify 輸出 + 截圖/數據 hook）
- 6 件 reversibility kit（worktree 隔離✓、原子 merge、integration-only、kill-switch、bounded --max✓、真 CI 綠燈）

Out:
- 自主 merge 進 main（永久人類 promote）
- Claude worker backend / multi-backend failover（defer 到 rung-C 之後高量才需要；屆時加在現有 agent-worker 抽象內，不另開平行 cron）
- 編排拓樸 (a)/(b) 之爭（現況即 (a)，無需重建；(b) 需從頭建執行層，本輪不做）
- Knowledge/Writer skills（write / deepwiki / gatekeeper / retro-*）排除於 coding-agent 目標設計
- stale metadata 清理（goal #1）走獨立 /sprint，PRO-30 已記，不需 office-hours

## Next skill (recommended)

```
Shape: N-sequential-sprints
Reasoning: Q2=No（任務間有依賴：真 verify 是 router 的前提，router 是自主 merge 的前提），非平行獨立分支。

Recommended skill:
  → /sprint coding-agent-autonomy-rungs   （逐 task 跑，T01 真 verify 先行）

Persona for next skill:
  → eng-lead
  Reason: 主訊號是 code/架構（verify 契約、router、reversibility kit），非 UI/process/strategy。
```

## Gotchas surfaced

- VERIFY 信任 model 自我回報（driver-autonomy.md:94）—— 拆 SHIP 閘前必須先頂上真 check，否則 = 自主 merge 沒人驗證的 code 且複利。
- `linear-reduce` 已會擋 prose acceptance（machine-checkable 才放行）—— router 的骨頭已在，缺 blast_radius tag + PRD 分解。
- destructive-guard + SessionStart 是 Claude-only hook，Codex 安裝從不 wire hooks.json —— Codex 上 loop 裸奔，與本 brief 正交但須一併文件化（PRO-30）。
- 自主 merge 進 main 是偽裝成雙向門的單向門：壞 commit 會在你發現前複利。integration-branch + bounded --max 把最壞情況壓到「reset 一條 branch」。

## Gate Log

- Stage 1 (load context): skipped (--quick)；用 PRO-30 審查結果
- Stage 2 (premise challenge): 4 questions，0 push-once，escape-hatch 未觸發；premise 從 (a)/(b) 拓樸位移到 autonomy 分級 + DOD 上游化
- Stage 3 (alternatives): 選 B+C-subset router，A 暖機，D Reject
- Stage 4 (premise refresh): 原 premise partial load-bearing；主軸已位移
- Stage 5 (output): 本檔

## Design decisions (OPEN_QUESTIONS resolved 2026-06-19)

三題收斂到同一原則：**deterministic policy + 真實 artifact 評估 + manual-start ratchet**。非三個獨立選擇，是同一條安全線的三個切面。

1. **blast_radius 誰標** → 沒人逐張標。寫一次 high-blast path policy（`migrations/`、`**/*.sql`、`**/schema*`、`auth/`、`payment/`、`.env*`、`infra/`…）；router 在 merge 時拿 loop 的**真實 diff** 比對，命中任一 high-blast path → 強制人類 merge。AI 可在 PLAN 預估，但綁定決策是 deterministic diff-match，model 改不動。比對真實 diff，非 predicted scope（loop 可能動到沒計畫動的檔）。理由：AI 自標 blast = 同 DoD 的循環論證（能把碰 DB 的 change 標成 low-blast 放行自己）。
2. **機器可驗覆蓋率** → 無百分比門檻。規則：每張卡要嘛有機器 check（→ auto-merge lane），要嘛有**指名的證據 artifact**（截圖/數字/before-after，→ 證據包 PR 人類 merge）；模糊 acceptance → PLAN gated needs-spec。每張都能 build，acceptance 型別只決定 merge lane。自主覆蓋率是跑出來發現的，非預設。
3. **promote 節奏** → 起步手動（前 ~20 筆乾淨 auto-merge 逐批親眼看）；畢業後 auto-promote = N=5 merge OR 24h 先到先觸發（起始預設可調）；promote 後 main CI 紅 → 自動 rollback 該次 promote。
