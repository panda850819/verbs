# Chinese AI Slop Patterns

> 24 patterns adapted from Humanizer-zh (op7418). Use during `/write edit` for Chinese articles.
> Source: https://github.com/op7418/Humanizer-zh

## Content Patterns

| Pattern | Example | Fix |
|---------|---------|-----|
| Exaggerated significance | "這具有深遠的影響" "這將徹底改變..." | State the actual impact concretely |
| Promotional/trend language | "引領潮流" "開創新紀元" | Cut or replace with specific fact |
| Shallow -ing analysis | "不斷演變" "持續發展" | Say what actually changed |
| Vague attribution | "業內人士指出" "專家表示" | Name the source or delete |
| Formulaic "challenges & outlook" | "挑戰與機遇並存" "未來可期" | Either commit to a prediction or end earlier |
| Generic conclusions | "總而言之，X非常重要" | Say something new or cut the section |

## Language Patterns

| Pattern | Example | Fix |
|---------|---------|-----|
| AI vocabulary | "賦能" "閉環" "抓手" "顆粒度" "底層邏輯" | Use plain language |
| Avoiding simple verbs | "進行了深入的探討" vs "討論了" | Use direct verb |
| Negation parallelism | "不是X，而是Y" overuse | Vary sentence structure |
| Rule-of-three | "更快、更高、更強" pattern everywhere | Break the rhythm, use 1 or 2 |
| Synonym cycling | Rotating "重要/關鍵/核心/至關重要" | Pick one, don't repeat the point |
| False scope | "從X到Y，從A到B" | Just state the scope directly |
| Dash / em dash | "AI——這個時代的..." / "X — Y" | **Banned.** Replace with comma, period, or line break. Panda never uses em dashes. |
| Bold overuse | Every key term bolded | Bold only 1-2 per section max |
| Inline headers as emphasis | "**核心觀點：**" mid-paragraph | Restructure into actual sections or remove |

## Style Patterns

| Pattern | Example | Fix |
|---------|---------|-----|
| Emoji decoration | "讓我們一起探索吧 🚀" | Remove all decorative emoji |
| List-ification | Every thought becomes a bullet list | Write in prose, reserve lists for truly parallel items |
| Over-formatting | Mix of bold, italic, headers, callouts in short text | Simplify to 1-2 formatting types |

## Communication Patterns

| Pattern | Example | Fix |
|---------|---------|-----|
| Chatbot traces | "好的，讓我來..." "以下是..." | Write directly, skip the preamble |
| Obsequious tone | "您提出了一個很好的問題" | Delete entirely |
| Over-hedging | "可能" "也許" "某種程度上" stacked | Commit or qualify once |

## Scoring (for self-check)

| Dimension | Max |
|-----------|-----|
| Directness — no filler, no preamble | 10 |
| Pacing — varied sentence length, not monotone | 10 |
| Reader respect — no over-explanation | 10 |
| Authenticity — sounds like a person, not a model | 10 |
| Conciseness — every sentence earns its place | 10 |

Score < 35 = needs another pass.
