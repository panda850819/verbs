---
name: improve-codebase-architecture
type: flow
description: Produce a read-only visual survey of codebase architecture opportunities.
disable-model-invocation: true
reads:
  - repo: "**"
  - repo: CONTEXT.md
  - cli: git
  - skill: lib/codebase-design.md
  - skill: HTML-REPORT.md
writes:
  - fs: os-temp/architecture-review-*.html
  - cli: stdout
domain: shared
classification: hybrid
user-invocable: true
---
# Improve Codebase Architecture

Survey a repository for modules worth deepening. Produce one visual report;
do not edit repository files or design the chosen interface in this run.

Read `lib/codebase-design.md` first and use its module, interface, depth, seam,
adapter, leverage, locality, deletion-test, and test-surface definitions.

## 1. Bind the scan

Use a user-named subsystem, pain point, path, or upcoming spec as the scope. If
none is named, inspect at most the latest 100 commits and rank repeatedly changed
paths before reading code. Read `CONTEXT.md` and relevant repository
architecture-decision records when present. Record missing history or domain documents as evidence gaps.

Done when the report can name its scope, why those paths were selected, and
which domain and ADR evidence constrained the scan.

## 2. Find deepening or deletion-first candidates

Trace concepts through production callers, implementation, tests, external
effects, and current decision records. Look for wide interfaces, scattered
knowledge, pass-through modules, concrete dependencies crossing seams, and
behavior tests cannot alter through the caller-facing interface. Also look for
unused production surface, mirrored state, speculative public API, duplicate
lifecycle machinery, and hand-rolled infrastructure a maintained dependency
could replace with net deletion.

Keep a candidate only when repository evidence identifies all of:

- current friction and the files that demonstrate it;
- production consumers, or explicit evidence that tests/docs are the only users;
- the responsibility to localize, delete, collapse, demote, or replace;
- leverage across named callers/tests, or net deletion including remaining glue;
- current ADR/decision ownership and why the candidate does not discard an
  intentional seam or defensive guarantee;
- the deletion-test result: removal concentrates responsibility or deletes it
  without scattering required knowledge.

Merge candidates with the same seam or responsibility. Exclude style cleanup,
generic layering advice, unsupported dependency swaps, dormant code with no
named pressure, and decision-rejected directions without new evidence. Done
when every retained candidate passes every item or is discarded.

## 3. Rank honestly

Assign exactly one strength:

- **Strong:** repeated friction plus concrete caller/test evidence makes the
  locality and leverage gain clear.
- **Worth exploring:** the seam is evidenced, but payoff depends on an upcoming
  change or one unresolved constraint.
- **Speculative:** plausible signal with a named evidence gap; never choose one
  as the top recommendation.

If every result is Speculative, state that no investment-worthy candidate was
found and omit the top recommendation.

## 4. Render and stop

Read `HTML-REPORT.md`. Write a self-contained report with inline CSS and SVG to
`$TMPDIR/architecture-review-<timestamp>.html`, falling back to the platform OS
temp directory. Escape all repository-derived text. Use no CDN, remote asset,
or executable script. Open it with the platform command when available; a failed
open leaves the report valid and the absolute path visible.

Each card must contain files, evidence-backed friction, plain-language change,
production consumers or explicit evidence that tests/docs are the only users,
locality/leverage or net-deletion gain, test-surface effect, deletion-test
result, strength, a current-decision check, ADR conflict when present, and a
side-by-side Before / After
diagram. End with one top recommendation only when a non-Speculative candidate
exists.

Report the absolute path and stop. Ask the user to select one candidate; the
selected candidate belongs in a later `grill` session. That session reads
`lib/codebase-design.md` to choose the interface and seam.

## Native delta

Repository search can list complexity. This flow binds deepening and
simplification findings to consumer evidence, current decisions, deletion-test
evidence, honest ranking, and a visual artifact
while preserving a no-edit decision boundary.
