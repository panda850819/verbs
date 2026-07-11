# lib/push-once.md — Pushback patterns

> Shared module. Loaded by `grill` and `grill --brief`. Gives the model a fixed menu of 5 named pushback prompts to use when a first reply is rehearsed / vague / unsupported. Replaces ad-hoc improvised pushes with named, audit-able patterns.
>
> Origin: a gstack structured-brief precursor ships five pushback patterns.
> Verbs keeps the reusable pattern catalog here.

## When to load

Skills that take user input on a fuzzy / unverified claim and need to drill before accepting it. Specifically:

- `grill` Protocol step — a reply is rehearsed, vague, or unsupported
- `grill --brief` premise challenge — a claim needs one concrete challenge

Do NOT load for skills where input is already concrete (bug fix, typo, executing a confirmed plan).

## The 5 patterns

When a reply is shallow, the model selects one pattern using the priority below,
prints its label, and asks that exact prompt. Do not spend another turn asking
the user to choose a pattern.

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

1. When a reply matches a symptom in the table, select the highest-leverage
   matching pattern and print:

   ```
   Push [N] {pattern-name}: {the exact pattern prompt}
   ```

2. Wait for the answer. If the user says `skip`, accept the original reply and
   record `axis-N: accepted without push` in the emitted grill log.

3. For `[5]`, write a context-specific variant in the same shape.

## Anti-patterns

- ❌ Improvising outside the five-pattern catalog without using `[5]`
- ❌ Running 2 patterns in one message ("具體一點，而且你看過嗎？")
- ❌ Falling back to chat prose without picking from the menu
- ❌ Asking the user to choose a pattern before the model makes its own selection

## Relationship to escape hatch

Push-once is **before** the escape hatch. It challenges only a rehearsed, vague,
or unsupported reply. Escape hatch handles user signaling enough.

- Push-once: "unsupported reply, use one named challenge"
- Escape hatch: "user says 夠了, stop pushing, log unprocessed"

## Why a menu and not a rule

A rule ("push once before switching axes") leaves the prompt shape to the model, which improvises with drift over sessions. A 5-named-pattern menu:

- Audit-able: log records "Q3 pushed with pattern [3] reverse-premise" instead of "Q3 pushed with some prompt"
- Composable: same 5 patterns work across grill / `grill --brief`, so user learns the menu once
- User-correctable: if user prefers [3] always, they can say so; if [1] feels too aggressive in brief mode, can disable per-skill

This is the gstack residue lift: copy the discipline, not the body.

## Origin

- gstack structured-brief precursor (943 lines) — 5 pushback patterns embedded inside skill body, repeated 11x
- Verbs — shared by `grill` and `grill --brief`
