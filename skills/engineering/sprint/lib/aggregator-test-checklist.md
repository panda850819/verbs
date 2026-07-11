# Multi-source aggregator dispatch-branch test checklist

Applies when a sprint adds a new dispatch branch / per-source handler / per-source filter to a multi-source aggregator (e.g. `if (source.name === "X")` ladder, per-source `evaluateX` filter, per-source `_setXClientForTest` mock seam).

**Rule**: handler-level integration test for the new branch is part of Stage 3 implementation, NOT Stage 4 review iter 2.

A branch can pass its handler unit test while never being registered in the
aggregator's real dispatch path. The integration test below exists to catch that
exact false green.

**Test shape**: drive `createCallToolHandler` (or equivalent) with one denied-input case + one allowed-input case, assert audit emit shape + that deny does NOT consume any cross-source state (pivot window / cache eviction).
