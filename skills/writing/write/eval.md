---
type: skill-eval
skill: write
bucket: writing
evaluated_skill_hash: a896138f4153885faf59e28ff8cb212c0b866880
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — write

**Verdict: SOLID.** Process determinism is the leading virtue: every generative mode aborts on a checkable drift criterion, and the bulky reference material is dispatched cold, not inlined.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L33 — the Mode Selection table maps each user signal to a fixed route ("Help me write about X" → Spar, never ghostwrite), so the agent runs the same process each invocation rather than improvising. |
| Description / invocation | weak | L4 — the HOT description front-loads the "PERSONAL-VOICE… tuned to the author's voice" caveat before the trigger words; the leading slot does warning work, not invocation work, and the capability list restates branches the trigger list names again. |
| Completion criteria | pass | L83 — "your output should contain zero new sentences that weren't in the original draft… delete it" is checkable and exhaustive; mirrored per mode (L58, L91, L166, L184). |
| Information hierarchy | pass | L54 — hot/cold dispatch with teeth: the ~8K-token article-patterns library is explicitly NOT loaded hot, a sub-agent returns only the matched entry; matches the conditional zh-ref trigger table (L93-102). |
| Leading words | pass | L15 — "You are not a ghostwriter. You are a sparring partner, structure coach, and slop detector" anchors three pretrained roles in one line that the agent thinks with across all 8 modes. |
| Pruning | weak | L239 — "Zero tolerance — every match gets flagged" repeats L231 verbatim within eight lines; combined with a 292-line body (~3.6x the ~80-line discipline), the sprawl exceeds what the 8 modes earn. |
| Native parity | pass | L41 — names the native/default failure as ghostwriting from scratch and gives the earned delta: redirect into sparring with the user's own take before prose generation. |
| Granularity | pass | L213 — the Structural Toolkit is pushed to references/structural-checks.md rather than split into a skill; 8 modes correctly co-locate under one /write verb sharing the voice + slop core that keeps them inside one skill. |
| pandastack conformance | pass | L54 — hot/cold dispatch honoured, frontmatter valid (`name: write` matches folder, version, user-invocable), every `references/` + repo-root `lib/quality-rubric.md` ref resolves; the PERSONAL-VOICE marker is good distribution-fitness. |

## Why it's good
The anti-ghostwriting contract is enforced by construction, not exhortation: every generative mode ends on a hard self-check that names the drift and the abort action (Spar L58, Structure L83, Edit L124, Distill L166), and the L286 Output Validation pointer makes the per-mode checks exhaustive. Progressive disclosure is exemplary — the 8K pattern library and four conditional Chinese slop refs load cold via sub-agent or trigger table (L54, L93-102), keeping the hot body legible. The de-personalization lands its target: voice specifics now live in references/voice-profile.md and the HOT description flags PERSONAL-VOICE so a fresh user customizes the profile before output comes back in the author's style.

## Top fixes
1. L4 — re-order the HOT description so "/write" + the capability/trigger words lead and the PERSONAL-VOICE caveat trails; the leading slot is the invocation lever and is currently spent on a warning, while "draft review" / "postmortem" / "idea-gate" each appear twice in one hot string.
2. L239 / L231 — delete the duplicated "Zero tolerance — every match gets flagged" (keep one), and prune the 292-line body; the sprawl past the 8 earned modes is the weak axis.
3. L205 and `references/idea-gate.md` L67 — source attribution is now generic, but it still appears in two places; keep one owner if the Shann-derived idea-gate discipline changes again.

## Behavioral cases
- trigger `/write spar` ("help me write about X") → expected process: route to Spar (L50-58), cold sub-agent pattern-check against article-patterns.md, ask 2-3 sparring questions, emit thesis + skeleton + challenges, never prose.
- trigger `最後掃一遍 / final pass on this near-final draft` → expected process: Postmortem mode (L178-203) — quote the exact line per category, banned generic-praise words enforced, run AFTER `/write edit` for long posts.
- anti-trigger `just make this text sound human, de-AI it` → should NOT fire (outside `/write`, per L4).
- anti-trigger `final voice cleanup on this IC / investment memo` → should NOT fire (outside `/write`, per L4).
