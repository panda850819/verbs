---
type: skill-eval
skill: careful
bucket: engineering
evaluated_skill_hash: 70d7b96cedb1e451595375e37c59f7ef7384811f
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — careful

**Verdict: SOLID.** Same gate-check process every run with a concrete checkable confirmation, and the two heavy integrity subsystems now correctly deferred to resolving lib/ pointers; the one cost is the destructive-command list living verbatim in both `forbids:` frontmatter and the prose gates.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L30 — fixed On Invoke → While Active gates → Confirmation Format → Deactivate runs identically every activation; gates are objective predicates, not model-chosen branches. |
| Description / invocation | pass | L4 — front-loads "Use when working on production code…"; model-invocation is correct (the agent must self-reach a safety gate), no body-identity smuggled into the trigger. |
| Completion criteria | pass | L69 — the Confirmation Format yields a literal `[y/n]`; L57 "Unproven ⇒ the bug is the pipeline" is a hard checkable predicate, not premature-completion bait. |
| Information hierarchy | pass | L55 — the two costly modules (verify-the-test-loop, stopping-discipline) sit behind `@`/`lib/` pointers, keeping the hot body to gates only; progressive disclosure honoured, no re-inline of their rules. |
| Leading words | pass | L30 — "Before executing any of the following, pause and ask…" is a pretrained imperative anchor; gate items are stated once, not re-explained. |
| Pruning | weak | L33 — `git push --force`, `git reset --hard`, `git clean -f` (and L48 `npm publish`, `cargo publish`) are echoed verbatim from the `forbids:` list (L10-15); the same command strings carry in two sources of truth. |
| Granularity | pass | L44 — the Git/FS/External/DB split each earns its load; the dense rm-rf exemption is one block of load-bearing judgment, not over-fragmented. |
| pandastack conformance | pass | L2 — `name: careful` = folder; 94-line body exceeds ~80 but the rm-rf exemption logic, rationalizations table, and two integrity modules earn it; both lib/ refs (L55, L77) resolve and are deferred, honouring hot/cold dispatch (~2.2K tokens, gated). |

## Why it's good
The body is pure gate-and-confirm: every pause is a concrete destructive predicate ending in a fixed yes/no confirmation block, so the process is identical on every run. The two expensive disciplines (test-loop trust, stopping-discipline) that bloated the prior 154-line version are now behind pointers that actually resolve, keeping the hot path lean. The rationalizations table converts the hardest override-temptations into a checkable reality column instead of a vague "be careful".

## Top fixes
1. L33/L48 — collapse the verbatim command echo: let the prose gates reference categories and add only the judgment the frontmatter cannot carry (exemptions, multi-path rule), so `forbids:` (L10-15) stays the single source of the literal command strings.
2. L44 — the rm-rf exemption is a ~200-word single paragraph; if it grows further, move it behind a `lib/` pointer like the other two modules to hold the body near the ~80-line norm.

## Behavioral cases
- trigger `git push --force origin main` -> expected process: announce CAREFUL ON, hit the Git gate (L33 + L89 rationalization), emit the Confirmation Format block (reversible:no), wait for explicit `y`.
- trigger `rm -rf /anywhere/node_modules` -> expected process: NO gate fires — basename is a regenerable artifact and the path is explicit (L44 exemption), proceed without confirmation.
- anti-trigger `review this plan's architecture` -> should NOT fire (routes to eng-lead / boardroom); careful gates execution of destructive commands, not plan critique.
