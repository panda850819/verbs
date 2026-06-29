---
type: skill-eval
skill: boardroom
bucket: productivity
evaluated_skill_hash: 4d1bca8d5780bcf8f4b866f2819a2def501471b8
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — boardroom

**Verdict: SOLID.** A tiny forcing-function skill: it packages the one capability the deleted persona-boardroom actually had — mutually-blind parallel critique — as ~30 lines with no persona machinery. Every step is a move the model skips by default (it accepts its own plan, runs one correlated review pass, or lets critics see each other): mutual blindness for decorrelated errors, distinct risk-surface lenses, keep-every-lone-finding, per-finding gate, stop-don't-execute. It carries no lore (none is needed — the value is the discipline), so it lives or dies on the forcing functions, and they hold.

| Axis | Verdict | Evidence |
|---|---|---|
| Description / invocation | pass | Front-loaded triggers (zh + en) with three NOT-clauses carving it from `review` (diff), `office-hours`/`grill` (fuzzy idea), and `sprint` (execute). The object — a prepared plan — is named, distinguishing it from every neighbour. |
| Predictability | pass | Fixed move every run: spawn N blind critics → synthesize keeping lone findings → per-finding gate → stop. No improvisation in the control flow. |
| Forcing-function integrity | pass | Each step overrides a real default: blindness vs groupthink/single-pass, distinct lenses vs N identical reviews, keep-lone-finding vs outlier-drop, gate vs auto-incorporate. None is restated pretrained advice. |
| Pruning | pass | ~30 lines, no persona contract, none of the sequential-vs-panel duplication that bloated the old boardroom; reuses `lib/gate-contract.md` rather than restating the gate. |

**Recommendations:** none. If a fixed count of 3 proves wrong for large plans, let the caller pass N; otherwise leave it fixed.
