---
name: decision-map
description: |
  Cross-session navigation route when one destination depends on several
  decisions whose dependencies or evidence cannot fit the current Grilling
  Session. Create a named map or resolve one human-selected unblocked entry,
  optionally through `prototype`; update the frontier and stop before implementation.
reads:
  - repo: AGENTS.md
  - skill: prototype
  - skill: lib/interview.md
writes:
  - repo: docs/briefs/**/*.md
  - cli: stdout
domain: shared
classification: exec
user-invocable: true
---
# Decision Map

A Decision Map preserves multi-session decision fog. Ordinary ambiguity stays
inside the automatic Grilling Session required by the repository Project
Contract.

## Create a map

1. Read `AGENTS.md`, apply the Brain First Rule, and name one destination.
2. Use `@lib/interview.md` to identify decisions whose answers depend on other
   decisions or evidence that cannot fit the current session.
3. If the Work Contract can be completed now, create no map; finish the current
   Grilling Session instead.
4. Otherwise create `docs/briefs/{YYYY-MM-DD}-{slug}-map.md` with the destination,
   confirmed context, and typed entries: `research`, `prototype`, `grilling`, or
   `task`. Each entry names dependencies, status, and its completion evidence.
5. Stop after creation. Do not select or execute an entry in the same invocation.

## Work a map

1. Read the map index and only the notes required by one unblocked entry.
2. Use the user-named entry, or ask the user to select one. Never schedule the
   frontier autonomously.
3. Resolve that entry by type. Research writes cited facts; prototype invokes
   `prototype`; grilling follows the Project Contract's Grilling Session;
   `task` records a confirmed Work Contract without implementing it.
4. Write the result under `docs/briefs/{map-slug}/{NN}-{entry-slug}.md`, update
   the map status and newly unblocked entries, then stop.

## Completion

A run completes when one map is created or one selected entry has checkable
evidence and the map reflects its new frontier. Implementation remains a new,
human-selected coding task governed by `AGENTS.md`.
