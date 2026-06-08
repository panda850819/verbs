---
name: tool-web-extract
description: |
  Clean markdown from web pages via Defuddle CLI.

  Trigger on: HTTP URL needing reading.
  Skip when: GitHub/Notion/X (use specialized tool first).
---

# Defuddle

Use Defuddle CLI to extract clean readable content from web pages. Prefer over WebFetch for standard web pages — it removes navigation, ads, and clutter, reducing token usage.

Before first use, verify installation: `which defuddle || npm install -g defuddle`

## Usage

Always use `--md` for content extraction:

```bash
defuddle parse <url> --md
```

Save to file:

```bash
defuddle parse <url> --md -o content.md
```

Extract specific metadata (no `--md` needed — `-p` returns a single value):

```bash
defuddle parse <url> -p title
defuddle parse <url> -p description
defuddle parse <url> -p domain
```

## Output formats

| Flag | Format | When |
|------|--------|------|
| `--md` | Markdown | Default for content extraction |
| `--json` | JSON with both HTML and markdown | Only when user requests JSON |
| (none) | HTML | Rarely needed |
| `-p <name>` | Specific metadata property | Standalone — don't combine with `--md` |

## Fallback

If defuddle returns empty content or errors (common with JS-heavy SPAs, login-gated pages), fall back to WebFetch.

**Fallback decision tree:**
1. `defuddle parse <url> --md` returns empty/error → retry once without `--md` to check if site is reachable
2. Still empty → use WebFetch as fallback (raw fetch, no rendering)
3. WebFetch also fails → use agent-browser (full headless browser, handles JS-rendered content)

**When user requests multiple formats** (e.g., "give me JSON and markdown"): use `--json` which returns both HTML and markdown content in a single call. Do not run defuddle twice with different flags.
