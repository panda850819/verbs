---
name: product-planning
description: |
  Clarify the product problem, Product Goal, priority, and candidate backlog
  outcomes. Use when deciding what product work should happen next, why an
  opportunity matters, or which outcome deserves priority. May use ask-boss,
  wayfinder, prototype, or to-spec when their narrower contract applies. NOT
  backlog-item readiness, iteration selection, or implementation.
reads:
  - repo: "**"
  - repo: AGENTS.md
  - repo: CLAUDE.md
  - skill: ask-boss
  - skill: wayfinder
  - skill: prototype
  - skill: to-spec
writes:
  - cli: stdout
domain: shared
classification: lifecycle-flow
user-invocable: true
---
# Product Planning

Product Planning turns product evidence into one prioritized outcome. It does
not make an implementation commitment or become a product-truth store.

## 1. Bind evidence and authority

Read the repository contract and the available product evidence: stated user
problem, current behavior, prior decisions, active goals, and relevant tracker
references. Separate observed facts from assumptions. If the owner, source of
truth, target, or authority is unclear, use `ask-boss`; if several dependent
decisions require work across sessions, use `wayfinder`.

Completion: the decision owner, evidence sources, and decision horizon are
named; missing sources remain visible.

## 2. Frame the opportunity

State the affected user, current problem, consequence, desired outcome, and a
success signal. Challenge solution-first requests by distinguishing the outcome
from the proposed feature. A single design uncertainty may use `prototype`;
established spec-sized requirements may use `to-spec` only through its own
publication gate.

Completion: the product problem and outcome can be evaluated without assuming a
particular implementation.

## 3. Set priority

Compare candidate outcomes against the current Product Goal, user impact,
evidence strength, urgency, dependencies, and cost of delay. Mark unsupported
claims instead of inventing customer evidence. Return `INSUFFICIENT_EVIDENCE`
when the visible outcomes cannot be compared. Return `DECISION_REQUIRED` when
evidence supports the tradeoff but only the named owner can choose. Otherwise
recommend one priority.

Completion: the result names why the outcome comes first, what evidence could
reverse it, or the exact evidence or owner decision still required.

## Output and stop

```markdown
Product Planning: <topic>
Status: PRIORITIZED | DECISION_REQUIRED | INSUFFICIENT_EVIDENCE
Product Goal: <one outcome>
User problem: <observed problem and consequence>
Success signal: <observable measure>
Priority: <recommended outcome and reason>
Candidate backlog outcomes:
- <outcome, not implementation task>
Assumptions / gaps:
- <gap or none>
Evidence:
- <source>
```

Stop after the record. Do not mark backlog items ready, select iteration work,
create tickets, assign ownership, or start implementation.
