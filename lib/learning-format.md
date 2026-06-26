# Learning File Format

All learnings are stored as markdown files with YAML frontmatter.

## File Location

Configured in CLAUDE.md under `## pstack`:
```yaml
learnings: docs/learnings    # default, can be any path
```

## Directory Structure

```
{learnings_dir}/
├── patterns/        # Reusable approaches
├── pitfalls/        # What NOT to do
├── architecture/    # Structural decisions
└── preferences/     # User-stated preferences
```

## File Format

```markdown
---
type: pattern | pitfall | architecture | preference
key: short-kebab-case-name
confidence: 1-10
source: observed | inferred | user-stated
skill: review | compound | ship
files:
  - path/to/relevant/file.ts
first_seen: YYYY-MM-DD   # first time this learning was hit (= created on day one)
recurrence: N            # times this same key recurred; starts at 1, +1 on each match
status: active           # active | stale — learning-refresh proposes stale; retro/human sets it
stale_reason: ...        # why it went stale (only when status: stale)
stale_date: YYYY-MM-DD   # when it was marked stale
created: YYYY-MM-DD
last_seen: YYYY-MM-DD
---

## Problem
1-2 sentences. Include observable symptoms.

## What Didn't Work
Failed approaches and WHY they failed. (Optional for patterns)

## Solution
The fix or approach, with code if useful.

## Prevention
How to catch this earlier next time.
```

## Confidence Scale

| Score | Meaning |
|-------|---------|
| 9-10 | Verified in code. Concrete evidence. |
| 7-8 | High confidence pattern. Very likely correct. |
| 5-6 | Moderate. Could be wrong. Show with caveat. |
| 3-4 | Low confidence. Suppress from review output. |
| 1-2 | Speculation. Only surface for P0 severity. |

## Source Types

| Source | Decays? | Meaning |
|--------|---------|---------|
| `observed` | Yes, -1 per 30 days | Found in code during review/debug |
| `inferred` | Yes, -1 per 30 days | AI deduction, not directly verified |
| `user-stated` | Never | User explicitly told us this |

## Writing Rules

- Only log genuine discoveries that would save time in a future session.
- Check for existing learnings with the same key before creating a new file.
- If a match exists, update the existing file: bump `last_seen`, **increment `recurrence`**, add context. Never open a second file for the same key — that is how the corpus turns into write-only sediment instead of a ratchet.
- Don't log obvious things or routine fixes.

## Reading Rules

- Calculate effective confidence: `max(0, confidence - floor(days_since_created / 30))`
- `user-stated` sources never decay.
- Skip learnings with effective confidence < 3.
- Skip `status: stale` learnings entirely (kept for provenance; `learning-refresh` flags them, retro/human sets them). Passive decay only *suppresses*; an explicit stale mark is the corpus correcting itself.
- A high `recurrence` (>= 2) marks a repeat offender — surface it even at lower effective confidence; a learning that keeps recurring has earned its place.
- When a learning matches the current work, display: "Prior learning: [key] (confidence N/10, recurrence M, from [date])"
