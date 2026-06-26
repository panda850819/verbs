# review A/B pilot — results (run 1)

Model: sonnet (both arms). n=2 fixtures. 2026-06-02.
Judge rubric: neutral — real bugs caught vs ground truth + bugs invented on clean code.

## Scores

| Fixture | Ground truth | WITHOUT | WITH | WITHOUT | WITH |
|---|---|---|---|---|---|
| R1 buggy (SQLi + IndexError + off-by-one) | catch ≥2 of 3 | caught all 3 (+extras) | caught all 3 | PASS | PASS |
| R2 clean (is_even / clamp) | LGTM, invent nothing | LGTM, 0 invented | LGTM, 0 invented | PASS | PASS |

**Pass rate: WITHOUT 100% (2/2) · WITH 100% (2/2). Delta = 0.**

## Reading — and the methodology bug it exposes

Second objective skill, second delta-0. But the cause here is NOT "review is
useless" — it's **ceiling effect**: these fixtures sit inside sonnet's baseline
ability. The model catches a string-concat SQL injection and an off-by-one
`range(1, len)` without any skill, and doesn't hallucinate bugs on two pure math
functions without any skill. Both arms max out → no room for the skill to show
lift OR harm.

**This is the load-bearing finding for scaling to all 34:**

> A/B discrimination lives entirely in fixture difficulty. A fixture the baseline
> already passes (or already fails identically) yields delta 0 regardless of
> whether the skill helps. Easy fixtures manufacture false "skill is noise"
> verdicts.

gatekeeper's F2 (benign-but-suspicious) was the only fixture across both pilots
that *separated* anything — and even it separated by exposing a shared over-fire,
not a with/without gap.

## Implication for the 34-skill run

Do NOT mass-run 1600 agents on convenience fixtures — that buys a pile of
delta-0 false negatives. Fixtures must be authored at the **baseline edge**:
bugs subtle enough that no-skill misses them, and ambiguous cases where no-skill
over-fires. That's a per-skill design investment, not a volume problem.
Fixture design is the bottleneck, not eval throughput.
