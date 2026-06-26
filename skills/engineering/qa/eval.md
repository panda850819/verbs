---
type: skill-eval
skill: qa
bucket: engineering
evaluated_skill_hash: ce845dfa5c91c52bff57bcd52239b28bbebe993d
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — qa

**Verdict: SOLID.** A genuinely repeatable QA process: the three-round test-planning loop plus the rigor-ranked assertion/verification protocol force the same disciplined path every run, which is exactly what predictability buys.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L25 — the forced "Re-read Round 1. What did you miss?" adversarial pass makes the planning process reproducible, not just the output |
| Description / invocation | weak | L3 — front-loads "Browser-based QA" well, but carries no NOT-clause, so it collides with `verify` / `review` / `testing` on overlapping triggers |
| Completion criteria | weak | L113 — "If a UI pattern... was discovered, write a learning" is conditional with no checkable done-state; premature-completion bait |
| Information hierarchy | weak | L14 — `{learnings_dir}` / `type: pitfall` is a dangling context pointer; `lib/learning-format.md` exists and defines the format but is never linked |
| Leading words | pass | L25 — "Adversarial" anchors a whole pretrained region of QA behaviour in one word; "fan out", "rigor" do the same elsewhere |
| Pruning | weak | L45 — one long line of process narration on per-group model selection ("a trivial smoke check and a group combining... are not the same load"; "don't pin a fixed mapping") restates a no-op the agent already does by default |
| Granularity | pass | L40 — five sequential steps each end on a real handoff (plan → test → fix → learn); the splits track genuine sequence boundaries, not gratuitous cuts |
| pandastack conformance | weak | L117 — body is 117 lines, past the ~<80-line writing-great-skills budget with no length-earning reason. Frontmatter itself is valid: SKILL-FRONTMATTER.md requires only `name`+`description` (qa has both, `name` matches folder); `version`/`type` are optional and `reads:` is advisory audit metadata nothing enforces, so their absence is not a conformance fault. Length is the only real signal; hot/cold dispatch does not apply (the skill reads no large reference) |

## Why it's good
The skill's spine is its verification ladder (L69-74): four checks ranked by rigor, with screenshot-on-failure ranked weakest, which structurally pushes the agent toward deterministic `eval` evidence over screenshots. The structured markers (`STEP_PASS|STEP_FAIL|STEP_SKIP`, L60-64) and the bug-report format (L86-94) make every test outcome machine-checkable and greppable, so completion of Step 3 is unambiguous. The three-round plan (functional → adversarial → coverage-gaps) is the load-bearing predictability lever.

## Top fixes
1. L14 — resolve the `{learnings_dir}` pointer: either link `lib/learning-format.md` here and at Step 5, or inline the one rule the agent needs. As written it dead-ends.
2. L3 — add a NOT-clause to the description (e.g. "NOT for non-UI verification — use `verify`; NOT for code-diff review — use `review`") to stop trigger collision.
3. L113 — give Step 5 a checkable criterion (learning written to `{learnings_dir}` with `type: pitfall`, or explicit "no learning warranted"). Separately, the 117-line body is over the ~<80 budget; trim process narration (L45) and push the screenshot/bug-report mechanics behind a pointer to cut toward budget. (Frontmatter is already spec-valid; no `version`/`reads:` fix is needed for conformance — those are optional/advisory.)

## Behavioral cases
- trigger `QA the new checkout page` → expected process: Step 1 load config + UI pitfalls, Step 2 three-round plan, Step 3 browser flows emitting STEP_PASS/FAIL markers with deterministic-eval evidence, Step 4 auto-fix mechanical bugs, Step 5 learning.
- anti-trigger `verify my refactor didn't break the API` → should NOT fire (no UI surface; routes to `verify`); `review my PR before I push` → routes to `review`, not qa.
