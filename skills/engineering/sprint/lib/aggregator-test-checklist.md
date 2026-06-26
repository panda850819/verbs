# Multi-source aggregator dispatch-branch test checklist

Applies when a sprint adds a new dispatch branch / per-source handler / per-source filter to a multi-source aggregator (e.g. `if (source.name === "X")` ladder, per-source `evaluateX` filter, per-source `_setXClientForTest` mock seam).

**Rule**: handler-level integration test for the new branch is part of Stage 3 implementation, NOT Stage 4 review iter 2.

Cold reviewer empirically catches this as P0 every time the branch is added without the test (companyos sprints 3 / 5 / 6 = Notion / Slack / Linear all hit this same gap).

**Test shape**: drive `createCallToolHandler` (or equivalent) with one denied-input case + one allowed-input case, assert audit emit shape + that deny does NOT consume any cross-source state (pivot window / cache eviction).
