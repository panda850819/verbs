# Verbs

Verbs binds how a repository defines, implements, verifies, and delivers work to
one authoritative `AGENTS.md` Project Contract. It adds specialist procedures
only where coding agents need a material execution or safety override.

## Operating model

```text
AGENTS.md Project Contract
        │
        ▼
read ticket / document / prompt
        │
        ▼
Brain First: retrieve relevant GBrain memory
        │
        ▼
build Work Contract
        │
        ├─ unclear ─▶ automatic Grilling Session ─▶ confirm
        │
        ▼
implement with native coding-agent workflow
        │
        ▼
verify and deliver by AGENTS.md
        │
        ▼
evidence-backed learning candidate ─▶ GBrain
        │
        └─ stable policy ─▶ preview + approval ─▶ AGENTS.md
```

`AGENTS.md` is policy. GBrain is historical evidence. Current user instruction,
the confirmed Work Contract, and current repository evidence outrank memory.
GBrain lookup fails soft so unavailable memory never blocks ordinary work.

## Project Contract

Run:

```bash
scripts/verbs setup --questionnaire
scripts/verbs setup --check
```

The questionnaire covers:

- work source: GitHub Issues, Jira, Linear, document, or prompt;
- ticket policy;
- goal and acceptance sources;
- exact verification commands;
- branch, review, PR, release, and approval rules;
- GBrain availability.

The root `AGENTS.md` `## verbs` block is the only source of truth. A host file may
symlink to it but must not define a competing contract. `scripts/verbs setup`
resolves GitHub SSH aliases through `ssh -G`, previews mutations, requires
approval before writes, and reports actionable blockers.

## Work Contract and Grilling Sessions

Before implementation, establish:

```text
Goal
Scope
Out of Scope
Acceptance Criteria
Constraints
Delivery Target
```

When a required field is missing, ambiguous, or contradictory, the agent enters
a Grilling Session automatically. It retrieves repository, ticket, and GBrain
facts first, asks only current blocking-frontier questions, then presents the
Work Contract for confirmation. Grilling is not a command or runtime skill.

## Specialist skills

Use a specialist only when the problem type is known:

- **`debug`** — You have an observed error, regression, crash, failing test, or
  intermittent failure, but its cause is unknown. `debug` reproduces it, names
  the root cause before editing, verifies the correction with a red-capable
  check, and scans for siblings. Browser acceptance can continue through `qa`.
- **`review`** — You have a bounded diff or PR that needs a correctness verdict.
  `review` binds intent and scope, selects a risk lane, tests each surviving
  finding, and stops with actionable findings or an evidence-backed clean result.
- **`ship`** — The code work is complete and you want the branch delivered.
  `ship` runs test, scope, and review gates, commits relevant files, pushes a
  non-default branch, then upserts the PR and available QA evidence. Unfinished
  work returns to its execution owner.
- **`ui`** — A production page or component needs a committed visual direction,
  or a taste complaint needs correction. `ui` names and implements the direction,
  covers required states, and verifies rendered locales. Use `prototype` first
  while the direction remains open, then `qa` for browser acceptance.
- **`qa`** — UI changed and browser-visible acceptance remains unproven. `qa`
  maps current-artifact browser checks to acceptance criteria and stores a
  PR-ready evidence handoff for `ship`.
- **`prototype`** — One logic, state, or visual design question is cheaper to
  experience than discuss. `prototype` builds one disposable terminal driver or
  set of UI variants, records the verdict in the brief, and stops before
  production work. A selected visual direction continues through `ui`.
- **`gatekeeper`** — An external skill, MCP server, repository, URL, package,
  API, SDK, or service may enter the system. `gatekeeper` classifies STRIDE,
  follows the artifact-specific review, and returns adopt, restrict, or reject.
  High-risk paths require human approval; rejected paths stop with refusal and
  evidence.
- **`careful`** — Work touches production, shared infrastructure, live harness
  paths, or an imminent destructive action. `careful` pauses that action for
  explicit confirmation while reversible work continues.

Visual references:

- [Skill routing map](docs/diagrams/verbs-skill-route-map.html)
- [Task lifecycle examples](docs/diagrams/verbs-task-lifecycles.html)

These procedures do not form a mandatory lifecycle. Native coding-agent behavior
owns ordinary inspection, planning, implementation, testing, and correction.

## GBrain project memory

Before planning, implementing, debugging, reviewing, or shipping, search GBrain
for relevant decisions, conventions, pitfalls, preferences, and failed
approaches. Store only evidence-backed records using `lib/learning-format.md`.
Never store secrets, unsupported inference, routine task details, or duplicate
`AGENTS.md` policy.

GBrain cannot edit `AGENTS.md`. A stable learning becomes policy only after the
agent previews the exact contract diff and the user approves it.

## Skills

**Core** skills require no optional external CLI beyond declared baseline tools.
**Ext** skills require an additional public CLI.

<!-- BEGIN GENERATED: skill-catalog -->
| Skill | Tier | Purpose |
|---|---|---|
| `/verbs:careful` | core | Confirmation gate for production, shared infrastructure, live harness paths, and destructive commands. |
| `/verbs:gatekeeper` | core | Pre-adoption trust check for external skills, MCPs, repositories, packages, URLs, APIs, and services. |
| `/verbs:review` | core | Risk-adaptive diff review on request, before commit, or before PR, with a bounded low-risk fast path and cold-context escalation. |
| `/verbs:debug` | core | Systematic root-cause debugging with an evidence gate before fixes. |
| `/verbs:ui` | core | Build or fix production UI with a committed visual direction. |
| `/verbs:qa` | core | Browser-based UI QA with PR-ready acceptance evidence through host-provided browser automation. |
| `/verbs:prototype` | core | Build one throwaway artifact to answer one logic or UI design question. |
| `/verbs:ship` | ext | Close completed code work through test, commit, push, PR, and available QA evidence publication. |
<!-- END GENERATED: skill-catalog -->

## Install

Claude Code:

```bash
claude plugin marketplace add panda850819/verbs --scope user
claude plugin install verbs@verbs --scope user
```

Codex:

```bash
codex plugin marketplace add panda850819/verbs --json
codex plugin add verbs@verbs --json
```

Pi and compatible hosts can load `skills/` directly.

## Verify

```bash
python3 scripts/verbs sync --check
bash tests/run-all.sh
```

See [`RESOLVER.md`](RESOLVER.md) for routing boundaries,
[`PHILOSOPHY.md`](PHILOSOPHY.md) for design principles, and
[`maintainer/harness-slim.md`](maintainer/harness-slim.md) for the read-only
post-adoption runtime audit.
