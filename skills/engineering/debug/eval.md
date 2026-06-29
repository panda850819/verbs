---
type: skill-eval
skill: debug
bucket: engineering
evaluated_skill_hash: df8a14241c1a55d063930776fb41e957f3c95a98
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — debug

**Verdict: SOLID.** A lean override-based debugging skill: three reflex-overrides in the spine, all method and lore offloaded to `lib/diagnosis.md`. Its leading virtue is that every spine line is a reflex the model gets wrong *despite* understanding debugging (edit-before-root-cause, claim-fixed-before-running, ignore-siblings) rather than understood procedure restated as a checklist — the opening "you already know how to debug, this is not the method" makes that contract explicit and prevents checklist-LARPing. Loses points only on completion criteria, where "specific enough" root cause and the sibling sweep lean on judgment.

| Axis | Verdict | Evidence |
|---|---|---|
| Description / invocation | pass | Front-loaded triggers (zh + en) with NOT-clauses routing to `review` (diff), `ui` (taste); a render bug is explicitly carved to `debug`. |
| Predictability | pass | Same shape every run: 3 fixed overrides + a lore pointer. No per-bug branching in the hot path. |
| Completion criteria | weak | The overrides are gates, but "root cause specific enough" and "grep the signature for siblings" rest on judgment; the `file:function:line` + testable-vs-untestable contrast is the real bar that keeps it from being vague. |
| Information hierarchy | pass | Lore (known bug classes, CLI archetypes, instrument-first, bisect, handoff template) is cold behind `lib/diagnosis.md`; the spine stays 36 lines. |
| Pruning | pass | The line-by-line cut removed the rationalization catalog (restated existing gates) and the evidence-ladder enumeration (pretrained); only the deflection tell survived as genuine lore. |

**Recommendations:** none load-bearing. If a recurring bug class proves the completion bar too soft, add one checkable "the hypothesis names the propagation path" line to the gate.
