---
type: skill-eval
skill: checkpoint
bucket: engineering
evaluated_skill_hash: a472924a10c39700d2136f75791fa7102acd9a92
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — checkpoint

**Verdict: SOLID.** Clean three-branch dispatch with deterministic per-mode sequences and an explicit completion string; loses a point only for restating the focus-arg contract across the Save table and the Resume Hint field.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L21 — `Save (default)` and each mode run a fixed numbered sequence with fixed bash + a verbatim template; same input yields a structurally identical artifact every run |
| Description / invocation | pass | L4 — front-loads the leading verbs "Save, resume, or list" then a clean "Use when" trigger clause covering all three branches; no body-identity restatement |
| Completion criteria | pass | L84 — Save terminates on an explicit output string; Resume archives only after the RESUMING block printed AND the file is read into context (L106-109), List has an empty-case (L121) |
| Information hierarchy | pass | L69 — "Reference, don't duplicate" and "Redact secrets" are co-located inside the Save template they govern, not floated to a generic preamble |
| Leading words | pass | L21 — pretrained-anchor verbs "Save / Resume / List" as section heads mirror the dispatch table at L15-17, no restatement to collapse |
| Pruning | weak | L65 — "If a focus arg was passed, anchor the hint to it" restates the focus-arg contract already fully enumerated at L15 (which names Resume Hint among the three tailored fields); collapse one |
| Granularity | pass | L11 — Detect Command + 3 mode sections is the minimum split; the branches share `docs/checkpoints/` and the `/checkpoint` word yet each earns its own section because the processes genuinely diverge |
| pandastack conformance | pass | L2 — frontmatter `name: checkpoint` equals the folder; 121 lines / ~954 tokens, under the 5K hot/cold threshold so no sub-agent dispatch owed and no lib/ refs to resolve; the embedded template earns the body length |

## Why it's good
The Detect-Command table (L11-17) gives one unambiguous trigger per branch, and each mode is a deterministic numbered recipe, so two agents checkpointing the same branch produce structurally identical artifacts. The Save template inlines its two cross-cutting guardrails (reference-don't-duplicate, redact-secrets) exactly where they bind, and the prior eval's three defects are repaired: the description now reaches the List branch (L4-6), the destructive delete became a recoverable archive gated on a defined success condition (L106-109), and Resume step 2 now falls through to the List branch (L94) instead of restating it.

## Top fixes
1. L65 — drop the Resume Hint field's "If a focus arg was passed, anchor the hint to it"; L15 already states the focus arg tailors Resume Hint, so the field restatement is sediment.
2. L6 — the description tail "or to list saved checkpoints" echoes the leading word "list" from L4; trim to keep the trigger clause one-per-branch.
3. L78 — `project-state append` is the one external binary with no inline contract; a one-line note on what the flags mean (or a lib/ pointer if it grows) would keep the step self-checking.

## Behavioral cases
- trigger `/checkpoint "ship the auth refactor"` -> expected process: Save branch — run the L23 gather block, write `docs/checkpoints/{branch}-{date}.md` from the L33-67 template with Remaining/Suggested-Skills/Resume-Hint tilted toward the focus arg, best-effort `project-state append` if a project page exists (L78), print "Checkpoint saved." (L84).
- trigger `/checkpoint resume` on a branch with no saved file -> expected process: Resume branch falls through to List (L94), printing available checkpoints rather than erroring.
- anti-trigger `pause work and hand this to Codex` -> should NOT fire (routes to handover; checkpoint snapshots state for a later same-agent resume, it does not delegate unfinished work).
