---
name: review
description: |
  Review a code diff before PR or on request. Adds scope provenance, risk-adaptive passes, cold-context escalation, and evidence-ranked findings beyond a host's ordinary single-pass review. NOT browser QA, prepared-plan critique, or external artifact trust checks.
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
user-invocable: false
---
# Code Review

Native models already perform useful single-pass review. This skill earns its
slot by binding the intended diff, scaling scrutiny to risk, separating a cold
reviewer when confirmation bias matters, and refusing ungrounded findings.

## 1. Bind scope

1. Read `AGENTS.md` or `CLAUDE.md` when present.
2. Resolve the comparison base from the PR, upstream branch, or merge-base.
   Print the base and changed-file list. Never silently review the whole repo.
3. Read the issue, brief, or user request that defines intent. If none exists,
   state `INTENT GAP` and infer only from the diff.
4. Check branch state and uncommitted changes. Inspect history only when it
   explains the diff; broad TODO or churn audits are out of scope.

Completion: the reviewed base, files, and intent source are explicit.

## 2. Set the risk lane

Choose one lane and say why:

- **low**: local, reversible, no trust boundary or persistent-data change.
- **medium**: shared behavior, multiple files, compatibility or concurrency.
- **high**: auth, secrets, money, permissions, migrations, destructive writes,
  production infrastructure, or unfamiliar behavior whose failure is costly.

Every lane gets one grounded correctness pass. Medium adds only the lenses
triggered by changed surfaces. High adds all relevant lenses plus a cold review.

Triggered lenses are: security for attacker-controlled input or privilege;
data integrity for schema, persistence, ordering, or retries; concurrency for
shared mutable state; architecture for public interfaces or dependency flow;
operations for deploy, rollback, observability, or failure recovery.

Completion: every changed surface maps to a used lens or an explicit skip.

## 3. Review from evidence

Trace changed inputs through the real code path. Compare behavior with tests,
callers, contracts, and failure handling. For each candidate finding, attempt
to disprove it with the repository before reporting it.

A finding survives only when it has all of:

- severity `P0` to `P3`;
- exact file and tight line range;
- triggering input or state;
- failure mechanism and user-visible consequence;
- a concrete correction direction.

Do not report style preferences, speculative risks with no reachable trigger,
or pre-existing defects outside the diff. Do not edit code during review.

## 4. Escalate only when earned

Use a cold-context reviewer when the lane is high, the diff exceeds roughly
5K tokens, or a load-bearing conclusion remains disputed. Give it the bound
diff and intent without the current review's conclusions. If a different model
seat is available, select it from `lib/model-anchors.md`; never hardcode a model.

Merge duplicate findings by mechanism. Disagreement lowers confidence and is
reported as `NEEDS TRACE`; it does not become a finding by vote count. Low-risk
reviews do not pay cross-model or multi-agent overhead by default.

## 5. Verify coverage and conclude

Match each acceptance criterion and changed branch to existing or newly run
tests. Run the narrowest relevant checks when read-only review authorization
allows it. Report `COVERAGE GAP` only when a concrete behavior has no proof.
Report `SCOPE DRIFT` only when a changed file or behavior cannot be traced to
the intent source.

Before concluding, self-refute once: name the highest-risk assumption and test
it against code or a command. Completion requires a clean working tree after
the review and one of these outcomes:

- actionable findings, ordered by severity;
- `No actionable findings.` with residual test or environment gaps;
- `BLOCKED` with the missing diff, intent, dependency, or runtime proof.

## Output format

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
- Treating a large repository scan as evidence about the changed code.
- Auto-fixing findings and then reviewing one's own rewrite as independent proof.
- Reporting hypothetical security language without an attacker-controlled path.
- Calling unavailable cold review clean; record the gap.
