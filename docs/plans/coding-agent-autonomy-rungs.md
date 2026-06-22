---
slug: coding-agent-autonomy-rungs
date: 2026-06-19
updated: 2026-06-20
type: plan
source: office-hours
brief: docs/briefs/2026-06-19-coding-agent-autonomy-rungs.md
execution: code
status: in-progress
---

# Coding-agent 自主 loop — executable plan

> WHAT only. WHY 在 brief。閘的搬移、autonomy 分級的理由在 brief。
> 2026-06-20 reshaped:ladder review(30 agents)+ human-in-loop boundary 決議(brain `decisions/2026-06-20-pandastack-human-in-loop-boundary.md`)後重排。原線性鏈 T01→T05 被低估了 sequencing 與 T03 scope。
>
> **重排後依賴鏈**：
> ```
> T01✓ ─ T02✓
>   ├─ KS  kill-switch          (只依賴 T01,先於任何 auto-merge)
>   ├─ VH  verify 兩洞加固        (T03 硬前置)
>   ├─ LG  結構化 ledger          (success-signal 量測底座)
>   ├─ CC  並發鎖                 (auto-merge 前必須)
>   ├─ T03 router + integration merge   ── 平行 ── T04 證據包
>   └─ T05a 手動 promote + reset → T05b auto-promote + rollback(棘輪後)
> T06 defer
> ```
> **啟用閘**:auto-merge **到 integration**(T03)是賺 streak 的訓練輪——靠 `~/.config/pandastack/drive-autonomy.json` 的 `merge_auto` opt-in 開啟,**不是** gated on the streak(streak 只由 auto-merge 產生,gate 住會死鎖)。它只進 local integration,從不碰 main。真正的棘輪閘是 promote **到 main**(T05b):連 20 筆乾淨(host-verified + 零 fake-green + 零事後 revert + 零 rollback)且 `drive-graduate --check` 過,才解凍遠端寫 default branch(boundary #3)。在那之前 integration→main 是 `drive-promote` 手動(T05a)。build 維持 `--build-auto --only` opt-in(boundary #2)。

## Phase 0 — done

### coding-agent-autonomy-rungs-T01 — 真 VERIFY backend（取代 model 自我回報）
- scope: scripts/pandastack-drive (VERIFY phase), plugins/pandastack/docs/driver-autonomy.md, tests/drive-verify.sh
- acceptance: `bash tests/drive-verify.sh` 綠；故意失敗的 change 在 VERIFY 被攔下、不進 REVIEW；driver 呼叫 per-project verify 契約
- depends-on: none
- status: **done** — PR #16 (merged 2026-06-20, @8395956)
- carry-forward: read-only AUTO-VERIFY 仍信 model RESULT line(F-M);標 advisory-only,T03 router merge 只 key host-verify.ok

### coding-agent-autonomy-rungs-T02 — PRD → work-order 分解，每張卡帶機器 check 或指名 artifact
- scope: scripts/pandastack-linear-reduce, scripts/pslib.py, plugins/pandastack/docs/linear-contract.md, tests/linear-reduce.sh
- acceptance: tests/linear-reduce.sh「無機器 check 且無指名證據 artifact → gated needs-spec」綠；machine lane / evidence lane / gated 三態
- depends-on: none
- status: **done** — PR #16 (merged 2026-06-20, @8395956)

## Phase 1 — 安全前置（任何 auto-merge 上線之前，缺一不可）

### coding-agent-autonomy-rungs-KS — kill-switch（driver pre-dispatch flag gate）
- 來源: boundary #12 + review F-E / F-J。從原 T05 拆出、提前。
- scope: scripts/drive-cron.py (main() 頂 + build_queue() pre-dispatch flag check), plugins/pandastack/docs/driver-autonomy.md, 新增 tests/drive-killswitch.sh
- acceptance: tests/drive-killswitch.sh 綠 — flag 存在 → 下一 launchd tick 在 dispatch 前零 dispatch + drive-log 留 `suppressed:true` + exit 0;flag 不存在 → 正常。check UNCONDITIONAL,兩處(讓直接 `--execute` 也認)。drive-build.sh 仍綠
- depends-on: coding-agent-autonomy-rungs-T01
- status: todo — Linear PRO-36

### coding-agent-autonomy-rungs-VH — verify gate 兩洞加固（T03 硬前置）
- 來源: review F-A / F-B。不補=auto-merge 即 fake-green。
- scope: scripts/pandastack-drive (verify.sh materialize), scripts/agent-worker (run_verify), tests/drive-verify.sh
- acceptance: tests/drive-verify.sh 新增兩條負向 case 綠 —（F-A）tautological acceptance(`true`/`exit 0`/`echo`/`[ 1 == 1 ]`)被 anti-tautology sentinel 攔下(對 pre-build HEAD 先跑,build 前就綠 → demote);（F-B）多行 acceptance 首行真失敗 + 尾行 echo,因 `set -euo pipefail` prelude 整體 demote FAIL。既有 good case 仍綠
- depends-on: coding-agent-autonomy-rungs-T01
- status: todo

### coding-agent-autonomy-rungs-LG — 結構化 ledger（success-signal 量測底座）
- 來源: review F-K / F-L。「零 fake-green」要可 git-grep。
- scope: scripts/pandastack-drive (emit per-item JSON), scripts/drive-cron.py (逐字 append 取代 stdout regex)
- acceptance: drive-log.jsonl 每筆帶 `verify_ran` / `verify_ok` / `verify_cmd` + 短 verify_tail;fake-green 反例 = 一行 grep `verdict==PASS AND advance!=null AND verify_ran==false` 計數可得;test 斷言欄位存在
- depends-on: coding-agent-autonomy-rungs-T01
- status: todo

### coding-agent-autonomy-rungs-CC — 並發鎖（drive 級 flock）
- 來源: review C1。互動 `--execute` 與 launchd tick 同時對同一 issue 跑 `git worktree add` 會 race,威脅 never-half-merged。
- scope: scripts/pandastack-drive (whole-loop flock), scripts/drive-cron.py
- acceptance: 新 test 證明兩個並發 driver 對同一 issue 不會雙開 worktree;branch-exists guard 不再是唯一(check-then-act race)防線
- depends-on: none
- status: todo

## Phase 2 — 自駕機構（可平行）

### coding-agent-autonomy-rungs-T03 — blast×可驗性 router + integration 自主 merge（重 scope）
- 來源: review F-D / F-H / F-C；boundary #1。**注意:drive 今天無 SHIP/merge path(SHIP 在 GATE_PHASES 從不進 executor)。T03 是改 exec_build 成功路徑,不是加一個檔。**
- scope: scripts/pandastack-drive (exec_build PASS+committed 路徑加 router-gated MERGE step + 三態 branch model + branch-exists guard 改 + integration-from-main refresh), 新增 config/high-blast-paths, 新增 tests/drive-merge-router.sh
- acceptance: tests/drive-merge-router.sh 綠 — 雙分支斷言:`low_blast(真實 diff vs policy) AND machine-lane AND host-verify 綠` → merge 進 **integration**(非 main);`high-blast OR evidence-lane` → 只開 PR。matcher default-deny + 每條 changed path(含 rename 新舊、deletion)以 `**/X/**` 比對;classify-fail/empty-diff/read-error → high-blast。三 fixture:nested-migration / rename-out-of-auth / deletion。read-only AUTO-VERIFY 永不當 merge gate(F-M assert)。非乾淨 merge → `git merge --abort` + 轉 GATE,絕不半 merge。grep 證明無 path 自動 push/merge main。**auto-merge 出廠 gated OFF,棘輪解鎖。**
- depends-on: T01, T02, KS, VH, LG, CC
- status: todo

### coding-agent-autonomy-rungs-T04 — 證據包進 PR（與 T03 平行）
- 來源: review F-G。brief 指人工 30 秒蓋章是 rung-0 operating mode,不排在 T03 後。
- scope: scripts/pandastack-pr-review-comment 或 PR-open path, tests/linear-linkback.sh
- acceptance: dry-run 證明 PR body 含 verify 指令輸出 + acceptance 對照 + artifact 連結欄位;既有 linear-linkback.sh 仍綠
- depends-on: coding-agent-autonomy-rungs-T01  （**∥ T03**,皆吃 exec_build result dict,互不依賴）
- status: todo

## Phase 3 — 上真路（棘輪畢業後）

### coding-agent-autonomy-rungs-T05a — 手動 promote + integration reset（local，無遠端寫）
- scope: scripts/pandastack-drive, 新增 integration→main 手動 promote 路徑 + reset docs, tests/drive-promote.sh
- acceptance: tests/drive-promote.sh 綠 — promote 預設**手動**;docs 記載 integration-branch reset 復原步驟;bounded `--max` 與 worktree 隔離仍生效(drive-build.sh 綠)
- depends-on: coding-agent-autonomy-rungs-T03
- status: todo

### coding-agent-autonomy-rungs-T05b — auto-promote + CI-read + auto-rollback（remote，棘輪後）
- 來源: review F-I;boundary #3。**系統第一次 push 遠端 default branch,破 driver-never-pushes 不變式。careful-mode,非 auto-resolve。**
- scope: scripts/pandastack-drive (promote push), 新增 CI commit-status/checks reader, drive-cron.py, tests/drive-promote.sh
- acceptance: auto 模式限速 N=5 merge OR 24h;promote 後 main CI 紅 → 自動 revert 該次 promote;**閘 = 連 20 筆乾淨 auto-merge 棘輪 + careful-mode**,未畢業前 human-gated
- depends-on: coding-agent-autonomy-rungs-T05a
- status: todo

### coding-agent-autonomy-rungs-T06 — [DEFER] Claude worker backend + multi-backend failover
- scope: scripts/agent-worker (claude backend), pandastack.toml
- acceptance: agent-worker 對 backend=claude 不再 raise;failover 在 Codex quota 耗盡切 Claude
- depends-on: coding-agent-autonomy-rungs-T03
- status: defer — 高量全自主才需要,低量階段 Codex 用不完,勿另開平行 cron

## 橫貫 infra（slot in，別事後追）

- **C4 notify**：gate fire → 立刻 ping Panda + daily digest;隊列不變則安靜。通知可靠性 gate 了表上每個人門是真是戲。
- **C5 secrets**：build 轉 auto 時,commit 前 block 含 .env/key 的暫存(AGENTS.md 硬禁,該 auto-enforce 非肉眼)。
- **C6 capability fence 演化**：編 SAFE_SKILLS / 為新 project 開 `--build-auto` = harness 編輯,human-gate。
