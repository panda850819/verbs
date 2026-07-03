---
name: qa
description: |
  Browser-based QA. Use when UI has changed, or when asked to
  "test this", "QA", or "check the page". Requires browser automation
  tool. NOT for non-UI verification (use `verify`); NOT for code-diff
  review (use `review`).
user-invocable: false
---
# QA

## Step 1: Load Context

1. Read pandastack config from `CLAUDE.md` or `AGENTS.md` (whichever the project uses). Resolve `{learnings_dir}` from it (default `docs/learnings`).
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

When the merged test list has 3+ groups, fan out to parallel sub-agents:

1. Assign each test group to a separate Agent (sub-agent), passing `model:` to fit the group's load.
2. Each sub-agent gets its own browser session via `--session <name>` for isolation.
3. Each sub-agent prompt must include:
   - The exact numbered test list to run (no exploration beyond assigned tests)
   - The assertion protocol below
   - A step budget (~25 for targeted checks, ~40 for a full page, ~75 for multiple pages)
4. The main agent does NOT run browser commands itself. It coordinates, merges results, and produces the final summary.
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

AUTO-FIX bugs that are mechanical (CSS, missing null check, wrong URL).
ASK about bugs that involve design or architecture decisions.

After fixing, re-run the affected flow to verify the fix.

## Step 5: Write Learnings

If a UI pattern or browser-specific pitfall was discovered, write a learning to `{learnings_dir}` with `type: pitfall` (format in `lib/learning-format.md`). Otherwise state explicitly "no learning warranted". Either way, Step 5 is done only once one of the two is recorded.
Common examples:
- "This component breaks on mobile viewport"
- "Form validation fires before user finishes typing"
- "Loading state missing on slow network"
