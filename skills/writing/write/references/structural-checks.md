# Structural Checks

> Structural toolkit for Spar / Structure / Edit modes. Run before building any skeleton, or as a diagnostic pass on a draft.

## 1. Spine Check — "What holds this article together?"

Every article needs ONE of these as its structural spine:

| Spine type | When to use | Example |
|---|---|---|
| **Operational principle** | Writing about systems, workflows, tools | "越懶越好" / "SSOT" / "blacklist > whitelist" |
| **Number inventory** | Writing about what you built/shipped | "53 skills, 11 tools, 40 workflows" |
| **Before → After delta** | Writing about transformation or results | "From 3h manual → 15min automated" |
| **Borrowed framework** (Alan Chan style) | Writing about strategy, learning, or industry analysis | Christensen's disruption / S-curves / PMF treadmill |
| **Unresolved tension** (Ping Chen style) | Writing about trade-offs, failures, or philosophical topics | "I automated everything but lost the craft feel" |

If you can't identify the spine, stop and ask: "What's the ONE thing holding this piece together?"

## 2. Opening Check — "Does the first sentence earn the second?"

| Pattern | Rating | Example |
|---|---|---|
| Number-first hook | Best for Panda | "53 個 AI 技能、11 個 CLI 工具" |
| Thesis-first (先講結論) | Strong | "先講結論：越懶的人越能發揮出 AI 真正的價值。" |
| Scene/anecdote | OK if short | "昨天半夜兩點我發現..." (max 2 sentences) |
| Generic topic intro | REJECT | "在 AI 快速發展的今天..." |

## 3. Closing Check — "Does the ending add something new?"

| Pattern | Rating |
|---|---|
| New insight not in the intro | Best |
| Call-to-action (try it, build it) | Good for operator pieces |
| Unresolved question (Ping Chen style) | Good for reflective pieces |
| Restate the intro | REJECT — either say something new or end one section earlier |

## 4. Rhythm Check — "Does it breathe?"

- At least one **one-sentence paragraph** per 500 words (let it breathe)
- No more than 3 consecutive paragraphs of similar length
- At least one **cross-domain one-liner** per article (an image from outside the topic)

## 5. Four-Quadrant Check — "Does each piece carry reader weight?"

For long-form pieces (>500 words) and X long posts (>200 words), every major section should hit all four quadrants:

| Quadrant | Question | Weak signal | Fix |
|---|---|---|---|
| **Problem** | Is the reader's pain named in the first 3 sentences? | Generic topic intro, no "you're doing X wrong" | Rewrite opening to name the pain |
| **Mechanism** | Is there a specific framework/model/sequence? | Vague "approaches" or "ways to think" | Name the framework or cut the section |
| **Proof** | Are there concrete numbers or named examples? | "Significant improvements" / "many users" | Add at least 1 specific number or named case |
| **Template** | Can the reader copy a step-by-step action? | Ends with "food for thought" / "供參考" | Add 3-7 numbered steps or cut the piece to commentary |

Missing 2+ quadrants → piece reads like commentary, not operator's log. Flag to user with which quadrant(s) are missing and suggest fix direction. Do NOT auto-fill quadrants with generic content.

**Short pieces exemption**: Skip this check for posts under 200 words. Short-form is Panda's natural voice main stage — forcing four quadrants makes it read like a KOL template.

## Source

Source: Shann Holmberg X analysis (2026-04-18). Updated 2026-05-11 with Content OS essay anchor → `[[people/shann-holmberg]]` · `[[media/articles/shann-content-os-bookmarkable-personalized]]`.
