---
name: to-spec
description: |
  Publish established discussion and repository evidence as one canonical GitHub
  Spec Issue, then continue into approved child-Issue decomposition when called
  from planning. Use when settled requirements need a durable specification or
  `grill` routes a spec-sized effort here. NOT discovery.
reads:
  - repo: "**"
  - repo: AGENTS.md
  - repo: CLAUDE.md
  - skill: setup-verbs
  - skill: to-tickets
  - cli: git
  - cli: gh
writes:
  - cli: gh issue create
  - cli: stdout
domain: shared
classification: exec
user-invocable: true
---

# To Spec

Synthesize established intent into one canonical GitHub Spec Issue. Do not
restart a requirements interview. The Issue is the only requirements source of
truth; this skill creates no repository Spec copy. When the
planning caller requests implementation Issues, continue into `to-tickets` after the Spec
is verified.

## 1. Bind the tracker and evidence

Read the root `AGENTS.md` or `CLAUDE.md` and require one unambiguous
`tracker: github` under `## verbs`. If it is absent or conflicts, invoke
`setup-verbs` and stop until configuration is resolved. Derive `owner/repo` from
the Git remote and verify authenticated GitHub access.

Collect confirmed decisions, inspect only repository surfaces needed for real
vocabulary, constraints, and test commands. Search open Issues for the same outcome;
if a canonical Spec already exists, return it instead of publishing a duplicate.

Completion: every factual implementation or testing claim is supported by the
conversation or inspected repository; unresolved facts go in Further Notes.

## 2. Draft the complete Issue

Use `[Spec] <outcome>` and exactly these top-level sections:

1. `## Problem`
2. `## Solution`
3. `## User Stories`
4. `## Implementation Decisions`
5. `## Testing Decisions`
6. `## Out of Scope`
7. `## Further Notes`

Cover each affected actor and material failure/edge state in User Stories, using
`As a / I want / so that` where it clarifies acceptance. Implementation Decisions
name settled seams and constraints, not task breakdowns.
Testing Decisions propose the highest practical seam first:

1. existing end-to-end or behavioral contract;
2. existing public boundary or integration test;
3. focused unit or structural contract;
4. a new lower-level harness only when higher seams cannot prove the requirement.

State why each seam proves the requirement and list concrete gaps. Include this
ownership sentence in Further Notes:

> This GitHub Spec Issue is the only requirements source of truth. Do not
> create or maintain a canonical repository spec copy.

Completion: all required headings, substantive stories, evidenced decisions,
and explicit exclusions are present; implementation breakdown remains outside
the Spec body.

## 3. Confirm the test seams once

Show the complete draft and Testing Decisions. Ask once:
`[publish / reject]`.

- `publish`: publish this exact draft.
- `reject`: create nothing and stop.

Do not ask new discovery questions; leave missing information explicit in
Further Notes.

## 4. Publish and verify

Create exactly one Issue in the GitHub repository derived from Git, using the
host capability or authenticated `gh`. Do not write a body file inside the
repository or create branches, commits, or PRs.

Read the Issue back and verify its URL, title, all seven headings, and ownership
sentence. Missing or unreadable evidence means publication is not verified.

## 5. Continue to child Issues when requested

After verified Spec publication, invoke `to-tickets` in the same planning
invocation when the caller requested implementation Issues.
Pass the verified Spec URL and established context; `to-tickets` owns its graph
preview, publication approval, native relations, and frontier verification.
Return the Spec URL, child Issue URLs, dependency status, and verified frontier
to the caller. Otherwise report the Spec URL and unresolved Further Notes and
stop.
