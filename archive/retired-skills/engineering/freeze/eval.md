---
type: skill-eval
skill: freeze
bucket: engineering
evaluated_skill_hash: 4bd4d792cc9042f04cfd51bd27a5016b7b5f9b44
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — freeze

**Verdict: SOLID.** A tight, single-purpose guard with a now-precise "falls under" matching contract (L30) and an honest best-effort caveat (L34); it loses points only because the core mechanism is an in-context self-check whose guarantee degrades as context drifts, and the no-args branch (L21) is the one step without a checkable success condition.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | weak | L34 — enforcement "holds only while this skill stays in context... a discipline, not a hard guard"; the same trigger does not yield the same standing enforcement once the skill falls out of context, so the process is not reliably reproducible over an unbounded session. The caveat is honest, but it documents the non-determinism rather than removing it. |
| Description / invocation | pass | L4 — front-loads "Use when you want to lock editing scope to specific paths"; one model-facing trigger branch, no body-identity, no longer restates `/unfreeze` in the description. |
| Completion criteria | weak | L21 — "If no arguments: ask the user which paths to freeze to" is the only step with no success condition or example; every other step (announce block L23-28, refuse string L31) is concrete and verifiable. |
| Information hierarchy | pass | L29 — the standing per-edit rule sits correctly after the ordered On-Invoke steps; the matching semantics are co-located with the check that needs them (L30), no premature reference dump, one file. |
| Leading words | pass | L29 — "before any file edit (Edit, Write, NotebookEdit)" and "refuse the edit" (L31) are strong pretrained anchors; each step leads with an imperative verb, no restatement padding. |
| Pruning | pass | L34 — single source of truth for the matching rule and one honest enforcement paragraph; 40-line body, no sediment, no no-ops, no duplicated definitions across sections. |
| Granularity | pass | L29 — the four On-Invoke steps each earn their load (parse, no-arg fallback, announce, enforce) and the enforcement sub-bullets (L30-32) split exactly at the decision points; unfreeze is a clean inline branch, no longer straddling as an advertised peer command. |
| pandastack conformance | pass | L2 — frontmatter `name: freeze` matches the folder; 40 lines, well under ~80; reads no reference so no >5K-token hot/cold dispatch is owed; no lib/ pointers to resolve. |

## Why it's good
The repair fixed the two structural defects from the prior version: the "falls under" definition (L30) now spells out normalized-absolute prefix match for directories, exact match for files, and symlink-escape rejection, so two runs agree on edge paths; and the enforcement-honesty paragraph (L34) tells the model the guard is a discipline rather than a hook instead of overpromising determinism. Length, hierarchy, and pruning are exemplary for an engineering utility.

## Top fixes
1. L34 — give the per-edit gate a way to survive context drift (a state file or PreToolUse guard reference) or explicitly scope the predictability claim to "while loaded"; right now the standing guarantee silently weakens mid-session.
2. L21 — make the no-args branch checkable: state what a valid resolution looks like (e.g. "re-prompt until at least one path is given; never default to freezing everything or nothing").
3. L31 — the refuse string points to `/unfreeze` generically; consider echoing the current allowed-path list on each block so the user sees the active scope at the moment of refusal, not just where the announce ran.

## Behavioral cases
- trigger `/freeze src/api/ tests/api/` -> expected process: parse both as the allowlist (L20), announce FREEZE active listing both (L23-28), then for every subsequent Edit/Write/NotebookEdit normalize the target and refuse anything not under either path with the exact FROZEN string (L29-32).
- trigger `/freeze` (no args) -> expected process: ask which paths to freeze to before activating (L21); do NOT freeze everything or nothing.
- anti-trigger `careful mode for this prod repo` -> should NOT fire; routes to pandastack `careful` (confirmation gates on destructive commands, not path-scoped edit blocking).
- anti-trigger `save my working state before I switch context` -> should NOT fire; routes to pandastack `checkpoint` (state snapshot, not edit-scope locking).
