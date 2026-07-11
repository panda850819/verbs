---
type: skill-eval
skill: debug
bucket: engineering
evaluated_skill_hash: e42e553ddfabe04acff58cf55550e1a62dbe321d
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — debug

**Verdict: STRONG.** Four compact momentum-reflex overrides make diagnosis and proof checkable, while current references keep recall repo-scoped and learning output candidate-only with a valid debug schema.
Grounding sample: L22 — "Diagnosis ends only on a red-capable command."

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L19 — every run begins by naming an evidence-backed root cause at a concrete code location before editing, followed by equally explicit proof and sibling-scan gates. |
| Description / invocation | weak | L6 — the hot trigger surface repeats many synonyms for the same debugging branch, paying context load without adding distinct invocation behavior. |
| Completion criteria | pass | L22 — diagnosis ends only after an already-run deterministic command capable of going red has produced observed output. |
| Information hierarchy | pass | L32 — bug-class tactics, instrumentation, bisect discipline, and handoff format stay behind a current cold reference while the reflex overrides remain inline. |
| Leading words | pass | L22 — “red-capable command” compresses falsifiability, determinism, and observed execution into one reusable concept. |
| Pruning | pass | L14 — the introduction now avoids a brittle numeric count, the body remains compact, and the learning tail contains only behavior that changes recall or candidate output. |
| Native parity | pass | L14 — “You already know how to debug” names the native method and limits the skill’s delta to momentum failures plus non-derivable project lore. |
| Granularity | pass | L8 — explicit anti-triggers keep review, UI judgment, and feature building outside this diagnosis unit, so no additional invocation cut earns its load. |
| Verbs conformance | pass | L40 — all current references resolve, the candidate schema now admits `debug`, and both the skill and its diagnosis reference explicitly leave store mutation to the host or project. |

## Why it's good

The skill avoids reteaching generic debugging and targets four steps models skip under momentum: exact root cause, red-capable proof, run-and-look verification, and sibling search. Its supporting files now agree on repo-only recall and candidate or `seen again` output, with no hidden write, counter increment, or persistence claim.

## Top fixes

1. L6 — collapse the synonym list to one trigger per distinct branch while retaining the three anti-triggers.

## Behavioral cases

- trigger `this test used to pass and now flakes` → recall relevant learnings from the configured repo path, name the root cause before editing, show an already-run red-capable command, run and inspect the fix, then grep the signature for siblings.
- trigger `this root cause is a new reusable bug class` → emit a `skill: debug` learning candidate only; do not write or update the learning store.
- trigger `this matches an existing learning` → emit a one-line `seen again` candidate only; leave counters and persistence to the host.
- anti-trigger `review my diff` → should NOT fire; route to `review`.
- anti-trigger `the spacing feels wrong` → should NOT fire; route to `ui`.
