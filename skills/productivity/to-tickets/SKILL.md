---
name: to-tickets
description: |
  Decompose one canonical GitHub Spec Issue into approved child implementation Issues and blocking edges. Use when a complete Spec is ready for vertical-slice ticketing. Do not use for requirements discovery, Spec publication, scheduling, or implementation.
reads:
  - repo: AGENTS.md
  - repo: CLAUDE.md
  - repo: .git/config
  - skill: setup-verbs
  - cli: git
  - cli: gh
writes:
  - cli: gh issue create
  - cli: gh api
  - cli: stdout
domain: shared
classification: exec
user-invocable: true
disable-model-invocation: true
---

# To Tickets

Turn one complete canonical Spec Issue into a dependency graph of independently
deliverable implementation Issues. Present the graph once before writing.
Publication does not claim, schedule, or execute any frontier Issue.

## 1. Bind the source

Require one unambiguous `tracker: github` in the root `## verbs` block; invoke
`setup-verbs` and stop when configuration is missing or conflicting. Derive
the repository from Git and verify authenticated GitHub access.

Read the entire source Issue and require substantive `Problem`, `Solution`,
`User Stories`, `Implementation Decisions`, `Testing Decisions`,
`Out of Scope`, and `Further Notes` sections. Confirm it declares itself the
only requirements source of truth. On any gap, report the missing section and
stop; do not interview, rewrite, or close the parent.

Search existing open and closed Issues for children naming this parent. Reuse
an Issue on retry only when its body contract and approved outcome match.
Otherwise stop on a publication conflict rather than duplicating or silently
adopting stale scope.

## 2. Design vertical slices

Each proposed implementation Issue must:

- deliver one observable behavior through every required layer, rather than
  one horizontal component;
- have acceptance evidence runnable independently;
- fit one fresh-context Sprint;
- map to one independently reviewable and revertible PR;
- name its parent, outcome, scope, acceptance criteria, blockers, and explicit
  exclusions.

Split only when review/revert independence or blast radius differs. Keep
several inseparable parts in one Issue.

For a wide mechanical refactor that cannot form honest vertical slices, use:

```text
expand (add the compatible seam)
  -> migrate batch 1..N (bounded, behavior-preserving batches)
  -> contract (remove the old seam after every migration)
```

Every migrate batch depends on expand; contract depends on every batch.

Build a directed acyclic graph. A blocker must represent a real prerequisite,
not preferred ordering. Reject cycles and tickets whose acceptance depends on
unwritten future work.

## 3. Preview and approve

Show every proposed title, outcome, acceptance set, exclusion, and
`blocked by` edge, followed by the computed initial frontier. Ask once:
`[publish / reject]`.

- `publish`: create this exact graph.
- `reject`: create nothing and stop.

No Issue may be created before approval.

## 4. Publish the graph

Create each implementation Issue with this body contract:

```markdown
## Parent
#<spec-number>

## Outcome
<one independently verifiable vertical slice>

## Acceptance criteria
- [ ] <observable proof>

## Blocked by
<None | issue references>

## Out of Scope
- <explicit exclusion>

## Delivery contract
One Issue -> one independently reviewable and revertible PR.
```

Create or reuse all child Issues first, then:

1. attach each child through GitHub's native sub-issue relation;
2. write every native `blocked by` dependency;
3. keep the explicit Parent and Blocked by body references as a visible
   fallback even when native relations succeed.

Use the host GitHub capability or authenticated `gh api`. When a native
relation is unavailable or rejected, preserve the body fallback and report the
exact missing native edge. Never claim full native publication after a partial
write. Do not change the parent Issue's body, title, or state.

## 5. Verify and report the frontier

Read back every child body, parent relation, dependency, and state. The current
frontier is the set of open child Issues with no open blocker. Report:

- parent Spec URL;
- child Issue URLs and native-relation status;
- every blocking edge;
- the current frontier;
- any fallback-only relation or partial-write gap.

Stop after reporting. Do not assign, claim, branch for, or execute a frontier
Issue.

Native agents can create Issues. This skill's delta is vertical-slice
granularity, the wide-refactor exception, one pre-write graph gate,
retry-safe publication, dual native/body relations, and verified frontier
calculation.
