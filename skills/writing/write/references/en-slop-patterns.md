# English AI Slop Patterns

> Vocabulary blacklist for English writing. Companion to `zh-slop-patterns.md` (Chinese). Load during `/write edit` Layer 1 vocabulary scan when draft contains English prose.

Zero tolerance — every match gets flagged.

## Wrapper phrases

| Pattern | Action |
|---|---|
| "It's worth noting that" / "It bears mentioning" | Delete the wrapper, keep the content |
| "In today's rapidly evolving landscape/world/era" | Delete entire sentence |
| "Let's dive in" / "Let's explore" / "Let's unpack" | Delete |
| "In conclusion, X is important" | Say something new or end earlier |

## Sequence / structure tells

| Pattern | Action |
|---|---|
| "Furthermore" / "Moreover" / "Additionally" in sequence | Keep max one, cut rest |
| "On one hand... on the other hand" (without real tension) | Commit to the opinion |
| "It might perhaps be possible" (hedge stack) | Commit or qualify once |

## Word-level

| Pattern | Action |
|---|---|
| "Leverage" as verb (when "use" works) | Replace unless used deliberately |
| "Robust" / "Streamline" / "Utilize" / "Facilitate" | Replace with plain English |
| "Game-changer" / "Paradigm shift" / "Revolutionary" | Delete or state the actual change |
| Em dash (— or ——) anywhere | **Banned.** Use comma, period, or line break. |

## Voice test (Layer 3 reminder)

After the vocabulary scan, compare against the resolved voice profile. With no profile, ask only whether the sentence is plainer and more specific than the original; do not invent an author voice.
