# Verbs Resolver

Use this document only when the request's specialist execution surface is
unclear. Ordinary intake is governed by the root `AGENTS.md` Project Contract,
not by a routing skill.

## Sources of truth

| Source | Ownership |
|---|---|
| `AGENTS.md` | Authoritative project policy, intake, verification, delivery, approval, and Brain First rules. |
| Confirmed ticket or Work Contract | Current task outcome and acceptance. |
| GBrain | Historical project evidence; never policy. |
| `manifest.toml` | Runtime skill catalog, dependencies, composition, and resources. |
| Each `SKILL.md` | One specialist procedure and its stop boundary. |

Conflict order:

```text
current user instruction
> AGENTS.md
> confirmed ticket / Work Contract
> repository evidence
> GBrain memory
```

## Intake

Every task starts by reading `AGENTS.md`, retrieving relevant GBrain memory, and
establishing Goal, Scope, Out of Scope, Acceptance Criteria, Constraints, and
Delivery Target. Missing, ambiguous, or contradictory fields automatically
start a Grilling Session. The session retrieves facts first, asks only current
blocking questions, and exits on a user-confirmed Work Contract.

Grilling is Project Contract behavior. It is not a skill, command, planning
stage, tracker mutation, scheduler, or implementation owner.

## Specialist routing

| Known condition | Route | Completion delta |
|---|---|---|
| Reproducible error, regression, crash, or failing test | `debug` | Root cause is evidenced before a fix is claimed. |
| Production UI must be built or visually corrected | `ui` | The committed visual direction is implemented and rendered. |
| Browser-visible acceptance remains unproven | `qa` | Current-artifact browser evidence is captured. |
| A diff or PR needs grounded correctness review | `review` | Findings are risk-adaptive, scoped, and evidenced. |
| Completed Git work needs delivery | `ship` | Tests, commit, pushed branch, PR, and available QA evidence are verified. |
| One design uncertainty can be answered cheaply | `prototype` | One disposable artifact yields a recorded verdict. |
| An external artifact may enter the system | `gatekeeper` | Trust evidence supports adopt, restrict, or reject. |
| Production, shared infrastructure, or destructive actions are involved | `careful` | Required confirmation and recovery evidence are present. |
| Several dependent decisions need cross-session state | `decision-map` | One map is created or one selected entry is resolved. |
| The repository area worth architectural improvement is unknown | `improve-codebase-architecture` | An explicitly requested read-only survey ranks candidates. |

Known specialist tasks bypass further routing. A specialist still obeys the
Project Contract and Brain First Rule. Architecture surveys remain explicit so
periodic surveys do
not start opportunistically. When the module is already chosen but its interface
or abstraction seam is unclear, use the automatic Grilling Session with the
canonical `lib/codebase-design.md` vocabulary instead of another survey.

## Native parity boundary

Verbs does not wrap ordinary coding-agent behavior in lifecycle skills. The host
already owns repository inspection, planning, implementation, testing, and
correction. Verbs keeps only procedures with a material delta:

- evidence-before-fix debugging;
- grounded diff review;
- browser acceptance;
- Git and PR closure;
- production UI craft;
- destructive-action and trust gates;
- disposable prototypes;
- named cross-session decision maps;
- explicit architecture surveys.

Project planning, backlog readiness, sprint selection, sprint execution, sprint
review, retrospectives, tracker publication, generic orientation, cross-model
advice, and manual grilling are not runtime routes.

## GBrain boundary

GBrain records project decisions, conventions, pitfalls, preferences, and failed
approaches using `lib/learning-format.md`. Retrieval is proactive and fail-soft.
Memories that materially affect work are cited. Stale, unrelated, unsupported,
or cross-project records are ignored.

A learning cannot become policy by recurrence alone. The agent must preview the
exact `AGENTS.md` change and receive explicit human approval. Superseded memory
remains provenance and is not silently reused.

## Review surfaces

| Surface | Object |
|---|---|
| `review` | Current repository diff or PR. |
| `qa` | Rendered behavior of the current artifact. |
| `gatekeeper` | External artifact before adoption. |
| `careful` | Imminent destructive or shared-state action. |

Use `debug` for an unexplained failure. Use the automatic Grilling Session for
an unclear Work Contract. Neither is a review substitute. Maintainers auditing
post-adoption context and attention load use `maintainer/harness-slim.md`; it is
not a runtime route.
