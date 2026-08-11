---
name: sprint-review
description: "Review one Sprint outcome against its Goal and product acceptance evidence."
reads:
  - repo: "**"
  - repo: AGENTS.md
  - repo: CLAUDE.md
  - skill: lib/qa-evidence-format.md
  - skill: qa
  - skill: review
writes:
  - cli: stdout
domain: shared
classification: lifecycle-flow
user-invocable: true
disable-model-invocation: true
---
# Sprint Review

Sprint Review inspects the product outcome. Code review proves properties of a
diff and QA can prove browser-visible criteria; neither alone proves that the
Sprint Goal was achieved.

## 1. Bind goal and delivered artifact

Read the Sprint Goal, completed-item references, acceptance criteria, delivered
artifact identity, QA evidence when applicable, and stakeholder feedback. Name
who has authority to accept the product outcome.

Return `UNPROVEN` immediately when the Sprint Goal is missing or the delivered
artifact cannot be identified.

Completion: goal, artifact, acceptance set, and acceptance authority are bound.

## 2. Inspect outcome evidence

Map every acceptance criterion and Goal claim to current evidence. Apply
`@lib/qa-evidence-format.md` artifact identity rules: stale evidence, uncovered
untracked files, a `FAIL`, or an `UNPROVEN` criterion cannot support acceptance.
A clean `review` report supports code quality but is not product acceptance.

Record stakeholder observations as evidence or feedback; do not silently turn
feedback into a requirement.

Completion: every criterion and Goal claim is `PASS`, `FAIL`, or `UNPROVEN` on
the delivered artifact.

## 3. Decide the result

- `ACCEPTED`: every criterion and Goal claim passes on current evidence, and any
  required human acceptance is present.
- `NEEDS_CHANGES`: current evidence demonstrates at least one failed criterion
  or the outcome does not achieve the Goal.
- `UNPROVEN`: evidence is missing, incomplete, stale, indirect, or awaiting a
  required human decision.

Never convert missing evidence into `ACCEPTED`.

## Output and stop

```markdown
Sprint Review: <label>
Result: ACCEPTED | NEEDS_CHANGES | UNPROVEN
Sprint Goal: <goal>
Artifact: <commit / PR / build identity>
Acceptance:
- AC-1: PASS | FAIL | UNPROVEN — <evidence>
Goal assessment: PASS | FAIL | UNPROVEN — <evidence>
Stakeholder decision: <accepted / changes requested / pending / not required>
Feedback:
- <observation or none>
Candidate backlog outcomes:
- <outcome or none>
Evidence gaps:
- <gap or none>
```

Stop after the review record. Do not edit code, redefine acceptance criteria,
create backlog items, schedule work, or start another stage.
