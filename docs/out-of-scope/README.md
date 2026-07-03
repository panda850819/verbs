# Out-of-Scope KB

This directory records rejected directions as advisory precedent for future
skill and abstraction proposals. It is a lookup surface for agents, not an
enforcement surface.

`skill-creator` consults these entries before proposing a new skill or
abstraction. If a proposal matches an entry, surface that precedent first.

## Entry Format

Use one `<slug>.md` file per rejected direction:

```markdown
---
decided: YYYY-MM-DD
source: "ROADMAP.md:<line> - exact greppable phrase"
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
