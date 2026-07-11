# lib/escape-hatch.md — Hard-cap user-impatience protocol

> Shared module. Loaded by skills that ask the user multiple questions in sequence (`grill`, `grill --brief`, `gatekeeper`). Defines a 2-strike hard cap: when the user signals enough, the skill stops asking and logs unprocessed items.
>
> Origin: a gstack structured-brief precursor shipped an embedded escape hatch
> (943 lines total). Verbs keeps the rule in one shared lib.

## When to load

Any skill where the model asks ≥2 questions in sequence and the user might reach a "stop asking" threshold:

- `grill` — adversarial drilling
- `grill --brief` — structured brief flow, diagnostic pressure cooker
- `gatekeeper` — `Apply? [approve/edit/reject/skip]` per-finding gate
Skip for skills that ask 0-1 questions (`ship`, `qa`).

## User triggers

Any of these phrases (case-insensitive, exact or substring match):

```
夠了 / 不要再問 / 別問了 / 跳過 / skip / skip the questions /
ship it / just do it / 直接做 / 不用問 / enough / stop asking /
i'll deal with it / proceed / move on
```

## Protocol — 2 strikes hard cap

### Strike 1 (acknowledge once, ask top-2, then stop)

Model output template:

```
聽到。剩 2 題收：
1. [most critical unanswered question]
2. [second most critical]

Pattern: __ / [skip both]
```

Wait for user reply. If user answers both, log + stop. If user answers `skip both`, log + stop. If user gives a third "夠了" within strike-1 turn, escalate to strike 2 immediately.

### Strike 2 (stop immediately, log)

Model output:

```
停。Unprocessed: [list of axes / questions not asked]
Logging to OPEN_QUESTIONS in the terminal output or active artifact.
Proceeding to {next stage / output}.
```

No follow-up question. No "are you sure?" No "one more thing". Skill proceeds to its terminal output stage with the unprocessed list logged.

### Anti-patterns (must not happen)

- ❌ Asking a 3rd time after strike 2 ("確定不問了？")
- ❌ Hidden ask ("好，那最後一個小問題..." — that IS asking again)
- ❌ Pretending to stop but writing more questions in the output ("Output also raises: ...")
- ❌ Escalating to a different skill / mode without permission ("switching to brief mode 因為你說 ship it" — no, ship it means stop, not switch)
- ❌ Logging unprocessed items as completed because user said skip ("we covered axis-N: skipped" — write `axis-N: not asked, user signaled stop after Q3` instead)

## Output contract

Skill must emit an OPEN_QUESTIONS section. If the active mode already writes an
artifact, include it there; otherwise keep it in terminal output:

```markdown
## OPEN_QUESTIONS (escape-hatch triggered)

Stopped at user request after Q{n}. The following axes / premises / findings were not processed:

- {axis-name} — {short reason it would have mattered}
- ...

Re-run skill with `--continue` flag (where supported) to pick up where left off, or address these in next session prep.
```

Never let unprocessed items disappear silently. Even if the user signaled stop, the existence of unprocessed work is part of the audit trail.

## Why hard-cap and not soft-cap

Soft caps ("ask user nicely if they want one more") drift over sessions because the model keeps finding "just one more critical question". A hard cap with 2 strikes:

- Removes model judgment from "should I ask again"
- Makes the user's escape signal load-bearing (they know it works, they use it freely)
- Enforces output contract (unprocessed items always logged)
- Compresses to a rule the user can hold in their head

Companion to `lib/push-once.md`, which supplies a fixed pushback catalog when
an answer is vague or unsupported. The escape hatch sets the breadth ceiling.

## Origin

- gstack structured-brief precursor — embedded escape hatch repeated 5+ times in body
- pandastack 2026-05-03 `~/.agents/AGENTS.md` Response Discipline (v0.6.0) — escape hatch added at substrate layer
- pandastack 2026-05-04 — extracted to `lib/escape-hatch.md` for skill-level reference
