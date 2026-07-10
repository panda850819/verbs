---
date: 2026-07-10
type: audit
scope: pandastack source, installed Claude/Codex runtime, usage telemetry, zero-to-one software lifecycle
source_commit: c238cd7f320eebd8d2180dba08903a1b7a7982fa
status: phase0-implemented
implementation_issue: https://github.com/panda850819/pandastack/issues/174
method: harness-slim + harness-eval + runtime/transcript evidence
---

# pandastack pack stack audit

## Decision

目前的 source-level 收斂方向正確，但這份 pack 還不能宣稱「任何人都能從零到一完成軟體開發」。它目前可靠覆蓋的是：

```text
既有 repo + 模糊需求 -> brief/plan -> build/test -> review -> PR
```

目標要求的完整週期還多出四段：project bootstrap、current research/prototype、production delivery、observe/rollback。

更急的問題仍在runtime，但審計期間狀態已前進一步。第一個snapshot是`main@1cbdf99` / `3.4.0`：source 14、Claude 19、Codex 23。PR #173隨後把`main`與兩個cache刷新到`c238cd7` / `3.4.1`；現在Claude明確曝光14個，Codex recursive loader仍曝光18個，額外4個全來自`skills/_deprecated`。Version bump證明能刷新cache，exact discovery仍未成立；已開啟的舊session也不會自動重寫startup snapshot。

因此執行順序固定為：

1. 先修 runtime exact-set parity 與 cache invalidation。
2. 再清 onboarding 與 retired semantic refs。
3. 再用delivery-archetype contract把dev lifecycle補到merge、交付、observe與recover。
4. 最後依 current-model behavioral eval 瘦 `sprint`、`review` 與非 dev slots。

本文的 findings 與分數保留 `main@c238cd7` / 3.4.1 baseline。Issue #174
在同一交付分支實作 Phase 0；它不改寫 baseline 證據，也不把後續 Phase 1-5
混進 hotfix。共用 runtime cache 會等 PR 合併後再刷新，不從未合併分支覆寫。

「任何人」不能由有限測試字面證明。可驗收的產品承諾應改成：任何落在公開support matrix內的fresh user，都能只靠文件完成一次zero-to-one delivery與一次recovery drill。Matrix必須明列persona、OS、host與delivery archetype；未測組合不得宣稱支援。

## Evidence boundary

- Repo baseline：乾淨的`main@c238cd7`；實作依據為GitHub issue #174。
- Source active surface：14 skills、2,046行、120,227 bytes。
- Installed 3.4.1 cache tree：18個`SKILL.md`、2,480行、138,026 bytes；Claude manifest曝光14個，Codex與Hermes recursive discovery曝光18個。
- Active skill description：6,025 bytes；cached 18-skill tree description：7,006 bytes。
- `bash tests/run-all.sh`：11 passed、0 failed、0 quarantined。
- SessionStart envelope smoke：Codex、Claude、Cursor 三種 JSON envelope 都通過。
- Claude actual invocation：只計 `Skill` tool call，依 tool-use id 去重；保留區間為 2026-06-10 至 2026-07-08。
- Codex usage：沒有 `Skill` tool，只能用 distinct-rollout `SKILL.md` read 當上界 proxy，不能等同 invocation。
- Prior decisions：讀取 2026-07-02 harness audit、2026-07-09 skill convergence、capability-vs-context scaffolding 與 7-phase development pages。
- Current-model calibration：以本 session 已提供的 native goals、subagents、tool use、browser/computer use 與 official Anthropic/OpenAI material校正，不用 marketing benchmark 代替 repo evidence。

現有 green checks 只證明 source 結構與 lint contract 自洽。它們沒有證明 fresh install、live runtime exact set、routing semantics 或 production lifecycle。

## Phase 0 implementation status

`fix/174-runtime-parity` 將 source bump 到 3.4.2，並完成以下變更：

- 4 個 retired skills 移到 `archive/retired-skills/`，離開所有 plugin discovery roots。
- Claude/Codex 共用 event normalizer；ticket gate 涵蓋 `apply_patch`，verify gate只接受 final successful code edit 後的成功 test result。
- Codex App 的 nested patch 由 `patch_apply_end.changes` 保守辨識。App rollout目前沒有 nested command exit code，因此 outer JS cell 的 `Script completed` 不會被猜成 test green；正式 passing-test unlock只宣稱支援有 structured exit evidence 的 Claude Code 與 Codex CLI。
- `doctor --strict` 比對 exact names、version、DISPATCH 與完整 hook tree；synthetic fixtures覆蓋每一種 drift。
- Conformance parser拒絕 missing、extra、retired與foreign-namespace collisions。

Branch verification：`bash tests/run-all.sh` 為 12 passed、0 failed、0 quarantined；ticket truth table 33 cases、Stop truth table 44 cases、runtime-surface synthetic fixtures 9 cases。用真實 Codex App rollout重播時，normalizer讀到4筆successful nested patch events與6個changed paths，Stop gate在沒有structured test exit時正確block。

PR 前的預期 live 狀態是 source 3.4.2、installed cache 3.4.1，strict doctor必須報紅。合併、cache refresh與fresh-session exact enumeration後才滿足 Phase 0 live acceptance。

## P0 findings

### P0-1. Source 14，Claude runtime 14，Codex runtime 18

PR #173已把source與兩個installed caches刷新到`3.4.1`。Claude使用explicit manifest，現在正確曝光14個；Codex與Hermes使用whole-root discovery，仍會遞迴看到4個`_deprecated` skills。

| Surface | Count | Key state |
|---|---:|---|
| Repo manifest | 14 | 有 `advisor` |
| Claude 3.4.1 manifest loader | 14 | 與source manifest一致，包含`advisor` |
| Codex 3.4.1 recursive loader | 18 | 額外曝光4個`_deprecated` skills |

Deprecated仍可被Codex與Hermes discovery看見：`checkpoint`、`dojo`、`freeze`、`team-orchestrate`。Source與cache的DISPATCH/hooks hashes現在一致；在3.4.1 refresh前開啟的session仍可能保留舊的`office-hours`/`boardroom` startup snapshot，必須restart才能取得新dispatch。

3.4.0時的cache drift來自surface change沒有bump version；PR #173已用3.4.1關閉這一半。剩餘root cause是Codex manifest的`"skills": "./skills/"`與Hermes whole-root import都會recursive-discover`_deprecated`。

### P0-2. Parity目前為綠，但doctor與release checks沒有證明它

3.4.1 source、Claude cache與Codex cache的DISPATCH與完整hook tree hashes目前一致，`stop-verify-gate.py`也已進兩個cache。這是live recheck結果；3.4.0 cache缺gate是審計較早snapshot，已由refresh修復。

`scripts/pandastack doctor`仍回報全綠，因為它排除`_deprecated`後才計source skills，且沒有比較installed cache、dispatch hash、hook set或source commit。

`scripts/conformance-smoke.sh`只檢查輸出裡是否出現`grill`。Claude的14-skill surface與Codex的18-skill surface都會PASS。

### P0-3. Hard gates 沒有跨 runtime parity

Ticket guard 只接受 `Edit|Write|MultiEdit`。Codex canonical edit path 是 `apply_patch`；實測同一個 `main` branch code file：

```text
apply_patch -> exit 0
Write       -> exit 2
```

Stop verify gate同樣只識別 Claude-style edit/shell tool names，而且 parser只理解 Claude transcript schema：`type=user|assistant`與`message.content[].type=tool_use`。Codex rollout把 edit記成`type=response_item`、`payload.type=custom_tool_call`、`name=apply_patch`。只把`apply_patch`加入 tool-name allowlist仍無效，parser根本看不到那筆 edit。

另外，verify gate 只看 command string 是否像 test。它不讀 tool result 或 exit code；一個失敗的 `pytest` 也會被標成 verified。這個 hook目前是「測試命令嘗試過」gate，還不到「驗證成功」gate。

## Usage audit

### Actual Claude top-level invocations

統計只計真實 `Skill` tool calls。Mentions、runtime exposure、file reads都不計。

| Active skill | 7d | 14d | 30d/retained | Interpretation |
|---|---:|---:|---:|---|
| `sprint` | 3 | 3 | 9 | 最高頻 lifecycle driver |
| `careful` | 1 | 2 | 7 | Safety burst，保留 |
| `handover` | 0 | 5 | 5 | 7/2-7/3 專案 burst |
| `grill` | 0 | 0 | 3 | 加 absorbed `office-hours` 後為 9 |
| `ship` | 0 | 1 | 3 | 內嵌於 sprint，direct count 低估 |
| `gatekeeper` | 0 | 0 | 1 | 低頻 trust boundary；另有1筆nested call不列top-level |
| `review` | 0 | 0 | 2 | 內嵌於 sprint，direct count 低估 |
| `debug` | 1 | 1 | 1 | 事件型 skill |
| `advisor` | 0 | 0 | 0 | Sample window結束時尚未曝光；3.4.1現在可見，仍不能判讀 |
| `qa` | 0 | 0 | 0 | Codex read proxy 有 7 rollouts |
| `ui` | 0 | 0 | 0 | Codex read proxy 有 3 rollouts |
| `write` | 0 | 0 | 0 | Codex read proxy 有 5 rollouts |
| `skill-creator` | 0 | 0 | 0 | Codex read proxy 有 10 rollouts |
| `writing-great-skills` | 0 | 0 | 0 | Codex read proxy 有 11 rollouts |

Current active names有31次top-level actual calls。把`office-hours`歸入`grill` lineage後為37次；`sprint + grill lineage + careful + handover`佔30/37，約81%。另排除1筆由`idea-ingest` subagent觸發的nested `gatekeeper`。核心需求已集中在少數verbs，這支持繼續收斂cognitive surface。

### Codex read proxy

Codex transcript 的 `SKILL.md` reads 只能表示「這個 skill 被載入或研究過」。它混合真執行、nested dependency、audit 與 skill 編修。

| Skill | Distinct rollouts | Main source of reads |
|---|---:|---|
| `review` | 119 | 66 stop-gate + 53 scheduler |
| `careful` | 91 | 19 stop-gate + 72 scheduler |
| `sprint` | 28 | 3 stop-gate + 25 scheduler |
| `handover` | 20 | mixed |
| `ship` | 14 | mixed |
| `grill` | 11 | mixed |

最清楚的 over-invocation 是 stop-gate：如果前一 turn 沒有直接 edit，應在載入完整 269-line `review` 前就 `ALLOW`。這個 fast path 應放在小型 wrapper或機械 guard，不應支付 full review context。

### Telemetry limits

- `dispatch-fired.log` 只有 15 筆，從 7/3 開始，而且全是 Claude。
- Hook 只記 `tool_name == Skill`；Codex inline skill execution 永遠漏記。
- `dispatch-miss.log` 只有一筆人工 miss，沒有 denominator。
- 沒有 session id、mode、parent skill、task id、outcome，無法分辨 nested call 或 scheduler retry。
- `harness-slim` 還在讀不存在的 epoch-based `~/.Codex/skill-usage.log`，與目前 ISO pipe schema不相容。

因此 zero-use 不能直接觸發刪除。先修 runtime parity，再收 30 天 normalized telemetry。

## Lifecycle audit

| Phase | Current evidence | Verdict |
|---|---|---|
| Project bootstrap | First-session 仍要求已移除的 `/pandastack:init`、`/office-hours`；CLI也印出 `/pandastack:init` | Missing |
| Discovery/spec | `grill --brief` 會產 brief + executable plan | Strong, heavy |
| Current research/prototype | 只在 prose 裡當 knowledge variant；沒有 current-doc/prototype decision gate | Missing |
| Ticket/worktree | Hook只驗 branch name pattern，不驗 issue存在；plan無 ticket/worktree field | Partial |
| Build/test | Acceptance、idempotency、architect re-verify完整 | Strong, over-orchestrated |
| Debug/UI | 37-line `debug` 與 27-line `ui` 都是高密度 reflex override | Strong |
| QA | Browser assertions完整，但 Step 4直接改 code | Responsibility leak |
| Review/security | 3 pass + cold + Codex固定執行，且 AUTO-FIX | Too heavy, responsibility leak |
| Commit/PR | 能 test/commit/push/PR，但先 commit 才建 branch | Incorrect order |
| CI | 沒有等待 checks green | Missing |
| Merge/deploy | GitHub Release可選；沒有 merge/deploy contract | Missing |
| Smoke/observe | 無標準 project commands與 evidence contract | Missing |
| Rollback | 只問 reversibility，沒有可執行 rollback path | Missing |
| Learning | Review、QA、debug、ship、sprint多處都可寫 learning | Too many owners |

### Onboarding evidence

在乾淨 temporary HOME 執行 bootstrap：

1. 它先說缺 `~/.agents/AGENTS.md` 會讓 flow ABORT。
2. 下一段仍說 10 core skills「runnable with zero external CLI」。
3. Ext table列出已移除的 `agent-browser`、`deepwiki`，漏掉 `advisor`。
4. SessionStart無條件注入「Use brain first」；fresh user沒有`gbrain`時會收到不可執行的規則。

README自己也明載 verified fresh-user install count = 0；ROADMAP把 no-vault from-zero使用者列為 out of scope。「任何人 zero-to-one」會改變產品邊界，不能靠修幾行 trigger達成。

### Semantic residue after 20 -> 14

Source lints通過，但 active docs/libs仍有 retired behavior：

- `docs/first-session.md`：`/pandastack:init`、`/office-hours`。
- `README.md`：安裝後仍叫 `/pandastack:init`。
- `scripts/bootstrap.sh`：`deepwiki`、`agent-browser`、缺 `advisor`。
- `hooks/session-start`：把Panda-specific brain-first規則當成所有安裝者的universal default。
- `lib/skill-decision-tree.md`：仍路由 `team-orchestrate`。
- `lib/output-templates.md`：frontmatter source/tags仍寫 `office-hours`。
- `docs/state-schema.md`：仍列 `office-hours`、`checkpoint`，且把 PR-level SHIP當 terminal。
- `tests/resolver-golden.md`：仍測 `office-hours`、`boardroom`、`deepwiki`，而且不在 CI 自動執行。
- `skills/engineering/review/SKILL.md` description：仍指向 `boardroom`。
- `skills/engineering/qa/SKILL.md`：non-UI verification 指向不存在的 `verify` skill。

Eval freshness能抓 hash drift，抓不到這些 semantic dead refs。

## Current-model pressure test

Official Anthropic harness research給出兩個直接校正：

- 新模型到來後，應逐件移除不再承重的 harness component，再以真實 trace檢查品質。
- Opus 4.6實驗移除了 sprint decomposition；planner仍承重，evaluator改為依任務難度啟用。低於模型能力邊界的任務，固定 evaluator只是 overhead。

Source: [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)

Anthropic context guidance同時要求保留另一半：context仍有限，應保持 minimal high-signal context、JIT retrieval與清楚、不重疊的 tool surface。

Source: [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

Codex App目前提供durable goals、subagents、skills、worktrees與computer/browser workflows；deploy use case還依賴特定app/plugin surface。Claude Code、Codex CLI與Hermes並不共享完整能力集合。Pack應保留Panda-specific policy、risk、artifact與verification delta，並先做host capability detection；只有存在的native primitive才交給host，缺少時走state file、git worktree CLI、browser adapter或人工evidence fallback。

Sources: [Follow a goal](https://learn.chatgpt.com/codex/use-cases/follow-goals), [Save workflows as skills](https://learn.chatgpt.com/codex/use-cases/reusable-codex-skills), [Deploy an app or website](https://learn.chatgpt.com/codex/use-cases/deploy-app-or-website), [QA your app with Computer Use](https://learn.chatgpt.com/codex/use-cases/qa-your-app-with-computer-use)

### Capability / context / authority disposition

| Skill | Assumption class | Decision |
|---|---|---|
| `advisor` | Cross-model independence | Keep, expensive-if-wrong only |
| `careful` | Authority/safety | Keep hard gate, slim prose |
| `debug` | Reflex override + local lore | Keep as-is shape |
| `handover` | Quota/economics + context isolation | Keep opt-in ext |
| `qa` | Browser evidence protocol | Keep conditional, report-only |
| `review` | Capability scaffold + decorrelation | Risk-adaptive rewrite |
| `ship` | External mutation policy | Keep, extend delivery contract |
| `sprint` | Capability scaffold + lifecycle state | Thin lifecycle router |
| `gatekeeper` | Trust boundary | Keep generic core; move DeFi/on-chain branch to personal overlay |
| `skill-creator` | Maintainer context | Move to maintainer-only profile |
| `writing-great-skills` | Reference | Demote to `skill-creator` lib |
| `grill` | Human intent protocol + planning | Keep explicit/high-uncertainty path, slim gates |
| `ui` | Craft lore + reflex override | Keep as-is shape |
| `write` | Private voice context | Move to personal overlay or default-disabled |

The cleanest active split is：11 universal dev runtime skills、1 maintainer-only skill、1 scorecard lib、1 personal overlay skill。User-visible dev verbs維持三個：`grill`、`sprint`、`ship`。

## Six-dimension score

評分對象是目前有效 runtime，不是只看 source tree。

| Dimension | Score | Evidence |
|---|---:|---|
| Persistence | B, 3.0/4 | Brief/plan/git artifacts可恢復；long-task orchestration過度綁 sprint |
| Context efficiency | C, 2.0/4 | JIT skill bodies正確；舊 cache與大 skill chain污染 context |
| System cost | D, 1.3/4 | Session hook很小；full sprint與固定 reviewers造成高變動成本 |
| Compliance | D, 1.0/4 | Hook已進cache；Codex`apply_patch`仍穿過edit guard，failed test可算verified |
| Robustness | D, 1.4/4 | Source/Claude 14、Codex/Hermes 18；doctor仍回綠 |
| Collaboration | B, 2.8/4 | Isolation、outside voice、human authority良好；fan-out與gates偏重 |
| Weighted total | C, 1.9/4 | Robustness×2、persistence/compliance×1.5，其餘×1 |

### Recomputable indicator scores

依`harness-eval`規則，A/B/C/D/F分別換算4/3/2/1/0；維度分數是指標平均。以下保留每個分數的直接佐證，避免總分成為不可重算的主觀點估計。

| Dimension | Indicator | Score | Direct evidence |
|---|---|---:|---|
| Persistence | Context budget | 4 | SessionStart JSON約2.7KB；skill bodies按需載入 |
| Persistence | Usage ceiling | 3 | Host有compaction/goals；pack沒有可量測40%上限 |
| Persistence | Growth ceiling | 3 | State與handoff有邊界；tool/subagent output仍可線性增長 |
| Persistence | Recovery design | 3 | Brief、plan、git、state與handover可恢復主要工作 |
| Persistence | Recovery chain | 2 | Handover為opt-in；quick/full state contract有矛盾 |
| Persistence | Continuity | 3 | Git與handover支援跨session；fresh start仍斷鏈 |
| Persistence | Degradation curve | 3 | 有quick/full modes；實作不一致，尚非可靠分級 |
| Context | Redundancy | 1 | Source/Claude 14、Codex/Hermes 18；retired names仍注入 |
| Context | Index vs encyclopedia | 1 | 12/14 skill bodies超過80行；dev spine 900行 |
| Context | Signal/noise | 2 | Conditional skills有價值；固定review fan-out帶入非必要內容 |
| Context | Timeliness | 3 | Runtime可JIT讀skill；stop-gate會過早載入full review |
| Context | Freshness | 2 | 3.4.1 cache已更新；active docs與recursive discovery仍過時 |
| Context | Layering | 3 | Dispatch、skills、libs、docs分層存在 |
| Context | Deduplication | 1 | Learning ownership與lifecycle rules在多skills重複定義 |
| Context | Output signal control | 3 | 多數hooks輸出短；telemetry仍缺normalized outcome |
| Cost | Fixed cost | 4 | SessionStart envelope約2.7KB，約700 tokens |
| Cost | Variable cost | 0 | Hot dev chain正文約13K tokens，未計diff與subagents |
| Cost | Ritual steps | 0 | Full sprint約30個命名steps，固定review再加5 reviewers |
| Cost | Startup flow | 3 | Session hook自動載入；仍需dispatch與brain lookup |
| Cost | Idle components | 0 | 固定review passes與stop-gate full-skill load常無新增產出 |
| Cost | Resource guards | 2 | 部分重試/timeout有上限；default fan-out沒有task-risk budget |
| Cost | Trigger placement | 0 | Stop-gate fast path位於full review load之後，Codex gate又漏觸發 |
| Compliance | Executability | 1 | 有hard hooks且已進cache；cross-runtime parsing/result semantics仍失效 |
| Compliance | Repair guidance | 2 | Block訊息有修法；failed-test與schema miss不會block |
| Compliance | Phase separation | 2 | Brief/plan存在；sprint/review/qa仍會跨責任直接edit |
| Compliance | E2E gate | 0 | PR可完成但沒有CI/deploy/smoke/observe硬閘門 |
| Compliance | Backpressure | 2 | Ticket/test/review有壓力；type/architecture與production path不完整 |
| Compliance | Observability | 1 | 有logs；缺session、parent、outcome與Codex invocation |
| Compliance | Consistency | 0 | Quick mode、ship order、source/cache與docs互相矛盾 |
| Compliance | Proportionality | 1 | Safety分級存在；review與subagent fan-out仍一刀切 |
| Compliance | Escape hatch | 1 | 有PAUSE/override prose；hard-gate與runtime行為不一致 |
| Compliance | Cross-mapping | 0 | AGENTS宣稱的gate與live hooks、Codex schema不對應 |
| Robustness | Graceful degradation | 2 | 多數hooks fail-open；會靜默失去保護 |
| Robustness | Error isolation | 3 | Hook錯誤多被catch，不致整個session崩潰 |
| Robustness | State consistency | 0 | Source/Claude/Codex/Hermes discovery仍不是同一集合 |
| Robustness | Empty state | 0 | Clean HOME bootstrap同時宣稱ABORT與runnable |
| Robustness | Mid-task change | 2 | AI可重規劃；沒有機械偵測需求/branch drift |
| Robustness | Version control as record | 3 | Source、docs、evals在git；installed cache state不在同一真相面 |
| Robustness | Entropy defense | 2 | 有lint與tests；semantic dead refs仍通過 |
| Robustness | Dependency survival | 0 | Active docs/libs引用多個retired/nonexistent skills |
| Robustness | State format resilience | 1 | 有state schema；PR-level SHIP誤當terminal且delivery states缺失 |
| Collaboration | Right info at right time | 3 | JIT skills與dispatch可用；stop-gate load timing錯位 |
| Collaboration | Noise | 3 | Hook輸出短；fixed review/subagent narration偏吵 |
| Collaboration | Autonomy grading | 4 | Auto/draft/escalate/no-action authority分級清楚 |
| Collaboration | Transparency | 3 | Plan/state/git可見；telemetry與runtime parity不可見 |
| Collaboration | Multi-agent design | 3 | Isolation與outside voice存在；權限scope與fan-out budget不足 |
| Collaboration | Agent observability access | 3 | 可讀logs/browser/runtime；production metrics contract缺失 |
| Collaboration | Agent readability | 3 | Markdown/Bash/git/worktree友善；onboarding仍含private assumptions |
| Collaboration | Failure analysis | 2 | Debug有root-cause流程；hook schema miss與failed green是靜默失敗 |
| Collaboration | Settings alignment | 1 | Behavioral contract、hook registration與installed cache未對齊 |

| Dimension | Strongest point | Weakest point | Single repair |
|---|---|---|---|
| Persistence | Git/state/handover可恢復 | Fresh-start與mode chain斷裂 | 統一state machine與resume fixture |
| Context | JIT skill loading | 大skill chain與stale cache | Exact-set parity後瘦dev spine |
| Cost | Fixed session payload小 | 固定ritual與review fan-out | Sprint thin router + risk-adaptive review |
| Compliance | Authority policy清楚 | Gate不懂Codex/result status | Runtime-normalized event adapter |
| Robustness | Hook failure多能隔離 | 多真相面靜默drift | Doctor/release exact parity gate |
| Collaboration | Auto/draft/escalate分級 | Production observability缺contract | Project contract加入observe evidence |

固定context不是目前最大成本。真正的cost在skill觸發後：`sprint + grill + review + ship`正文共51,355 bytes，約13K tokens，還沒算diff、tool output與subagents。

Pack自己的scorecard要求skill約80行內；目前12/14超過80行。四個dev spine bodies共900行：`grill 149 + sprint 301 + review 269 + ship 181`。

14份 current eval都判 `SOLID`，同時仍有10個 `Pruning: weak`、7個 `Native parity: weak`。Construction hash freshness無法證明 behavioral value。唯一 historical A/B只有 n=3，曾顯示 `review -0.333`、`sprint 0`、`qa 0`；它已過時，但足以證明下一次 model-upgrade gate必須重新測 with-vs-without，而非重簽 hash。

## Target stack

不新增research、prototype、deploy、operate skill。用host capability adapter與project delivery contract承接差異：

```text
Host capability adapter
  detect: goal · subagents · worktrees · browser/computer · compaction
  fallback: state file · git worktree CLI · browser adapter/manual evidence
        |
        v
Pandastack policy
  dispatch · safety hooks · grill · sprint · review/qa · ship
        |
        v
Project contract
  dev · test · build · deliver · release_verify · observe · recover
  hosted · package/CLI · mobile/desktop archetype adapters
        |
        v
Durable artifacts
  brief · plan/ticket · git/PR · runtime evidence · learning candidate
```

Public dev pack只編碼三類模型自己推不出的東西：

1. 可設定的authority與risk policy，加安全預設；Panda-specific值留在personal overlay。
2. 跨 session、跨 runtime需要的artifact contract。
3. 工具與真實環境的verification evidence。

通用拆解、逐步 narration、固定多 agent fan-out交給 current host model判斷。

## Target zero-to-one lifecycle

```text
scripts/pandastack project-init
  -> grill --brief
       discover · current-doc research · prototype decision · risk
       choose stack + delivery archetype
  -> populate + validate project command contract
  -> ticket + issue-keyed worktree + executable plan
  -> sprint --plan
       build · deterministic tests
       debug/ui/careful/handover only when triggered
  -> adaptive review
       UI-only QA; high-risk-only cold/cross-model
  -> ship
       branch exists -> commit -> push -> CI green -> PR_READY
  -> human merge
       bind MERGED state to remote merged SHA
  -> ship deliver
       deliver -> release_verify -> observe
       fail -> recover -> debug/sprint
  -> DONE
       one learning candidate owner
```

Key contracts：

- `project-init`是deterministic CLI command，不佔skill slot。它只在空目錄建立git、project `AGENTS.md`與未填值的command-contract schema；它不能在stack決定前虛構commands。
- `grill --brief`只在scope模糊時進互動問答；current-doc research、prototype與delivery archetype是plan branches，不是新skill。Plan負責填入實際commands，第一次sprint在code edit前機械驗證。
- `sprint`保留 acceptance、idempotency、terminal state與ship boundary；刪除 per-step narration與「每個non-trivial unit一律subagent」。
- `review`與`qa`改成 report-only。Fix回到 sprint，確保每次改動後重新驗證。
- `review`依 risk分級：低風險單一 grounded pass；auth/infra/migration啟用conditional pass；高風險才加cold/cross-model。
- `ship`先驗issue真實存在、remote可達、issue-keyed worktree與branch一致，再commit。PR開好且CI綠只到`PR_READY`；human merge後記錄remote merged SHA才到`MERGED`。
- `ship deliver`讀project contract的`deliver/release_verify/observe/recover` commands。External mutation仍由`careful`要求一次明確批准；產物必須綁定merged SHA或tag。
- Hosted adapter把四個verbs映射為deploy/smoke/metrics/rollback；package/CLI映射為publish/clean-install/usage/yank-or-replacement；mobile/desktop映射為sign-and-distribute/install-and-launch/crash-rollout/halt-or-replacement。
- Release verification與observation有證據後才進`DONE`。失敗會進`RECOVERING`，成功recover後記`RECOVERED`並回到debug/sprint；recover失敗必須停在blocked incident state。
- Learning只有一個terminal owner。Review、QA、debug只提出candidate，避免同一事件寫四次。

## Skill-by-skill action

| Skill | Lines | Actual Claude calls | Action |
|---|---:|---:|---|
| `advisor` | 93 | 0 | Keep；3.4.1已曝光，開始累積behavior evidence |
| `careful` | 85 | 7 | Keep；只留hook沒覆蓋的authority gates |
| `debug` | 37 | 1 | Keep；目前最佳形狀 |
| `handover` | 134 | 5 | Keep ext；縮quota與model-anchor重複敘述 |
| `qa` | 102 | 0 | Keep conditional；report-only、capability-detected browser first |
| `review` | 269 | 2 | Rewrite risk-adaptive；移除AUTO-FIX |
| `ship` | 181 | 3 | Rewrite branch/CI/MERGED/deliver/recover ordering |
| `sprint` | 301 | 9 | Rewrite成thin router；保留artifact與acceptance |
| `gatekeeper` | 137 | 1 top-level + 1 nested | Slim generic trust core；DeFi/on-chain移overlay |
| `skill-creator` | 147 | 0 | Maintainer-only；保留conformance delta |
| `writing-great-skills` | 92 | 0 | Demote to lib，不占runtime slot |
| `grill` | 149 | 3 direct / 9 lineage | Slim；保留planner與human unknowns |
| `ui` | 27 | 0 | Keep；cold craft ref按需載入 |
| `write` | 292 | 0 | Move personal overlay/default-disabled |

## Implementation plan

### Phase 0. Runtime parity hotfix

Implementation basis：GitHub issue #174、branch`fix/174-runtime-parity`。

1. 從3.4.1 bump到3.4.2，讓本輪surface/hook變更取得新cache key。
2. 把 `_deprecated` 移出任何 plugin discovery root。
3. 建立Claude/Codex共用的normalized event adapter，辨識兩種hook envelope與transcript schema。PreToolUse只做offline issue-keyed branch + linked-worktree檢查；external ticket existence在worktree建立或CI/ship驗一次，不在每次edit打API。
4. Ticket gate納入`apply_patch`與Codex path fields；verify gate只接受「final code edit之後、exit 0或tool result success」的test evidence。
5. 為Claude tool-use與Codex `response_item/custom_tool_call`各加invalid-ticket edit、valid-worktree edit、passing test、failing test、edit-after-test與non-code edit fixtures。
6. Release gate比對repo、Claude cache、Codex cache：exact skill names、DISPATCH hash、hook file set、plugin version。
7. `doctor`新增 installed runtime parity，發現source/cache drift就紅燈。
8. Conformance smoke由「含grill」改成 exact set assertion。

Acceptance：Claude、Codex與Hermes都只看見14個source active names，包含`advisor`，不含4個retired/deprecated names；live dispatch與hook hashes等於repo。兩種runtime都必須符合雙向truth table：main或issue-shaped但非linked-worktree的code edit被擋；linked issue-keyed worktree code edit可放行；non-code edit不誤擋；final edit後passing test解除verify gate；failing test不解除；passing test後再edit會重新鎖住。永遠block或永遠allow都算失敗。

### Phase 1. Fresh-start repair

1. 刪除所有active semantic refs中的retired skill names：`/pandastack:init`、`office-hours`、`boardroom`、`team-orchestrate`、`deepwiki`、`checkpoint`；保留有效installer command `scripts/pandastack init --host`。
2. `bootstrap.sh`從manifest衍生ext rows，不再hardcode。
3. 新增`scripts/pandastack project-init` deterministic command，只建立repo scaffold與空的typed command-contract schema，無需Panda brain/vault。
4. SessionStart只注入universal dispatch；brain-first只在偵測到`gbrain`且personal overlay啟用時加入。
5. Plan schema加入`research_evidence`與`prototype_decision`。Current docs/API/tooling facts要記primary source與as-of date；prototype必須記required/skipped理由、問題、最小spike與result。
6. 建立Claude Code、Codex CLI/App、Hermes capability matrix；每個native primitive都要有detected path與fallback path。
7. 發布support matrix：persona、OS、host、delivery archetype與已驗證fallback；未測組合明標unsupported。
8. 把resolver golden接進CI，測current names、anti-triggers與retired names fail-loud。

Acceptance：乾淨HOME、空目錄、無`~/.agents/AGENTS.md`時，可以安裝、執行project-init與第一個`grill --brief`。未填command contract時會fail-loud並給修法；plan填值後validate通過。Stale dependency-doc fixture必須產出current primary-source evidence；高不確定integration fixture必須完成disposable spike；明確低風險fixture必須記錄prototype skipped理由且不支付spike成本。每個host fixture都只使用自己具備的native capability，缺少時走已測fallback；全程不出現Panda-only path或retired command。

### Phase 2. Complete delivery lifecycle

1. Project contract新增`dev/test/build/deliver/release_verify/observe/recover`與delivery-archetype adapter。
2. Plan新增`ticket/worktree/risk/delivery_archetype/recovery`欄位；worktree建立或CI/ship時一次性驗external issue存在、remote與branch/worktree binding，PreToolUse hot path只驗offline binding。
3. Slim sprint；review/qa report-only且risk-adaptive。Findings固定走`sprint -> reverify -> rereview/QA`，不能直接改完就算clean。
4. Ship修正branch-before-commit，等待CI的success/failure/cancelled/timed-out/no-check states，成功只到`PR_READY`。
5. Human merge後驗remote merged SHA；delivery artifact必須綁定該SHA或tag，才可進`MERGED`。
6. Ship新增generic deliver mode與archetype-specific release_verify/observe/recover contract。
7. State schema加入`PR_READY/MERGED/LIVE/DONE/RECOVERING/RECOVERED/INCIDENT_BLOCKED`，不再把PR當terminal success。
8. Failure matrix覆蓋build/test、review finding、QA failure、CI各終態、delivery、release verification、observe、recover失敗。

Acceptance：三個delivery fixtures都從空目錄走完完整路徑：hosted service、package/CLI、mobile/desktop。Hosted fixture先走preview，再由`careful`取得明確批准，對reference production environment執行canary、traffic-safe smoke、observe與rollback drill；有migration時先跑forward/backward compatibility。Package/CLI在disposable registry namespace完成publish、clean install與recover；mobile/desktop在beta/test distribution完成sign、install、launch與halt/replacement。每個artifact都能回指issue、worktree branch、PR、merged SHA/tag；failure matrix的每個transition都有機械可查state/evidence。

### Phase 3. Surface recut

1. `writing-great-skills`降lib。
2. `skill-creator`移maintainer-only exposure。
3. `write`移personal overlay/default-disabled。
4. `gatekeeper`只留software trust routes；DeFi/on-chain移private overlay。
5. Public policy改成可設定schema與安全預設；Panda-specific brain/risk值移personal overlay。
6. 以behavior delta裁內容，不把80行當盲目硬上限。

Acceptance：universal dev runtime為11 skills；fresh-user cognitive surface只有`grill/sprint/ship`三個verbs。Universal bodies由目前1,515行降到不超過1,100行；dev spine由900行/51,355 bytes降到不超過450行/30,000 bytes；model-invoked descriptions由6,025 bytes降到不超過4,000 bytes。每個state與artifact只有一個terminal owner。全active-set route/anti-trigger matrix通過，retained skills之間沒有collision或silent miss。這些是complexity guardrails；behavior gate優先於為了達標而刪必要內容。

### Phase 4. Current-model behavioral gate

Routing correctness測完整active set。Paired with-vs-without behavior eval測所有本輪重寫、safety或高成本skills：`grill`、`sprint`、`review`、`qa`、`ship`、`careful`、`advisor`、`handover`、`gatekeeper`。

每次major model upgrade記錄：model、date、fixture set、with-vs-without delta、overfire、miss、cost。Construction eval繼續保留，但不能單獨判`SOLID`。

Acceptance：每個active skill至少有20個route/anti-trigger cases，fixture precision與recall都為100%。九個paired-eval skills各有至少20個blind-scored cases，跨兩個current models重跑。所有品質軸都必須non-regression，且primary axis需帶來至少10 percentage points task-success提升，或至少20% critical-defect detection提升；review/advisor不得產生phantom P0/P1，其他finding false-positive rate低於5%。一般低/中風險case的median token+tool-turn overhead不得超過25%。Safety skill同時要求zero critical bypass與safe-operation false-block低於5%，不用低頻率判退役。未達門檻的capability scaffold直接縮或退役；若要超過cost ceiling，必須有唯一P0/P1 finding作為保留證據。

### Phase 5. Usage observability

1. 定義normalized JSONL event：timestamp、runtime、session、task、skill、mode、parent、caller、eligible、event_kind、confidence、outcome、duration、tokens。
2. Claude收top-level與nested actual `Skill` calls；Codex以runtime transcript adapter收dispatch selection與`SKILL.md` load proxy。沒有first-class invocation event時，Codex不得把read標成actual fired。
3. Dispatch在每個task-shaped prompt記它自己的eligible set與selected route，但這只算prediction，不能當ground truth；nested calls獨立標記，不能混入top-level frequency。
4. 另由不知道dispatch結果的人工reviewer加第二模型，對stratified transcript sample獨立標`expected_route`；歧義由人工裁決。Metrics按skill與route class分開算，不能用大量常見route稀釋rare-skill miss。
5. Runtime parity修好後收滿30天；至少人工抽查20個sessions，逐筆對回raw transcript與independent route label。
6. Zero-use只在skill確實曝光30天且出現eligible opportunities後才成為退役訊號；safety/trust skills不套frequency淘汰。

Acceptance：fixture transcripts在Claude與Codex都產生同一schema，並保留`actual_invocation/dispatch_selection/load_proxy`語意差異；抽查20個sessions為零漏記/重複或proxy冒充actual。滿30天且至少100個task-shaped events後，以independent labels計算macro與per-skill precision/recall；有至少20個eligible cases的skill兩者都需達95%，不足20個則明標insufficient evidence，不得併入全局平均假綠。每個active skill都能分開報top-level、nested、eligible、event confidence與successful outcome。只寫JSONL與parser，不建dashboard。

## Completion proof for the user objective

這個目標完成時，必須同時有以下證據：

1. Source/cache/dispatch/hooks exact-set parity。
2. Claude與Codex clean-HOME install test；Claude/Hermes capability fallbacks另有fixture。
3. Research/prototype fixtures證明current-source evidence、required spike與justified skip三條path都可機械驗收。
4. Empty-directory flow建立真實issue、remote、issue-keyed worktree與branch，走到CI-green `PR_READY`，human merge後記錄remote merged SHA/tag。
5. Hosted、package/CLI、mobile/desktop三種delivery archetype都走完deliver、release_verify、observe與recover；production/external mutation都有明確批准。
6. Failure matrix涵蓋build/test、review、QA、CI、delivery、verification、observe與recover失敗，且每個transition留下state/evidence。
7. Claude/Codex hard-gate雙向truth table全通過；valid work可放行，invalid edit會擋，failed test不能算green，later edit會重鎖。
8. Retired-name scan為零，routing golden進CI；全active-set route/anti-trigger matrix沒有collision或silent miss。
9. Universal/dev-spine/description budgets與single-terminal-owner檢查全通過。
10. 30天normalized usage達到100個task-shaped events；actual/proxy分開，route metrics使用independent labels並逐skill報告，樣本不足不得宣稱通過。
11. 至少6位fresh users各自只靠公開文件完成一次zero-to-one delivery與一次injected-failure recovery。Coverage matrix含novice/working/senior三種persona、macOS/Linux/Windows-or-WSL、Claude/Codex/Hermes與三種delivery archetype；每個宣稱支援的cell都有至少一筆成功證據，作者不得hand-hold。

在這十一項之前，`10/10 tests green`只能表示repo內部checks通過，不能支持「support-matrix內的fresh user可zero-to-one」的claim；字面上的「所有人」不會成為可宣稱結論。

## Explicit non-goals

- 不新增 research、prototype、deploy、operate skills。
- 不重建 autonomous driver或scheduler；那是已拆出的platform concern。
- 不用使用率決定是否保留safety/trust boundary。
- 不建新的usage dashboard；先以normalized JSONL與transcript parser取得可信30-day sample。
- 不因hash-fresh eval而跳過behavioral eval。

## Brain candidate after approval

若本計畫進入實作，durable decision應吸收進一頁：`decisions/2026-07-10-pandastack-zero-to-one-pack-recut.md`。在Panda核准前不寫brain，也不改現有2026-07-09 decision。
