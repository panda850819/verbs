---
type: skill-eval
skill: write
bucket: writing
evaluated_skill_hash: 82b11d1879c046fe80496414e2c89b654d317d3d
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — write

**Verdict: SOLID.** Leading virtue is structurally-enforced anti-ghostwriting predictability: every generative mode aborts on a checkable drift criterion, and the #106 slim pulled the Idea Gate catalog behind a pointer so the body now reads as routing + self-checks rather than inlined reference.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L31 — the Mode Selection table maps each user signal to a fixed route, and every mode (L50, L73, L85, L126, L138, L168, L178, L207) runs the same process each invocation rather than improvising. |
| Description / invocation | weak | L4 — front-loads a leading word ("Voice-aware writing assistant") and is shorter than before, but the capability list (sparring / structure coaching / draft review / slop detection / postmortem / idea-gate) restates branches that the trigger list names again, so it still duplicates meaning the body owns. |
| Completion criteria | pass | L124 — "if you've written more than 3 consecutive sentences of new prose outside a `→` annotation… Stop and convert to annotations" is checkable and anti-premature-completion; mirrored per mode (L58, L83, L166). |
| Information hierarchy | pass | L209 — the full Idea Gate routing table, packet template, and rules now sit behind a context pointer to `references/idea-gate.md`, loaded only when the idea-gate branch fires; matches the hot/cold dispatch for the ~8K article-patterns library (L54, L105) and the conditional zh-ref table (L93). |
| Leading words | pass | L15 — "sparring partner, structure coach, and slop detector" anchors the whole skill in three pretrained roles in one line; "ghostwriter" (L41) reuses a compact behavior anchor for the redirect. |
| Pruning | weak | L239 — "Zero tolerance — every match gets flagged" repeats L231 verbatim within eight lines; the Gotchas (L290–291) also restate annotate-never-replace and short-sentence rules already enforced in Edit/Structure self-checks. Improved: the prior largest no-op (Idea Gate rationale block) is gone. |
| Granularity | pass | L207 — Idea Gate earns its place as a subcommand: distinct `/write idea-gate` leading word and an upstream-gate reach (originals/ → packet → handoff) no other mode covers, while sharing the voice/slop core that keeps it inside one skill. |
| pandastack conformance | weak | L54 — hot/cold dispatch honoured, `name: write` matches folder, and every `references/` + repo-root `lib/quality-rubric.md` ref resolves; residual is the 292-line body (down from 358) — earned by 8 modes but still far over the ~<80 discipline and partly prunable. |

## Why it's good
The anti-ghostwriting contract is enforced by construction, not exhortation: every generative mode ends on a hard self-check that names the drift and the abort action (Spar L58, Structure L83, Edit L124, Distill L166), and the L285 Output Validation pointer makes the per-mode checks exhaustive. The #106 slim landed its target cleanly — the Idea Gate mode collapsed from ~65 inlined lines to a single pointer (L209), so the body now carries routing and guardrails while the bulky route table lazy-loads. Predictability is real across eight distinct uses because the L31 signal table plus subcommand routing pins one process per signal.

## Top fixes
1. L4 — collapse the capability list into the trigger list; "draft review", "structure", "postmortem", and "idea-gate" each appear twice in one hot string.
2. L239 — delete the duplicated "Zero tolerance — every match gets flagged" (kept once at L231); fold any Gotcha (L290–291) already covered by a mode self-check.
3. L211 — push the Structural Toolkit and Slop Detection sections toward the same pointer treatment Idea Gate just received if the body needs to reach the ~<80 discipline; they remain the largest hot blocks.

## Behavioral cases
- trigger `should I write about this originals/2026-06-26-thought.md` → expected process: Idea Gate (L207) — loads `references/idea-gate.md`, runs Stage-0 brain grep, picks 1 of 5 routes, emits a writer-context-packet or 暫不寫.
- trigger `/write postmortem on this near-final draft` → expected process: Postmortem mode (L178) — quote the exact line per category, banned generic-praise words enforced (L198), run AFTER `/write edit` for long posts (L202).
- anti-trigger `just make this text sound human, de-AI it` → should NOT fire (routes to `humanizer`, per L4).
- anti-trigger `final voice cleanup on this IC memo` → should NOT fire (routes to `avoid-ai-writing`, per L4).
