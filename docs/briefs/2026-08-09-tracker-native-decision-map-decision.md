# Tracker-native Decision Map decision

Date: 2026-08-09  
Issue: [#349](https://github.com/panda850819/verbs/issues/349)  
Blocked-by evidence: [#348](2026-08-09-github-frontier-query-evidence.md)  
Status: DEFER — keep repository Markdown as Wayfinder's canonical map

## Decision

Do not build or adopt a tracker-native Wayfinder map now. No synchronization,
duplicate-work, or shared-editing failure is recorded, so a disposable GitHub
copy would test presentation preference without an observed problem. Keep
`docs/briefs/{date}-{slug}-map.md` and its detail-note directory as Wayfinder's
canonical artifact. Keep GitHub Issues canonical for Specs and implementation
ticket graphs.

This is a defer decision. Reopen only after a real Markdown-map collaboration
failure. Concurrent advancement alone is insufficient; it must first produce
one of the named failures below. Then use that failing real map as the prototype
input and keep Markdown canonical until the comparison is complete.

## Evidence used instead of a new disposable graph

The historical Verbs v1 direction map is the only real multi-session map with
enough typed entries, blockers, detail notes, and decisions to exercise the
question. It was originally worked one entry per session and now remains a
historical decision record:

- index: `docs/briefs/2026-07-13-verbs-v1-direction-map.md`;
- twelve typed entries with blocker and status metadata;
- separate detail notes under
  `docs/briefs/2026-07-13-verbs-v1-direction-map/`;
- later reconciliation moved the executable queue to GitHub Issues without
  moving the decision record itself.

Existing native GitHub graphs #265 -> #266/#267/#268/#269 and #283 -> #284/#285
already demonstrate the alternate mechanics without creating throwaway Issues.
They show native parent and blocker integrity for implementation work, but they
do not show that moving the Wayfinder artifact prevents any failure.

Creating another graph would mutate the public tracker, generate notifications
and cleanup work, and duplicate a canonical historical record. The prototype's
own precondition is therefore unmet.

## Comparison

| Dimension | Repository Markdown map | GitHub Issue graph | Current verdict |
|---|---|---|---|
| Frontier visibility | Requires reading statuses and blockers in one index; adequate for the observed solo sessions. | Native filters and GraphQL can list relations, but #348 found that complete verification still needs relation reads. | No observed visibility failure justifies migration. |
| Detail-note ergonomics | One compact index links unconstrained repository-local notes and diffs review cleanly. | Child Issues can hold detail, but discussion, decision record, and executable work share one tracker surface. | Markdown better preserves the current decision-record/work-queue split. |
| Blocker integrity | Prose links can drift and have no server validation. No drift caused duplicate or invalid work in the real map. | Native dependencies reject some invalid relations and expose exact edges through GraphQL. | GitHub has a mechanical advantage without demonstrated user impact. |
| Concurrent editing | Git merge conflicts expose simultaneous edits; there is no claim protocol. | Independent Issues reduce index conflicts and assignees could signal ownership. | The repository has no concurrent-map collision; #348 found no evidence for assignee-as-claim. |
| Offline readability | Complete map and notes remain available, searchable, versioned, and reviewable with the checkout. | Full reading requires GitHub/API access or a separate export. | Markdown wins for the current product boundary. |
| API and latency | No API cost after checkout. | Fully qualified filters work for partial views; one complete batched native read took 0.539 s and one GraphQL point in #348. Writes and cleanup add external-state cost. | Query cost is small, but still buys no observed outcome lift. |
| Human attention | Decision work stays outside the executable Issue queue until it graduates. | Map nodes, Specs, implementation tickets, and product defects compete in one queue and notification stream. | Markdown better preserves queue meaning for a solo maintainer. |

## Product-boundary check

Wayfinder owns decision fog and stops after one entry. `to-spec` owns the one
canonical GitHub Spec Issue; `to-tickets` owns an approved implementation Issue
graph and reports without claiming work. Moving Wayfinder into Issues would add
a tracker dependency and blur those artifact boundaries before evidence shows
that the current split fails.

The earlier direction map proposed tracker-native maps and assignee-as-claim.
The shipped skills-only product later chose explicit human selection and a
Markdown Wayfinder artifact. #348 found no duplicate-claim case and no query
failure requiring that decision to be reversed.

## Reopen and prototype conditions

Reopen only with one named failure, such as:

- two actors edit or advance the same map and lose or duplicate a decision;
- a blocker/status drift causes the wrong frontier entry to be worked;
- a repository-only map prevents a required collaborator from reading or
  contributing;
- map-to-Spec handoff repeatedly loses detail because the artifact is not on the
  tracker.

Then build one disposable GitHub representation of that exact failing map and
compare both forms while preserving:

- one-entry close;
- typed entries and explicit blockers;
- full detail notes and decision gists;
- human selection and stop boundaries;
- offline export or a deliberate decision to give it up;
- cleanup and rollback steps.

A production migration would still require a separate Spec because it changes
Wayfinder's canonical artifact and external dependency.
