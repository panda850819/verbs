---
type: skill-eval
skill: review
bucket: engineering
evaluated_skill_hash: f825d2559e2f4365f65921b73bc3d8f76cd83024
evaluated_at: 2026-07-12
rubric: writing-great-skills@1.1.0
---

# Eval — review

**Verdict: STRONG.** The skill keeps review independent and evidence-bound while replacing fixed fan-out with a deterministic risk lane and an earned cold-context branch.

Grounding sample: L48 — "Every lane gets one grounded correctness pass."

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L27 — five ordered phases bind scope, risk, evidence, escalation, and conclusion. |
| Description / invocation | pass | L4 — the description names review triggers, the native delta, and three exclusions. |
| Completion criteria | pass | L94 — conclusion requires a self-refute plus one exhaustive terminal outcome. |
| Information hierarchy | pass | L77 — cold review and model anchors load only for high risk, large diffs, or disputed conclusions. |
| Leading words | pass | L39 — `risk lane` compresses the adaptive decision and controls downstream work. |
| Pruning | weak | L102 — the output template is useful but repeats fields already specified in the finding contract. |
| Native parity | pass | L23 — the opener explicitly names native single-pass review and the four deltas that earn this skill. |
| Granularity | pass | L72 — the skill stays read-only and leaves mutation, browser QA, and artifact trust to neighboring verbs. |
| Verbs conformance | pass | L77 — the >5K-token branch uses a cold reviewer; references resolve and the longer body is earned by the risk and evidence contracts. |

## Why it's good

The fixed three-pass and always-on cross-model cost is gone. Low-risk diffs get one grounded pass; medium and high lanes add only evidence-triggered lenses, and every reported defect must survive an explicit disproof attempt.

## Top fixes

1. L102 — if the output remains stable across releases, move the template to a cold reference and keep only required fields inline.

## Behavioral cases

- trigger `review this auth diff before PR` → bind the merge-base and intent, choose high risk, trace attacker-controlled paths, run an independent cold review, and report only grounded findings.
- trigger `review this one-line local rename` → choose low risk and perform one pass without fixed fan-out.
- anti-trigger `QA this page in Chrome` → should NOT fire; route to `qa`.
- anti-trigger `is this MCP safe to install` → should NOT fire; route to `gatekeeper`.
