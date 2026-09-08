---
name: debug
description: Diagnose an unexplained error, crash, regression, or failing test; reproduce the mechanism and verify the fix on the failing path.
user-invocable: true
---
# Debug

Reproduce the failure and identify its mechanism before editing. Verify the fix with a check that demonstrated the failure, rerun after the final edit, and search for the same defect in sibling paths. If reproduction is unavailable, report the diagnosis as unconfirmed.

For UI, native, or generated-artifact bugs, verify the running/rendered output rather than compilation alone. Before asking a human to test, prove artifact identity using [the test-loop reference](lib/verify-the-test-loop.md).

Consult [known bug classes](lib/diagnosis.md) when relevant to the symptom. Use [project learning recall](lib/learning-recall.md) for unexplained or recurring failures, not as an extra ceremony for an already-proven cause. New reusable findings are candidates for the host's memory store, not automatic writes.
