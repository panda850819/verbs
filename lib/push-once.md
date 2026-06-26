# lib/push-once.md — Pushback patterns

> Shared module. Loaded by `grill`, `office-hours`, `boardroom`. Gives the model a fixed menu of 5 named pushback prompts to use when a first reply is rehearsed / vague / unsupported. Replaces ad-hoc improvised pushes with named, audit-able patterns.
>
> Origin: gstack `office-hours` ships 5 pushback patterns inside the skill body (943 lines total). pandastack lifts the residue (the 5 patterns themselves) into a shared lib so multiple skills can ref it without duplicating the body.

## When to load

Skills that take user input on a fuzzy / unverified claim and need to drill before accepting it. Specifically:

- `grill` Protocol step — first reply on any axis
- `office-hours` Stage 2 (Premise challenge) — first claim
- `boardroom` per-voice critique — when a voice's first take is too soft

Do NOT load for skills where input is already concrete (bug fix, typo, executing a confirmed plan).

## The 5 patterns

Print these to the user as a numbered menu when the first reply is shallow. Model picks one (or asks user to pick) and uses that exact prompt as the next message.

```
[1] 具體一點    — "給我名字、數字、case 編號。沒有具體例子等於沒講。"
[2] 證據檢查    — "你看過嗎？哪個 case？什麼時候？讀的還是聽的？"
[3] 反命題      — "拿掉這個假設會怎樣？這個前提成立的根據是什麼？"
[4] 邊界條件    — "什麼情況下這個會不成立？哪些 user / size / time / 條件不適用？"
[5] 自由發問    — "我寫一個更尖的問題：{model 自己針對當下 context 寫}"

或：self — user 自己接著寫，model 不發 push。
```

## Pattern selection rules

| Symptom in first reply | Pick pattern |
|---|---|
| 抽象名詞 / 形容詞滿天飛（"很多 user 說"、"通常"、"普遍"）| [1] 具體一點 |
| 引用未驗證 / 二手 / 來源模糊（"聽說"、"我朋友"、"據說"）| [2] 證據檢查 |
| 前提沒挑戰過 / 假設當公理（"當然要 X"、"這個 obvious"）| [3] 反命題 |
| 涵蓋面講太滿 / 沒邊界 / 一刀切（"all"、"every"、"100%"）| [4] 邊界條件 |
| 以上都不切 / context 特殊 / 需要更尖的問法 | [5] 自由發問 |

If 2+ symptoms present, pick the highest-leverage one (usually [3] reverse-premise > [4] boundary > [2] evidence > [1] specifics). Run one pattern, wait for the answer, pick the next pattern based on the new reply.

## Output protocol

When loading this lib in a skill:

1. After user's first reply on any axis, model prints:

   ```
   First reply detected. Pick a push pattern:

   [1] 具體一點    — give me names / numbers / cases
   [2] 證據檢查    — have you seen it? which case?
   [3] 反命題      — what if we remove that assumption?
   [4] 邊界條件    — where does this NOT apply?
   [5] 自由發問    — model writes a sharper one
   [self] I'll push myself

   Pattern: __ (or "skip" to accept reply as-is)
   ```

2. User picks. Model uses that pattern as the literal next prompt.

3. If user picks `[5]`, model writes a context-specific variant in the same shape (specific → demand reality, evidence → demand source, reverse → strip assumption, boundary → find counter-case).

4. If user picks `skip`, model proceeds without pushing — but logs `axis-N: accepted on first reply` to the grill log so the absence of push is auditable.

## Anti-patterns

- ❌ Skipping the menu and improvising a push from scratch (defeats the audit trail)
- ❌ Running 2 patterns in one message ("具體一點，而且你看過嗎？")
- ❌ Falling back to chat prose without picking from the menu
- ❌ Asking the user "want me to push?" — that's escape hatch territory, not push-once

## Relationship to escape hatch

Push-once is **before** the escape hatch. Push-once enforces minimum-1 push per axis. Escape hatch handles user signaling enough after multiple pushes have happened.

- Push-once: "1st reply rehearsed, must push once"
- Escape hatch: "user says 夠了, stop pushing, log unprocessed"

If user triggers escape hatch BEFORE the model has done 1 push on any axis, that's a signal the menu was too noisy or the timing was wrong. Log to `Inbox/feedback-log.md` for retro review.

## Why a menu and not a rule

A rule ("push once before switching axes") leaves the prompt shape to the model, which improvises with drift over sessions. A 5-named-pattern menu:

- Audit-able: log records "Q3 pushed with pattern [3] reverse-premise" instead of "Q3 pushed with some prompt"
- Composable: same 5 patterns work across grill / office-hours / boardroom, so user learns the menu once
- User-correctable: if user prefers [3] always, they can say so; if [1] feels too aggressive in office-hours, can disable per-skill

This is the gstack residue lift: copy the discipline, not the body.

## Origin

- gstack `office-hours` SKILL.md (943 lines) — 5 pushback patterns embedded inside skill body, repeated 11×
- pandastack 2026-05-04 — extracted to `lib/push-once.md`, refed by `grill`, `office-hours` (B5), `boardroom` (B4)
