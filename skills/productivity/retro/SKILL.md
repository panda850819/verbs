---
name: retro
description: "Review one completed Sprint and choose one evidence-backed process improvement."
reads:
  - repo: "**"
  - repo: AGENTS.md
  - repo: CLAUDE.md
writes:
  - cli: stdout
domain: shared
classification: lifecycle-flow
user-invocable: true
disable-model-invocation: true
---
# Retro

Retro improves the product-engineering system after one completed Sprint. It is
not a personal reflection, scheduled journal, or general learning generator.

## 1. Bind evidence

Read the Sprint Goal and result, selected versus completed work, blockers,
review findings, QA evidence, delivery evidence, rework, and relevant human
observations. Separate observed events from explanations and opinions.

If no evidence supports a process conclusion, return `NO_SUPPORTED_ACTION`.
Do not invent a lesson to fill the format.

Completion: each candidate observation cites a Sprint artifact or named human
observation.

## 2. Find the highest-leverage change

Inspect quality, effectiveness, tools, interactions, assumptions, and the
Definition of Done. Identify what helped, what caused material friction, and
which system change could prevent the most important recurrence. Prefer a
specific reversible change over a broad aspiration.

Self-refute the proposed explanation against one competing cause. Drop the
change when the evidence does not survive that check.

Completion: the chosen change traces from evidence through mechanism to an
observable next-use check.

## 3. Choose one action

Emit at most one Action. It must name the behavior or process to change, its
evidence, an owner or decision owner, and how the next use will show whether it
helped. The record is a proposal; it does not schedule, assign, or execute the
action.

## Output and stop

```markdown
Retro: <Sprint label>
Status: ACTION_PROPOSED | NO_SUPPORTED_ACTION
Keep:
- <evidence-backed practice or none>
Change:
- <evidence-backed friction or none>
Action:
- <one action with owner and next-use check, or none>
Evidence:
- <artifact or observation>
Self-refute: <competing cause and result>
```

Stop after the record. Do not create calendar events, personal reflection files,
brain or memory entries, tracker items, or a second Action. Do not invoke or
schedule another stage.
