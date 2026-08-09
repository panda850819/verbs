# GitHub frontier query and claim evidence

Date: 2026-08-09  
Issue: [#348](https://github.com/panda850819/verbs/issues/348)  
Status: DEFER — keep the current verified read-back contract and human selection

## Decision

Do not change `to-tickets` yet.

GitHub's fully qualified advanced filters can cheaply list a parent's children
and issues blocked by one known blocker, but they cannot replace the complete
read-back contract. The current contract must verify each child body, native
parent relation, exact dependency edges, and state before reporting the
frontier. Search results expose only issue-level fields and `is:blocked` does
not expose the blocker edge or fallback body.

A single paginated GraphQL query can batch the complete native graph and is the
preferred execution tactic under the existing `gh api` wording. The four-child
representative graph reduced one observed read from five GraphQL requests and
2.649 seconds to one request and 0.539 seconds. This is useful but does not yet
show a product defect or material operator cost in a personal-first workflow:
four API points and about 2.1 seconds were saved once, with no incorrect
frontier result. The measured comparison consumed five points for the per-child
run and one for the batch; the account-level quota snapshot also included
unrelated discovery and introspection calls, so it is not attributed to these
six points. No skill-contract change is justified by this one small graph.

Do not add assignee-as-claim. No duplicate-claim incident exists in the current
solo-author workflow, and assignment would add coordination semantics to a
contract that intentionally stops at reporting. Reconsider only after a real
concurrent execution collision.

## Runtime and representative graph

- GitHub CLI: `2.86.0-87-g4e6563747`.
- Repository: `panda850819/verbs`.
- Representative native graph: parent #265 and children #266 through #269.
- #266 blocks #267 and #268; #267 and #268 block #269.
- All five Issues are closed, so the observed current frontier is empty.
- The same repository also contains the smaller native graph #283 -> #284 ->
  #285. No open native child graph exists here, so this run proves relation and
  state retrieval but does not manufacture an open frontier fixture.

## Query capability

The GraphQL `Issue` type currently exposes `parent`, `subIssues`, `blockedBy`,
`blocking`, and `issueDependenciesSummary`. Direct introspection and the #265
query returned the expected native relations.

Advanced Issue filters require a fully qualified reference:

```text
parent-issue:panda850819/verbs#265
blocked-by:panda850819/verbs#266
```

The first returned `#266`, `#267`, `#268`, and `#269`. The second returned
`#267` and `#268`. Bare `parent-issue:265` and `blocked-by:266` returned no
results rather than an error, so an implementation must not silently use the
short form.

`is:blocked` returned no result for this repository because the known native
dependencies are already closed. Even when populated, it is only a current
boolean filter; it does not return the exact `blockedBy` edges needed for
publication verification.

The current GitHub search documentation describes general advanced filters but
does not document `parent-issue` or `blocked-by` in its ordinary search
qualifier table. The live endpoint behavior above is therefore retained as
observed capability evidence, not treated as a stable replacement for native
GraphQL relation reads.

## Read-back measurement

The per-child run performed:

1. one GraphQL request for parent #265's child numbers;
2. four GraphQL requests, one per child, for body, state, parent, and
   `blockedBy` edges.

Observed result:

```text
requests: 5
wall time: 2.649 s
GraphQL points: 5
```

The batched run requested parent #265, all four child bodies/states/parents, and
each child's blocker states in one nested query:

```text
requests: 1
wall time: 0.539 s
GraphQL points: 1
```

Both returned:

```text
#266 CLOSED parent=#265 blockedBy=[]
#267 CLOSED parent=#265 blockedBy=[#266:CLOSED]
#268 CLOSED parent=#265 blockedBy=[#266:CLOSED]
#269 CLOSED parent=#265 blockedBy=[#267:CLOSED, #268:CLOSED]
frontier=[]
```

The exact timings include separate `gh` process and network overhead and are a
single local observation, not a benchmark distribution. For a future large
Issue graph, paginate both `subIssues` and every dependency connection; never
truncate a graph to preserve the one-request shape.

## Claim evidence

No current repository Issue records duplicate implementation ownership or a
claim collision. The open queue is unassigned, and `to-tickets`, `README.md`,
`RESOLVER.md`, and Sprint all preserve explicit human selection. Assignment
would therefore change product ownership semantics without an observed failure.

## Reopen conditions

Create an implementation Issue only when at least one of these occurs:

- verified frontier reporting is incorrect;
- a representative graph shows material latency or rate-limit pressure after
  using a paginated batched GraphQL read;
- GitHub exposes a documented query that returns all required bodies, native
  relations, exact blockers, and states more reliably than GraphQL read-back;
- a real concurrent execution collision demonstrates that human selection is
  insufficient.

Any later implementation must preserve body-reference fallbacks, native
relation verification, pagination, and the rule that reporting never claims,
assigns, schedules, or executes a frontier Issue.
