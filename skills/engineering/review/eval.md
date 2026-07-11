---
type: skill-eval
skill: review
bucket: engineering
evaluated_skill_hash: 546fb61add742113be42bdb80af20ca62f8923c4
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — review

**Verdict: SOLID.** A fixed audit, scoped parallel lenses, cold-context review, and an internal opposite-seat transport make the review process unusually resistant to confirmation bias; the main construction costs are its long hot body and an implicit native-parity claim.

Grounding sample: L104 — "Verbs defines the three review lenses and their output contract"

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L102 — the skill fixes the parallel-review mechanism and gives every pass the same diff, so the process is stable even though findings vary. |
| Description / invocation | pass | L4 — the description front-loads review triggers and excludes UI QA, prepared-plan critique, and lightweight checks. |
| Completion criteria | pass | L229 — the mandatory completion box makes every stage, count, skipped gate, and open question observable before exit. |
| Information hierarchy | pass | L130 — conditional lenses live behind a pointer and load only when a deterministic scope signal fires. |
| Leading words | pass | L121 — “Grounding requirement” and `needs-trace` compress the security-review standard into memorable execution anchors. |
| Pruning | weak | L121 — the attacker-control rule is load-bearing but occupies one very dense paragraph; the overall hot body remains far beyond the usual size budget. |
| Native parity | weak | L146 — cold review clearly adds decorrelation, but the skill never names the nearest native single-pass review feature and states the earned delta only implicitly. |
| Granularity | pass | L172 — cross-model review stays an internal parallel transport, preserving `review` as the one code-diff verb instead of leaking into `advisor`. |
| Verbs conformance | weak | L256 — references resolve and heavy reads use isolated agents, but the 227-line body substantially exceeds the normal guideline without an explicit size justification. |

## Why it's good

The skill attacks three distinct blind spots: in-context lens coverage, zero-intent cold review, and an opposite-seat model reached through a bounded internal transport. Its completion box prevents unavailable or skipped review paths from being silently reported as clean, while learning and skill-edit outputs remain candidates owned by the host.

## Top fixes

1. L4 — state the native-parity delta directly: this workflow adds scoped parallel lenses, zero-context review, and opposite-seat adversarial review beyond a host's ordinary single-pass diff check.
2. L121 — extract the full exploit-path decision tree behind a focused pointer while keeping the attacker-control and `needs-trace` gate inline.
3. L172 — keep “internal transport, not advisor” as the single boundary statement and trim later merge prose that restates the same ownership split.

## Behavioral cases

- trigger `review my branch before I open a PR` → expected process: audit branch state, bind the full diff, inject relevant learnings, check brief coverage, run scoped parallel passes, run cold review and the internal opposite-seat transport, then emit candidates and the completion box.
- trigger `review this auth diff` from a Codex seat → expected process: code-review ownership stays here; Step 6.5 uses the verified Claude transport from the sibling reference and treats its findings as outside voice requiring approval.
- anti-trigger `QA this page in the browser` → should NOT fire; route to `qa`.
- anti-trigger `red-team this prepared plan` → should NOT fire; route to `advisor --panel`.
