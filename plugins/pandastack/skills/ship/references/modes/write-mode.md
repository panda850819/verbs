# Ship — write mode

Close a `Blog/_daily/<date>.md` (or in-progress draft) → `Blog/Published/<slug>.md`. Triggered by `/ship write <draft>` or `/ship <path>` where `<path>` is under `Blog/_daily/`.

Run from vault root. Pass draft path or slug as `$ARGUMENTS`. If empty, ask.

## Scope: vault-only

This mode **never publishes to external platforms**. `Blog/Published/` lives in the vault and is downstream-synced by the website repo. Twitter thread output is a draft file in `Inbox/x-drafts/`, never posted. Newsletter sync, RSS push, and external distribution happen later, manually.

`/ship write` is safe at any time. Nothing escapes the vault until you push it yourself.

## Anti-ceremony rule

Default to **Close-only** (Stage 1) unless user opts into full ship, OR Stage 1 detects a Backflow trigger (cites ≥2 knowledge notes / surfaces ≥1 byproduct idea / voice deviation noticed).

Open with one question:

> 「Close-only 還是完整 ship（Close + Extract + Backflow）？」

Default Close-only. Skip on `--full` / `--close-only`.

Extract returning "no new insight" is valid.

---

## Stage 1: Close (mechanic)

### 1.1 Resolve draft path

```bash
DRAFT="$ARGUMENTS"
[ -z "$DRAFT" ] && echo "需要 draft path 或 slug" && exit 1
[ ! -f "$DRAFT" ] && DRAFT=$(ls Blog/_daily/*${ARGUMENTS}*.md 2>/dev/null | head -1)
[ ! -f "$DRAFT" ] && echo "找不到 draft" && exit 1
```

### 1.2 Confirm slug + frontmatter

Prompt user for:

- `slug` (default: derive from filename)
- `distribution` (default: `[blog]`; ask if also `twitter`, `newsletter`)
- `published` (default: today)

Add/update frontmatter:

```yaml
slug: <slug>
published: <YYYY-MM-DD>
distribution: [blog, ...]
```

### 1.3 Move to Published

```bash
git mv "$DRAFT" "Blog/Published/<slug>.md"
```

Use `git mv` so backlinks-aware tooling tracks the rename. Do NOT change slug after this point.

### 1.4 Reverse-cite update

Scan for `[[wiki-link]]` references to `knowledge/` notes. For each cited note, append:

```yaml
cited_in:
  - <slug> (<YYYY-MM-DD>)
```

Bidirectional knowledge-graph link.

### 1.5 Detect Backflow triggers

- **Knowledge cites**: count `[[knowledge/...]]` references
- **Byproduct potential**: count `<!-- aside: ... -->` or footnote-marked tangents
- **Voice flag**: any line that triggered `write` slop detection upstream

### 1.6 (Optional) Twitter thread draft

If `distribution` includes `twitter`, generate `Inbox/x-drafts/<slug>.md`:

- 7-12 tweet thread, each <280 chars
- Hook tweet first
- Tail tweet links back to blog post
- DO NOT post — manual posting later (via `pandastack-private:bird` if you have the overlay, or X UI directly)

### 1.7 Show & Confirm (gate)

```
=== /ship write 完成（vault 已更新）===

Close 完成: Blog/Published/<slug>.md
  cited knowledge notes: N
  byproduct asides: M
  voice flags: K
  Backflow triggers detected: [<list>]

== 已寫入 ==
1. Blog/Published/<slug>.md (git mv from <draft>)
   frontmatter added: slug, published, distribution

2. <cited knowledge notes> (frontmatter)
   + cited_in: - <slug> (<date>)

3. Inbox/x-drafts/<slug>.md (only if distribution includes twitter)

== 接下來 ==
- vault 已更新，沒有任何發文 / 推送
- Twitter draft 仍是檔案，未發出
- 要繼續 Stage 2 (Extract) + Stage 3 (Backflow) 嗎？[y/N]
```

If no, write ship-log entry and exit.

If no Backflow triggers AND Close-only at start, default stop, no Stage 2 question.

---

## Stage 2: Extract (semantic)

Three questions, one at a time. Allow skip.

1. **Thesis 一句話？** (這篇文章的單一主張)
2. **副產品 idea？** (寫的過程中 surface 出哪些「沒寫進來但值得單獨成 note」的想法)
3. **Voice / 結構 insight？** (有什麼 reusable 寫法 / 反 pattern？)

Store for Stage 3.

---

## Stage 3: Backflow (system update)

| 條件 | 動作 | 落點 |
|---|---|---|
| Q1 thesis exists | Add entry to `knowledge/<domain>/_index.md` "Published thesis" section. Format: `- [<title>](Blog/Published/<slug>.md) — <thesis> (<date>)` | `_index.md` |
| Q2 lists byproducts | For each, draft `Inbox/<slug>-aside-<n>.md` with aside content + `source: <published-slug>` frontmatter | `Inbox/` |
| Q3 produces voice rule / structural pattern | Draft addition to `<memory-dir>/project_writing_style.md` (show diff, ask) | memory |
| Q3 flags a slop pattern | Draft addition to `~/.claude/rules/voice.md` "Prohibited" list (show diff, ask) | rules |
| Cited ≥3 different knowledge notes from same `knowledge/<domain>/` | Mark this published post as a "synthesizer" — add to `knowledge/<domain>/_index.md` "Synthesizer posts" | `_index.md` |

**Rule**: Stage 3 NEVER writes destructively without diff + confirm.

---

## Output

Append to `Inbox/ship-log/YYYY-MM-DD.md`:

```markdown
## /ship write <slug> @ HH:MM

- Close: ✓ (mv → Published, frontmatter, cited_in updated on N notes)
- Extract: <empty | thesis + N byproducts + voice insight>
- Backflow:
  - <action> → <落點>
- Triggers: [<list>]
- Knowledge cites: N
- Byproduct stubs created: M
```

---

## Failure modes

| 症狀 | 處理 |
|---|---|
| `Blog/Published/<slug>.md` already exists | Abort. Ask if user wants `<slug>-v2` or to update existing |
| Draft has no body (just frontmatter) | Abort with "draft empty, write something first" |
| `[[wiki-link]]` target doesn't exist | Warn but don't block. Record as "broken link" |
| `git mv` fails | Fall back to `mv`, warn that backlinks tooling may miss the rename |
| Slug collision | Append `-2`, ask to confirm |
