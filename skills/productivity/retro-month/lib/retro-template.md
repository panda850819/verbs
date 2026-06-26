# Phase 3 output template — monthly retro

Write `brain/reflections/monthly/$YEAR-$MONTH.md` (brain, not vault) using this shape. Every section traces to interview answers or Phase 1 scan data — never invent.

```markdown
---
date: $LAST_DAY
type: monthly-retro
month: $YEAR-$MONTH
range: $FIRST_DAY..$LAST_DAY
status: complete
prep_source: $(basename "$PREP")
scan_data: true
weekly_retros_referenced: [W$N, W$N-1, W$N-2, W$N-3]
---

# Monthly Retro $YEAR-$MONTH

## Git Activity Summary (30 days)
- [from Phase 1 scan: repos + commit counts]

## Learnings Health
- Total: N | New this month: N | Stale (90d+): N

## Weekly Retro Thread
- W[N]: [one-line recommendation + open question from that week's retro]
- W[N-1]: ...
- W[N-2]: ...
- W[N-3]: ...

## Goal Status (vs me.md)
- Goal A: [verdict from interview] — evidence + user's words
- ...

## Strategic Decisions This Month
- [decision] — context + downstream

## Drift Acknowledged or Rejected
- Acknowledged: [drift] → action: [修 / 接受]
- Rejected: [drift] → why user disagreed

## Project Memory Updates Applied
- `project_X.md`: [updated / superseded / archived] — what changed

## Feedback Patterns Status
- [pattern]: active (count: N) / resolved / archived

## Operating System Health
- Vault notes: N (Δ ±M)
- Cron health: list any failures
- Intake-to-knowledge promotion rate: P/N

## What Got 2x Better
> User's answer — verbatim.

## Strategic Shift for Next Month
> One shift, in user's words. Not a list.

## Commodity-drift Watch
> Skill or process user named as commoditizing in 6 months, plus whether a replacement is being built. Verbatim. Empty if none.

## Open Strategic Question
> What user is sitting with going into next month.
```
