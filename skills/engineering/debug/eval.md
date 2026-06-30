---
type: skill-eval
skill: debug
bucket: engineering
evaluated_skill_hash: 8ed3ef8cd40a62eb14aa3839e3c186dcc686307b
evaluated_at: 2026-06-30
rubric: writing-great-skills@1.0.0
---

# Eval — debug

**Verdict: SOLID.** Override-of-reflexes spine with all method, lore, and now recall pushed cold — predictable and lean; the one soft spot is judgment-leaning completion gates.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L17 — `## Override` holds exactly three invariant gates (name root cause / ran-and-looked / grep siblings); per-bug method is pushed cold, so the run-shape is identical every time. |
| Description / invocation | pass | L4 — front-loads the leading phrase "Systematic root-cause debugging," then enumerates branches (errors/crashes/regressions/used-to-work/flaky) with bilingual triggers and NOT-routing. |
| Completion criteria | weak | L25 — "grep the signature for siblings" is checkable in spirit but "the signature" and its exhaustiveness rest on judgment; same softness in the root-cause "specific enough" bar. The ran-and-looked gate (L22) is the one fully checkable criterion. |
| Information hierarchy | pass | L35 — the recall procedure is not inlined; it is a store-agnostic context-pointer to `../../../lib/learning-recall.md` loaded only when stuck, alongside the diagnosis.md lore pointer. Spine stays at live gates. |
| Leading words | pass | L15 — "lore you cannot derive" anchors the consult-don't-invent region in three words; "the failure mode" (L21) and "ratchet" (L35) also pull weight. |
| Pruning | pass | L14 — "You already know how to debug. This skill is not the method." explicitly refuses to restate pretrained procedure (anti-duplication / anti-no-op); body is 35 lines with all method offloaded. |
| Granularity | pass | L9 — by-invocation splits are explicit (NOT for `review` diff / `ui` taste); lore split by size into diagnosis.md and recall shared by-reference via lib, neither minted as its own skill. Right-sized. |
| pandastack conformance | pass | L30 — hot/cold dispatch honored: the >5K-token lore lives cold in `skills/engineering/debug/lib/diagnosis.md`; frontmatter valid, 35 lines (<80), and the L35 recall lib ref resolves to repo-root `lib/`. |

## Why it's good
Every spine line is a reflex the model gets wrong *despite* understanding debugging (edit-before-root-cause, claim-fixed-before-running, ignore-siblings), and the opening "this is not the method" contract is what keeps it from decaying into a restated checklist. The new store-agnostic recall is a clean info-hierarchy + granularity move: it resurfaces prior learnings via a shared lib pointer rather than hardcoding a brain path or duplicating per-skill, and it retains the recurrence/last_seen bump only here, where bug classes genuinely recur — the one place the ratchet that `learning-recall.md` argues against elsewhere actually earns its keep.

## Top fixes
1. L25 — tighten the sibling-sweep into a checkable criterion (e.g. "name the signature you grepped and the count of hits"), which would lift Completion criteria from weak to pass.
2. L35 — the bare `lib/learning-format.md` does not resolve from the skill dir while the same-line `../../../lib/learning-recall.md` does; normalize both to the `../../../lib/` form for one consistent, resolvable pointer.

## Behavioral cases
- trigger `以前是好的，現在這個 build 跑不通` → expected process: name the root cause at `file:function:line` with evidence before editing; run-and-look (not compile-only) before claiming fixed; grep the signature for siblings; consult diagnosis.md and recall matching prior learnings when the cause is not obvious.
- anti-trigger `review my diff before I open the PR` → should NOT fire (routes to `review`).
- anti-trigger `this button spacing looks off` → should NOT fire (routes to `ui`).
