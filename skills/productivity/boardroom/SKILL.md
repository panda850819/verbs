---
name: boardroom
description: |
  Get independent, mutually-blind critique of a PREPARED plan before you commit.
  Triggers: critique this plan, 多角度審這個 plan, stress-test the plan, red-team
  this, poke holes in this, panel review, 找這個方案的問題. NOT for code-diff
  review (use `review`), a fuzzy idea with no plan yet (use `office-hours` /
  `grill`), or executing an approved plan (use `sprint`).
reads:
  - repo: lib/gate-contract.md
user-invocable: false
---
# Boardroom

A plan you wrote, you accept — your own blind spots are invisible to you, and a single review
pass shares them. This forces independent critique you cannot self-generate.

## The move

Spawn N mutually-blind critics (default 3) on the plan, each a distinct lens, each told to surface
the strongest objection — what breaks, what's missing, what's over-built. Then gate.

- **Mutually blind.** Each critic gets the plan + its one lens, never the others' output. Blindness is
  the point: it decorrelates their errors. Critics that see each other converge (groupthink); a single
  reviewer has one set of blind spots.
- **Distinct lenses, picked by the plan's risk surface** — e.g. correctness / does-it-reproduce, the
  user outcome, simplicity (is it over-built), what's-missing, failure modes + reversal. Not fixed
  roles; choose the 3 angles this plan is most likely to fail on, one per critic.
- **Each critic returns its single strongest finding plus 2-3 lesser ones**, each with the concrete
  evidence (the plan line / assumption it attacks), not adjectives.

Dispatch all N in one message: parallel `Agent` calls, `subagent_type: "general-purpose"`, each prompt =
the full plan + that one lens + "find the strongest objection; default to finding a real problem." The
subagent does not read `~/.agents/AGENTS.md`, so inline any hard rules a critic needs.

## Synthesize and gate

- Dedup across critics, but **keep every lone-critic finding** — a problem only one angle caught is the
  whole reason for the panel; never drop it as an outlier.
- Rank by severity. Present each as: finding, evidence, suggested change.
- **Per-finding gate** (`lib/gate-contract.md`): `Apply? [Y / N / edit]`. Outside-voice findings are
  informational — never auto-incorporate; the caller decides each.

Stop after the gated list. Boardroom returns findings; it does not execute them (that is `sprint`).
