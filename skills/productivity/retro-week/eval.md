---
type: skill-eval
skill: retro-week
bucket: productivity
evaluated_skill_hash: d08d94db646e25785175db9fc49b7646d6f8cbd2
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — retro-week

**Verdict: SOLID.** A well-gated multi-phase interview — every phase ends on an explicit "wait for user" gate and Phase 1.6 holds a strict propose-only / recurrence-gate discipline — but the leading "same brief every run" virtue is undercut: the engine path does not resolve and the skill contradicts its own write target. Plus the 473-line body of hot inline bash blows the pandastack length + hot/cold budget and carries ticket-id sediment.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | weak | L18 says Phase 3 writes to `docs/retros/`; L400 (the actual Phase 3 instruction) writes to `brain/reflections/weekly/$YEAR-W$WEEK_NUM.md`. The skill forks its own output destination with no gate — an agent that trusts the phase-summary overview writes to the wrong (and retired-vault) directory. L20's cross-runtime "same brief" claim is real for the _data source_ but rests on an engine path that does not resolve (see conformance fail), so run-to-run sameness is aspirational, not executable. |
| Description / invocation | weak | L3 — the three triggers ("/retro-week", "weekly retro", "weekly review") are one branch renamed; the rubric says collapse near-synonyms, only the slash command + one phrase earn their context load. |
| Completion criteria | pass | L317 — "**GC sweep 完了 … 準備好聊嗎？**" — wait for user; every phase ends on a literal user gate (also L68, L146, L349), no premature-completion bait. |
| Information hierarchy | weak | L164 — "Use -mtime -7 (BSD-compat). Do NOT use `-newer <(date ...)`…" portability commentary sits hot in SKILL.md; that is engine-script reference, not a step the agent reads inline. |
| Leading words | pass | L157 — "Garbage Collection Day" deliberately borrows Lopopolo's pretrained anchor (cited inline) to compact the whole convert-slop-to-mechanism sub-protocol into two words. |
| Pruning | weak | L196 — "Compound-loop GC fuel (PRO-42)" and the PRO-40/PRO-42 ticket lineage are sediment: provenance the runtime never obeys, paying load to say nothing. |
| Granularity | weak | L155 — Phase 1.6 (GC sweep) is a ~160-line sub-protocol with its own leading word and its own bash + tables; it earns a split off the main retro flow rather than living inline. |
| pandastack conformance | fail | L23 — `bash ~/site/skills/pandastack/scripts/retro-scan.sh week` points at a path that does not exist on disk (live copy is the worktree's `scripts/retro-scan.sh`); plus 473-line body vs the ~<80 budget and hot inline bash that should dispatch under hot/cold. |

## Why it's good
The load-bearing strength is the gate-and-discipline architecture, not the engine. The "propose only, never auto-write" rule (Ln 159, 321-324, 379) is restated at every surface where the agent might overstep, and completion is enforced by literal user-gate prompts at each phase boundary (Ln 68, 146, 317, 349) so the agent cannot silently chain past a checkpoint. The recurrence gate (Ln 230, count >= 2) gives the GC sweep a checkable threshold instead of "be selective". The cross-runtime engine (Ln 20-27) is the right design to remove run-to-run variance, but it is currently aspirational: the path it references does not exist on disk, so the "identical briefs across Claude/Codex/Hermes" benefit is not realized until the path is fixed.

## Top fixes
1. L23 — fix the engine path: `~/site/skills/pandastack/scripts/retro-scan.sh` does not exist (that `scripts/` dir holds many scripts but not this one; the live copy is the worktree's `scripts/retro-scan.sh`). Reference it relative to the skillpack root or via a resolved variable so it does not silently break post-merge; this is the hard fail and it also guts the predictability claim.
2. L18 vs L400 — reconcile the Phase 3 write target: the overview says `docs/retros/`, the actual step writes `brain/reflections/weekly/`. L20 itself declares the brain is the source and the vault is retired, so `docs/retros/` on L18 is stale sediment that mis-routes any agent reading the summary. Make both say `brain/reflections/weekly/`.
3. L164-201 — move the shell-portability commentary and PRO-40/PRO-42 ticket lineage into the engine script (or a `lib/` ref); the SKILL.md body should read process, not carry the engine's debugging sediment, which is the bulk of the 473-line overrun.
4. L3 — collapse the three synonym triggers to the slash command plus one canonical phrase; renaming one branch three times is pure context-load duplication.

## Behavioral cases
- trigger `/retro-week` → expected process: run `retro-scan.sh week` engine → print compressed scan → Phase 1.5 brain synthesis → Phase 1.6 GC sweep → Phase 2 one-question-at-a-time interview → Phase 3 write `brain/reflections/weekly/$YEAR-W$WEEK.md`.
- anti-trigger `monthly review` → should NOT fire (routes to `retro-month`); a same-session "save this note" / "ship this" routes to `ingest` / `ship`, not retro-week.
