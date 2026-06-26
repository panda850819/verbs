# Test Output Format

Screenshot-on-failure and bug-report mechanics for Step 3. Every `STEP_FAIL` gets both.

## Screenshot on Failure

Every `STEP_FAIL` should have an accompanying screenshot captured at the moment of failure. Store in `.context/ui-test-screenshots/<step-id>.png`.

```bash
mkdir -p .context/ui-test-screenshots
```

## Bug Report Format

For each `STEP_FAIL`, also produce:

```
[BUG] page/flow - description
  Steps to reproduce: ...
  Expected: ...
  Actual: ...
  Screenshot: .context/ui-test-screenshots/<step-id>.png
  Action: AUTO-FIX | ASK
```

`Action` routes the bug into Step 4: `AUTO-FIX` for mechanical bugs (CSS, missing null check, wrong URL), `ASK` for design or architecture decisions.
