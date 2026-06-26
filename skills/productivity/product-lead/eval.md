---
type: skill-eval
skill: product-lead
bucket: productivity
evaluated_skill_hash: e987b6938b7fd001062e1b8b595d279d3f39eee6
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — product-lead

**Verdict: WEAK.** A tight, predictable product-lens persona with strong pretrained anchors and clean lib delegation, but it carries three weak axes: the description's invoke/NOT routing is restated wholesale in the body Routing Boundary (description duplication), the Anti-patterns re-encode the Iron Laws (pruning), and the On-Invoke steps frame rather than gate (completion). Three weak with no fail is WEAK under the scorecard arithmetic.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L44 — `On Invoke` fixes the same 4-step lens (problem -> metric -> non-goals -> failure mode) every run, regardless of output. |
| Description / invocation | weak | L4 — front-loads "Product lens", one `/product-lead` trigger, NOT-clause delimits cleanly, BUT the entire invoke/NOT routing is restated in the body Routing Boundary (L20-22): description "user problem, metric, PMF, MVP scope... NOT for strategy-only / implementation / UI polish / ops cadence / generic planning" ~ L20-22 "user problem, target user, metric, PMF, MVP scope... Do not invoke for `ceo` / `eng-lead` / `design-lead` / `ops-lead` / plan". Body-identity restated, which the scorecard axis 2 calls out ("no duplication, no body-identity"). The body adds only the backticked sibling names; the routing facts are otherwise a second copy. |
| Completion criteria | weak | L49 — "Predict the failure mode" ends on a framing prompt with no done/not-done check; only L46 ("in 1 sentence") is genuinely checkable, the other three steps invite premature completion. |
| Information hierarchy | pass | L16 — shared persona structure and L61 BAD/GOOD calibration are pushed to `lib/` behind `@`-pointers, keeping the body legible. |
| Leading words | pass | L40 — "Job-to-be-done", "Leaky bucket" (L41), "Focus through subtraction" (L42) are compact pretrained concepts that anchor the lens in few tokens. |
| Pruning | weak | Two duplications, not one. (a) L54 — Anti-patterns restate Iron Laws: "Multi-metric proposals" (L54) ~ "One metric per decision" (L34); "Users want X with no data" (L53) ~ "No feature without a user problem" (L32). (b) L20-22 — the Routing Boundary section restates the L4 description's invoke/NOT routing verbatim in meaning; the same routing facts live in two spots, the exact single-source-of-truth violation the scorecard names. Three meanings each carried twice. |
| Granularity | pass | L16 — the persona-contract split (shared frame in lib, content in body) earns its load: boardroom and 4 sibling leads reach the same structure. |
| pandastack conformance | pass | L2 — `name: product-lead` equals folder; both `lib/` refs (L6-7, L16, L61) resolve to repo-root `lib/`; 58-line body under ~80; no >5K hot read so no dispatch owed. |

## Leading virtue
The skill does the one thing a persona lens must: it imposes the same product process (user problem -> single metric -> explicit non-goals -> failure mode) on any input, anchored in three high-recall pretrained models (JTBD, leaky bucket, subtraction). Frontmatter and `@`-pointers are clean — the 6-section persona contract and the BAD/GOOD calibration live in shared `lib/`, so the body stays short. That virtue is real, but it is offset by three weak axes: the routing facts live in two places (description + Routing Boundary), the Anti-patterns re-encode the Iron Laws, and three of the four On-Invoke steps are framing prompts with no done-state. Hence WEAK, not SOLID.

## Top fixes
1. L4 vs L20-22 — Kill the routing duplication. The description (L4) and the Routing Boundary (L20-22) carry the same invoke/NOT facts. Pick one source: either drop the prose Routing Boundary and let the description be the single dispatch contract, or strip the routing prose down to only what the description omits (the backticked sibling names `ceo`/`eng-lead`/`design-lead`/`ops-lead`) as a one-line "see also" rather than a re-statement. This is the cheapest path back to SOLID — it clears both the description-axis and one of the two pruning hits.
2. L51-57 — Collapse the Anti-patterns/Iron-Laws overlap. "Multi-metric" (L54), "no user problem" (L53), and "ship and iterate without a signal" (L56) each re-encode an Iron Law (L32-35). Keep the Iron Laws as the single source; cut anti-patterns to only the ones with no law (e.g. L57 "features because competitors have them").
3. L47-49 — Make the last three On-Invoke steps checkable like L46. e.g. step 2 -> "name the single metric and its target threshold"; step 4 -> "name the most likely failure mode and the signal that would confirm it" — so each step has a done state and can't be skimmed.

## Behavioral cases
- trigger `/product-lead: should we build feature X?` -> expected process: state the user problem in one sentence (L46), pick the one metric (L47), name what we're NOT solving (L48), predict the failure mode (L49).
- trigger `is this the right metric to optimize for PMF?` -> expected process: product lens fires on "metric"/"PMF" branch (L20), runs the On-Invoke 4-step.
- anti-trigger `should we kill or pivot this whole line of business?` -> should NOT fire; routes to `ceo` (L22, strategy-only kill/pivot).
- anti-trigger `what's the cleanest architecture for this feature?` -> should NOT fire; routes to `eng-lead` (L22, technical implementation).
- anti-trigger `the button states feel off, fix the interaction` -> should NOT fire; routes to `design-lead` (L22, interaction/visual design).
