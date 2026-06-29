# office-hours output templates

Fill-in scaffolds for the two artifacts office-hours emits. The behavioural rules
(what each section means, the WHY-vs-WHAT split, the acceptance-must-be-checkable
rule) stay in SKILL.md; this file is the verbatim shape only.

## Brief template — Stage 5

Write to `docs/briefs/{YYYY-MM-DD}-{slug}.md`:

```markdown
---
date: {YYYY-MM-DD}
type: brief
source: office-hours
topic: {topic}
tags: [brief, office-hours]
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

## Next skill (recommended)

Apply `lib/skill-decision-tree.md` 2-question test against the chosen approach:

```
Shape: {single-target-iterative / N-sequential-sprints / N-branch-parallel}
Reasoning: {one line — which question of Q1/Q2 hit Yes and why}

Recommended skill:
  → /sprint {topic-slug}                          # if Q1=Yes (single-target, iteration expected; for N-step, run N sprints)
  → /team-orchestrate (with this brief as input)  # if Q2=Yes (N-branch parallel, independence audit required)
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
source: office-hours
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
