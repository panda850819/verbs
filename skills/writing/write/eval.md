---
type: skill-eval
skill: write
bucket: writing
evaluated_skill_hash: ec8901671f6042e33b0414bdfdb605469d5eaf9e
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — write

**Verdict: SOLID.** Leading virtue is structurally-enforced anti-ghostwriting predictability: every generative mode aborts on a checkable drift criterion, and the repair cleared the hard hot/cold dispatch break by routing the ~8K article-patterns library through a sub-agent. Remaining cost is a 358-line body and a long description that tries to index too many branches at once.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L31 — the Mode Selection table maps each user signal to a fixed route, and every mode (L50, L73, L85, L126, L138, L168, L178, L207) runs the same process every invocation. |
| Description / invocation | weak | L4 — the description is model-useful but overloaded: it names many trigger phrases and two NOT routes in one hot string, so it violates the one-trigger-per-branch pruning pressure even though the branch coverage is accurate. |
| Completion criteria | pass | L124 — "if you've written more than 3 consecutive sentences of new prose outside a `→` annotation… Stop and convert to annotations" is checkable and anti-premature-completion; mirrored per mode (L58, L83, L166, L265). |
| Information hierarchy | pass | L93 — the conditional-reference trigger table pushes the four zh-slop dictionaries behind context pointers, loaded only when a signal fires; heavy refs (`article-patterns`, `voice-profile`, output-validation) are external. |
| Leading words | pass | L15 — "sparring partner, structure coach, and slop detector" anchors the whole skill in three pretrained roles; "ghostwriter" (L41) and "idea gate" (L207) reuse compact behavior anchors. |
| Pruning | weak | L211 — Idea Gate still carries rationale prose ("prevents two failure modes") that partly restates the mode's process, and the Gotchas section (L352) repeats routing and voice constraints already represented in the description and mode rules. The prior zh-ref duplication is fixed at L327. |
| Granularity | pass | L207 — Idea Gate earns its split: distinct `/write idea-gate` leading word, an upstream-gate reach (originals/ → brief → handoff) no other mode covers, independent invocation. |
| pandastack conformance | weak | L54 — hot/cold dispatch is now honoured ("`article-patterns.md` is ~8K tokens — do NOT load it hot. Dispatch a sub-agent… return ONLY the matched entry", mirrored L105); frontmatter `name: write` matches folder and refs resolve. Residual: 358-line body vs the ~<80 discipline — earned by 8 distinct modes but still long and partly prunable, so not pass. |

## Why it's good
The anti-ghostwriting contract is enforced by construction, not exhortation: every generative mode ends on a hard self-check that names the drift and the abort action (Spar L58, Structure L83, Edit L124, Distill L166, Idea Gate L265), and the L348 Output Validation pointer makes the per-mode checks exhaustive. The repair landed its core target cleanly: both pattern-match steps (L54, L105) now dispatch a sub-agent instead of loading the ~8K-token library hot, and the Slop section's conditional zh-ref list is collapsed to a single-source pointer (L327). Predictability is real across eight distinct uses because the L31 table plus subcommand routing fixes one process per signal.

## Top fixes
1. L4 — split or shrink the description; it is currently a trigger inventory plus NOT-routing policy in one long hot string.
2. L211 — prune Idea Gate's rationale block and let the route table + process carry the behavior. This is the largest remaining body-level no-op.
3. L352 — fold Gotchas into the relevant mode sections or delete any item already represented by the description / guardrails.

## Behavioral cases
- trigger `/write postmortem on this near-final draft` -> expected process: Postmortem mode (L178) — quote the exact line per category, banned generic-praise words enforced (L198), run AFTER `/write edit` for long posts (L202).
- trigger `should I write about this originals/2026-06-26-thought.md` -> expected process: Idea Gate (L207) — Stage-0 brain grep (L224), pick 1 of 5 routes, emit writer-context-packet or 暫不寫.
- anti-trigger `just make this text sound human, de-AI it` -> should NOT fire (routes to `humanizer`, per L4).
- anti-trigger `final voice cleanup on this IC memo` -> should NOT fire (routes to `avoid-ai-writing`, per L4).
