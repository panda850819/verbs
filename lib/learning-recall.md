# lib/learning-recall.md — surface captured learnings at the start of a dev unit

> Shared module. The compounding half that actually pays. This makes a dev unit OPEN by pulling the handful of repo learnings relevant to the task, so captured insight changes current behavior instead of sedimenting.

## When to load

At the START of a dev unit, right after `capability-probe`, BEFORE planning or executing:

- `sprint` Stage 0 · `review` Step 2 (its "Load Learnings" step) · `debug` opener.

Skip for atomic skills that do not open a development unit, such as `careful`.

## The recall

Given the task topic (one line you derive from the request), pull the top **3-5** relevant learnings from the repo's configured `{learnings_dir}`:

- **directory present**: rank its Markdown files by topic-token overlap against title + tags; take the top 3-5. A small `grep -rIl` + token score is enough; no index is required.
- **directory absent**: print `(no repo learning directory found — recall skipped)` and proceed. Not an error.

## Inject + USE (the load-bearing part)

Print one compact RECALL block, then actually use it:

```
== recall (N learnings for: <topic>) ==
- <key> (conf N, <age>): <one-line lesson>  [<path>]
- ...
```

For each surfaced learning, if it bears on the current plan, state in one line **how it changes the approach**. A recall that just lists titles and moves on is the failure mode this exists to kill (that is what review Step 2 did = nothing). Apply confidence decay: `effective = max(0, confidence − floor(days_since_created / 30))`; `user-stated` never decays; skip learnings with effective confidence < 3.

If nothing relevant surfaces, print `(no relevant prior learning)` and proceed — a clean miss is a valid outcome, not a skipped step.

## Why recall

The useful mechanism is resurfacing a relevant project lesson when it can
change the current plan. Recurrence counts and store mutation are host policy;
this module only reads the configured repo path and injects the strongest match.

## Anti-patterns

- ❌ Listing recalled learnings without using them — recall MUST change the plan or be explicitly dismissed. Listing-and-ignoring is why the prior Step 2 was dead.
- ❌ Querying the whole knowledge dump — scope to `learnings/`, top 3-5, confidence-decayed.
- ❌ Treating "no relevant learning" as an error or a reason to skip the step — a clean miss is a result.
- ❌ Searching a personal or external knowledge store implicitly — Verbs reads only the repo path configured by the host project.
