---
type: pitfall
key: flag-removal-sweep-bare-token
confidence: 8
source: observed
skill: review
files:
  - README.md
  - DISPATCH.md
  - RESOLVER.md
  - lib/
first_seen: 2026-07-19
recurrence: 1
status: active
created: 2026-07-19
last_seen: 2026-07-19
---

## Problem

Removing or renaming a CLI flag (`grill --brief` → `grill`) requires sweeping
every reference. Grepping the fully-qualified form `skill --flag` misses call
sites that dropped the skill name and wrote the bare flag — e.g. a table row
reading "Use `--brief` for a written brief". The qualified grep reported the
surface clean while a bare `--brief` still shipped in README.

## What Didn't Work

Scoping the sweep to `grep -rn 'grill --brief'`. It returned "NONE — clean" and
looked complete, but the reference count it produced was a false all-clear: any
mention that had already contextualized the skill and used only `--brief` was
invisible to it.

## Solution

Sweep in two passes: first the qualified form `skill --flag` to catch the
obvious references, then the BARE token (`--brief`) across the routing/skill
surface to catch de-qualified mentions. Rewrite each hit prose-aware — many
sentences contrast the old mode against a default, so a blind substitution
leaves a dangling contrast, not a correct sentence.

## Prevention

- For any flag removal/rename, the completeness check is `grep -rn -- '<bare-flag>'`
  over the routing + skill surface, not `grep '<skill> <bare-flag>'`.
- Run it as an explicit self-refute step AFTER the qualified sweep reports clean;
  treat a clean qualified grep as a candidate, not proof.
- Exclude only the historical record (CHANGELOG entries, prior dated briefs) and
  the artifact that documents the removal itself; everything else in the routing
  surface must come back empty.
