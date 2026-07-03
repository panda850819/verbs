---
type: skill-eval
skill: using-pandastack
bucket: meta
evaluated_skill_hash: b87825dbf2e84e266d8093ca00c84897f4daa229
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — using-pandastack

**Verdict: SOLID.** The 1%-threshold forcing function (L11) plus the recorded-skip done-state (L32) give this router a genuine check-before-act invariant; the bleed is a hot session-opener block, an overlay sentence duplicated into its own lib, and a 101-line body over the soft cap.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L11 — "even a 1% chance a pandastack skill might apply … you MUST invoke the skill via the `Skill` tool before responding" fixes one invariant (check-before-act) that runs identically every turn regardless of task shape. The root virtue, stated concretely with a numeric threshold rather than 'be careful'. |
| Description / invocation | pass | L3 — front-loads the positional leading phrase "Use at the start of any session"; model-invoked (`user-invocable: false`) is correct for a SessionStart contract; single trigger, and the tail ("including clarifying questions") widens *when* it fires rather than restating body identity. |
| Completion criteria | pass | L32 — "invoked this turn — or you must record an explicit skip-reason this turn … an unrecorded skip is a skipped check" converts the headline check into a binary done-state and explicitly kills the "I checked and decided no" premature-completion bait. The session ritual stays checkable too (L58 "Healthy session = zero lines printed"). |
| Information hierarchy | weak | L48 — the 18-line session-opener ritual + fenced code block (L46-63) sits fully hot, while its three neighbours (loop-guard L67, harness-evolution L71, overlay L101) were correctly pushed behind lib/ pointers. The ritual is the heaviest, most reference-shaped block in the file; a one-line 'run the 5-step opener → `lib/session-opener.md`' pointer would match how the neighbours were already extracted. |
| Leading words | pass | L18 — "forcing function" (and "cognitive contract" in the description) are compact pretrained anchors naming the whole behaviour region in few tokens; the red-flags table (L77-90) collapses a dozen rationalizations into one reusable STOP-on-this-thought pattern instead of restating the rule per row. |
| Pruning | weak | L101 — both sentences of the overlay-extension paragraph are verbatim copies of `lib/overlay-extension.md` L3 + L16 ("A personal / org overlay may be appended…"; "If no overlay loads, this public contract still works on its own — the lifecycle map degrades to abstract guidance"). A pointer block should carry the trigger, not duplicate the ref's prose; the copy means a future edit to one will silently diverge. Body is otherwise clean (v2.1 rename noted once inline at L40, no stale skill count). |
| Native parity | pass | L18 — names the native/default competitor ("the model defaults to 'I'll just answer directly'") and the delta ("this file is the forcing function") in the body. |
| Granularity | pass | L67 — the three splits each earn their load: loop-guard, harness-evolution, and overlay-extension are independently-triggered subsystems (loop detection vs skill-authoring vs install-time wiring) gated behind distinct conditions, so each pointer fires only when its condition is live rather than taxing every read. |
| pandastack conformance | weak | L2 — frontmatter `name: using-pandastack` matches the folder and is valid; all three body lib pointers (L67/L71/L101) resolve. Weak only because the body runs 101 lines, over the ~80 soft cap, with the hot session-opener ritual (L46-63) as the main overflow. |

## Why it's good
The 1% contract (L11) plus the recorded-skip done-state (L32) make this a real invariant router: the same check-before-act process runs every turn, and the skip is auditable rather than a soft 'I looked'. Reference subsystems (loop-guard, harness-evolution, overlay) ride resolving lib/ pointers, and the red-flags table (L77-90) is the right shape — pattern-collapse over per-rule restatement.

## Top fixes
1. L46-63 — extract the 5-step session-opener ritual (incl. the fenced block and failure-mode list) to `lib/session-opener.md` behind a one-line trigger pointer, matching loop-guard / harness-evolution / overlay; this single change pulls hierarchy to pass and the body under the ~80-line cap.
2. L101 — replace the two verbatim sentences with a bare trigger pointer to `lib/overlay-extension.md` (the lib already carries both verbatim), removing the silent-divergence duplication and clearing the pruning weak.

## Behavioral cases
- trigger `start of a fresh session, about to edit a prod config file` → expected process: run the 5-step opener silent-unless-anomaly (L46), then before the edit invoke `pandastack:careful` per L36, recording an explicit skip-reason this turn if declining (L32).
- anti-trigger `read this file so I understand the layout, no edits planned` → should NOT fire (routes to the "When NOT to invoke" orientation-only carve-out at L94; no skill invocation and no skip-reason required).
