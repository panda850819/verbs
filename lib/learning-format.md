# Learning Candidate Format

Panda Verbs emits this shape to stdout. It does not select a storage path or
write a learning file. A host/project may persist the candidate in its own
configured store.

## Optional host store

Configured in CLAUDE.md or AGENTS.md under `## verbs`:
```yaml
learnings: docs/learnings    # default, can be any path
```

If the host persists candidates, it may use a structure such as:

```
{learnings_dir}/
├── patterns/        # Reusable approaches
├── pitfalls/        # What NOT to do
├── architecture/    # Structural decisions
└── preferences/     # User-stated preferences
```

## Candidate Format

```markdown
---
type: pattern | pitfall | architecture | preference
key: short-kebab-case-name
confidence: 1-10
source: observed | inferred | user-stated
skill: review | debug | qa | ship | sprint
files:
  - path/to/relevant/file.ts
first_seen: YYYY-MM-DD   # first time this learning was hit (= created on day one)
recurrence: N            # times this same key recurred; starts at 1, +1 on each match
status: active           # active | stale — host policy proposes; human sets it
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

## Candidate Rules

- Emit only genuine discoveries that would save time in a future session.
- Search the host-configured store for the same key when one is available.
- A match emits `seen_again: <key>` plus the new context. The host decides
  whether to update `last_seen` or `recurrence`; the skill never mutates it.
- Do not emit obvious things or routine fixes.

## Reading Rules

- Calculate effective confidence: `max(0, confidence - floor(days_since_created / 30))`
- `user-stated` sources never decay.
- Skip learnings with effective confidence < 3.
- Skip `status: stale` learnings entirely (kept for provenance; flagged during retro, human sets them). Passive decay only *suppresses*; an explicit stale mark is the corpus correcting itself.
- A high host-provided `recurrence` (>= 2) marks a repeat offender — surface it
  even at lower effective confidence.
- When a learning matches the current work, display: "Prior learning: [key] (confidence N/10, recurrence M, from [date])"
