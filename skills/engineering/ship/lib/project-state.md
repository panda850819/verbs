# project-state mechanics

`project-state` lives at `~/.local/bin/project-state`. It does the markdown surgery on a brain project page deterministically so the page's table is never hand-edited:

- Refreshes the STATE baton and appends one dated METRICS row, idempotent per day.
- Auto-skips the METRICS row for repo-backed projects (the page declares its repo as the state SSOT) and only refreshes `next`.

Derive `done` / `open` / `blocked` from the project's own tracker (its `## Status` / `## Open` sections, or the repo if repo-backed).
