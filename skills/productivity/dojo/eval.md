---
type: skill-eval
skill: dojo
bucket: productivity
evaluated_skill_hash: c07a6701e502040c91d573a892eaff0f0593107b
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — dojo

**Verdict: SOLID.** Leading virtue: a clean, fixed 5-stage Stage-0 spine that runs the same process every invocation. The old origin sediment and inline prep template are gone; remaining costs are a trigger-stuffed description and a 108-line body.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L42 — "## Stages" opens a fixed 0a→0e sequence (probe → past-case → lib-load → gotcha → output) that runs identically every invocation; output varies by topic, process does not. |
| Description / invocation | weak | L6 — front-loads "Pre-action prep" well, but stacks 5 triggers plus "any non-trivial work session" and restates body identity ("Scans past similar cases (filename + grep), loads relevant lib/ refs, surfaces gotchas") the Stages already own — duplication the description should cut. |
| Completion criteria | pass | L59 — "Take top 5 hits across both. De-dup. Read the matched file's first 200 chars" is bounded and checkable; the lib-load step (L65) anchors the soft word "relevant" with a required 1-line-per-lib print so done-vs-not-done stays observable. |
| Information hierarchy | pass | L46 — `@../../../lib/capability-probe.md` pushes the probe behind a resolving context pointer; steps inline, reference externalized, each stage co-located under one heading. |
| Leading words | pass | L26 — the dojo/ring metaphor ("Before stepping into the ring, you walk into the dojo … Then you fight") + "Stage 0" anchor prep-before-action in one pretrained concept the agent runs the skill with. |
| Pruning | pass | L90 — the verbose prep-file template has been extracted to `skills/productivity/dojo/lib/prep-brief-template.md`, and the old origin block is gone; the remaining lines all change runtime behavior. |
| Granularity | pass | L90 — `/prep` alias and the 0a→0e split each earn their load: alias = Layer-1 typing reach, and the sequential stages split to block rushing past-case lookup (premature completion). |
| pandastack conformance | weak | Frontmatter is valid: `name=dojo` matches folder, `description` present, `mode: skill` is permitted, and all `@`/lib refs resolve. Weak only because the body is 108 lines vs the ~80-line discipline, though the excess is mostly earned by the prep pipeline. |

## Why it's good
The five-stage spine (L42-92) is the load-bearing strength: each stage has a concrete action and most end on a checkable result (top-5 + de-dup, first-200-char read, 1-line-per-lib, 1-3 gotchas), so the agent runs the same process every time. The dojo leading word (L26) and resolving `@`-imports (L46, L106) keep the prep contract legible, and the anti-fabrication guard (L86) plus escape-hatch handling (L108) close the two ways a prep flow most often goes wrong.

## Top fixes
1. L6 — prune the body-identity restatement ("Scans past similar cases (filename + grep), loads relevant lib/ refs, surfaces gotchas") from the description; keep only the triggers and the `/sprint`+`/office-hours` auto-invoke reach clause, which are the parts doing invocation work.
2. L63-73 — the lib-loading example is helpful but reference-shaped; consider moving it beside the prep-brief template if body length becomes a problem.
3. L104-108 — escape-hatch details are valuable but could be a one-line pointer to the shared escape-hatch rule plus the dojo-specific partial-prep clause.

## Behavioral cases
- trigger `/sprint on the payments refactor` -> expected process: dojo auto-fires at Stage 0 (L33), runs capability-probe (0a), scans `docs/sessions`/`learnings`/`knowledge` for "payments refactor" (0b), loads the sprint flow's declared libs (0c), surfaces real gotchas (0d), writes `Inbox/prep-*.md` and prints the path (0e), then STOPS — does not auto-continue into Stage 1 (L92).
- anti-trigger `fix this one-line typo in the config` -> should NOT fire; the "When to skip" gate (L38, "Trivial fix (1-line typo, single config)") routes it straight to the edit, no prep brief.
