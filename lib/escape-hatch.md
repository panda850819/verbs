# lib/escape-hatch.md — Hard-cap user-impatience protocol

> Shared module. Loaded by skills that ask the user multiple questions in sequence (`grill`, `office-hours`, `boardroom`, `gatekeeper`, `prep` / `dojo`). Defines a 2-strike hard cap: when the user signals enough, the skill stops asking and logs unprocessed items.
>
> Origin: gstack `office-hours` ships an embedded escape hatch (943 lines total). pandastack lifts the rule into shared lib so every interrogation skill obeys the same hard cap, no per-skill drift.

## When to load

Any skill where the model asks ≥2 questions in sequence and the user might reach a "stop asking" threshold:

- `grill` — adversarial drilling
- `office-hours` (default + `--quick`) — structured 5-stage flow, diagnostic pressure cooker
- `boardroom` (B4) — 4-voice critique with per-finding gates
- `gatekeeper` — `Apply? [Y/N/edit]` per-STRIDE-finding gate
- `prep` / `dojo` (B3) — pre-action clarification

Skip for skills that ask 0-1 questions (`ship`, `qa`, `done`).

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
Logging to OPEN_QUESTIONS in {output-file}.
Proceeding to {next stage / output}.
```

No follow-up question. No "are you sure?" No "one more thing". Skill proceeds to its terminal output stage with the unprocessed list logged.

### Anti-patterns (must not happen)

- ❌ Asking a 3rd time after strike 2 ("確定不問了？")
- ❌ Hidden ask ("好，那最後一個小問題..." — that IS asking again)
- ❌ Pretending to stop but writing more questions in the output ("Output also raises: ...")
- ❌ Escalating to a different skill / mode without permission ("switching to office-hours 因為你說 ship it" — no, ship it means stop, not switch)
- ❌ Logging unprocessed items as completed because user said skip ("we covered axis-N: skipped" — write `axis-N: not asked, user signaled stop after Q3` instead)

## Output contract

Skill must write OPEN_QUESTIONS section to its output file:

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

Companion to `lib/push-once.md` (which enforces minimum 1 push per axis). Push-once enforces depth on each axis; escape hatch enforces breadth ceiling. Together they bound interrogation: "push once minimum, escape hatch maximum".

## Origin

- gstack `office-hours` SKILL.md — embedded escape hatch repeated 5+ times in body
- pandastack 2026-05-03 `~/.agents/AGENTS.md` Response Discipline (v0.6.0) — escape hatch added at substrate layer
- pandastack 2026-05-04 — extracted to `lib/escape-hatch.md` for skill-level reference
