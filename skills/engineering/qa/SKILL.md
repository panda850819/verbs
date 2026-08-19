---
name: qa
description: |
  Browser evidence route when UI changed, browser acceptance remains unproven,
  or the user asks to test a page. Requires host browser automation; maps the
  current artifact to acceptance criteria and stores a PR-ready handoff for
  `ship`. Use `review` for the diff and native tests for non-UI behavior.
capability_required:
  - host browser automation
reads:
  - repo: "**"
  - repo: CLAUDE.md
  - repo: AGENTS.md
  - repo: docs/briefs/**
  - skill: lib/learning-format.md
  - skill: lib/qa-evidence-format.md
  - cli: git
writes:
  - cli: stdout
  - repo: ".git/verbs/qa-evidence.md"
user-invocable: true
---
# QA

QA is the evidence protocol: structured assertions a merge decision can trust,
not a test-writing tutorial.

## Context

Read the `## verbs` config from `CLAUDE.md` or `AGENTS.md`; resolve
`{learnings_dir}` (default `docs/learnings`) and search related `type: pitfall`
entries using `lib/learning-format.md`. Read a matching brief from
`docs/briefs/`. Bind the intent source and assign stable
`AC-1`, `AC-2`, ... identifiers to its acceptance criteria. Without an issue,
brief, or explicit goal, report `INTENT GAP`; behavior alone cannot prove intent.

## Plan

Produce ONE numbered list of action → expected result checks: core user flows
first, then error/empty/loading states, edge inputs, double submit, Escape,
keyboard-only navigation, mobile viewport, and console errors. If the flows are
unclear, ask what to test.

## Test

Run small changes directly. Use isolated browser workers only for 3+ groups when
session isolation is proven; otherwise run sequentially. Give each worker its
numbered tests, the assertion protocol below, and a step budget (~25 targeted / ~40 full page / ~75 multi-page);
at budget accept partial results with `STEP_SKIP`; the main agent merges and
summarizes worker results, and never share a browser session.

Every test step MUST emit one marker:

```
STEP_PASS|<step-id>|<evidence>
STEP_FAIL|<step-id>|<expected> -> <actual>
STEP_SKIP|<step-id>|<reason>
```

Use the strongest available verification in this order: deterministic evaluation,
accessibility snapshots, before/after comparison, and screenshots only where the
tree cannot prove the property. A
`STEP_FAIL` always gets a screenshot and a `[BUG]` report per
`lib/qa-evidence-format.md`. End with:

```
Tests: N | Passed: N | Failed: N | Skipped: N | Pass rate: N%
```

## Acceptance evidence handoff

Map every acceptance criterion to the strongest step evidence. Emit the exact
marker block from `lib/qa-evidence-format.md`, including intent, current
artifact identity, per-criterion `PASS` / `FAIL` / `UNPROVEN`, totals, gaps, and
timestamp. Persist it at `git rev-parse --git-path verbs/qa-evidence.md` without
dirtying the worktree.

QA does not write to GitHub; `ship` owns the PR upsert. A later code change
invalidates the evidence until the affected checks rerun.

## Fix and learning

Run each bug report's `Action` through `lib/qa-evidence-format.md`; never
reclassify it. Re-run an affected flow after `AUTO-FIX`; keep `ASK` pending.
Emit one `type: pitfall` candidate only for a genuinely new UI pattern or
browser pitfall; otherwise state no learning is warranted.

Done when every acceptance criterion is mapped to current artifact-bound
`PASS`, `FAIL`, or `UNPROVEN` evidence and the test totals are reported.
