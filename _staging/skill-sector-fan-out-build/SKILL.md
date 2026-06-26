---
name: sector-fan-out-build
mode: skill
status: draft
origin: done-promote
observed_count: 1
description: |
  Build complete brain coverage of a large universe (台股 / Yei protocols / 朋友產品線 / 任何 N≫50 entity set) via structural decomposition + subagent fan-out. Three phases:
  (1) master page first — single-thread author writes the universe-level taxonomy + 5 axis projection + hub status table, prevents fan-out conflicts;
  (2) batched fan-out — 8 batches of 4-8 parallel subagents, each writes 1-3 sibling sector / group / chain pages mirroring an existing schema reference;
  (3) cross-link + index update — author updates master + sibling indexes after all batches return.
  Strictly enforces subagent identity-vs-data discipline (identity fields MUST web-verify, data fields can write 待補) per [[feedback_subagent-fanout-identity-vs-data-fields]] — this rule actively self-heals master/brief errors during fan-out, not just defensive.
  Triggers on: "全部覆蓋 X universe", "把 X 系統化進 brain", "建 X 全行業 hub", N≫50 entity sets where ticker-by-ticker is infeasible but structural decomposition is.
  Skill metaphor: 把 universe 投影到結構化 unit 而非平鋪 entity list — 「全部覆蓋」= 結構化的全部，不是 entity 表的全部。
reads:
  - vault: topics/stocks/passive-components-tw-2026.md   # schema reference example
  - vault: topics/stocks/tw-stock-sectors-master-2026.md # master page example
  - vault: topics/stocks/tw-stock-groups-2026.md         # group master example
  - vault: learnings/architecture/full-coverage-via-structural-decomposition.md
  - memory: feedback_subagent-fanout-identity-vs-data-fields.md
writes:
  - vault: topics/<area>/<entity>-master-<year>.md         # universe master
  - vault: topics/<area>/<unit>-<dimension>-<year>.md      # sector/group/chain pages
  - vault: <entity>/<slug>-<id>.md                          # entity deep dives (selective)
domain: shared
classification: builder
capability_required:
  - parallel_subagent_dispatch
  - web_search_for_identity_verification
---

## Contract

**When to invoke**: large universe build where N entity > 50 and "全部覆蓋" would otherwise be unattempted. Examples:
- 台股族群（~2500 上市櫃 → 108 結構化 page）
- Yei team brain ingest（5 source × 多 entity → ~30 hub）
- 朋友品牌全產品線（N SKU → 結構化分類 + 集團持股）

**NOT when**:
- N ≤ 20: 直接寫 N 個 page，無需 master + fan-out
- 動態 / 週期性數據 (法人籌碼 / 股價 / 訂單金額): 用 framework page 而不是 fan-out
- universe 沒明確邊界 / 結構: 先做 office-hours brief，不是直接 build

## Phases

### Phase 1: Master 自寫 (single-thread, ~30-60 min)

Author writes universe-level master page. **Must come first** because:
- 定義 universe scope (避免 fan-out 重複 / 漏)
- 列 hub slug list (subagent prompt 指 slug 一致性)
- 5 axis 投影框架 (sector / group / chain / 龍頭 / framework — 不是每個 universe 都全有)

Master schema (借鏡 `tw-stock-sectors-master-2026.md`):
- YAML frontmatter
- 為什麼這頁存在
- 官方 / 內部分類速覽表
- 子分類 / 跨類概念
- 主軸 chain (3-5 條)
- hub 狀態總表 (slug + 預估覆蓋 N + 狀態)
- 投資 / 操作角度的分群
- See also + Timeline

### Phase 2: Batched fan-out (~3-5 hrs)

8 個批次邏輯 (依 universe 性質調整):
- B1: 核心 / 旗艦類 (~4 hub)
- B2: 次重要類 (~5 hub)
- B3: 跨類概念 (~5 hub)
- B4-7: 中等優先類 (~5 hub × 4)
- B8: 利基類 (~4 hub)

每 agent prompt 必含:
1. **Output path** (絕對路徑)
2. **Schema reference** (已建的 sibling page, read first)
3. **Master sector map** (read 為 sibling slug 對齊)
4. **Companies / entities to cover** (列 ~15 個 ticker / slug + 中英文簡介)
5. **Identity discipline (CRITICAL)** — 引用 [[feedback_subagent-fanout-identity-vs-data-fields]]:
   - 公司全名 / 註冊地 / 法人 → web-verify (cnyes / TWSE 公司資訊 / 公司官網 / Wikipedia)
   - 不查證的標「待補」+ 在 Open questions 列
6. **Numeric discipline** — 營收 / 毛利 / 市佔 / 訂單 → 標「待補 quote 法說」, 不寫絕對數
7. **Wikilink convention** — `[[../../entity/<slug>-<id>|<short>]]` 或 sibling `[[<slug>]]`
8. **Output**: write file → return 3-line summary including identity fixes

### Phase 3: Cross-link + index (~30 min)

Master 完成後 + fan-out 全 return 後:
- Update master 「hub 狀態總表」: 待建 → ✓ 已建
- Add Timeline v2 entry (含 ROI 數字 + identity fix log)
- Update 上層 _index.md 加新 entry 入口
- 跨 hub bidirectional link (some sibling hubs 沒指回 master, 補一行)

## Identity-vs-data discipline (核心防呆)

寫 fan-out prompt 時, **這條 rule default-on, 不是「記得加」**:

```
**Identity 紀律 (CRITICAL — 這是 fan-out 失敗模式)**:
- 公司 FULL English name, ticker 確認, 註冊地 (TW / KY-Cayman / US ADR), 母公司 → 必查證
- Cyntec 2452 vs 三集瑞-KY 6862 案 (2026-05-23 早上): subagent 從中文簡稱「三集瑞」反推「Cyntec」是經典幻覺
- 不確定的查 cnyes / TWSE 公開資訊 / 公司官網; 查不到留空 + Open questions

**Numeric 紀律**:
- 營收 / 毛利 / 市值 / 訂單金額 → 標「待補 quote 法說」
- 製程節點 / 客戶名單 → 確認 source, 不確認 hedge「市場傳聞」
```

ROI: 兩個 wave 共 62 agents 抓到 master/brief 中 10+ 個 ticker/全名錯誤 (連騰科/康普/Ennostar/漢磊/動力-KY/鵬鼎/鎧勝-KY/中橡/信昌化/福華/TPK). 等於 fan-out + audit pass 一次完成.

## Cost / time envelope

- 100 page build: ~30-40 agents × 60-100K tokens/agent = 3-4M tokens total ≈ $100-200 (Opus 4.7)
- Wall clock: ~5 hours (含 master + 8 batches + cross-link)
- 比同質量人工: 200-300 hours (跨多週)

## Anti-patterns

- ❌ 直接 fan-out 不寫 master — sibling slug 不一致 / 範圍重疊
- ❌ 1 agent 寫 ≥ 5 個 page — token budget 爆掉, 後幾個粗糙
- ❌ subagent 不准 web research — identity 幻覺必出 (Cyntec 案)
- ❌ subagent 強制全 quantitative — 數字幻覺 + 浪費 token
- ❌ 不 update master 狀態表 — 下次 build 不知道做過什麼
- ❌ universe N < 20 還用 fan-out — overhead > 直接寫

## See also

- [[learnings/architecture/full-coverage-via-structural-decomposition]] — 為什麼這個 pattern 是 viable 的 architectural argument
- [[memory/feedback_subagent-fanout-identity-vs-data-fields]] — identity-vs-data discipline 完整 rule
- `passive-components-tw-2026.md` — sector hub schema reference (早上 morning 那次)
- `tw-stock-sectors-master-2026.md` — universe master schema reference
- `tw-stock-groups-2026.md` — group master schema reference (cross-cutting graph 不同於 sector taxonomy)

## Promotion criteria (從 _staging → skills/)

需湊到 **observed_count: 2** 才從 staging 升 production. 目前:
- 第 1 次: 2026-05-23 早上 passive-components fan-out (16 公司 + 1 hub, 3 agents 較小 scale, 不算正式 strike)
- 第 2 次: 2026-05-23 下午 sector hubs build (32 agents, 40 hubs)
- 第 3 次: 2026-05-23 晚上 group/chain/company build (30 agents, 49 pages)

3 strikes 同一天, 但都是同一個 user / 同一個 topic. 若下次別的 domain (Yei protocols / 朋友品牌) 也用同 pattern 成功, 才算真正 cross-domain validation 可升 production.
