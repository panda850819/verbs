# Brief + plan output templates

Fill-in scaffolds for the two artifacts `grill --brief` emits (brief + executable
plan). The behavioural rules (what each section means, the WHY-vs-WHAT split, the
acceptance-must-be-checkable rule) stay in the skill body; this file is the
verbatim shape only.

## Brief template — Stage 5

Write to `docs/briefs/{YYYY-MM-DD}-{slug}.md`:

```markdown
---
date: {YYYY-MM-DD}
type: brief
source: grill
topic: {topic}
tags: [brief, grill]
---

# {Topic}

## Problem

{user problem, not feature description}

## Original premise

{what user walked in with}

## Revised premise (after grill)

{what holds after Stage 2}

## Alternatives considered

- A: {name} — {summary} — [Add / Defer / Reject]
- B: {name} — {summary} — [Add / Defer / Reject]
- C: {name} — {summary} — [Add / Defer / Reject]

## Chosen approach

{A/B/C} — {one-line rationale}

## Scope

In: {what's included}
Out: {what's explicitly excluded}

## Seams

{which existing test seams the work passes through; new seams named and placed
as high as possible — omit this section for pure-decision briefs}

## Next skill (recommended)

Apply `lib/skill-decision-tree.md` 2-question test against the chosen approach:

```
Shape: {single-target-iterative / delegated-mechanical-batch / pure-decision}
Reasoning: {one line — which route fits and why}

Recommended skill:
  → /sprint {topic-slug}                          # if active judgment and review stay in the foreground session
  → /handover {topic-slug}                        # if the next work is a bounded mechanical batch for Codex
```

## Gotchas surfaced

{from Stage 1 past cases}

## Gate Log

- Stage 1 (load context): {summary}
- Stage 2 (premise challenge): {n questions, n pushes via push-once, escape-hatch fired? Y/N}
- Stage 3 (alternatives): chose {A/B/C}
- Stage 4 (premise refresh): {premise still load-bearing}
- Stage 5 (output): brief saved to {path}

## OPEN_QUESTIONS

{any axes not addressed due to escape-hatch or user defer}
```

## Plan template — Stage 5b

Write to `docs/plans/{slug}.md`:

```markdown
---
slug: {slug}
date: {YYYY-MM-DD}
type: plan
source: grill
brief: docs/briefs/{YYYY-MM-DD}-{slug}.md
execution: {code | knowledge-work}
status: todo
---

# {Topic} — executable plan

> WHAT only. WHY is in the brief (`brief:` above). Agents read this file; per-task `status:` is DERIVED from git at execute time, never hand-edited mid-sprint.

## Tasks

### {slug}-T01 — {title}
- scope: {files / paths this task touches}
- acceptance: {a concrete greppable or runnable check that proves it done}
- depends-on: {none | U-ID list}
- status: todo

### {slug}-T02 — {title}
- scope: ...
- acceptance: ...
- depends-on: {slug}-T01
- status: todo
```
