---
name: summarize
aliases: [tool-summarize]
description: |
  Extract full text + optional AI summary from URL/YouTube/podcast/PDF via summarize CLI. Always preserves original (vault discipline: never summary-only).

  Trigger on: 'summarize', 'transcribe', 'TL;DR', YouTube/podcast URL, PDF read.
  Skip when: text-only article (use defuddle for cleaner markdown extraction).
homepage: https://summarize.sh
version: "2.0.0"
metadata:
  {
    "openclaw":
      {
        "emoji": "🧾",
        "requires": { "bins": ["summarize"] },
        "install":
          [
            {
              "id": "brew",
              "kind": "brew",
              "formula": "steipete/tap/summarize",
              "bins": ["summarize"],
              "label": "Install summarize (brew)",
            },
          ],
      },
  }
user-invocable: true
---

# Summarize (extract-first, summary-optional)

Fetch source content via `summarize` CLI. **Original full text is always extracted and preserved.** AI summary is an optional convenience layer, not a replacement.

## Vault Discipline (READ THIS FIRST)

Per vault `AGENTS.md` § Source preservation rule: **never write a vault file that has only a summary**. Original always present, summary clearly marked as not-endorsed.

This skill enforces that contract:
- Default behavior: `--extract-only` to get full text. Summary is opt-in.
- When summary is added, it lives in a separate `## AI Summary` section under the original.
- If full text extraction fails, **do not write to vault** — return error and stop. Summary-only files pollute the brain layer (you lose ability to re-distill or verify later).

## Two modes

### Mode 1: Extract-only (default for vault writes)

For URL / YouTube / podcast / PDF:

```bash
# Get full content, no summary
summarize "<url>" --extract-only --json
```

Returns JSON with full text. Save to vault using the template below.

For YouTube specifically:
```bash
# Best-effort transcript without LLM summarization
summarize "<youtube-url>" --youtube auto --extract-only
```

Fallback chain if `--extract-only` returns empty/short:
1. `summarize <url> --extract-only --firecrawl always`
2. `~/.bun/bin/defuddle parse <url> --md` (for HTML pages)
3. `yt-dlp --write-sub --sub-lang en --skip-download` then `whisper` (for video without subs)
4. If all fail → return error, do NOT write to vault

### Mode 2: Extract + summarize (for in-conversation reply only)

When user wants a quick TL;DR in chat (not for vault):

```bash
summarize "<url>" --length short
```

Display summary inline. Do not save to vault unless user explicitly asks.

If the user later says "save this", the workflow becomes:
1. Re-fetch with `--extract-only --json` to get full text
2. Append AI summary that was already shown
3. Write using vault template below

## Vault write template

When writing fetched content to vault (`Inbox/feeds/raw/YYYY-MM-DD/<slug>.md`):

```markdown
---
date: YYYY-MM-DD
type: feed-raw
source: <url>
fetched_at: <ISO8601>
origin: ai-fetched
extractor: summarize | defuddle | yt-dlp+whisper | bird | pdftotext
ai_summary_at: <ISO8601 OR omit>
ai_summary_model: <model id OR omit>
---

# {title}

## Original (full source)

<完整原文 — 不修剪、不重排、不格式化>

---

## AI Summary (auto-generated YYYY-MM-DD, not endorsed)

<optional. only if user explicitly requested summary alongside extract.
clearly marked as AI output. can be regenerated; original cannot.>
```

Rules:
- `## Original` must contain the FULL extracted text. Truncation = bug.
- `## AI Summary` is optional. Omit the section entirely if no summary was generated.
- `ai_summary_at` / `ai_summary_model` only present when summary section exists.
- Re-summarizing later: replace `## AI Summary` content + update `ai_summary_at`. Never touch `## Original`.

## Model + keys

Set the API key for your chosen provider:

- OpenAI: `OPENAI_API_KEY`
- Anthropic: `ANTHROPIC_API_KEY`
- xAI: `XAI_API_KEY`
- Google: `GEMINI_API_KEY` (aliases: `GOOGLE_GENERATIVE_AI_API_KEY`, `GOOGLE_API_KEY`)

Default model: `google/gemini-3-flash-preview`.

## Useful flags

- `--extract-only` — return full text, no LLM summary (default for vault writes)
- `--length short|medium|long|xl|xxl|<chars>` — summary length when summarizing
- `--max-output-tokens <count>` — cap output tokens
- `--json` — machine-readable output (use for vault writes to parse cleanly)
- `--firecrawl auto|off|always` — fallback extraction for paywall/JS-heavy sites
- `--youtube auto` — Apify fallback (needs `APIFY_API_TOKEN`)

Add `--firecrawl auto` proactively for known paywall domains (nytimes, wsj, bloomberg, ft, etc.).

## Anti-patterns (do NOT do these)

| Anti-pattern | Why bad | Do instead |
|---|---|---|
| Save summary-only file to vault | Destroys re-distillation; original is gone | Always extract first, summary is optional addition |
| `summarize <url>` then save output as the note body | Same as above — output is a summary not the source | `--extract-only` first, then optionally append summary |
| Truncate `## Original` because "it's too long" | The point of preserving original is to NOT truncate | If truly too large, link to external archive instead and don't store |
| Modify `## Original` after writing | Original is immutable | Only `## AI Summary` is regenerable |
| Skip writing because summary alone is "good enough" | Today's summary is not tomorrow's question | If worth saving, save the original |

## Execution Rules

1. **Default to extract-only** when writing to vault. Summarize only on explicit request OR for in-conversation reply.
2. **Never expose API keys**: reference by env var name in commands; never print actual values.
3. **Quote all file paths**: `summarize "/path/with spaces.pdf"`.
4. **Clean output by default**: present as readable markdown; no raw CLI JSON unless `--json` requested.
5. **Match user length requests**: map "brief/short/detailed" to `--length` flag accordingly.

## Config

Optional config file: `~/.summarize/config.json`

```json
{ "model": "openai/gpt-5.2" }
```

Optional services:

- `FIRECRAWL_API_KEY` for blocked sites
- `APIFY_API_TOKEN` for YouTube fallback
