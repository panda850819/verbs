---
name: to-tickets
description: |
  Turn one complete canonical GitHub Spec Issue into approved child Issues and
  dependency edges. Use for vertical-slice ticketing only. NOT discovery, Spec
  publication, scheduling, or implementation.
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
Publication never claims, schedules, or executes a frontier Issue.

## 1. Bind the source

Require one unambiguous `tracker: github` in the root `## verbs` block; invoke
`setup-verbs` and stop when configuration is missing or conflicting. Derive the
repository from Git and verify authenticated GitHub access.

Read the entire source Issue and require substantive `Problem`, `Solution`,
`User Stories`, `Implementation Decisions`, `Testing Decisions`, `Out of Scope`,
and `Further Notes` sections. Confirm it declares itself the only requirements
source of truth. On any gap, report it and stop; do not interview, rewrite, or
close the parent.

Search existing open and closed Issues for children naming this parent. Reuse an
Issue only when its body contract and approved outcome match; otherwise stop on a publication conflict rather than duplicating or adopting stale scope.

## 2. Design vertical slices

Each proposed Issue must:

- deliver one observable behavior through every required layer;
- have independently runnable acceptance evidence;
- fit one fresh-context Sprint;
- map to one independently reviewable and revertible PR;
- name its parent, outcome, scope, acceptance, blockers, and exclusions.

Split only when review/revert independence or blast radius differs. For a wide
mechanical refactor that cannot form honest vertical slices, use:

```text
expand (add the compatible seam)
  -> migrate batch 1..N (bounded, behavior-preserving batches)
  -> contract (remove the old seam after every migration)
```

Every migrate batch depends on expand; contract depends on every batch. Build a
DAG: a blocker is a real prerequisite, not preferred ordering, and no ticket may
depend on unwritten future work.

## 3. Preview and approve

Show every proposed title, outcome, acceptance set, exclusion, and `blocked by`
edge, followed by the computed initial frontier. Ask once:
`[publish / reject]`.

- `publish`: create this exact graph.
- `reject`: create nothing and stop.

No Issue may be created before approval.

## 4. Publish the graph

Use the host GitHub capability or authenticated `gh` for Issue writes, and the host capability or authenticated `gh api` for native relations. Create each implementation Issue with this body contract:

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

Create or reuse all children first, then attach each through GitHub's native sub-issue relation and write every native `blocked by` dependency. Keep explicit Parent and Blocked by body references as a fallback. If a native relation is
unavailable or rejected, report the exact missing edge; never claim full native
publication after a partial write. Do not change the parent Issue's body, title, or state.

## 5. Verify and report the frontier

Read back every child body, parent relation, dependency, and state. The current
frontier is open child Issues with no open blocker. Report the parent URL, child
URLs and relation status, every blocking edge, the frontier, and any fallback-only
relation or partial-write gap.

Done when publication and the frontier are verified. Do not assign, claim, branch for, or execute a frontier Issue.
