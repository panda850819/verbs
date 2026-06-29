# lib/inbox-template.md — team-orchestrate Inbox artifact

Write `Inbox/team-orchestrate-{slug}-{date}.md` using this skeleton:

```markdown
---
date: {YYYY-MM-DD}
type: team-orchestrate
topic: {topic}
branches: N
outcomes: {n_approved, n_rejected, n_skipped}
tags: [team-orchestrate]
---

# Team-orchestrate — {topic} — {date}

## Branch results

| Branch | Outcome | Commit / Note |
|---|---|---|
| 1 {title} | APPROVED | {commit} |
| 2 {title} | REJECTED | {reason} |
| ... | | |

## Independence audit

PASS / file-overlap details if FAIL

## Gate Log

{per-branch gate decisions}

## OPEN_QUESTIONS

{anything skipped or deferred}
```
