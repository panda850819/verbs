# Out-of-Scope KB

This directory records rejected directions as advisory precedent for future
skill and abstraction proposals. It is a lookup surface for agents, not an
enforcement surface.

Consult these entries before proposing a new skill or abstraction. If a
proposal matches an entry, surface that precedent first. Retain an entry while
it still prevents a tempting, plausible mistake and its reopen condition can
guide a future decision. Age, length, and quotas do not decide retention. When
a direction is obsolete or fully superseded, consolidate any unique rationale
into the current owner before removing it under normal repository review.

## Entry Format

Use one `<slug>.md` file per rejected direction:

```markdown
---
decided: YYYY-MM-DD
source: "<file>:<line>, issue, or PR URL - exact greppable phrase (git history counts for removed files)"
---

## What was rejected

<Rejected direction in current terms.>

## Why

<Reason from the source. Do not reconstruct from memory.>

## What would reopen it

<Evidence or condition that would justify revisiting after the 30-day decision
freeze.>
```

`source:` must point to a repo location, issue, or PR where the cited phrase is
greppable. Keep entries concise and update the original decision source when
the precedent changes.
