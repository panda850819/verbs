---
slug: dispatch-map-signal-split
date: 2026-07-31
type: plan
source: grill
brief: docs/briefs/2026-07-31-dispatch-map-signal-split.md
execution: code
status: shipped
delivered_by: https://github.com/panda850819/verbs/pull/293
---

# Dispatch map-signal split — executable plan

> WHAT only. WHY is in the brief (`brief:` above). Agents read this file;
> per-task `status:` is DERIVED from git at execute time, never hand-edited
> mid-sprint.

Target wording, so every acceptance check below is greppable:

- Row 7 keys on visible map language only.
- Row 8 explicitly absorbs a large effort that has no map yet.

## Tasks

### dispatch-map-signal-split-T01 — Narrow DISPATCH row 7, widen row 8
- scope: `DISPATCH.md` rows 7 and 8 only
- acceptance: `grep -q 'a large effort with no map yet' DISPATCH.md` succeeds
  AND `grep -c 'Large/fuzzy effort spanning sessions' DISPATCH.md` is 0
- depends-on: none
- status: todo

### dispatch-map-signal-split-T02 — Align RESOLVER with the split
- scope: `RESOLVER.md` selection rule 2 and the `verbs:wayfinder` catalog row
- acceptance: `grep -q 'A large effort with no map still enters' RESOLVER.md`
  succeeds AND `grep -c 'spans multiple decisions or sessions' RESOLVER.md` is 0
- depends-on: dispatch-map-signal-split-T01
- status: todo

### dispatch-map-signal-split-T03 — Assert the route, mutation-proof
- scope: `tests/resolver-routes-test.py`
- acceptance: the test appends a failure when the wayfinder dispatch row carries
  generic fuzzy language, proven by a seeded-mutation self-check in the same
  shape as the existing `retired_routes("Run /office-hours now.")` line;
  `python3 tests/resolver-routes-test.py` exits 0 on the real tree, and exits
  non-zero when row 7's old text is restored
- depends-on: dispatch-map-signal-split-T01, dispatch-map-signal-split-T02
- status: todo

### dispatch-map-signal-split-T04 — Version, sync, changelog
- scope: `manifest.toml`, `.claude-plugin/`, `.codex-plugin/`, `.agents/plugins/`,
  `CHANGELOG.md`
- acceptance: `manifest.toml` reads `version = "0.19.3"`; a second
  `python3 scripts/verbs sync` reports no files to sync; `bash tests/run-all.sh`
  reports 0 failed
- depends-on: dispatch-map-signal-split-T03
- status: todo
