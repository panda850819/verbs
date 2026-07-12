---
decided: 2026-07-12
source: "https://github.com/panda850819/verbs/issues/220"
---

## What was rejected

Maintaining a fresh-user certification layer: release-artifact determinism
proof (`release-preflight.sh`), disposable-profile installer smoke matrices
(`installer-smoke.sh`), a portable hook-free `npx skills` surface, legal-files
release tests, the per-skill `eval.md` hash-freshness ceremony, and a v1.0
gate requiring three non-author users.

## Why

Verified fresh-user install count was 0 while this layer consumed the
majority of maintenance: 18 of 43 commits in the 2026-07-09..12 window were
release/smoke/preflight plumbing. Verbs stays a public, installable
marketplace product; its primary user is the author, so certification
obligations calibrate to that user. What remains: hook truth-table tests,
`doctor --strict` runtime parity, `verbs sync` determinism, the structural
lint suite, and the model-upgrade behavioral audit.

## What would reopen it

Real external users — repeated fresh-install attempts by non-authors with
issues filed against the install docs — or a deliberate decision to promote
Verbs as a supported public product with certification commitments.
