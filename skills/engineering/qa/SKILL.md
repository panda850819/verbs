---
name: qa
description: |
  Browser-based QA. Use when UI has changed, or when asked to
  "test this", "QA", or "check the page". Requires browser automation
  from the host. NOT for non-UI checks (use the project's normal test or
  verification path); NOT for code-diff review (use `review`).
capability_required:
  - host browser automation
user-invocable: false
---
# QA

## Step 1: Load Context

1. Read verbs config from `CLAUDE.md` or `AGENTS.md` (whichever the project uses). Resolve `{learnings_dir}` from it (default `docs/learnings`).
2. Search `{learnings_dir}` for `type: pitfall` related to UI or the changed components. The `type: pitfall` shape is defined in `lib/learning-format.md`.
3. Read the brief (if exists in `docs/briefs/`) to understand expected behavior.

## Step 2: Plan Tests

From the diff, brief, or user instructions, identify what to test.

**Round 1 - Functional:** What are the core user flows? Write each test as: action -> expected result.
- Which pages/URLs changed?
- What should work after this change?

**Round 2 - Adversarial:** Re-read Round 1. What did you miss?
- Error paths, empty states, loading states
- Edge inputs (empty, huge, special chars, rapid clicks)
- Double-submit, Escape mid-flow, keyboard-only nav

**Round 3 - Coverage gaps** (skip for small changes): Re-read Rounds 1-2.
- Accessibility (keyboard nav, focus management)
- Mobile viewport breakpoints
- Console errors after interactions

**Merge** into a single numbered test list. Remove overlaps.

If unclear what to test, ask the user: "What flows should I test?"

## Step 3: Test

### Parallel Execution (for large changes)

Direct main-agent browser checking is the native baseline. This branch adds
isolated workers plus structured markers only when a larger suite needs
separable, mergeable evidence.

When the merged test list has 3+ groups and the host provides isolated browser
workers, fan out to parallel sub-agents:

1. Assign each test group to a separate isolated worker. The host owns model and worker selection.
2. Give each worker a distinct browser session through the host's browser adapter. If session isolation cannot be proven, run the groups sequentially.
3. Each sub-agent prompt must include:
   - The exact numbered test list to run (no exploration beyond assigned tests)
   - The assertion protocol below
   - A step budget (~25 for targeted checks, ~40 for a full page, ~75 for multiple pages)
4. The main agent does not share one browser session across parallel workers. It coordinates, merges results, and produces the final summary.
5. When a sub-agent hits its budget, accept partial results as-is. Include STEP_SKIP for uncovered tests.

For small changes (1-2 groups), run tests directly without sub-agents.

### Assertion Protocol

Every test step MUST produce a structured marker:

```
STEP_PASS|<step-id>|<evidence>
STEP_FAIL|<step-id>|<expected> -> <actual>
STEP_SKIP|<step-id>|<reason>
```

- `step-id`: short identifier like `homepage-cta`, `form-empty-submit`, `modal-escape`
- `evidence`: what you observed that proves the step passed (element text, URL, eval result)

### Verification (in order of rigor)

1. **Deterministic check** (strongest): `eval` returns structured data (element count, field value, console errors)
2. **Snapshot element match**: specific element with expected role/text exists in accessibility tree
3. **Before/after comparison**: snapshot before action, act, snapshot after, verify expected change
4. **Screenshot + visual judgment** (weakest): only for visual properties the accessibility tree cannot capture

### Failure Output

Every `STEP_FAIL` gets a screenshot and a bug report. See `skills/engineering/qa/lib/test-output-format.md` for the screenshot location and the `[BUG]` template (its `Action: AUTO-FIX | ASK` field feeds Step 4).

### Summary

After all tests, output a summary line:

```
Tests: N | Passed: N | Failed: N | Skipped: N | Pass rate: N%
```

## Step 4: Fix

Execute each bug report's `Action` field using the routing contract in
`skills/engineering/qa/lib/test-output-format.md`. Do not reclassify it from a
second rule here.

After an AUTO-FIX, re-run the affected flow. ASK items remain explicit pending
decisions and are never reported as fixed.

## Step 5: Surface a Learning Candidate

If a UI pattern or browser-specific pitfall was discovered, emit one `type:
pitfall` candidate using `lib/learning-format.md`. Do not write it to
`{learnings_dir}`; persistence belongs to the host/project. Otherwise state
explicitly "no learning warranted".
Common examples:
- "This component breaks on mobile viewport"
- "Form validation fires before user finishes typing"
- "Loading state missing on slow network"
