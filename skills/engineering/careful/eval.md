---
type: skill-eval
skill: careful
bucket: engineering
evaluated_skill_hash: 93722d5996ca37af4ba2f1cbccf3faeb55c3fb44
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — careful

**Verdict: SOLID.** The destructive-action gate is concrete and predictable: enumerated trip-wires, a fixed confirmation format, and a sharply-reasoned reinstallable-artifact exemption make the core behaviour the same every run.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L32 — "Before executing any of the following, pause and ask the user for explicit confirmation" anchors one deterministic process against an enumerated trip-wire list. |
| Description / invocation | weak | L3 — description covers only the destructive-gate half; the entire stopping-discipline / continue-failure-logging branch (L77+) has no trigger and no mention, so that behaviour is unreachable by description. |
| Completion criteria | weak | L32 — "pause and ask" is checkable, but "While Active" carries no overall done/not-done criterion; the gate is a standing rule-set, leaving when-it-ends implicit. |
| Information hierarchy | weak | L77 — a ~60-line logging+audit+retro subsystem (Lopopolo discipline, log format, retro-week wiring) sits hot in SKILL.md; it is on-demand reference that should drop behind a context pointer. |
| Leading words | pass | L77 — "every continue is a harness failure" (Lopopolo) is a strong pretrained anchor that collapses the whole stop-discipline region into one phrase. |
| Pruning | weak | L143 — the "Common Rationalizations" table is largely persuasive prose (no-op against a model that already obeys the gate at L32), padding a body already at 134 lines, well over the ~80-line budget. |
| Granularity | weak | L77 — two distinct skills are welded in one: the destructive-action gate and a continue-failure logging/retro mechanism. The second has its own leading word and its own trigger and earns a split. |
| pandastack conformance | weak | L1 — frontmatter omits `version` and ships advisory firewall fields (reads/writes/forbids); `name: careful` matches folder and `@../../../lib/verify-the-test-loop.md` (L57) resolves, but body is 134 lines vs the ~<80 budget with no earned reason. |

## Why it's good
The core gate is exemplary: L34-54 enumerate the exact commands that trip it, so the agent has a checkable list rather than a vibe, and L42-46 reason out the reinstallable-artifact exemption precisely enough to stop the gate mis-firing on routine `node_modules` cleanup. The confirmation format at L68-75 fixes the output shape, and the Lopopolo anchor (L77) gives the stop-discipline region a single load-bearing concept. Predictability — same process every run — is genuinely achieved for the destructive-command path.

## Top fixes
1. Split the stopping-discipline + continue-failure logging subsystem (L77-137) into its own skill (or push it behind a context pointer); it is a second skill with its own trigger that the L3 description does not announce.
2. Prune the "Common Rationalizations" table (L143-154): it is persuasion the model already obeys after L32, not a behaviour change. Cut it or compress to one line per gate.
3. Add `version` to frontmatter (L1) and bring the body toward the ~80-line budget once the two cuts above land.

## Behavioral cases
- trigger `working on production code, about to git push --force` → expected process: announce CAREFUL ON (L28), match the command against the Git trip-wire list (L34-35), emit the L68-75 confirmation block, wait for y/n before executing.
- anti-trigger `rm -rf node_modules` in the current project → should NOT fire the gate (L42-46 reinstallable-artifact exemption); and a request to "stress-test my plan / interrogate this idea" routes to `grill`/`office-hours`, not careful.
