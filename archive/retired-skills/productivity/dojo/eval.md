---
type: skill-eval
skill: dojo
bucket: productivity
evaluated_skill_hash: 06ca525615c59896270badb2df20a155ed8f3b66
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — dojo

**Verdict: SOLID.** Leading virtue: a fixed 0a→0e Stage-0 spine that runs the same prep process every invocation, with the verbose template and origin sediment already pushed out to lib/.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L42 — `## Stages` opens a fixed 0a→0e sequence (probe → past-case → lib-load → gotcha → output prep) that runs identically every run; only the output varies by topic, the process does not. |
| Description / invocation | weak | L6 — front-loads "Pre-action prep" well, but the one description line stacks `/dojo`, `/prep`, two NL trigger phrases, "any non-trivial work session", AND the `/sprint`+`/office-hours` auto-invoke reach clause; useful triggers, but too much hot context for one line. |
| Completion criteria | pass | L59 — "Take top 5 hits across both. De-dup. Read the matched file's first 200 chars" is bounded and checkable (done vs not-done), forcing the past-case legwork rather than inviting "we know this topic". |
| Information hierarchy | pass | L46 — standalone `@../../../lib/capability-probe.md` pointer pushes the probe behind a context pointer; the prep-brief template is likewise externalized (L89), so steps stay inline and reference is loaded only on demand. |
| Leading words | pass | L26 — the dojo/ring metaphor ("Before stepping into the ring … Then you fight") + "Stage 0" anchor prep-before-action in one pretrained concept the agent runs the skill with. |
| Pruning | weak | L34 — the NL trigger phrases "before I start" / "let me prep first" are restated verbatim here after already living in the description (L6); the description should own the triggers and "When to invoke" should keep only the >30-min scope threshold + the unique "what did I do last time on X". |
| Granularity | pass | L3 — `aliases: [prep]` earns the Layer-1 typing reach by invocation, and the 0a→0e split is by-sequence to stop the agent rushing past-case lookup (premature completion); neither cut is gratuitous. |
| pandastack conformance | weak | L89 — frontmatter is valid (`name: dojo` matches folder, `type: skill` is the canonical key after the #106 `mode→type` fix, description present) and all three refs resolve, but L89's co-located template pointer is bare repo-root `@skills/...` while the pack convention backtick-wraps co-located lib pointers (ship/careful/review/sprint); body is also ~84 lines, a touch over the ~80 discipline though the prep pipeline mostly earns it. |

## Why it's good
The five-stage spine (L42-93) is the load-bearing strength: each stage names a concrete action and most end on a checkable result (top-5 + de-dup + first-200-char read, 1-line-per-lib print, 1-3 gotchas), so the agent takes the same process every time. The dojo leading word (L26) and the standalone `@`-imports (L46, L105) keep the contract legible, and the anti-fabrication guard (L85) plus partial-prep escape-hatch (L107) close the two ways a prep flow most often fails.

## Top fixes
1. L6 / L34 — collapse the trigger duplication: keep the model-facing triggers + the `/sprint`+`/office-hours` reach clause in the description, and let "When to invoke" carry only the unique scope threshold (>30 min) and "what did I do last time on X", not a re-list of the same NL phrases.
2. L89 — match the pack convention: backtick-wrap the co-located template pointer (`` `@skills/productivity/dojo/lib/prep-brief-template.md` ``) so it reads as a lazy pointer like ship/careful/review/sprint, rather than a bare mid-sentence import.
3. L65-72 — the lib-loading worked-example block is reference-shaped; if body length later matters, fold it beside the prep-brief template in lib/ and leave a one-line instruction.

## Behavioral cases
- trigger `/sprint on the auth refactor` → expected process: dojo auto-fires at Stage 0 (L33), runs capability-probe (0a, L44), scans `docs/sessions`/`docs/learnings`/`knowledge` for "auth refactor" (0b, L52), loads the sprint flow's declared libs (0c, L65), surfaces only real gotchas (0d, L76), writes `Inbox/prep-*.md` and prints the path (0e, L89-91), then STOPS — no auto-continue into Stage 1 (L91).
- anti-trigger `fix this one-line typo in the config` → should NOT fire; the "When to skip" gate (L38, "Trivial fix (1-line typo, single config)") routes straight to the edit, no prep brief.
- anti-trigger `stress-test this fuzzy idea` → should NOT fire; that is adversarial discovery, routes to `grill` / `office-hours`, not dojo's pre-action prep.
