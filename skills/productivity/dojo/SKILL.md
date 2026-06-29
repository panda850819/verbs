---
name: dojo
aliases: [prep]
mode: skill
description: |
  Pre-action prep before a sprint / office-hours or any non-trivial work session. Triggers on /dojo, /prep (Layer-1 typing alias), "before I start", "let me prep first", auto-invoked by /sprint and /office-hours at Stage 0.
reads:
  - repo: lib/capability-probe.md
  - repo: lib/escape-hatch.md
  - vault: knowledge/**
  - vault: docs/sessions/**
  - vault: docs/learnings/**
writes:
  - vault: Inbox/prep-*.md
  - cli: stdout
domain: personal
classification: lifecycle-flow
capability_required:
  - agents.md
  - vault
  - lib/capability-probe.md
---

# Dojo — Pre-action prep (Stage 0)

> Before stepping into the ring, you walk into the dojo. You stretch, you check past matches, you surface what you forgot last time. Then you fight.

Universal Stage 0 for every Layer 1 flow (sprint, office-hours, work, knowledge, write). Replaces the implicit "I'll just start working" that loses prior context.

## When to invoke

- Before starting a non-trivial work session (>30 min scope)
- Beginning of a `/sprint` or `/office-hours` (auto-invoked there)
- When user says "before I start", "let me prep first", "what did I do last time on X"

## When to skip

- Trivial fix (1-line typo, single config)
- User explicitly says "skip prep"
- Vault inaccessible (capability-probe blocks)

## Stages

### Stage 0a: Capability probe

@../../../lib/capability-probe.md

Run probe. Abort if substrate broken. Continue if all green.

### Stage 0b: Past-case lookup

Take the user's stated topic. Run filename + content scans against vault:

```
ls docs/sessions/ docs/learnings/ knowledge/ | rg -i "<topic>"  # filename match
rg -l "<topic>" docs/sessions/ docs/learnings/ knowledge/ | head -10  # content match
```

Take top 5 hits across both. De-dup. Read the matched file's first 200 chars to extract context.

If 0 hits: surface "no prior context found, this looks new". User can confirm or correct ("you've worked on this — search again with different terms").

### Stage 0c: Lib + relevant pattern load

For each lib/ file relevant to the upcoming flow (read the flow's frontmatter `reads:`), load and stage in context. Print 1-line summary per lib loaded:

```
Loading for /sprint:
  ✓ lib/capability-probe.md  (substrate availability)
  ✓ lib/escape-hatch.md      (2-strike user-stop)
  ✓ lib/stop-rule.md         (per-decision gate)
```

### Stage 0d: Gotcha surface

From past-case content + learnings/, extract 1-3 gotchas relevant to the current topic. Format as:

```
## Gotchas (from prior sessions)

1. [date] [session-slug] — "<short lesson>" — relevance: <why it matches current topic>
2. ...
```

Don't fabricate gotchas if none surface from real past content. Empty list is OK; print `## Gotchas — none found in vault for this topic`.

### Stage 0e: Output prep brief

Write to `Inbox/prep-{slug}-{date}.md` using the template: @skills/productivity/dojo/lib/prep-brief-template.md

Print the path to user. Do NOT auto-continue into the next flow stage — user reads the prep, then decides to proceed.

If invoked auto from `/sprint` or `/office-hours`, the parent flow's Stage 1 reads this file and continues. User can interrupt between stages.

## Anti-patterns

- ❌ Skipping past-case lookup ("we know this topic, no need to search")
- ❌ Fabricating gotchas to fill the section ("sometimes timezone bugs happen" — only if a real prior session said so)
- ❌ Loading EVERY lib/ file regardless of flow (only ones the downstream flow declares)
- ❌ Continuing into Stage 1 without printing the prep file path
- ❌ Re-running dojo for the same topic in same session (use the existing prep file)

## Escape-hatch

@../../../lib/escape-hatch.md

If user says "skip prep" / "夠了" during the past-case lookup phase, stop the lookup, write whatever past-cases were found, mark gotcha section as `[skipped, escape-hatch]`, output the prep file. Do not abort the prep entirely — partial prep is better than none.
