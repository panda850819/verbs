---
type: skill-eval
skill: handover
bucket: engineering
evaluated_skill_hash: 0e2490858a426a445ac476f6c3b80fd0e3f85e98
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — handover

**Verdict: SOLID.** Exemplary progressive disclosure paired with a fail-closed Gate: the SKILL.md stays a pure orchestration layer while every brittle `codex exec` mechanic lives behind one shared pointer, and no run can skip a precondition.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L60 — the 5-check "Gate (both modes)", each ending in a hard `stop`, plus the numbered sync Flow (L72) fix the delegate-poll-classify process every run |
| Description / invocation | weak | L4 — the full `/ship`-vs-`/handover` distinction sits in the HOT description and is then restated almost verbatim in the body at L40; HOT fields should carry triggers + the reach clause, not body-identity prose that pays context load every turn |
| Completion criteria | weak | L94 — "Best-effort: skip silently if the binary is absent" is an uncheckable done-condition for the state-emission step; a silent skip is indistinguishable from a forgotten step |
| Information hierarchy | pass | L70 — XML payload, result schema, sandbox-escape gate, and classification table are all pushed to `references/codex-invocation.md` and pulled only on demand; SKILL.md keeps only the orchestration sequence |
| Leading words | pass | L62 — "this skill is a no-op (delegation would recurse)" anchors the platform gate in one pretrained concept; "session occupancy" (L58) anchors the sync/async axis |
| Pruning | weak | L42 — the economics paragraph restates the L40 ship-vs-delegate distinction at length, and the negative-scope clause is stated three times (L7 description, L32 routing list, L49 skip line). Real duplication: a tidy-up the single-source-of-truth rule should collapse |
| Granularity | pass | L70 — the split to `references/codex-invocation.md` earns its load: it is independently reached by `/sprint --delegate codex` (per that file's own header), not a single-use cut |
| pandastack conformance | pass | L1-23 — `name` matches folder, `forbids` lists the three push variants, `classification: exec`, every `reads:` path resolves; 111 total / ~59 non-blank body lines sits at the ~80 budget, far under siblings (ship 183, review 286, sprint 346) |

## Why it's good
The skill nails the hardest part of a delegation verb: it keeps Claude as the git/review/ship owner and shoves the brittle `codex exec` mechanics behind a context pointer (L70), so the SKILL.md reads as pure orchestration. The Gate (L60-66) is genuinely exhaustive and each check fails closed with a named stop reason. The mode table (L53-56) plus the "session occupancy, not cost" framing (L58) kills the most likely confusion — that async is cheaper — in one line.

## Top fixes
1. L4 / L40 — collapse the duplicated `/ship`-vs-`/handover` distinction: keep the trigger + reach clause in the HOT description, state the distinction once in the body, cut the verbatim restatement (single source of truth, and it is the costliest duplication because the description is HOT).
2. L94 — give the state-emission step a checkable criterion (e.g. "event appended OR binary confirmed absent"), not a silent best-effort skip that hides partial failure.
3. L32 / L49 — the Routing Boundary "Do not use it for" list and the "Skip when" line both restate the description's L7 NOT-clause; keep the Routing Boundary table, drop the overlapping prose.

## Behavioral cases
- trigger `/handover pro-31` with a plan holding ≥3 rote build units → expected process: run the L60 gate, derive non-passing U-IDs from acceptance checks (L74), build the XML payload, spawn `codex exec` in background, poll in foreground, classify the single result per the reference table, then Claude commits a `completed` batch and keeps review/ship.
- anti-trigger `ship this finished work / open the PR` → should NOT fire; routes to `ship` (L37 excludes closing finished work, PR, publishing). Handover only delegates already-planned, unfinished mechanical units.
