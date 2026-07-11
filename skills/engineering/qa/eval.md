---
type: skill-eval
skill: qa
bucket: engineering
evaluated_skill_hash: 99c5e7b27084d74012e15aef31edce99d1846a76
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — qa

**Verdict: STRONG.** A measurable browser-QA pipeline now has direct main-agent browser checking as the explicit native baseline, exact Action field routing to a single SSOT, and an optional isolated-worker branch when suites exceed three test groups.

Grounding sample: L46 — "Direct main-agent browser checking is the native baseline."

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L62 — every executed test step must end in one of three structured markers, making pass, fail, and skip exhaustive and mergeable. |
| Description / invocation | weak | L5 — "test this", "QA", and "check the page" are three phrasings for the same browser-QA branch; one representative trigger plus the two anti-routes would carry the same dispatch signal with less hot text. |
| Completion criteria | pass | L101 — every auto-fix requires an affected-flow rerun, while ask-required items remain explicitly pending and cannot be reported as fixed. |
| Information hierarchy | pass | L82 — screenshot paths and bug-report shape live in one current skill-local reference, while the always-needed failure requirement remains visible at the point of use. |
| Leading words | pass | L75 — "Deterministic check" leads an explicit rigor ladder that prefers structured evidence over visual judgment. |
| Pruning | pass | L98 — Step 4 now executes the report's `Action` field through the referenced contract and explicitly refuses a second classification rule, making the SSOT explicit. |
| Native parity | pass | L46 — direct main-agent browser checking is named as the explicit native baseline; isolated workers plus structured markers are the optional delta for larger suites. |
| Granularity | pass | L58 — small changes run directly and large grouped suites may fan out to isolated workers, while both branches share one plan, assertion protocol, summary, fix, and candidate sequence. |
| Verbs conformance | pass | L104 — both repo-root references resolve, the current candidate format admits `skill: qa`, the capability extension is allowed, and persistence remains explicitly host-owned. |

## Why it's good

The skill turns browser testing into evidence through a three-round plan, structured step markers, a rigor ladder from deterministic checks to visual judgment, screenshots on failure, and an exact summary. The native baseline (direct browser checking) is explicit, so the optional isolation and parallelism branch is visible. Step 4 obeys a single `Action: AUTO-FIX | ASK` routing contract from the bug report, not a second rule. Step 5 emits a valid `skill: qa` candidate without writing the project store.

## Top fixes

1. L46 — native baseline clarified: direct main-agent browser checking is the baseline; isolated workers and structured markers are the optional branch for larger suites (3+ test groups).
2. L98 — Action routing SSOT: Step 4 executes each bug report's single `Action` field using the exact routing contract in test-output-format.md, with no competing classification rule.

## Behavioral cases

- trigger `the checkout UI changed; QA it` → load project context, build the three-round test list, execute through host browser automation (direct or isolated), emit a marker for every step, summarize counts, follow each report's Action field, and rerun auto-fixed flows.
- trigger `a failed check has Action: ASK` → preserve it as an explicit pending decision and never report it as fixed.
- trigger `this browser bug revealed a reusable mobile pitfall` → emit a `skill: qa`, `type: pitfall` candidate and leave persistence to the host or project.
- anti-trigger `run the unit tests for this parser` → should NOT fire; use the project's normal non-UI test or verification path.
- anti-trigger `review this code diff` → should NOT fire; route to `review`.
