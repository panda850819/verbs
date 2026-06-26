# Confidence Calibration

## Decay Formula

```
effective_confidence = max(0, confidence - floor(days_since_created / 30))
```

- `observed` and `inferred` sources lose 1 point every 30 days.
- `user-stated` sources NEVER decay. User preferences are permanent.
- Confidence floors at 0 (never negative).

## Display Rules

| Effective Score | Display Rule |
|----------------|-------------|
| 7-10 | Show normally in review output |
| 5-6 | Show with caveat: "Medium confidence — verify this is still relevant" |
| 3-4 | Suppress from main output. Include only if directly asked. |
| 1-2 | Only surface if severity would be P0 |
| 0 | Candidate for pruning in /ps:retro |

## Calibration Events

If a learning with confidence < 7 is confirmed as a real issue by the user,
that's a calibration event. Update the learning:
- Bump confidence to match reality
- Change source to `observed`
- Update `last_seen`

This makes future reviews more accurate over time.

## Staleness Detection

A learning is stale when:
1. Effective confidence < 3 (decayed too much)
2. Files referenced in `files:` field no longer exist in the repo
3. The pattern describes code that has been refactored away

`/ps:retro` checks for staleness and asks the user about each candidate.
Never auto-delete. Always ask.
