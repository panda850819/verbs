---
type: skill-eval
skill: instruction-audit
bucket: meta
evaluated_skill_hash: 2eec80f6c0a43604213115193033dfad6d186f06
evaluated_at: 2026-07-06
rubric: writing-great-skills@1.1.0
---

# Eval — instruction-audit

**Verdict: SOLID.** A tight read-only auditor: six named defect classes with per-class tests, exhaustive completion criteria (a class with no hits must still be reported), and a hard human-decides boundary. It stays short of STRONG because the read-only rule is restated in four places and the skill is unproven in live use.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L42-54 — three ordered phases (load corpus, hunt per class, write candidate list), each ending on a stated completion criterion, over a fixed defect-class table (L33-40); the same process reproduces every run. |
| Description / invocation | pass | L4 + L14 — user-invocable: true with a one-line human-facing description per the description cost rule; the leading word Audit front-loads the job and trigger lists are stripped. |
| Completion criteria | pass | L50 — every class explicitly reported including no-hits, with the closer that an unexamined class is not a clean class: checkable and exhaustive, blocking premature completion. |
| Information hierarchy | pass | L33-40 — the defect-class table is in-skill reference co-located with the steps that consume it; body is ~73 lines, so nothing needs pushing to an external reference. |
| Leading words | pass | L50 — greppable anchors the evidence standard in one word; L39 admission test and L74 displace-not-accrete do the same for classes (e) and the cadence rule. |
| Pruning | weak | L70 — the read-only rule already stated at L4, L18, and L84 is restated here a fourth time; deliberate emphasis, but two homes (opening + anti-pattern) would carry it. |
| Native parity | pass | L20 — names the native competitor (pasting a file into chat for review) and the earned delta: six classes hunted across all layers at once, greppable-quote evidence, hard read-only rule. |
| Granularity | pass | L14 — manual-only invocation spends zero context load; one skill covers the whole corpus-audit branch, and no step-sequence split is warranted at three phases. |
| pandastack conformance | pass | L6-10 — frontmatter matches SKILL-FRONTMATTER.md (name = folder, one-line description, explicit user-invocable) with advisory forbids documenting the no-edit boundary; body under 80 lines; all internal refs resolve. |

## Why it's good
The skill turns a vague chore (is my instruction stack bloated?) into a repeatable hunt: each defect class carries its own falsifiable test (L33-40), Phase 2 forces per-class exhaustiveness with no-hits reporting (L50), and the output contract pins every finding to a greppable source line with a delete/rewrite/merge action (L62-65). The read-only trust model makes it safe to run on the files that govern every session.

## Top fixes
1. L70 — cut the fourth restatement of the read-only rule; keep L18 (trust model) and L84 (anti-pattern) as the two homes.
2. L50 — Phase 2 could be even more mechanical: emit a surface-by-class checklist (4 surfaces x 6 classes) so the exhaustiveness claim is visibly enumerated rather than asserted.

## Behavioral cases
- trigger `/instruction-audit` -> expected process: read AGENTS.md, CLAUDE.md, judgment-compact, and skill bodies whole with `wc -l` recorded (L46) -> hunt classes (a)-(f) quoting exact rule lines (L50) -> output the ranked candidate table and stop without editing anything (L54, L70).
- trigger: retro-week wind-down or a new rule about to land in AGENTS.md -> same audit first, so the addition displaces instead of accretes (L74).
- anti-trigger `eval this skill` / `score skill-creator` -> should NOT fire; one skill's construction score routes to `pandastack:skill-eval` (L78).
- anti-trigger `review this draft with another model` -> should NOT fire; artifact review routes to cross-modal-review (L79).
- anti-trigger `clean up my AGENTS.md for me` -> fires only as an audit; the edit itself stays with the human (L18, L84).
