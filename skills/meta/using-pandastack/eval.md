---
type: skill-eval
skill: using-pandastack
bucket: meta
evaluated_skill_hash: 4537a3566b0789f62611575dd5383ec12cf5f169
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — using-pandastack

**Verdict: SOLID.** The 1%-threshold forcing function (L11) plus the now-recorded skip-reason done-state (L32) give this router a genuine invariant process; the main point still bleeding is the hot session-opener block that should ride a pointer.

_2026-06-29 re-stamp: SKILL.md L18 dropped the stale "persona lenses" phrase (persona layer removed, PR #100/#101). Content-preserving edit — verdict and axis citations unchanged; hash refreshed._

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L11 — "even a 1% chance a pandastack skill might apply … you MUST invoke the skill via the `Skill` tool before responding" fixes one invariant (check-before-act) that runs identically every turn regardless of task shape. The root virtue, and it is concrete. |
| Description / invocation | pass | L3 — front-loads the positional leading phrase "Use at the start of any session"; model-invoked (no `user-invocable`) is correct for a SessionStart contract; single trigger, no body-identity restated. |
| Completion criteria | pass | L32 — repaired: "invoked this turn — or you must record an explicit skip-reason this turn … an unrecorded skip is a skipped check" converts the headline check into a binary done-state and explicitly closes the prior "I checked, decided no" premature-completion bait. The session ritual stays checkable too (L59 "Healthy session = zero lines printed"). |
| Information hierarchy | weak | L47 — loop-guard (L68), harness-evolution (L72), overlay (L102) are now correctly deferred to lib/, but the 18-line session-opener ritual + fenced code block (L47-64) sits fully hot. It is run-procedure for a sub-mode, not the router's core check; a one-line "run the 5-step opener → `lib/session-opener.md`" pointer would match how the three neighbours were already extracted. |
| Leading words | pass | L18 — "forcing function" (L18) and "cognitive contract" (description) are compact pretrained anchors that name the whole behaviour region in few tokens; the red-flags table (L74-91) collapses a dozen rationalizations into one reusable STOP-on-this-thought pattern instead of restating the rule per row. |
| Pruning | pass | L40 — single-source discipline holds: the v2.1 rename is noted once inline ("replaces v2.1 `/work-ship`") rather than carried as a parallel row, the prior version's stale hardcoded skill count is gone, the maintainer-facing design-rationale no-ops are removed, and each lib file is the sole home of its subsystem. No sediment in the body. |
| Granularity | pass | L68 — the three splits each earn their load: loop-guard (424B), harness-evolution, and overlay-extension are independently-triggered subsystems (loop detection vs skill-authoring vs install-time wiring) gated behind distinct conditions, so each pointer fires only when its condition is live rather than taxing every read. |
| pandastack conformance | weak | L1 — frontmatter `name: using-pandastack` matches the folder and is valid; body-referenced lib pointers (L68/L72/L102) resolve, and the transitive lib files now mark their repo-root refs explicitly. Weak only because the body is 102 lines, over the ~80 soft cap, with the hot ritual (L47-64) as the main overflow. |

## Why it's good
The repair landed its two highest-value targets: the completion-criteria fix at L32 turns a soft "I checked" into an auditable recorded-skip done-state, and three reference subsystems moved behind resolving lib/ pointers, dropping the body from 131 to 102 lines and clearing the prior pruning/granularity weaks. The 1% contract (L11) remains a real, concrete forcing function, and the red-flags table (L74-91) is the right shape — pattern-collapse over restatement.

## Top fixes
1. L47-64 — extract the 5-step session-opener ritual (incl. the fenced code block and failure-mode list) to `lib/session-opener.md` behind a one-line trigger pointer, matching how loop-guard / harness-evolution / overlay were already handled; this single change pulls hierarchy to pass and the body under ~80 lines.
2. L100-102 — fold the one-sentence overlay degradation note into `skills/meta/using-pandastack/lib/overlay-extension.md` so the body carries only the trigger, not a partial restatement of the ref.

## Behavioral cases
- trigger `start of a fresh session, about to edit a prod config file` -> expected process: run the 5-step opener silent unless anomaly (L47), then before the edit invoke `pandastack:careful` per L36, recording an explicit skip-reason this turn if declining (L32).
- anti-trigger `read this file so I understand the layout, no edits planned` -> should NOT fire (routes to the "When NOT to invoke" orientation-only carve-out at L95; no skill invocation and no skip-reason required).
