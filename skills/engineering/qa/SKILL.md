---
name: qa
description: |
  Browser-based QA. Use when UI has changed, or when asked to
  "test this", "QA", or "check the page". Requires browser automation
  from the host. NOT for non-UI checks (use the project's normal test or
  verification path); NOT for code-diff review (use `review`).
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

You already know what to test. This skill is the evidence protocol: structured
assertions a merge decision can trust, not a test-writing tutorial.

## Context

Read the `## verbs` config from `CLAUDE.md` or `AGENTS.md`; resolve
`{learnings_dir}` (default `docs/learnings`) and search it for `type: pitfall`
entries related to the changed UI (shape per `lib/learning-format.md`). Read
the brief in `docs/briefs/` when one exists. Bind the intent source and assign
stable `AC-1`, `AC-2`, ... identifiers to its acceptance criteria. No issue,
brief, or explicit user goal means `INTENT GAP`; QA can test behavior but cannot
claim that the intended outcome is verified.

## Plan

From the diff, brief, or instructions, produce ONE numbered test list: core
user flows first (each as action → expected result), then the paths a
happy-path pass misses — error/empty/loading states, edge inputs, double
submit, Escape mid-flow, keyboard-only nav, mobile viewport, console errors
after interactions. Unclear what to test → ask: "What flows should I test?"

## Test

Run directly for small changes. Fan out to host-provided isolated browser
workers only when the list has 3+ groups AND session isolation is proven —
otherwise run sequentially. Each worker gets its exact numbered tests, the
assertion protocol below, and a step budget (~25 targeted / ~40 full page /
~75 multi-page); at budget, accept partial results with `STEP_SKIP`. Never
share one browser session across parallel workers; the main agent merges and
summarizes.

### Assertion protocol

Every test step MUST produce a structured marker:

```
STEP_PASS|<step-id>|<evidence>
STEP_FAIL|<step-id>|<expected> -> <actual>
STEP_SKIP|<step-id>|<reason>
```

Verification, in order of rigor — use the strongest available:

1. **Deterministic check**: `eval` returns structured data (element count, field value, console errors)
2. **Snapshot element match**: expected role/text exists in the accessibility tree
3. **Before/after comparison**: snapshot, act, snapshot, verify the change
4. **Screenshot + visual judgment** (weakest): only for properties the accessibility tree cannot capture

Every `STEP_FAIL` gets a screenshot and a `[BUG]` report per
`lib/qa-evidence-format.md`. After all tests:

```
Tests: N | Passed: N | Failed: N | Skipped: N | Pass rate: N%
```

## Acceptance evidence handoff

Map every acceptance criterion to the strongest relevant step evidence. Emit
the marker-delimited block from `lib/qa-evidence-format.md`, including intent,
artifact identity, per-criterion `PASS` / `FAIL` / `UNPROVEN`, totals, gaps,
and timestamp. Also persist the exact block at the Git metadata path returned
by `git rev-parse --git-path verbs/qa-evidence.md`; do not dirty the worktree.

QA does not write to GitHub. `ship` owns the pull-request upsert because it
already owns PR mutation and may run after QA but before a PR exists. A later
code change invalidates the evidence until the affected checks rerun.

## Fix

Execute each bug report's `Action` field using the routing contract in
`lib/qa-evidence-format.md`; never reclassify it here. After an AUTO-FIX,
re-run the affected flow. ASK items remain explicit pending decisions and are
never reported as fixed.

## Learning candidate

If a genuinely new UI pattern or browser pitfall surfaced, emit one
`type: pitfall` candidate per `lib/learning-format.md` — persistence belongs
to the host/project. Otherwise state "no learning warranted".
