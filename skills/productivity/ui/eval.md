---
type: skill-eval
skill: ui
bucket: productivity
evaluated_skill_hash: f51f99ace86c25b646a2254c1965fde119819720
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — ui

**Verdict: SOLID.** The inverted shape of `debug`: a lean 27-line spine (CJK gut-feel intake routing + three override reflexes) over a single 118-line `references/craft.md` that holds the lore. The skill's value is exactly what a model cannot derive — the reflex-font blocklist, CJK vs Latin line-heights, OKLCH chroma magnitudes, the CSS bans-with-rewrites, the strategic-omissions checklist — while the spine carries only the reflexes the model ships wrong by default (the AI-default aesthetic, trusting source over render, happy-path-only). Generic design advice (a11y basics, 60-30-10, "use whitespace") was filtered out at extraction. Loses points only where the single reference is dense.

| Axis | Verdict | Evidence |
|---|---|---|
| Description / invocation | pass | Front-loaded triggers (zh + en) with NOT-clauses to `qa` (browser test) and `debug` (broken render). |
| Predictability | pass | Intake routing for CJK taste complaints + three fixed overrides; same lens every run. |
| Information hierarchy | pass | All craft cold behind `references/craft.md`; the spine stays a running lens, read before writing CSS. |
| Lore density | pass | Every reference item is a concrete number / name / CSS pattern the model would not invent — not advice it already has. |
| Pruning | weak | `craft.md` at 118 dense lines is the upper bound for one reference file; defensible as pure lookup lore, but split by surface (type / css / product) if it grows past ~150. |

**Recommendations:** watch `craft.md` length; the split into per-surface references was collapsed to one file for simplicity, so re-split only if it earns it.
