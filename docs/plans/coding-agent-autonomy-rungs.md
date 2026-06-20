---
slug: coding-agent-autonomy-rungs
date: 2026-06-19
type: plan
source: office-hours
brief: docs/briefs/2026-06-19-coding-agent-autonomy-rungs.md
execution: code
status: todo
---

# Coding-agent 自主 loop — executable plan

> WHAT only. WHY 在 brief。閘的搬移、autonomy 分級的理由都在 brief，這裡只列可驗的 task。
> 依賴鏈：真 verify (T01) → PRD 分解出 blast/acceptance (T02) → router (T03) → 證據包 (T04) → reversibility kit (T05)。T06 defer。

## Tasks

### coding-agent-autonomy-rungs-T01 — 真 VERIFY backend（取代 model 自我回報）
- scope: scripts/pandastack-drive (VERIFY phase), plugins/pandastack/docs/driver-autonomy.md, 新增 tests/drive-verify.sh
- acceptance: `bash tests/drive-verify.sh` 綠；測試含「一個故意失敗的 change 在 VERIFY 被攔下、不進 REVIEW」的 case；driver 呼叫一個 per-project verify 契約（verify cmd from work-order/repo），grep `pandastack-drive` 不再有「VERIFY = 模型自報即過」的 path
- depends-on: none
- status: todo

### coding-agent-autonomy-rungs-T02 — PRD → work-order 分解，每張卡帶機器 check 或指名 artifact
- scope: scripts/pandastack-linear-reduce, scripts/pslib.py, plugins/pandastack/docs/linear-contract.md, tests/linear-reduce.sh
- acceptance: tests/linear-reduce.sh 新增 case「無機器 check 且無指名證據 artifact 的卡 → gated needs-spec」綠；一個 fixture PRD 分解產出 N 張卡，每張 acceptance 為 greppable check（→ auto lane）或**指名**的證據 artifact（截圖/數字/before-after，→ human lane），皆非模糊散文。blast_radius **不逐張手標** —— 由 high-blast path policy 檔（T03）在 merge 時對真實 diff 評估；AI 可在此預估標註供預覽，但非綁定
- depends-on: none
- status: todo

### coding-agent-autonomy-rungs-T03 — blast×可驗性 router + integration-branch 自主 merge（低-blast 子集）
- scope: scripts/pandastack-drive (SHIP/merge path), 新增 high-blast path policy 檔（config/high-blast-paths）, 新增 tests/drive-merge-router.sh
- acceptance: tests/drive-merge-router.sh 綠；router 決策 = `low_blast(真實 diff vs path policy) AND 機器可驗 acceptance AND verify 綠` → 自主 merge 進 integration branch（非 main）；high-blast（DB-touch fixture 命中 policy）或 人眼-artifact acceptance → 只開 PR；grep 證明無任何 path 自動 push/merge main；blast 決策綁 deterministic diff-match（拿真實 diff 非 predicted scope）
- depends-on: coding-agent-autonomy-rungs-T01, coding-agent-autonomy-rungs-T02
- status: todo

### coding-agent-autonomy-rungs-T04 — 證據包進 PR（verify 輸出 + 截圖/數據 hook）
- scope: scripts/pandastack-pr-review-comment 或 PR-open path, tests/linear-linkback.sh
- acceptance: dry-run 測試證明 PR body 含 verify 指令輸出 + acceptance 對照 + artifact（截圖/數據）連結欄位；既有 linear-linkback.sh 仍綠
- depends-on: coding-agent-autonomy-rungs-T01
- status: todo

### coding-agent-autonomy-rungs-T05 — reversibility kit（kill-switch + integration→main promote/rollback）
- scope: scripts/pandastack-drive (per-iteration kill-switch check), scripts/drive-cron.py, 新增 integration→main promote 機制, 新增 docs + tests/drive-killswitch.sh + tests/drive-promote.sh
- acceptance: tests/drive-killswitch.sh 綠（kill-switch flag 存在時 loop 下一圈自停不 dispatch）；tests/drive-promote.sh 綠（promote 預設**手動**；auto 模式 N=5 merge OR 24h 先到先觸發；promote 後 main CI 紅 → 自動 rollback 該次 promote）；docs 記載 integration-branch reset 復原步驟；bounded `--max` 與 worktree 隔離仍生效（既有 drive-build.sh 綠）
- depends-on: coding-agent-autonomy-rungs-T03
- status: todo

### coding-agent-autonomy-rungs-T06 — [DEFER] Claude worker backend + multi-backend failover
- scope: scripts/agent-worker (新增 claude backend), pandastack.toml (backends 加 claude)
- acceptance: agent-worker 對 backend=claude 不再 raise「unsupported backend」；failover policy 在 Codex quota 耗盡時切 Claude；保留 Codex/Claude quota 隔離說明
- depends-on: coding-agent-autonomy-rungs-T03
- status: todo
- note: rung-C 之後、高量全自主才需要；屆時加在現有 agent-worker 抽象內，勿另開平行 cron。低量階段 Codex 用不完，不做。
