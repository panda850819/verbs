---
name: review
description: |
  Review a code diff when asked, before committing, or before a PR. Uses scoped
  evidence, risk lanes, bounded correction, and cold-context escalation. NOT
  browser QA, prepared-plan critique, or external artifact trust checks.
reads:
  - repo: "**"
  - repo: AGENTS.md
  - repo: CLAUDE.md
  - skill: lib/learning-recall.md
  - skill: lib/model-anchors.md
  - cli: git
writes:
  - cli: stdout
forbids:
  - cli: git push
  - cli: gh pr create
domain: shared
classification: hybrid
user-invocable: true
---
# Code Review

The delta beyond an unstructured single-pass review is scope provenance,
risk-adaptive lanes, evidence gates, bounded correction, and cold escalation.

## 1. Bind scope

1. Read `AGENTS.md` or `CLAUDE.md` when present.
2. Resolve the base from the PR, upstream, or merge-base; print the base and
   changed-file list. Never silently review the whole repository.
3. Read the issue, brief, or request that defines intent. If none exists, report
   `INTENT GAP` and infer only from the diff.
4. Check branch state and uncommitted changes; use history only to explain scope.

## 2. Choose the risk lane

- **low:** local, reversible, with no trust boundary, persistent data,
  concurrency, public interface, generated contract, or production operation.
- **medium:** shared behavior, multiple files, compatibility, or concurrency.
- **high:** auth, secrets, money, permissions, migrations, destructive writes,
  production infrastructure, or unfamiliar costly behavior.

Choose the lane from the diff and intent. Promote when the first pass reveals a
risk trigger, candidate finding, coverage gap, or scope drift.

### Low-risk fast path

Only in the low lane with explicit scope and intent: trace the changed path,
match acceptance and branches to tests, and self-refute the likeliest defect. An
`INTENT GAP` promotes rather than entering this fast path. If no finding, gap, or
drift remains: Do not load review learnings or model anchors; enumerate no lenses,
print no empty scope-drift or cold-review fields, and return:

```markdown
Review scope: <base>..<head> | <n> files | risk: low
No actionable findings.
Coverage: <verified check>
Self-refute: <assumption and observed result>
```

## 3. Escalated review

Read `lib/learning-recall.md` and apply relevant repo learnings. Map the diff to
security, data integrity, concurrency, architecture, or operations lenses.
Medium uses only triggered lenses. High uses every relevant lens plus a
cold review.

Trace changed inputs through code, callers, contracts, tests, and failure
handling. A finding survives only with severity `P0`–`P3`, a tight file/line
range, a trigger, mechanism and user-visible consequence, and a correction
direction. Exclude style,
unreachable speculation, and pre-existing defects; review does not edit code.

Use a cold-context reviewer when the lane is high, the diff exceeds roughly 5K
tokens, or a load-bearing conclusion remains disputed. Give it only the bound
diff and intent; merge findings by mechanism; disagreement becomes `NEEDS TRACE`,
not a vote. Read `lib/model-anchors.md` only at this point and select its role.

Match acceptance and branches to tests, run the narrowest available checks, and
self-refute the highest-risk assumption. Report `COVERAGE GAP` only for unproved
concrete behavior and `SCOPE DRIFT` only for changes outside intent. Conclude with
findings, `No actionable findings.`, or `BLOCKED`.

## Output and completion

```markdown
Review scope: <base>..<head> | <n> files | risk: <lane>

Findings
- [P1] <title> — <file:line>
  Trigger: <input/state>
  Mechanism: <why it fails and impact>
  Direction: <correction>

Coverage: <verified checks or concrete gaps>
Scope drift: <none or entries>
Cold review: <not earned | completed | unavailable>
Self-refute: <assumption and result>
```

Done when findings are evidence-backed and the report names applicable
coverage, scope drift, cold review, and self-refutation.

## Anti-patterns

- Fixed three-pass fan-out for a small reversible diff.
- Skipping scope provenance or risk promotion because the diff looks small.
- Treating a repository-wide scan as evidence about the changed path.
- Auto-fixing findings and reviewing the rewrite as independent proof.
- Reporting hypothetical security language without an attacker-controlled path.
- Calling an unavailable cold review clean; record the gap.
