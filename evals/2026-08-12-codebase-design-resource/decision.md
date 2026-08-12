# Codebase Design resource decision

## Setup

Two matched design-seam cases used the same repository snapshot, prompt, Codex
CLI 0.144.4, `gpt-5.6-sol`, `high` effort, read-only sandbox, and ephemeral
sessions. Each case ran once without Skill guidance and once with the complete
`codebase-design` Skill body supplied directly.

Cases:

1. A job runner with 14 callers, one production queue provider, and deterministic retry/timeout test needs.
2. Feature flags spread across six handlers, one current environment source, and an uncommitted future remote provider.

Artifacts are the four `case-*.md` files beside this decision.

## Observed outcome

Both native arms produced a small concrete interface, placed the caller-facing
seam, hid shared policy, and described tests through injected dependencies. Both
also avoided adding a speculative provider abstraction. No primary-outcome or
critical-failure-prevention delta justified retaining a separate public route.

The guided arms were more consistent and concise about:

- the deletion test;
- depth as caller leverage rather than implementation size;
- locality of behavior and verification;
- the caller-facing interface as the test surface;
- one adapter as hypothetical evidence and two as a real varying seam.

## Decision

**Resource.** Move the vocabulary and principles to canonical
`lib/codebase-design.md`. Grill consumes it when a chosen approach adds or
changes a module interface or abstraction seam. Improve Codebase Architecture
consumes it while identifying deepening candidates. Remove the public route to
avoid overlapping direct design entry points while preserving the repeatable
design vocabulary.
