---
type: skill-eval
skill: boardroom
bucket: productivity
evaluated_skill_hash: bff013baaebd9d2dae84985bf426070ad86e87ff
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — boardroom

**Verdict: SOLID.** Leading virtue is a principled two-mode mechanism (sequential coherence vs `--panel` independence) with deterministic voice-scope, a checkable per-voice coverage criterion, per-finding Apply? gates, and real quorum aggregation. Remaining costs are body length and some repeated sequential-vs-panel framing.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L76 — optional ops-lead scope now uses a deterministic keyword-count rule plus an ambiguity tie-break (L84), so the same plan yields the same core/optional voice set unless the user overrides. |
| Description / invocation | pass | L5 — front-loads the leading word "Multi-lens plan critique router", one-trigger-per-branch list, explicit `/boardroom` + NOT clause, no body-identity restated. (Missing `version`/`user-invocable` are spec-OPTIONAL per SKILL-FRONTMATTER.md, not an invocation defect.) |
| Completion criteria | pass | L106 — each voice is complete only when every Iron Law in that voice's contract has been checked; zero findings must be said explicitly, so completion is coverage-based rather than count-based. |
| Information hierarchy | pass | L75 — capability-probe pushed behind `@../../../lib/...` pointer; per-voice contracts pushed to each voice's SKILL.md via `lib/persona-frame.md` rather than inlined; co-location of each Stage's rules under its heading. Progressive disclosure held. |
| Leading words | pass | L138 — "quorum-aggregate", "mutually-blind" (L36), "cold subagents" (L130), "uncorrelated errors across lenses" (L64) anchor the panel mechanism in pretrained concepts in few tokens. |
| Pruning | weak | L202 — the sequential-vs-panel distinction is still restated in the Modes table, Stage 2-PANEL, the ordering rationale, and Anti-patterns. The table is the SSOT; the repeated prose is the main remaining body-length cost. |
| Granularity | pass | L126 — Stage 2 vs Stage 2-PANEL earns its load: opposite mechanism (mutual blindness, independent reach), and panel dispatches cold subagents (L130) instead of loading four sibling SKILL.md hot; the cut is anti-correlated-error, not a premature-completion artifact. |
| pandastack conformance | weak | L1-219 — `name: boardroom` = folder and all refs resolve; body length is still ~219 lines against the ~80-line guidance. Default mode intentionally stays in one context for sequential coherence, while `--panel` uses cold subagents (L124); length, not broken refs, is the standing conformance cost. |

## Why it's good
The Modes table (L52-58) is the load-bearing asset: it turns the sequential/panel choice into a one-glance decision keyed to stakes, with mechanism, optimization target, cost, and failure-cure in one cell-set. The per-finding `Apply? [Y/N/edit]` gate (L107-116) routed through `lib/outside-voice-rule.md`, plus the stop-rule and escape-hatch (L116-117), make the skill checkable and interruptible. Panel mode's quorum-aggregation (L132-136) with an explicit "never drop single-voice findings" rule (L136) defends against consensus-washing, and every reference resolves.

## Top fixes
1. **L202-211** — shorten the default ordering rationale or move it behind a reference; the Modes table already owns the sequential-vs-panel split.
2. **L120-138** — panel mechanics are long but valuable; if body length becomes blocking, extract prompt/model-diversity/quorum details behind a `skills/productivity/boardroom/lib/` pointer.
3. **L38-46** — fold the Routing Boundary into the description or trim the description; both currently carry the plan-vs-problem boundary.

## Behavioral cases
- trigger `/boardroom plans/q3-launch.md --panel` -> expected process: Stage 0 probe + load plan, announce `boardroom mode: panel (independent)`, Stage 1 scope (CEO+product+design+eng; ops only if coordination-dominant), dispatch all voices as cold mutually-blind subagents on the original plan, quorum-tag each cluster `[high-confidence/corroborated/investigate]`, gate per finding via `lib/outside-voice-rule.md`, write `Inbox/boardroom-q3-launch-2026-06-26.md`.
- trigger `review this PRD, 4-voice critique` -> expected process: default sequential Stage 2, CEO->product->design->eng, each voice sees prior applied patches, per-finding gate, Stage 3 synthesis with Gate Log + final plan diff.
- anti-trigger `grill me on this scope` -> should NOT fire; routes to `/grill` (boardroom is for prepared plans, not problems; L54).
- anti-trigger `the login button is misaligned, fix it` -> should NOT fire; single-domain tactical execution routes to `/design-lead` or `/eng-lead` directly (L53-54).
