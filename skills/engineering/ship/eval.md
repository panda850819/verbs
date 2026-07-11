---
type: skill-eval
skill: ship
bucket: engineering
evaluated_skill_hash: 3a664680bbd4a102b793dacc2e14a71002eede0c
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — ship

**Verdict: SOLID.** The git-only delivery path is ordered around a mandatory pre-commit branch gate and closes on PR plus pushed commit/branch evidence; its native-parity delta and body-length justification remain implicit.

Grounding sample: L95 — "Do not stage or commit until this branch gate passes."

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L85 — the mandatory branch step occurs before commit, preventing local main from advancing before the feature branch exists. |
| Description / invocation | pass | L4 — the description front-loads completed-code delivery and separates unfinished work into `handover`. |
| Completion criteria | pass | L124 — completion requires both the PR URL and pushed commit/branch evidence, with a named gap when either is absent. |
| Information hierarchy | pass | L142 — quote verification is kept behind a focused pointer and loaded only when a learning candidate contains a quote. |
| Leading words | pass | L85 — “Branch (mandatory, before commit)” is a compact execution anchor for the highest-risk ordering rule. |
| Pruning | weak | L147 — the propose-only flaw-routing paragraph repeats ownership and timing constraints at length after an earlier guard-escalation sentence. |
| Native parity | weak | L41 — “one command” states convenience but does not explicitly name the delta over native `git` plus `gh pr create`: test, scope, review, branch, and evidence gates. |
| Granularity | pass | L36 — the skill owns one coherent git-to-PR lifecycle and explicitly leaves knowledge and external publication to the host. |
| Verbs conformance | weak | L151 — frontmatter and pointers resolve, but the 118-line body exceeds the normal guideline without an explicit reason for retaining all ten steps inline. |

## Why it's good

The workflow makes the dangerous ordering invariant unambiguous: create or confirm a feature branch before staging and committing. It also separates delivery from project administration, requiring only evidence the skill actually owns: a PR URL and the pushed commit/branch.

## Top fixes

1. L41 — name the native-parity delta over raw `git` and `gh`: ship adds test, scope, review, branch-order, and closure-evidence gates.
2. L147 — reduce flaw routing to the one propose-only rule and its existing reference pointer.
3. L43 — consider extracting optional release and learning-candidate branches so the main git-delivery spine stays under the hot-body budget.

## Behavioral cases

- trigger `ship this completed branch` while on `main` → expected process: read config, sync and test, check scope and review status, create a feature branch before staging or committing, push, open the PR, and print PR plus pushed commit/branch evidence.
- trigger `ship this completed branch` when `gh pr create` returns a URL but pushed commit evidence is missing → expected process: name the missing evidence and do not claim completion.
- trigger `ship this knowledge note` → should NOT enter a knowledge mode; knowledge lifecycle is a host concern.
- anti-trigger `hand this unfinished implementation to Codex` → should NOT fire; route to `handover`.
