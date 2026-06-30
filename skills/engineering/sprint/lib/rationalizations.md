# Sprint — Common Rationalizations

Anti-bypass table. Each shortcut is tied to the concrete failure it causes.

| Rationalization | Reality |
|---|---|
| "I already know this codebase, skip dojo" | The past-you who knew it was a different model context. Cold scans surface the half-built attempt you forgot about. |
| "Topic is clear, skip grill" | If it were clear, you'd be in execute mode, not opening `/sprint`. The 3-question cap costs 2 minutes; ambiguity costs a re-do. |
| "Small change, skip review" | Small changes are where regressions hide because nobody looks. P0 review still runs in 90 seconds on a small diff. |
| "One more iteration will fix it" (iter ≥ 3) | 3-strike rule is empirical: at iteration 4 the diagnosis itself is the bug. State=FAILED, manual intervention. |
| "It's partly UI, partly backend, do it all in one sprint" | Split into two sequential sprints — one for the `ui` surface, one for the backend. |
| "Sprint within a sprint for the sub-task" | Flatten. Either the sub-task is a Stage 3 step in the current sprint, or it's a separate sprint that fires after this one ends. |
| "Review found P1 but ship anyway" | Terminal state contract is load-bearing. P1 unaddressed = state ≠ SHIPPED. Mark PAUSED with the open finding logged, or fix and re-review. |
| "BUILD SUCCEEDED, so the user is testing my fix" | Success proves the compiler ran, not that the deployed artifact is the one you built. Deploy-proof before human test (`lib/verify-the-test-loop.md` R1). |
| "My instrumentation didn't show in their screenshot, weird — anyway" | That is the pipeline alarm, not a fluke. Stop, verify the loop (R1/R2). The session this rule exists for lost days exactly here. |
| "3 lifecycle variants failed, the 4th is my escalation" | Same-shape failure ×3 ⇒ the abstraction/loop is wrong (R4). A 4th variant of the same approach is strike 4, not escalation. Switch primitive or re-verify the loop. |
| "Re-asking the user to re-test is just one more round" | Each contaminated human round-trip is the expensive unit. If the loop needs repeated round-trips, harden the loop first (R3), then iterate. |
| "Let's sprint on stuff" (no single topic) | Sprint requires one concrete topic. No-topic ideation routes to `/office-hours`, not sprint. |
| "Substrate's fine, skip Stage 0 capability probe" | Probe each run — state changes between sessions. The probe block is the opening, not optional. |
| "Sprint didn't ship, so it failed (PAUSED = failure)" | PAUSED is a legitimate terminal outcome, not a break. No extract/backflow; write the checkpoint and stop cleanly. |
