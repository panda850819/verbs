---
name: grill
description: |
  Adversarial requirement discovery. Ask dependency-aware frontier rounds,
  hunting for hidden requirements / unknown unknowns. Its structured close routes
  spec-sized work to
  `to-spec`, large foggy work to `wayfinder`, and smaller work to a local brief plus
  executable plan. Say "quick" or "don't write files" for a chat-only log. Use for
  "grill me", "stress test this scope", "what am I missing", "draft a brief",
  structured intake, or a feature/refactor expected to touch 3+ files or add an
  abstraction. Skip when scope is already concrete.
reads:
  - skill: lib/interview.md
  - skill: lib/push-once.md
  - skill: lib/stop-rule.md
  - skill: lib/output-templates.md
  - skill: lib/skill-decision-tree.md
  - skill: to-spec
  - repo: knowledge/**
writes:
  - repo: docs/briefs/*.md
  - repo: docs/plans/*.md
  - cli: stdout
domain: shared
classification: tool
user-invocable: true
---
# Grill

Grill surfaces unknowns by questioning only the current decision frontier; it
is not a questionnaire. By default its structured close routes to `to-spec`,
`wayfinder`, or a local brief and executable plan. Say `quick`, `just talk`, or
`don't write files` to keep only the chat log.

## Use / skip

Use for fuzzy scope, hidden constraints, or an explicit request to stress-test
an idea. Skip bugs, documented scope, clear acceptance criteria, and P0 work.

## Protocol

Run **`@lib/interview.md`**. It owns cadence, facts-first lookup, delete-first
drilling, pushback, search space, stopping rule, and escape hatch; do not fork
it here. Its load-bearing first-turn contract is mandatory even before the
shared file is available:

1. Build a dependency graph before asking. If a decision's meaning, answer
   options, or authority changes with another unsettled decision or fact, it is
   blocked and cannot enter this round.
2. Separate repository-derivable facts into a `Fact lookups` list. Look them up
   when tools are available; otherwise mark each unresolved fact and block only
   its dependents. Never ask the human to supply a derivable value merely because
   lookup tools are unavailable.
3. Ask **every** active decision frontier item as one numbered `Q1`…`Qn` round. One
   active decision is still labeled `Q1`; never replace a multi-decision
   frontier with one umbrella question. When blocked work exists, list it under
   `Blocked this round` with its prerequisite instead of asking it early.
4. Stop after that round and wait. Do not recompute the frontier or begin the
   structured close before the answers arrive.

**If the interview already ran this session, do not run it again.** Carry its
answers into the close. **If an interview is still unfinished when the user
switches skills, say so before the next question.** The shared protocol owns the
exact announcement and the receiving caller owns the new close.

## Chat-only output

When the user requested no artifact, emit only:

```markdown
## Grill log — <topic> — <date>
### Confirmed
### Open / deferred
### Surfaced contradictions
### Recommended next step
```

Otherwise this log is the running record and the structured close follows.

## Structured close

After the interview stopping rule, run Stage A, Stage B, then exactly one route.
Do not skip or reorder these stages.

- **Stage A — Alternatives.** Use `@lib/stop-rule.md`: produce 2–3 named
  approaches with effort, pros, cons, a recommendation, and one-at-a-time
  Add / Defer / Reject gates.
- **Stage B — Premise refresh.** Record original premise, surfaced premises,
  revised premise, and whether the original remains load-bearing.

### Route after premise refresh

1. **Large and foggy -> `wayfinder`.** If the effort is too large for one
   session and the route is unclear, pass the drilling to `wayfinder` and stop.
   Do not write a map here.
2. **Spec-sized -> `to-spec`.** Route when the chosen work can require two or more implementation Issues, or even one PR changes a
   public contract, schema or migration, or security boundary. Give it the log,
   gates, premise, and repo
   evidence. Do not write a competing repository brief, executable plan, PRD,
   local Spec, tracking Issue, or child-Issue graph; stop after the Spec URL.
   Decomposition requires a separate explicit human invocation.
3. **Smaller work -> local close.** Continue to Stage C and C+.

### Local close

- **Stage C.** Write `docs/briefs/{YYYY-MM-DD}-{slug}.md` using
  `lib/output-templates.md`: problem, premises, alternatives, chosen approach,
  scope, seams, next skill, gotchas, and OPEN_QUESTIONS. Name the next skill;
  offer once to mint a tracking Issue when the repo has GitHub.
- **Stage C+.** If execution follows, also write `docs/plans/{slug}.md` with
  concrete acceptance per task, WHY/WHAT separation, and one granularity gate.

## Boundaries

The interview protocol owns questions and state; `grill` owns chat-only output
and structured close. It never silently skips gates, writes a map, or creates a
competing Spec artifact.
