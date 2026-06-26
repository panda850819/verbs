---
type: skill-eval
skill: ceo
bucket: productivity
evaluated_skill_hash: f500916c09a0dfbbb4be49cc8b9d3cf2baded9b1
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — ceo

**Verdict: SOLID.** A tight persona lens whose value is a fixed, pretrained-anchored decision process (two-way/one-way doors, effort gate, framework tension) bolted to a hard READ-ONLY, recommend-don't-act contract.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L45 — "## On Invoke" fixes a 4-step process (L47–50: pick frameworks → show tension → recommend → predict pushback) the agent runs the same way every invocation; predictability is process-not-output, and this is process. |
| Description / invocation | pass | L4 — front-loads the leading concept ("Strategic lens for scope, priority, kill/pivot/continue…"), lists trigger branches, and carries an explicit NOT-clause routing implementation/code-review/planning elsewhere. |
| Completion criteria | weak | L47 — On Invoke steps 1–3 ("Pick 2-3 frameworks", "Show where they agree and disagree", "Make a recommendation") have no checkable done-gate; only step 4 (L50, "top 3 pushback questions") and the Scope Review GO/ITERATE/KILL (L58) are exhaustive. Soft middle invites premature completion. |
| Information hierarchy | pass | L70 — BAD/GOOD calibration is pushed to `@../../../lib/bad-good-calibration.md` behind a context pointer (same with persona-frame at L17), so the hot body stays the persona contract and shared rules load on demand. |
| Leading words | pass | L41 — "Two-way / one-way doors (Bezos)" and "Effort gate (compression ratio)" (L42) anchor whole regions of behaviour in pretrained concepts rather than re-deriving them. |
| Pruning | weak | L37 — Iron Law 5 "Never act on scope changes" restates the recommend-don't-act meaning already carried by L15 (READ-ONLY), L33 (Iron Law 1 user sovereignty), and the L65 anti-pattern ("Ask first. Always."). Four sources of one truth = duplication that inflates the meaning's rank without adding behaviour. |
| Granularity | pass | L23 — the Routing Boundary cleanly hands implementation/code/debugging/planning/writing to eng-lead/plan/writing-plans/careful/write, so the ceo split earns its always-loaded description by owning a distinct strategic leading word (L21) rather than overlapping a sibling. |
| pandastack conformance | weak | L7 — frontmatter declares `reads: lib/escape-hatch.md`, but the body never `@import`s or references escape-hatch (only persona-frame L17 and bad-good-calibration L70 are actually consumed); a declared dependency that never fires is advisory sediment. (Frontmatter is otherwise contract-clean: persona-frame L11–15 requires only `name` + `description`, both present; `version`/`type` are NOT modeled and no sibling persona carries them — the prior eval's claim of "missing version/type" was a fabricated requirement, removed here.) |

## Why it's good
The skill earns its keep on predictability and leading words: a 4-step On-Invoke loop plus three named, pretrained frameworks give the agent the same strategic process every run with almost no token cost. The READ-ONLY / user-sovereignty stance is unambiguous, and progressive disclosure is real — persona-frame and the BAD/GOOD pairs live behind pointers, keeping the hot body to the persona contract. The Routing Boundary (L21–24) is the strongest single section: it explicitly disclaims implementation, code review, and generic planning, so the always-loaded description discriminates cleanly against eng-lead/plan/write.

## Top fixes
1. L43 — "Framework tension (multi-lens): used when single framework gives a clean answer (suspect of clean answers)" reads backwards as a trigger. Rewrite to the actual intent: reach for multi-lens *to challenge* a too-clean single-framework answer, e.g. "used to stress-test a clean single-framework answer before trusting it."
2. L37 — collapse the four restatements of recommend-don't-act (L15 READ-ONLY, L33, L37, L65) to a single source of truth; keep one (Iron Law 1) and let the others reference rather than re-assert.
3. L7 — either wire `lib/escape-hatch.md` into the body (an `@import` where the escape-hatch behaviour should fire) or drop it from `reads:`; declared-but-unconsumed dependencies are exactly the audit sediment the firewall fields warn about. (Do NOT add `version`/`type`: the persona-frame contract at lib L11–15 requires only `name` + `description`; the prior fix item asking for those fields was wrong.)

## Behavioral cases
- trigger `/ceo should we kill this feature or pivot?` → expected process: load persona-frame, pick 2–3 tension-creating frameworks (two-way/one-way door + effort gate), show agree/disagree, recommend GO/ITERATE/KILL with reasoning, predict top 3 pushback questions — never executes the kill, asks first (L37).
- anti-trigger `review my auth refactor diff` → should NOT fire (routes to eng-lead / review per L23); this is implementation/code-review, explicitly disclaimed in the Routing Boundary.
