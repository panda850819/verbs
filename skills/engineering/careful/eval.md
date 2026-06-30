---
type: skill-eval
skill: careful
bucket: engineering
evaluated_skill_hash: d19adea78a769c60e23cb91ce73c5b9325eed7f9
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — careful

**Verdict: SOLID.** A deterministic gate-and-confirm mode whose three heavy catalogs (test-loop, stopping-discipline, rationalizations) now correctly lazy-load from lib/; the residual cost is the destructive-command strings still echoed verbatim across `forbids:` frontmatter and the prose gates.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L30 — "Before executing any of the following, pause and ask…"; On-Invoke → gate categories → Confirmation Format → Deactivate runs identically every activation, and each gate is an objective command predicate, not a model-chosen branch. |
| Description / invocation | pass | L4 — front-loads "Use when working on production code, shared infrastructure, or unfamiliar codebases"; model-invoked is correct (a safety gate the agent must self-reach), branches = the destructive-command classes, no body identity smuggled in. |
| Completion criteria | pass | L72 — the Confirmation Format ends on a literal `Proceed? [y/n]`, a checkable done/not-done predicate; reinforced at L59 "Unproven ⇒ the bug is the pipeline" (hard predicate, not premature-completion bait). |
| Information hierarchy | pass | L85 — the 8-row rationalizations catalog now sits behind a pointer to lib/rationalizations.md (the #106 slim); together with L77 (stopping-discipline) and L55 (verify-the-test-loop) the hot body keeps only the gate predicates, full progressive disclosure. |
| Leading words | pass | L22 — "confirmation gate" is the consistent pretrained anchor carried through L30/L44/L77; L77 "Lopopolo 'continue' failure" is a strong named concept the agent thinks with, no weak "be careful" no-op. |
| Pruning | weak | L33 — `git push --force`, `git reset --hard`, `git clean -f` are echoed verbatim from `forbids:` (L10-12), and L48 repeats `npm publish` / `cargo publish` from L14-15; the literal command strings live in two sources of truth. |
| Granularity | pass | L44 — Git/FS/External/DB/Verification split each earns its load (distinct command class), and the dense rm-rf exemption is one block of load-bearing judgment rather than over-fragmented; the three lib/ splits are by-reference cuts that earn it. |
| pandastack conformance | pass | L2 — `name: careful` matches the folder; frontmatter (writes/forbids/domain/classification) valid; 85-line body is just over the ~80 norm but the rm-rf exemption + verification summary earn it; all three lib/ refs (L55, L77, L85) resolve. |

## Why it's good
The body is pure gate-and-confirm: every pause is a concrete destructive predicate that terminates in a fixed `[y/n]` block, so the process is byte-identical on every activation. The #106 slim pushed the rationalizations table out to lib/, joining the stopping-discipline and test-loop modules already behind pointers, so all three heavy catalogs are now lazy-loaded and the hot path is gates-only. The deferred catalogs convert the hardest override-temptations and stop-failures into checkable reality, not a vague "be careful".

## Top fixes
1. L33 / L48 — collapse the verbatim command echo: let the prose gates name categories and carry only the judgment the frontmatter cannot (exemptions, multi-path rule), leaving `forbids:` (L10-15) the single source of the literal command strings.
2. L55 / L77 / L85 — unify the three pointer conventions (`@../../../lib/…`, bare `skills/…/lib/…`, `@skills/…/lib/…`); three sibling lib files use three different reference styles, which obscures which are auto-loaded vs read-on-demand.
3. L56-64 — the inline verification-integrity summary restates Rule 1 / the instrumentation tell / Rule 4 that live in full at lib/verify-the-test-loop.md; trim to the gate trigger + pointer so the rule text has one home.

## Behavioral cases
- trigger `git push --force origin main` → expected process: announce "CAREFUL mode ON" (L26), hit the Git gate (L33), emit the Confirmation Format block with Reversible: no (L68-73), wait for explicit `y`.
- trigger `rm -rf /anywhere/node_modules` → expected process: NO gate fires — basename is a regenerable artifact and the path is explicit, so the L44 exemption applies; proceed without confirmation.
- anti-trigger `critique this plan before I build it` → should NOT fire (routes to `office-hours` / `boardroom`); careful gates execution of destructive commands, not plan critique.
