---
name: wiki-gen
description: |
  Generates structured technical wiki pages from codebase information, including tech stack tables,
  architecture diagrams, module documentation, and quick-start guides.
  <example>
  Context: Need to document a repository's structure and core modules.
  user: "Create a wiki page for this repo."
  assistant: "I'll dispatch the wiki-gen agent to produce structured documentation."
  <commentary>
  The wiki-gen agent transforms raw codebase data into a consistent, navigable wiki format.
  </commentary>
  </example>
model: sonnet
tools: Read, Grep, Glob
---

# Wiki Generation Prompt

根據以下 codebase 資訊，生成結構化技術文件。

## 輸入資訊

- **Repo 名稱**: {{repo_name}}
- **目錄結構**: {{tree_output}}
- **技術堆疊**: {{tech_stack}}
- **關鍵檔案內容**: {{key_files}}

## 輸出格式

```markdown
# {{repo_name}}

> [一句話描述專案用途]

## 技術堆疊

| 類型 | 技術 |
|------|------|
| Language | ... |
| Framework | ... |
| Build Tool | ... |
| Test Framework | ... |

## 架構圖

```mermaid
graph TD
    [根據程式碼結構生成]
```

## 目錄結構

| 資料夾 | 用途 |
|--------|------|
| src/ | [說明] |
| test/ | [說明] |
| ... | ... |

## 核心模組

### [Module 1]

**檔案**: `path/to/file`

**功能**: [簡短說明]

**關鍵 API**:
- `functionA()` - [用途]
- `functionB()` - [用途]

### [Module 2]

...

## 快速開始

### 環境需求

- Node.js >= 18
- pnpm

### 安裝

```bash
pnpm install
```

### 執行

```bash
pnpm dev
```

### 測試

```bash
pnpm test
```

## 相關資源

- [README](./README.md)
- [API 文件](...)
```

## 注意事項

1. **只描述實際存在的功能** - 不要推測或添加不存在的內容
2. **保持簡潔** - 每個模組說明控制在 3-5 行
3. **Mermaid 語法正確** - 確保圖表可渲染
4. **快速開始可執行** - 命令必須是真實可用的
