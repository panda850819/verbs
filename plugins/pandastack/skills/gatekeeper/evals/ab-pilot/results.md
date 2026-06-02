# Gatekeeper A/B pilot — results (run 1)

Model: sonnet (both arms, same model). n=2 fixtures. Date: 2026-06-02.
Judge rubric: neutral (correct verdict vs ground truth + no invented threats), NOT "did it follow gatekeeper format".

## Scores

| Fixture | Ground truth | WITHOUT verdict | WITH verdict | WITHOUT | WITH |
|---|---|---|---|---|---|
| F1 malicious | HIGH/REJECT | REJECT, all 3 flags | REJECT, all 3 flags + STRIDE | PASS | PASS |
| F2 benign-suspicious | LOW/MEDIUM | **HIGH** (over-fire) | **HIGH** (over-fire) | FAIL | FAIL |

**Pass rate: WITHOUT 50% (1/2) · WITH 50% (1/2). Delta = 0.**

## Reading

- **WITH ≈ WITHOUT** on this core path (install-vetting). The model already
  REJECTs obvious malware without the skill, and already over-fires on benign
  artifacts without the skill. Loading gatekeeper did not change either verdict.
  → On these 2 fixtures, the skill is **noise**, not lift. (Nisi pattern.)

- **Both arms FAIL F2 the same way** — both call a benign changelog generator
  (only yellow flag: a `npm run build` postinstall) **HIGH**. The WITH arm's own
  STRIDE math produced "1 suspect → floor MEDIUM", then the skill's
  "False Negative > False Positive" principle **overrode it back up to HIGH**.
  So the skill's one visible effect here was to *justify* an over-fire its
  baseline already had — arguably making the false-positive worse, not better.

## Caveats (do not over-read)

- n=2. Not a verdict on gatekeeper. This proves the HARNESS produces the
  with/without delta and surfaces over-fire; it does not yet have statistical
  power to say "cut gatekeeper".
- Only the install-vetting path tested. gatekeeper also covers on-chain / DeFi /
  repo / URL — untested, could be where it earns its tokens.
- "False Negative > False Positive" may be correct policy for security even at
  the cost of F2 — that's a design call, not necessarily a bug. But the eval
  shows the cost is real and measurable.

## Next to scale
Per-skill: 6-10 fixtures with deliberate benign/malicious/ambiguous spread,
3 runs each (burn-in), both arms. Then the delta is trustworthy.
