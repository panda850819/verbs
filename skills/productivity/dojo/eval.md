---
type: skill-eval
skill: dojo
bucket: productivity
evaluated_skill_hash: 937c55a4ca031d0c48771e57c6b12555d0ee8ae1
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — dojo

**Verdict: SOLID.** A well-shaped Stage-0 prep flow whose five sub-stages give the same deterministic process every run, anchored by a genuinely load-bearing leading word; it loses points to body sprawl and a few un-checkable "relevant" criteria.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L42 — "## Stages" opens a fixed 0a→0e sequence (probe → past-case → lib-load → gotcha → output); the process is identical every invocation. |
| Description / invocation | weak | L6 — front-loads well and lists distinct triggers, but re-states body identity ("Scans past similar cases (filename + grep), loads relevant lib/ refs, surfaces gotchas") that the Stages already own — duplication the description should cut. |
| Completion criteria | weak | L65 — "For each lib/ file relevant to the upcoming flow" leans on "relevant" with no checkable set; contrast the sharp L59 ("top 5 hits … De-dup. Read the matched file's first 200 chars"). |
| Information hierarchy | pass | L46 — `@../../../lib/capability-probe.md` pushes the probe behind a resolving context pointer; steps inline, reference externalized, co-located per stage. |
| Leading words | pass | L26 — the dojo/ring metaphor ("Before stepping into the ring, you walk into the dojo … Then you fight") anchors prep-before-action in one pretrained concept, doing real invocation + execution work. |
| Pruning | weak | L142 — the "## Origin" section (Codex Q6 review, 2026-05-04 changelog narrative) is sediment: it documents provenance, changes no behaviour, and helps push the body to 146 lines vs the ~80 discipline. |
| Granularity | pass | L24 — split off as a standalone skill earns its load: independently reachable via `/dojo` AND auto-invoked by `/sprint` + `/office-hours`, and the 0a→0e steps split by sequence to block premature completion. |
| pandastack conformance | weak | L1 — frontmatter `name: dojo` matches folder and `@`-imports resolve (~2.6K tokens, under the 5K hot/cold bar), but the body is 146 lines, well past the ~<80-line discipline without the length clearly earning itself. |

## Why it's good
The five-stage spine (L42–122) is the load-bearing strength: each stage has a concrete action and most end on a checkable result (top-5 + de-dup, first-200-char read, 1–3 gotchas), so the agent runs the same process every time. The dojo leading word (L26) and the resolving `@`-imports (L46, L138) keep the prep contract legible without bloating the description, and the anti-fabrication guard (L86, L131) plus the escape-hatch handling (L140) close the two ways a prep flow most often goes wrong.

## Top fixes
1. L142–146 — drop "## Origin" and "## Naming" into a CHANGELOG or commit body; they are provenance sediment that does not change runtime behaviour and inflate the body past the ~80-line line.
2. L65 — make the lib-load criterion exhaustive: replace "each lib/ file relevant to the upcoming flow" with "load exactly the files named in the downstream flow's frontmatter `reads:` — no more, no less" so done-vs-not-done is checkable.
3. L6 — prune the body-identity restatement ("Scans … surfaces gotchas") from the description; keep the triggers and the auto-invoke reach clause, which are the only parts doing invocation work.

## Behavioral cases
- trigger `/sprint on the payments refactor` → expected process: dojo auto-fires at Stage 0 (L33, "auto-invoked there"), runs capability-probe, scans `docs/sessions`/`learnings`/`knowledge` for "payments refactor", loads the sprint flow's declared libs, surfaces real gotchas, writes `Inbox/prep-*.md`, prints the path, and stops — does NOT auto-continue into Stage 1 (L124).
- anti-trigger `fix this one-line typo in the config` → should NOT fire; the "When to skip" gate (L38, "Trivial fix (1-line typo, single config)") routes it straight to the edit, no prep brief.
