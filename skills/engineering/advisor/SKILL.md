---
name: advisor
description: |
  Pull a decorrelated second opinion from a DIFFERENT model into the current session — the executor-calls-advisor pattern. Zero-config: self-locates the runtime seat and routes the call, never hardcodes a direction.
  - default: one cross-model consult on a load-bearing judgment (a design fork, a decision, "am I sure about this").
  - --panel: two mutually-blind cross-model critics on a PREPARED plan.
  Fires only on a LOAD-BEARING judgment (expensive-if-wrong: a design fork, a plan before you commit, an irreversible or outward-facing decision, keep-vs-rewrite) — reversible small calls just decide, no consult. Reach for the MOST INDEPENDENT model, not the nominally highest tier: from an Opus seat a different provider (Codex/GPT) usually gives more new signal than a same-family model. "get a second opinion", "red-team this", "多角度審". NOT code-diff review (use review), NOT sending mechanical build work out to Codex (use handover), NOT self-interview to sharpen a fuzzy idea (use grill).
reads:
  - skill: lib/gate-contract.md
  - skill: lib/model-anchors.md
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
- Adversarial critique of a PREPARED plan → advisor `--panel`.
- Review a code diff → `review`.
- Hand unfinished mechanical build work to Codex to DO → `handover`.
- Sharpen a fuzzy idea by self-interview → `grill`.

advisor never writes code, never commits, never touches git. It asks another model and returns the outside view; the caller decides. Never auto-incorporate a finding.

## Step 0: Locate the seat (zero-config)

Detect the current runtime only to guarantee that the outside opinion comes from a different model family:

- `CLAUDECODE=1` in env → **Claude seat**; reach out through the verified Codex transport.
- otherwise → **Codex seat**; reach out through the verified Claude transport.

This seat check chooses direction only. Authentication, budgets, and general
model-routing policy remain host concerns.

## Step 1: Select roles, then probe (fail loud, never silently self-review)

Select the complete role set before probing: default uses the one seat-derived
role from Step 2. A Claude-seat panel uses `advisor.panel.openai.fast` plus
`advisor.openai`; a Codex-seat panel uses `advisor.panel.fast` plus
`advisor.panel.deep`. Every panel critic therefore differs from the current
seat family. For every unique transport in that set, assert
the target binary is on PATH. Then read each row's minimum CLI version from
`lib/model-anchors.md`, parse `<name> --version`, and stop with
`ADVISOR: <name> <have> is below verified minimum <need> — upgrade required`
when it is missing, unparseable, or older. If a binary is missing, print
`ADVISOR: no cross-model binary on PATH (<name>) — judgment stays local, NOT self-reviewed`
and stop. A self-issued second opinion is not a second opinion; do not fake
decorrelation by asking the same model.

If the anchored call itself fails, emit the same banner with the command's
actionable error and keep the judgment local. Do not retry through the current
model or through an unpinned default.

## Step 2: Default — one cross-model consult

Read `lib/model-anchors.md`, select `advisor.openai` from a Claude seat or
`advisor.anthropic` from a Codex seat, and pass both its model and effort
explicitly. Pass the question + the minimum context + the specific fork. Narrow
in, structured out.

- Claude seat → direct `codex exec` with the `advisor.openai` anchor and its
  read-only sandbox guard.
- Codex seat → direct `claude -p` with the `advisor.anthropic` anchor, tools
  disabled, and session persistence off. Keep the call tight: one question,
  smallest sufficient context, a structured answer back.

Done when the outside view is returned as outside-voice, unincorporated. The
caller owns the decision.

## Step 3: --panel — blind cross-model critique

Only for a plan that is **expensive if wrong** (irreversible, outward-facing, multi-day). A daily plan uses the review pass built into `sprint`, not a panel. The panel is a forcing function, not a ritual.

Spawn two mutually-blind critics, each a **different model** and a **distinct
lens** (correctness / user outcome / simplicity / missing constraints / failure
modes + reversal). Cross-model is the point: same-model critics decorrelate only
the prompt, not the model's priors. Pick one likely-failure lens per critic.

- Select the seat-filtered two-role composition from Step 1. Use every row's
  model, effort, minimum version, and guard exactly. Synthesis and the
  per-finding gate stay in the main loop.
- Each critic gets the plan + its one lens + "find the strongest objection; default to finding a real problem", never the others' output. Inline any hard rule a critic needs — the subagent does not read your global config.
- **Keep every lone-critic finding.** A problem only one lens caught is the whole reason for the panel; never drop it as an outlier.
- Dedup across critics, rank by severity, present each as finding / evidence /
  suggested change, then use the exact per-finding gate from
  `lib/gate-contract.md`: `Apply? [approve / edit / reject / skip]`.
  Outside-voice findings are informational; the caller decides each.

Stop after the gated list. advisor returns judgment; it does not execute (that is `sprint`).
