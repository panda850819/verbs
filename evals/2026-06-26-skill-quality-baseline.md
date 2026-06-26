---
title: Pandastack skill-quality baseline (corpus-wide)
date: 2026-06-26
scope: 28 skills across engineering/ meta/ productivity/ writing/
criteria: writing-great-skills 8-axis scorecard
---

# Pandastack skill-quality baseline — 2026-06-26

## Method

Every skill was scored against the **writing-great-skills 8-axis scorecard**: Predictability, Description/invocation, Completion criteria, Information hierarchy, Leading words, Pruning, Granularity, pandastack conformance. Each axis verdict (pass / weak / fail) is **line-cited** to the exact `SKILL.md` line that backs it — no verdict rests on paraphrase. Every eval was then **adversarially re-verified** by a second pass that tried to refute each call: it confirmed the cited line exists and supports its verdict, probed every `pass` axis for a hidden no-op / duplication / vague criterion the first pass missed, and probed every `weak`/`fail` for an invented requirement (faulting `version`/`type`/`reads:` as missing when SKILL-FRONTMATTER.md makes them optional or advisory). Two evals were rewritten in that pass (`retro-week`, `team-orchestrate`) where a pass concealed a real defect or a fabricated requirement. Each eval's frontmatter carries an `evaluated_skill_hash` = `git hash-object` of the scored SKILL.md, so `scripts/lint-eval-fresh.sh` fails the moment a skill is edited without its eval being re-run. The baseline cannot silently drift.

**Corpus health: 28 skills. 2 STRONG, 26 SOLID, 0 WEAK.** Every skill clears the bar on its load-bearing virtue (a deterministic process anchored by a pretrained leading word). No skill carries an overall WEAK verdict; the entire quality story is in the per-axis weaknesses, which cluster on three axes (Pruning, Conformance, Completion) and almost never touch the core (Predictability, Granularity). **Two axis-level FAILs** sit inside otherwise-SOLID skills: init's Completion criteria and retro-week's pandastack conformance.

## Scorecard (per skill)

Weak/fail axes use short labels: Pred, Desc, Compl, Hier, Lead, Prune, Gran, Conf.

| Skill | Bucket | Verdict | Weak / fail axes |
|---|---|---|---|
| freeze | engineering | **STRONG** | Lead |
| writing-great-skills | meta | **STRONG** | Desc, Compl |
| skill-eval | meta | SOLID | Desc, Prune |
| design-lead | productivity | SOLID | Compl, Prune |
| grill | productivity | SOLID | Prune, Conf |
| ops-lead | productivity | SOLID | Compl, Prune |
| product-lead | productivity | SOLID | Compl, Prune |
| eng-lead | engineering | SOLID | Compl, Hier, Prune |
| handover | engineering | SOLID | Desc, Compl, Prune |
| gatekeeper | meta | SOLID | Compl, Prune, Conf |
| ceo | productivity | SOLID | Compl, Prune, Conf |
| checkpoint | engineering | SOLID | Desc, Compl, Lead, Prune |
| review | engineering | SOLID | Pred, Hier, Prune, Conf |
| ship | engineering | SOLID | Compl, Lead, Prune, Conf |
| sprint | engineering | SOLID | Compl, Hier, Prune, Conf |
| dojo | productivity | SOLID | Desc, Compl, Prune, Conf |
| office-hours | productivity | SOLID | Desc, Hier, Prune, Conf |
| retro-month | productivity | SOLID | Desc, Hier, Prune, Conf |
| write | writing | SOLID | Desc, Lead, Prune, Conf |
| deepwiki | engineering | SOLID | Compl, Hier, Lead, Prune, Conf |
| qa | engineering | SOLID | Desc, Compl, Hier, Prune, Conf |
| team-orchestrate | engineering | SOLID | Desc, Hier, Lead, Prune, Conf |
| skill-creator | meta | SOLID | Desc, Hier, Prune, Gran, Conf |
| using-pandastack | meta | SOLID | Desc, Compl, Hier, Prune, Conf |
| boardroom | productivity | SOLID | Pred, Desc, Compl, Prune, Conf |
| init | engineering | SOLID | Desc, Lead, Prune, Conf + **FAIL: Compl** |
| careful | engineering | SOLID | Desc, Compl, Hier, Prune, Gran, Conf |
| retro-week | productivity | SOLID | Pred, Desc, Hier, Prune, Gran + **FAIL: Conf** |

## Corpus patterns

Axis-level weakness counts across all 28 skills (a skill contributes once per weak/fail axis):

| Axis | weak | fail | total dings | % of corpus |
|---|---|---|---|---|
| **Pruning** | 26 | 0 | **26** | 93% |
| **pandastack conformance** | 18 | 1 | **19** | 68% |
| **Completion criteria** | 17 | 1 | **18** | 64% |
| Description / invocation | 16 | 0 | 16 | 57% |
| Information hierarchy | 12 | 0 | 12 | 43% |
| Leading words | 7 | 0 | 7 | 25% |
| Predictability | 3 | 0 | 3 | 11% |
| Granularity | 3 | 0 | 3 | 11% |

**Weakest axes (the systemic debt):**

1. **Pruning — 26/28 (93%).** Near-universal. The dominant failure shape is the **"Common Rationalizations" table** (sprint, ship, review, careful) — motivational prose the model already obeys, a no-op that pays hot-context load to change no behavior. The second shape is **changelog sediment** (`## Origin` sections in dojo, grill, team-orchestrate; PRO-id lineage comments in retro-week) — provenance that belongs in commit history, not a hot SKILL.md. The third is **single-fact-stated-N-times** (routing boundaries restated in description + body + Team-protocol across every persona lens). Pruning weakness is what drives most of the length overruns.
2. **pandastack conformance — 19/28 (68%), incl. 1 FAIL.** Almost entirely the **~80-line body budget**, not broken refs. The big bodies: retro-week (473), sprint (346), deepwiki (316), review (309), office-hours (280), boardroom (231). Lib/path refs resolve in the large majority of cases; the genuine *broken* refs are narrow and fixable — retro-month and retro-week both point at `~/site/skills/pandastack/scripts/retro-scan.sh` (canonical is the skillpack-root `scripts/...`), and skill-creator cites a dead `learnings/patterns/long-session-evals` path 3×. **retro-week is the only conformance FAIL:** the broken engine path plus a 473-line hot-bash body cross the hard bar. Frontmatter drift (`mode:` instead of `type:` in boardroom; missing `version`) is real but cosmetic and lint-tolerated.
3. **Completion criteria — 18/28 (64%), incl. 1 FAIL.** The pattern is **soft middle steps** — "do a quick sanity check", "if it revealed something useful", "predict the failure mode", "ground in team reality" — directives with no checkable done-state that invite premature completion. Persona lenses (ceo/product/design/ops/eng) all share this: their On-Invoke steps end on actions, not done-conditions. **init is the Completion FAIL:** its final step *prints* "pandastack initialized" without verifying the config block was appended or the dirs created — it asserts done instead of checking it.

**Strongest axes (what the corpus does right):**

1. **Predictability — only 3/28 weak (11%).** This is the corpus's spine and it holds. Almost every skill fixes a deterministic ordered process (numbered stages, fixed gather-state blocks, per-phase wait-gates, terminal-state contracts) so the *process* repeats even when the output varies. The three misses are routing non-determinism (boardroom's fuzzy `ops_dominant` keyword match), an unresolved `{learnings_dir}` path (review), and a self-contradicting write target (retro-week L18 vs L400) — not a vague core.
2. **Granularity — only 3/28 weak (11%).** Splits are disciplined: persona lenses share `lib/persona-frame.md` rather than copy it; heavy sub-phases (dojo/grill/review/ship) are split off `/sprint` by independent reach; modes stay as branches within one skill. The 3 misses are accretion (`.5` sub-phases in skill-creator) or an un-split heavy sub-protocol (careful's logging subsystem, retro-week's GC sweep), not fragmentation.
3. **Leading words — only 7/28 weak (25%).** The corpus leans hard on pretrained anchors that collapse a behavior region into a few tokens: "conductor", "STRIDE", "boil the lake", "leaky bucket", "pressure cooker", "whistle and a finish line", "every continue is a harness failure". These do real invocation+execution work, not decoration.

## Skills needing work

No skill earned an overall WEAK verdict, so "needing work" here means the heaviest axis-debt, ranked by severity. The two structural FAILs lead; the rest are the 5–6-weak-axis cluster.

1. **init** (engineering, Completion **FAIL**) — **top fix: replace the print-only finish with a real completion check.** Step 5 must assert the `## pandastack` block exists in the target config and the `docs/learnings/*` + `docs/checkpoints` dirs were created, *then* print success. As written, a failed Step 3/4 still reports "initialized". This is the only correctness-class defect in the corpus.
2. **retro-week** (productivity, Conformance **FAIL**, 6 dings) — **top fix: fix the broken engine path and the self-contradicting write target.** `~/site/skills/pandastack/scripts/retro-scan.sh` does not exist on disk (canonical is the skillpack-root `scripts/retro-scan.sh`), which also guts the "same brief every run" predictability claim; and L18 says Phase 3 writes `docs/retros/` while L400 actually writes `brain/reflections/weekly/`. Resolve the path via a skillpack-root variable, make both write targets read `brain/reflections/weekly/`, then move the 160-line GC-sweep sub-protocol and shell-portability sediment out of the 473-line hot body.
3. **careful** (engineering, 6 weak, no FAIL) — **top fix: split the stopping-discipline + continue-failure logging subsystem (L77–137) out of the destructive-action gate.** Two skills are welded into one; the second has its own leading word and trigger and is unreachable by the L3 description. Then cut the "Common Rationalizations" table.
4. **boardroom** (productivity, 5 weak incl. Predictability) — **top fix: make `ops_dominant` routing deterministic** (keyword-count threshold, or "if ambiguous, do NOT add ops-lead") — it is the one place same-process determinism breaks. Collapse the sequential-vs-panel distinction (restated 6×) to the single mode table; fix `mode:`→`type:` frontmatter.
5. **qa** (engineering, 5 weak) — **top fix: resolve the dangling `{learnings_dir}` / `type: pitfall` pointer** (L14) — link `lib/learning-format.md` (which exists) or inline the one rule. As written Step 5 dead-ends. Add a NOT-clause to the description to stop collision with verify/review/testing.
6. **deepwiki** (engineering, 5 weak) — **top fix: wire the existing-but-unreferenced `agents/system.md` / `agents/wiki-gen.md` / `agents/mermaid.md` via context pointers** and move the hot Phase-3 grounding essay + Phase-5 detail behind them. This is the single lever that pulls 316 lines toward budget and ends the duplication.
7. **skill-creator** (meta, 5 weak) — **top fix: repoint or drop the dead `learnings/patterns/long-session-evals` reference** (cited 3×) that backs its non-negotiable hot/cold rule — a rule that cites missing evidence erodes its own authority. Fold the `.5` accretion phases.
8. **using-pandastack** (meta, 5 weak) — **top fix: drop the four inlined on-demand subsystems (session-ritual, loop-guard, harness-evolution, overlay-extension, L47–131) behind context pointers**, matching the two pointers it already uses; the overlay block especially is install-time reference a router contract rarely needs hot. Replace the hardcoded "26 skills" count with count-free phrasing (it drifts on every skill add).

**Corpus-wide quick win (hits ~half the skills at once):** delete every "Common Rationalizations" table and `## Origin` changelog block. That single sweep clears the bulk of the Pruning debt (the 93%-weak axis) and pulls most over-budget bodies back toward the ~80-line guideline without touching any load-bearing step.

## What good looks like

Two skills earned **STRONG**, and they are the right two exemplars because they hit the discipline from opposite ends of the size scale:

- **freeze** (engineering, 39-line body) — *the minimal exemplar.* It does exactly one thing and says so in seven body lines: parse an edit allowlist, announce, then refuse out-of-scope edits with a fixed, greppable message and an explicit "never silently skip". The ordered On-Invoke sequence is deterministic, unfreeze is co-located as the obvious paired branch (no over-split), and there is zero sediment — no rationalizations table, no Origin block, nothing over-pushed. Its single soft spot (a leading word that restates the description) is the smallest weakness in the entire corpus. **This is the shape every guard/verb skill should converge toward: one job, one ordered process, one exact refusal string, nothing else.**

- **writing-great-skills** (meta, 48 non-blank lines) — *the self-applying exemplar.* It is the SSOT for the very scorecard everything else is judged by, and it obeys the discipline it teaches: it names the root virtue (predictability) **once** and never restates it, collapses its own restatements into leading words, and pushes every defined term to a single-source GLOSSARY via a context pointer instead of redefining inline. The scorecard is a faithful condensation — each of the 8 axes traces back to a named section above it, so skill-eval scores against the same vocabulary the prose builds and the two cannot drift. **It proves the rules are livable: a reference doc that practices its own pruning and progressive-disclosure rules under the same budget it imposes on others.**

The lesson the two share: STRONG is not earned by adding more, it is earned by cutting until only the load-bearing process remains. Every SOLID-but-debt-heavy skill above is one Pruning sweep and one Completion-check away from the same standard.
