# Verbs Resolver

Use this document when you understand the request but cannot tell which Verbs
skill owns it, how skills compose, or where an enforcement boundary begins.

The public sources have separate jobs:

| Source | Ownership |
|---|---|
| `README.md` | The first-visit explanation: why Verbs exists, the normal path, and install surface. |
| `RESOLVER.md` | The complete human-facing operating model and disambiguation guide. |
| `DISPATCH.md` | The single source for machine routing injected by supported plugin hosts. |
| `manifest.toml` | The skill catalog, tiers, requirements, composition metadata, resources, and product identity. |
| Each `SKILL.md` | The actual procedure, gates, outputs, and stop conditions for one skill. |
| `hooks/` | The narrow enforcement layer. Hooks block selected unsafe or unverified transitions; they do not run the workflow. |

`PHILOSOPHY.md` explains the design principles behind these ownership
boundaries.

## Operating model

Verbs is a set of composable procedures, not a fixed pipeline. The default
development route is:

```text
unclear request
  |
  v
grill
  |
  +-- smaller work --> local brief / plan --> selected Issue
  |                                               |
  |                                               +--> sprint --> review --> ship
  |
  +-- spec-sized --> to-spec --> canonical GitHub Spec Issue
  |                                  |
  |                                  +--> to-tickets --> child Issue graph
  |                                                           |
  |                                                           +--> human selects
  |                                                                one frontier Issue
  |                                                                  |
  |                                                                  +--> sprint
  |                                                                       --> review
  |                                                                       --> ship
  |
  +-- several unresolved decisions ----> decision map
                                         |
                                         +--> wayfinder resolves one frontier
                                              until work becomes sprint-sized
```

This route answers three common selection questions:

1. Use `grill` when intent, scope, constraints, or acceptance are still
   unknown. It asks one question at a time, then chooses a close based on the
   resulting work shape.
2. Use `wayfinder` when the request itself names a map — charting one, or
   resuming an existing one. With no map, `wayfinder` runs the interview,
   writes the map, and stops. With a map, it takes one unblocked frontier
   entry, records the decision, and updates the map.
   A large effort with no map still enters `grill`, which hands off once the
   drilling shows the route is unclear. The size of an effort is not knowable
   when the request is typed, and a wrong `grill` costs one hand-off while a
   wrong `wayfinder` can leave an unwanted map behind. `wayfinder` is the only
   skill that writes a map.
3. Use `to-spec` when the work is expected to need at least two implementation
   Issues, or when even one PR changes a public contract, schema or migration,
   or security boundary. Its GitHub Spec Issue becomes the only requirements
   source of truth.
4. Use `to-tickets` to decompose that complete Spec into vertical-slice child
   Issues and blocking edges. It reports the frontier but does not choose work.
5. A human selects one unblocked implementation Issue. `sprint` owns only that
   finish line through verification, review, and one independently reviewable
   and revertible PR.

Work below the Spec threshold retains Grill's local brief and executable-plan
close. A small reversible fix may use the repository's direct branch/PR path.

`handover` is not an alternative planning path. It is allowed only after a
plan contains one bounded, mechanical build unit with a locked specification
that benefits from fresh context. The original orchestrator waits, verifies
the returned evidence, and retains responsibility for acceptance and Git.

### Typed on-ramps

Some work starts with a known problem type and does not need the full default
route:

| Known condition | Start with | Continue when |
|---|---|---|
| Reproducible error, regression, crash, or failing test, including fixes expected to touch 3+ files | `debug` | Root cause is evidenced; fix execution can enter `sprint`. |
| Production UI needs to be built or corrected | `ui` | The direction and implementation are ready for live `qa`. |
| One design question can be answered by building | `prototype` | Record the verdict; discard the prototype or turn the result into a production plan. |
| A module boundary or abstraction seam is the problem | `codebase-design` | The interface and seam are concrete enough for implementation. |
| An external artifact may be installed or adopted | `gatekeeper` | Trust evidence supports an adopt, restrict, or reject decision. |
| Production, shared infrastructure, or destructive actions are involved | `careful` | Required confirmation and recovery evidence are present. |
| A load-bearing judgment needs independent challenge | `advisor` | The executor evaluates the second opinion; agreement is not a mandate. |
| A live multi-runtime harness has accumulated complexity | `harness-slim` | A verified, reversible reduction proposal exists. |
| A repository lacks an unambiguous Verbs issue-tracker setting | `setup-verbs` | The existing `## verbs` block names the tracker; repository identity remains derived from Git. |
| Established requirements need one durable source of truth | `to-spec` | One canonical GitHub Spec Issue is published after test-seam confirmation. |
| A complete canonical Spec needs implementation units | `to-tickets` | Approved vertical-slice child Issues and blocking edges are published; the frontier is reported but not claimed. |

### Execution and closing stages

`sprint` is the normal owner of a focused build-to-ship session. The specialist
stages remain independently callable because each has a distinct contract:

- `qa` proves browser-visible acceptance after a UI change.
- `review` inspects a diff for grounded correctness and risk findings.
- `ship` tests, commits, pushes, and creates the PR for completed work.
- `handover` executes one unfinished mechanical unit in fresh context.

For several independent outcomes, run several bounded sprints. Selection stays
manual: do not turn `sprint` into a permanent autonomous driver, let it claim
the next frontier, or use `wayfinder` as a task scheduler.

### Enforcement versus guidance

Skill prose guides model judgment. Marketplace Plugin hooks enforce only these
boundaries:

| Boundary | Enforcement |
|---|---|
| Routing availability | `SessionStart` injects `DISPATCH.md` at startup, clear, and compact. It does not choose or invoke a skill. |
| Destructive Bash commands | The destructive guard blocks positive scoped matches before execution. It is not a complete shell sandbox. |
| Issue-branch discipline | The ticket gate blocks default-branch commits and pushes plus broad pushes. It does not create the issue, worktree, or PR. |
| Verification before stopping | The Stop gate blocks the first stop after a code edit when no recognized verification ran, then allows a second stop to prevent a loop. |

Manual skill imports are hook-free. They retain the procedure but not these
enforcement guarantees.

## Skill catalog

### Development workflow

| Skill | Purpose | Trigger |
|---|---|---|
| `verbs:grill` | Adversarial requirement discovery, one question at a time. Routes large foggy work to Wayfinder, spec-sized work to `to-spec`, and smaller work to a local brief/plan. | grill me, stress test, draft a brief, scope this |
| `verbs:setup-verbs` | Configure or repair the existing repository-level issue-tracker setting with an idempotent preview and approval gate. | set up Verbs, configure tracker, missing tracker config |
| `verbs:to-spec` | Synthesize established intent and repository evidence into one canonical GitHub Spec Issue; no new interview or ticket creation. | turn this discussion into a spec, publish the requirements |
| `verbs:to-tickets` | Decompose a complete canonical Spec into approved vertical-slice child Issues, native dependencies, body fallbacks, and a current frontier. | create implementation tickets, decompose this Spec |
| `verbs:wayfinder` | Chart a cross-session decision map by interviewing and writing it here, or work one unblocked frontier entry at a time. | establish a map, resume the map, continue a named map |
| `verbs:sprint` | Execute a concrete outcome through acceptance, bounded review, and delivery evidence. | focused build-to-ship session, execute this plan |
| `verbs:debug` | Establish root cause through hypotheses, instrumentation, bisecting, and scope analysis before changing code. | error, crash, regression, failing test, used to work |
| `verbs:codebase-design` | Design a deep module behind a small interface at a clean, testable seam. | module design, abstraction boundary, interface too wide |
| `verbs:prototype` | Build a throwaway artifact that answers exactly one logic or UI design question. | prototype this, compare variants, test this state model |
| `verbs:ui` | Build or fix a production UI with an explicit visual direction and rendered verification. | design, layout, typography, janky interaction |
| `verbs:qa` | Verify a changed UI in a browser and capture acceptance evidence. | test this UI, QA, check the page |
| `verbs:review` | Review a code diff with risk-adaptive evidence and earned cold-context escalation. | review this diff or PR, about to commit |
| `verbs:ship` | Close completed Git work through test, commit, push, PR, and QA evidence publication when present. | code is done, ship it, create a PR |
| `verbs:handover` | Give one locked, bounded, unfinished mechanical unit to a fresh Claude or Codex worker while the original agent retains orchestration and Git. | fresh context would help this plan unit |
| `verbs:advisor` | Pull a decorrelated opinion from a different model; `--panel` critiques a prepared plan blindly from multiple angles. | second opinion, design fork, red-team this plan |
| `verbs:careful` | Add confirmation and recovery gates around production, shared infrastructure, or destructive work. | production, shared infra, destructive command |

### Trust and harness evaluation

| Skill | Purpose | Trigger |
|---|---|---|
| `verbs:gatekeeper` | Evaluate an external skill, MCP, repo, package, service, URL, or document before adoption. | should I install, clone, trust, or adopt this |
| `verbs:harness-slim` | Audit an already-adopted multi-runtime harness for parity, cold context, routing overlap, telemetry semantics, and attention cost. | audit or reduce the live agent harness |

## Disambiguation

### Review surfaces

| Surface | What it reviews |
|---|---|
| Built-in `/review` | A generic PR or diff review. |
| Built-in `/security-review` | Branch code for security issues. |
| `verbs:review` | Your code through scoped, risk-adaptive passes and grounded findings. |
| `verbs:gatekeeper` | Someone else’s artifact before it enters your system. |
| `verbs:harness-slim` | Your live multi-runtime harness after adoption. |

Use `review` for a diff, `qa` for rendered behavior, `debug` for an unexplained
failure, `gatekeeper` for pre-adoption trust, and `harness-slim` for
post-adoption system load.

### Architecture, prototype, and UI

- Use `codebase-design` when the answer is an interface or seam.
- Use `prototype` when one design uncertainty can be answered cheaply by a
  disposable build.
- Use `ui` when the artifact is intended to become production UI.
- Use `qa` after the UI exists and browser evidence is the remaining need.

### Grill, wayfinder, sprint, and handover

- `grill` discovers what the work must become.
- `wayfinder` maintains progress across a decision map when one plan would
  falsely imply certainty.
- `sprint` executes a concrete outcome and owns final acceptance.
- `handover` supplies fresh execution context for one locked plan unit; it
  never owns the broader outcome.

## Aliases

Only aliases still declared by an active `SKILL.md` appear here. They do not
alias the retired v3 plugin namespace.

| Old name (alias) | New name | Renamed in | Grace until |
|---|---|---|---|
| `slowmist-agent-security` | `gatekeeper` | v1.1 | 2026-08-04 |
