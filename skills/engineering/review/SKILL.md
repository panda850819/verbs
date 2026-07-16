---
name: review
description: |
  Review a code diff before PR or on request. Uses a bounded low-risk fast path, scoped evidence, risk-triggered lenses, and cold-context escalation. NOT browser QA, prepared-plan critique, or external artifact trust checks.
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

Native models already perform useful single-pass review. This skill earns its
slot through scope provenance, a bounded low-risk path, risk-triggered lenses,
cold-context escalation, and findings that survive an evidence gate.

## 1. Bind scope

1. Read `AGENTS.md` or `CLAUDE.md` when present.
2. Resolve the comparison base from the PR, upstream branch, or merge-base.
   Print the base and changed-file list. Never silently review the whole repo.
3. Read the issue, brief, or user request that defines intent. If none exists,
   state `INTENT GAP` and infer only from the diff.
4. Check branch state and uncommitted changes. Use history only when it explains
   the diff.

## 2. Choose the risk lane

- **low**: local, reversible, no trust boundary or persistent-data change.
- **medium**: shared behavior, multiple files, compatibility or concurrency.
- **high**: auth, secrets, money, permissions, migrations, destructive writes,
  production infrastructure, or unfamiliar behavior whose failure is costly.

Say why, run one grounded correctness pass, and promote when the diff, context,
or first pass reveals a higher-risk surface.

### Low-risk fast path

A review stays here when scope and intent are explicit, the diff is local and
reversible, and it touches no trust boundary, persistent data, concurrency,
public interface, generated contract, or production operation. Trace the
changed path, match acceptance and branches to tests, then self-refute the
assumption most likely to hide a defect.

When that pass finds no candidate finding, concrete coverage gap, scope drift,
or risk trigger, return this result and stop:

```markdown
Review scope: <base>..<head> | <n> files | risk: low
No actionable findings.
Coverage: <verified check>
Self-refute: <assumption and observed result>
```

Do not load review learnings or model anchors, enumerate lenses, or print empty
scope-drift and cold-review fields. Any failed condition promotes the review
without restarting scope discovery.

## 3. Escalated review

Read `lib/learning-recall.md` and apply relevant repo learnings. Map changed
surfaces to security, data integrity, concurrency, architecture, or operations
lenses. Medium uses only triggered lenses. High uses every relevant lens plus a
cold review.

Trace changed inputs through code, callers, contracts, tests, and failure
handling. Attempt to disprove each candidate. A finding survives only with:

- severity `P0` to `P3`;
- exact file and tight line range;
- triggering input or state;
- failure mechanism and user-visible consequence;
- a concrete correction direction.

Exclude style preferences, unreachable speculation, and pre-existing defects
outside the diff. Review does not edit code.

Use a cold-context reviewer when the lane is high, the diff exceeds roughly
5K tokens, or a load-bearing conclusion remains disputed. Give it the bound
diff and intent without current conclusions. Read `lib/model-anchors.md` only
now and select its role. Merge findings by mechanism; disagreement becomes
`NEEDS TRACE`, not a finding by vote.

Match acceptance and branches to tests, run the narrowest available checks, and
self-refute the highest-risk assumption. Report `COVERAGE GAP` only for
unproved concrete behavior and `SCOPE DRIFT` only for changes outside intent.
Conclude with findings, `No actionable findings.`, or `BLOCKED`.

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

## Anti-patterns

- Fixed three-pass fan-out for a small reversible diff.
- Printing the escalated envelope after a clean low-risk pass.
- Treating a large repository scan as evidence about the changed code.
- Auto-fixing findings and then reviewing one's own rewrite as independent proof.
- Reporting hypothetical security language without an attacker-controlled path.
- Calling unavailable cold review clean; record the gap.
