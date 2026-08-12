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

## Surface boundary

Extends Verbs routing with product-outcome acceptance; replaces neither code
diff review, browser QA, nor a host release gate. The applicable
`.out-of-scope/persona-layer.md` precedent is preserved: acceptance authority is
a named human, not a stakeholder or Product Owner persona. No other matching
out-of-scope precedent exists.

## 1. Bind goal and delivered artifact

Read the Sprint Goal, completed-item references, acceptance criteria, delivered
artifact identity, QA evidence when applicable, and stakeholder feedback. Name
who has authority to accept the product outcome. Bind the artifact as a full
commit SHA or `patch-sha256:<digest>`; patch evidence also requires the full base
SHA. A generic PR number, URL, build label, or abbreviated SHA is not an artifact
identity.

Return `UNPROVEN` immediately when the Sprint Goal is missing or the exact
delivered artifact identity cannot be established.

Completion: goal, exact artifact and base when required, acceptance set, and
acceptance authority are bound.

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

- `ACCEPTED`: every criterion and Goal claim passes on current evidence, and the
  named acceptance authority explicitly records `Stakeholder decision: accepted`.
- `NEEDS_CHANGES`: current evidence demonstrates at least one failed criterion,
  the outcome does not achieve the Goal, or the named authority records
  `Stakeholder decision: changes requested`.
- `UNPROVEN`: evidence is missing, incomplete, stale, indirect, or the stakeholder
  decision is pending, absent, or marked not required.

Never convert missing evidence into `ACCEPTED`.

## Output and stop

```markdown
Sprint Review: <label>
Result: ACCEPTED | NEEDS_CHANGES | UNPROVEN
Sprint Goal: <goal>
Artifact: <full commit SHA | patch-sha256:digest>
Base: <full base SHA | n/a for committed-head identity>
Acceptance:
- AC-1: PASS | FAIL | UNPROVEN — <evidence>
Goal assessment: PASS | FAIL | UNPROVEN — <evidence>
Acceptance authority: <named human>
Stakeholder decision: <accepted / changes requested / pending>
Feedback:
- <observation or none>
Candidate backlog outcomes:
- <outcome or none>
Evidence gaps:
- <gap or none>
```

Stop after the review record. Do not edit code, redefine acceptance criteria,
create backlog items, schedule work, or start another stage.
