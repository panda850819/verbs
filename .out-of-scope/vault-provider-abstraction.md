---
decided: 2026-05-07
source: "ROADMAP.md:46 - Vault-provider abstraction (Logseq / Roam / Notion adapter layer)."
---

## What was rejected

A vault-provider abstraction for Logseq, Roam, Notion, or similar adapters.

## Why

Source text: `Vault-provider abstraction (Logseq / Roam / Notion adapter layer). Removed from v2 scope on 2026-05-07 after re-audit.`

Pandastack skills are LLM prompts, not compiled code. Path conventions in skill
text can be overridden by the agent or edited by the user, so a backend adapter
would overcomplicate the prompt-based system.

## What would reopen it

Revisit only after the 30-day decision freeze if real non-Obsidian users show
that documented convention overrides are insufficient.
