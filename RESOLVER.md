# Verbs Resolver

Use this document when you understand the request but cannot tell which Verbs
skill owns it, how skills compose, or where an enforcement boundary begins.

The public sources have separate jobs:

| Source | Ownership |
|---|---|
| `README.md` | The first-visit explanation: why Verbs exists, the normal path, and install surface. |
| `RESOLVER.md` | The complete human-facing operating model and disambiguation guide. |
| `manifest.toml` | The skill catalog, tiers, requirements, composition metadata, resources, and product identity. |
| Each `SKILL.md` | The machine-routing description plus the actual procedure, gates, outputs, and stop conditions for one skill. |

`PHILOSOPHY.md` explains the design principles behind these ownership
boundaries.

## Operating model

Verbs is a set of composable procedures, not an autonomous pipeline. Its primary
product-engineering record has six stages:

```text
Product Planning
→ Backlog Refinement
→ Sprint Planning
→ Sprint
→ Sprint Review
→ Retro
```

1. `product-planning` binds the product problem, Product Goal, priority, and
   candidate backlog outcomes. It stops before readiness or implementation.
2. `backlog-refinement` makes one item `READY` or `NOT_READY` from scope,
   acceptance, dependencies, edge states, and an evidence seam. Readiness does
   not select the item.
3. `sprint-planning` proposes one Sprint Goal and ready, unblocked work that
   fits stated capacity. A human approves or rejects the exact selection; no
   tracker or branch mutation occurs.
4. `sprint` owns one human-selected finish line through implementation,
   verification, bounded review, and delivery evidence.
5. `sprint-review` inspects the delivered product outcome against its Goal and
   acceptance evidence. It returns `ACCEPTED`, `NEEDS_CHANGES`, or `UNPROVEN`;
   code review and browser QA are evidence sources, not substitutes.
6. `retro` inspects one completed Sprint and proposes at most one
   evidence-backed process Action. It is not personal reflection or scheduling.

Each stage stops after its own record. No stage invokes its successor, claims a
frontier Issue, schedules work, or starts implementation without a new human
choice. Clear typed specialist requests bypass the stage layer.

Supporting planning procedures retain their narrower contracts. `ask-boss`
orients unclear authority or sources, `grill` supplies dependency-aware
requirements discovery, and `decision-map` owns cross-session Decision Maps
when the request names a map. Spec-sized work follows `to-spec` into one canonical GitHub Spec Issue and
`to-tickets` into vertical-slice child Issues. `to-tickets` reports the frontier
but does not choose work. A human selects one unblocked implementation Issue.

Work below the Spec threshold retains Grill's local brief and executable-plan
close. A small reversible fix may use the repository's direct branch/PR path.
Explicit delegation uses Herdr inside a managed pane or the host's native worker
surface. The active Sprint retains acceptance, review, Git, and delivery ownership.

### Typed on-ramps

Some work starts with a known problem type and does not need the full default
route:

| Known condition | Start with | Continue when |
|---|---|---|
| Owner, source of truth, or next route is unclear | `ask-boss` | One specialist route and its context packet are explicit. |
| Reproducible error, regression, crash, or failing test, including fixes expected to touch 3+ files | `debug` | Root cause is evidenced; fix execution can enter `sprint`. |
| Production UI needs to be built or corrected | `ui` | The direction and implementation are ready for live `qa`. |
| One design question can be answered by building | `prototype` | Record the verdict; discard the prototype or turn the result into a production plan. |
| The repository area worth architectural improvement is unknown | `improve-codebase-architecture` | A visual report ranks evidence-backed deepening candidates; the user selects one for a later session. |
| A module boundary or abstraction seam is the problem | `codebase-design` | The interface and seam are concrete enough for implementation. |
| An external artifact may be installed or adopted | `gatekeeper` | Trust evidence supports an adopt, restrict, or reject decision. |
| Production, shared infrastructure, or destructive actions are involved | `careful` | Required confirmation and recovery evidence are present. |
| A load-bearing judgment needs independent challenge | `advisor` | The executor evaluates the second opinion; agreement is not a mandate. |
| A repository lacks an unambiguous Verbs issue-tracker setting | `setup-verbs` | The existing `## verbs` block names the tracker; repository identity remains derived from Git. |
| Established requirements need one durable source of truth | `to-spec` | One canonical GitHub Spec Issue is published after test-seam confirmation. |
| A complete canonical Spec needs implementation units | `to-tickets` | Approved vertical-slice child Issues and blocking edges are published; the frontier is reported but not claimed. |

### Execution and closing stages

`sprint` is the normal owner of a focused build-to-ship session. The specialist
stages remain independently callable because each has a distinct contract:

- `qa` proves browser-visible acceptance after a UI change.
- `review` inspects a diff for grounded correctness and risk findings.
- `ship` tests, commits, pushes, and creates the PR for completed work.
- Herdr or a host-native worker may execute one explicitly delegated unit; the
  active Sprint still owns completion.

For several independent outcomes, run several bounded sprints. Selection stays
manual: do not turn `sprint` into a permanent autonomous driver, let it claim
the next frontier, or use `decision-map` as a task scheduler.

### Invocation and guidance

Each host routes from the descriptions in `SKILL.md`; Verbs injects no separate
routing table. `product-planning` and `backlog-refinement` allow native model
invocation. `sprint-planning`, `sprint`, `sprint-review`, and `retro` are
human-initiated-only because selection, execution, product acceptance, and
process changes require human authority. `improve-codebase-architecture` stays
human-only so periodic surveys do
not start opportunistically; `to-tickets` retains its human-only publication
boundary. Claude Code and Pi
honor frontmatter; Codex uses matching `agents/openai.yaml` policy. Skills carry
safety and verification guidance, not host-level enforcement.

## Skill catalog

### Development workflow

| Skill | Purpose | Trigger |
|---|---|---|
| `verbs:product-planning` | Clarify the product problem, Product Goal, priority, and candidate backlog outcomes. | what product work should happen next, why does this matter, prioritize this opportunity |
| `verbs:backlog-refinement` | Make one backlog item `READY` or `NOT_READY` from scope, acceptance, dependencies, edge states, and evidence. | refine this Issue, is this ready, clarify this backlog item |
| `verbs:sprint-planning` | Propose one Sprint Goal and ready work for a human approval decision; never execute the selection. | explicit request to plan the next Sprint |
| `verbs:grill` | Adversarial requirement discovery through dependency-aware frontier rounds. Routes large foggy work to Decision Map, spec-sized work to `to-spec`, and smaller work to a local brief/plan. | grill me, stress test, draft a brief, scope this, 3+ file feature/refactor |
| `verbs:ask-boss` | Route unclear owner, target, reference, or next route to one existing specialist; facts first, no generic grilling. | where do I start, who decides, which reference, what route, unclear next step |
| `verbs:setup-verbs` | Configure or repair the existing repository-level issue-tracker setting with an idempotent preview and approval gate. | set up Verbs, configure tracker, missing tracker config |
| `verbs:to-spec` | Synthesize established intent and repository evidence into one canonical GitHub Spec Issue; no new interview or ticket creation. | turn this discussion into a spec, publish the requirements |
| `verbs:to-tickets` | Decompose a complete canonical Spec into approved vertical-slice child Issues, native dependencies, body fallbacks, and a current frontier. | create implementation tickets, decompose this Spec |
| `verbs:decision-map` | Create or work cross-session Decision Maps named by the request or handed off by `ask-boss`; resolve one unblocked frontier entry at a time. | establish a map, resume the map, continue a named map, several dependent decisions |
| `verbs:sprint` | Execute a concrete outcome through acceptance, bounded review, and delivery evidence. | focused build-to-ship session, execute this plan |
| `verbs:sprint-review` | Inspect the delivered product outcome against its Sprint Goal and current acceptance evidence. | explicit request to review or accept the Sprint outcome |
| `verbs:retro` | Choose at most one evidence-backed product-engineering process improvement from a completed Sprint. | explicit request to run a Sprint Retro |
| `verbs:debug` | Establish root cause through hypotheses, instrumentation, bisecting, and scope analysis before changing code. | error, crash, regression, failing test, used to work |
| `verbs:codebase-design` | Design a deep module behind a small interface at a clean, testable seam. | module design, abstraction boundary, interface too wide |
| `verbs:improve-codebase-architecture` | Produce a read-only visual survey that ranks evidence-backed deepening candidates before one is selected for design. | periodic architecture survey, find refactoring opportunities, prepare for a large build |
| `verbs:prototype` | Build a throwaway artifact that answers exactly one logic or UI design question. | prototype this, compare variants, test this state model |
| `verbs:ui` | Build or fix a production UI with an explicit visual direction and rendered verification. | design, layout, typography, janky interaction |
| `verbs:qa` | Verify a changed UI in a browser and capture acceptance evidence. | test this UI, QA, check the page |
| `verbs:review` | Review a code diff with risk-adaptive evidence and earned cold-context escalation. | review this diff or PR, about to commit |
| `verbs:ship` | Close completed Git work through test, commit, push, PR, and QA evidence publication when present. | code is done, ship it, create a PR |
| `verbs:advisor` | Pull a decorrelated opinion from a different model; `--panel` critiques a prepared plan blindly from multiple angles. | second opinion, design fork, red-team this plan |
| `verbs:careful` | Add confirmation and recovery gates around production, shared infrastructure, or destructive work. | production, shared infra, destructive command |

### Trust and harness evaluation

| Skill | Purpose | Trigger |
|---|---|---|
| `verbs:gatekeeper` | Evaluate an external skill, MCP, repo, package, service, URL, or document before adoption. | should I install, clone, trust, or adopt this |

## Disambiguation

### Review surfaces

| Surface | What it reviews |
|---|---|
| Built-in `/review` | A generic PR or diff review. |
| Built-in `/security-review` | Branch code for security issues. |
| `verbs:review` | Your code through scoped, risk-adaptive passes and grounded findings. |
| `verbs:sprint-review` | The delivered product outcome against its Sprint Goal and acceptance evidence. |
| `verbs:gatekeeper` | Someone else’s artifact before it enters your system. |

Use `review` for a diff, `qa` for rendered behavior, `sprint-review` for the
product outcome, `debug` for an unexplained failure, `gatekeeper` for
pre-adoption trust. Maintainers auditing post-adoption system load explicitly
use `maintainer/harness-slim.md`; it is not a public runtime route. An
escalated Review needs an isolated read-only context, not a particular model or
transport; `advisor` alone requires a different model family through pinned
model anchors.

### Architecture, prototype, and UI

- Use `improve-codebase-architecture` when the repository area or module worth deepening is unknown; it surveys and ranks without designing the final interface.
- Use `codebase-design` when the module is already chosen and the answer is an interface or seam.
- Use `prototype` when one design uncertainty can be answered cheaply by a
  disposable build.
- Use `ui` when the artifact is intended to become production UI.
- Use `qa` after the UI exists and browser evidence is the remaining need.

### Product stages and supporting procedures

- `product-planning` chooses an outcome and priority; `backlog-refinement`
  determines whether one candidate item is ready.
- `grill` supplies the dependency-aware interview discipline;
  `decision-map` maintains a cross-session Decision Map.
- `sprint-planning` selects ready work after a human approval gate; `sprint`
  executes one selected finish line.
- `review` inspects code and `qa` proves browser behavior; `sprint-review`
  decides whether the product outcome achieved the Goal.
- `retro` proposes one process improvement after completion.
- Herdr and host-native workers may supply delegated execution context, but the
  active Sprint owns the broader outcome.

## Aliases

Only aliases still declared by an active `SKILL.md` appear here. They do not
alias the retired v3 plugin namespace.

| Old name (alias) | New name | Renamed in | Grace until |
|---|---|---|---|
| `slowmist-agent-security` | `gatekeeper` | v1.1 | 2026-08-04 |
