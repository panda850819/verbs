---
name: advisor
description: |
  Pull a decorrelated second opinion from a DIFFERENT model into the current session — the executor-calls-advisor pattern. Zero-config: self-locates the runtime seat and routes the call, never hardcodes a direction.
  - default: one cross-model consult on a load-bearing judgment (a design fork, a decision, "am I sure about this").
  - --panel: 2-3 mutually-blind cross-model critics on a PREPARED plan (this replaced boardroom).
  Fires only on a LOAD-BEARING judgment (expensive-if-wrong: a design fork, a plan before you commit, an irreversible or outward-facing decision, keep-vs-rewrite) — reversible small calls just decide, no consult. Reach for the MOST INDEPENDENT model, not the nominally highest tier: from an Opus seat a different provider (Codex/GPT) usually gives more new signal than a same-family model. "get a second opinion", "red-team this", "多角度審". NOT code-diff review (use review), NOT sending mechanical build work out to Codex (use handover), NOT self-interview to sharpen a fuzzy idea (use grill).
reads:
  - repo: lib/gate-contract.md
  - cli: codex
  - cli: claude
writes:
  - cli: codex exec
  - cli: claude -p
  - cli: stdout
forbids:
  - cli: git commit
  - cli: git push
domain: shared
classification: read
user-invocable: false
---

# Advisor

## Routing Boundary

advisor pulls JUDGMENT in from a different model. It is the inbound half of the cross-runtime pair; `handover` is the outbound half (it sends mechanical build work OUT to Codex). Keep them distinct:

- Second opinion on a judgment / design fork / decision → advisor (default).
- Adversarial critique of a PREPARED plan → advisor `--panel` (this absorbed `boardroom`).
- Review a code diff → `review`.
- Hand unfinished mechanical build work to Codex to DO → `handover`.
- Sharpen a fuzzy idea by self-interview → `grill`.

advisor never writes code, never commits, never touches git. It asks another model and returns the outside view; the caller decides. Never auto-incorporate a finding.

## Step 0: Locate the seat (zero-config)

The economics flip by which runtime you are on, so detect it first — the direction is derived, never hardcoded:

- `CLAUDECODE=1` in env → **Claude seat** (metered). Your tokens are expensive; reach OUT to a flat-rate model for the opinion.
- otherwise → **Codex seat** (flat-rate). Your tokens are cheap; keep the bulk local, reach OUT only for the judgment.

## Step 1: Tool-parity probe (fail loud, never silently self-review)

Before crossing the boundary, assert the target binary is on PATH — Claude seat needs `command -v codex`, Codex seat needs `command -v claude`. If missing, print `ADVISOR: no cross-model binary on PATH (<name>) — judgment stays local, NOT self-reviewed` and stop. A self-issued second opinion is not a second opinion; do not fake decorrelation by asking the same model.

**Codex→claude gate (unverified arm):** the Codex-seat `claude -p` path is not yet verified on this machine (only the Hermes gateway print-mode path is known-good). On the Codex seat, additionally run `claude -p 'ping'` once; if it does not return cleanly, emit the banner above and keep the judgment local. Ship this arm only after the probe is green — until then the Codex seat degrades to "judgment stays local", loudly, never to self-review.

## Step 2: Default — one cross-model consult

Pass the question + the minimum context + the specific fork. Narrow in, structured out.

- Claude seat → `codex exec` a one-shot prompt (GPT, flat-rate, maximum decorrelation), or a Fable subagent when same-provider depth is what you want.
- Codex seat → `claude -p` a narrow prompt. The Claude side is metered, so keep the call tight: one question, smallest sufficient context, a structured answer back.

Return the outside view AS an outside view. The caller owns the decision.

## Step 3: --panel — blind cross-model critique (absorbs boardroom)

Only for a plan that is **expensive if wrong** (irreversible, outward-facing, multi-day). A daily plan uses the review pass built into `sprint`, not a panel. The panel is a forcing function, not a ritual.

Spawn 2-3 mutually-blind critics, each a **different model** and a **distinct lens** (correctness / does-it-reproduce · the user outcome · simplicity, is it over-built · what's-missing · failure-modes + reversal). Cross-model is the point: same-model critics decorrelate only the prompt, not the model's own priors. Pick the lenses the plan is most likely to fail on, one per critic.

- Default composition: 1 sonnet + 1 `codex exec` (GPT, flat-rate) + at most 1 opus. Synthesis and the per-finding gate stay in the main loop.
- Each critic gets the plan + its one lens + "find the strongest objection; default to finding a real problem", never the others' output. Inline any hard rule a critic needs — the subagent does not read your global config.
- **Keep every lone-critic finding.** A problem only one lens caught is the whole reason for the panel; never drop it as an outlier.
- Dedup across critics, rank by severity, present each as finding / evidence / suggested change, then per-finding gate (`lib/gate-contract.md`): `Apply? [Y / N / edit]`. Outside-voice findings are informational; the caller decides each.

Stop after the gated list. advisor returns judgment; it does not execute (that is `sprint`).
