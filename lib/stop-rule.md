# lib/stop-rule.md — Per-decision AskUserQuestion gate

> Shared module. Loaded by skills that present multiple decisions and must NOT proceed by writing the recommendation in chat prose and silently continuing. Enforces explicit gates so the user's approval is load-bearing.
>
> Origin: gstack `office-hours` repeats "STOP. Wait for user response." 11× because long skills make the model forget halfway. pandastack lifts the rule into a shared lib so every multi-decision skill enforces it without per-skill duplication.

## When to load

Skills that present:

- ≥2 alternatives that need user choice (e.g. `office-hours` Stage 3)
- Per-finding apply gates (`review` Step 6.5, `gatekeeper` STRIDE findings, `boardroom` per-voice critique)
- Per-stage gates inside a flow command (`sprint`, `office-hours`, `prep` / `dojo`)

Skip for skills with single linear output (no decision branches).

## Core rule

**A "clearly winning option" is still an option decision.** Do NOT proceed to next stage by writing "I recommend A" + continuing. The user's explicit YES on A is what unlocks the next stage. Without it, you stop.

## Gate format (AskUserQuestion contract)

When presenting a decision:

```markdown
[Decision context — 1-3 sentences]

[OPTION A] {name}
  Summary: {1 line}
  Effort: {S/M/L}
  Pros: {bullets}
  Cons: {bullets}

[OPTION B] {name}
  ...

[RECOMMENDATION] {A/B/...} because {one-line reason}.

[STOP — waiting for user response]
Apply? [A / B / edit / skip / escape-hatch]
```

Then literally wait. Do not generate next-stage content in the same message. The user sees the gate, picks, and only then does the skill emit the next stage.

## Per-finding variant

When integrating multiple findings (review, codex, boardroom critiques):

```markdown
## Finding {n}: {summary}
**Verdict**: {informational}
**Patch**: {concrete change}

Apply? [Y / N / edit]
```

One finding per gate. Do NOT batch ("apply findings 1-5? [Y/N]"). Batching loses the per-finding visibility and the user can't tell which finding's patch they actually accepted.

## Anti-patterns

- ❌ "I recommend A, proceeding to Step 5..." — silent continuation, missed gate
- ❌ "Findings 1-5 applied automatically since they look correct" — batched, no gate
- ❌ "A is clearly better, no need to ask" — yes there is, the user might disagree
- ❌ "Asking inline within prose" — gate must be explicit `[STOP — waiting]`, not buried in a sentence
- ❌ "Re-asking same gate on the same decision" (after Y/N answered) — that's escape-hatch territory
- ❌ Skipping the gate format and using free-form ("what do you want to do?") — defeats the audit trail

## Logging

Each gate outcome goes into the skill's output file under a `## Gate Log` section:

```markdown
## Gate Log

- [Step 4 Alternatives] approved A (recommendation accepted)
- [Step 6.5 Finding 3] edit: changed patch X to X' before applying
- [Step 6.5 Finding 7] N → routed to OPEN_QUESTIONS
- [escape-hatch fired after Q5] — remaining axes logged as OPEN_QUESTIONS
```

This makes the skill output reproducible and auditable. Re-running the skill with the same inputs but different gate decisions produces a different log, not silent state.

## Relationship to escape-hatch

stop-rule enforces gate per decision. escape-hatch enforces a session-wide max-strike when user signals enough.

- stop-rule: "you must ask, not assume"
- escape-hatch: "you must stop asking when user says enough"

Both load together in interrogation skills (grill, office-hours, boardroom).

## Origin

- gstack `office-hours` SKILL.md — STOP rule repeated 11×
- pandastack `grill/SKILL.md` Step 4 — MANDATORY forced-alternatives + per-approach AskUserQuestion gate (2026-05-03)
- pandastack 2026-05-04 — extracted to `lib/stop-rule.md` so other multi-decision skills (review / boardroom / sprint / office-hours) ref the same contract
