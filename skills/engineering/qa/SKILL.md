---
name: qa
description: Verify browser-visible acceptance on the current artifact using host browser automation; preserve evidence for PR delivery.
capability_required:
  - host browser automation
user-invocable: true
---
# QA

Bind checks to the user request, issue, or brief and current artifact. Missing intent or unavailable browser automation is an explicit gap, not a pass. Use native tests for non-UI behavior and `review` for the diff.

Test relevant user flows, error/empty/loading states, edge inputs, double submission, keyboard navigation, and console errors. UI acceptance includes 320px reflow, 200% zoom, shipped locales, and reduced motion where motion exists. Record actual viewport, locale, and state rather than claiming generic mobile coverage.

Use deterministic assertions or accessibility snapshots when they prove the property; use screenshots for visual properties. Emit one `STEP_PASS|id|evidence`, `STEP_FAIL|id|expected -> actual`, or `STEP_SKIP|id|reason` per check. These markers are the worker/handoff interface, not a required conversational transcript.

Run directly unless independent test groups benefit from parallelism and browser-session isolation is proven. Workers receive only their test group, artifact, acceptance criteria, session boundary, and budget. They do not share browser sessions; unfinished checks are skipped with reasons, never passed.

Use [the QA evidence format](lib/qa-evidence-format.md) for failure screenshots, bug actions, criterion statuses, totals, artifact identity, and the handoff at `git rev-parse --git-path verbs/qa-evidence.md`. Every criterion must have current `PASS`, `FAIL`, or `UNPROVEN` evidence. A later code change invalidates affected evidence until rerun.

Apply the reference's `AUTO-FIX`/`ASK` boundary and retest fixes. QA does not publish to GitHub; `ship` owns the authorized PR upsert. Report failures and gaps concisely; keep the full evidence in the handoff.
