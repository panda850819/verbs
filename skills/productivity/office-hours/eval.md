---
type: skill-eval
skill: office-hours
bucket: productivity
evaluated_skill_hash: 660182648217ca1a8503701c44591f13dbb1cd5e
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — office-hours

**Verdict: SOLID.** A genuinely predictable 5-stage pressure cooker with hard gates (ONE question at a time, per-approach Apply gate, STOP-and-wait) and a checkable terminal artifact; weakened by sprawl well past the pandastack line budget and a triggers-list / WHEN-section that restate the same boundaries three ways.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L93 — "ONE question at a time. Wait for answer." plus explicit stop conditions (L97) and STOP-and-wait gates (L135) force the same process every run, not the same output. |
| Description / invocation | weak | L5 — trigger list packs near-synonyms ("I have an idea" / "let me think out loud" / "stress test this" / "office hours") that rename one branch; one-trigger-per-branch is violated. |
| Completion criteria | pass | L266 — "acceptance: MUST be a concrete check (a grep, a test/lint command, a file-exists assertion)… write checks, not vibes" — the sharpest anti-premature-completion bar in the skill. |
| Information hierarchy | weak | L154 — Stage 5 inlines a full ~70-line brief template hot (L154–224), and Stage 5b inlines a second full plan template (L234–262); two large reference blobs sit in the step ladder instead of behind a context pointer. |
| Leading words | pass | L32 — "30-minute structured pressure cooker" anchors the whole behaviour in one pretrained concept; reinforced by "mid-flight weapon" (L61) and one-way/two-way door (L89). |
| Pruning | weak | L57–L61 — the "Differs from /grill" section states the grill-vs-office-hours distinction three times (L58, L59, L61); the third sentence is a no-op restatement of the first two. |
| Granularity | pass | L228 — splitting Stage 5b (executable plan) off Stage 5 (brief) is earned: it defends WHY/WHAT separation and prevents premature completion on pure-decision briefs. |
| pandastack conformance | weak | L279 — self-described "~250 lines"; the file is ~280, well over the ~<80-line body norm, and `@`-inlines 6 lib files hot rather than honouring the hot/cold sub-agent rule for heavy reference. |

## Why it's good

The process is deterministic where it counts: adversarial drilling is gated to one question at a time with named stop conditions, alternatives are gated per-approach with an explicit STOP, and the run only ends on a brief whose every task carries a greppable acceptance check. Leading words ("pressure cooker", "mid-flight weapon", one/two-way door) anchor behaviour cheaply, and the skip-guard at L79 (print evidence for all four concreteness conditions before declining to grill) is a strong defence against the self-confirming "no unknowns" judgment. The skill-vs-grill and Stage-5/5b WHY/WHAT separations are real, load-bearing boundaries.

## Top fixes

1. L5 — collapse the trigger list to one phrase per branch ("office hours" / "stress test this" / "draft a brief"); drop "I have an idea" and "let me think out loud" as synonyms that inflate context load every turn.
2. L154 / L234 — push the brief and plan templates behind context pointers (a `lib/office-hours-brief-template.md` + `lib/office-hours-plan-template.md`) so the step ladder stays legible and the body drops toward the ~80-line norm.
3. L57–61 — cut the third restatement of the grill distinction; one sentence ("/grill is the mid-flight 5-10 min tool with no brief; /office-hours is the full session that ends in a brief") covers it.

## Behavioral cases

- trigger `I think I want X but I'm not sure` → expected process: Stage 1 capability probe + vault scan for prior hits, then Stage 2 one-question-at-a-time premise challenge, Stage 3 forced 2-3 named alternatives with per-approach Apply gate, Stage 4 premise refresh, Stage 5 brief to `docs/briefs/`.
- anti-trigger `decision already made, just build it` → should NOT fire; routes to `/sprint` to execute (L45), and even if invoked the Stage 2 skip-guard (L79) declines to grill settled, evidenced-concrete scope.
