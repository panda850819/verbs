# Verbs (plugin internal)

An opinionated skill pack for taking software work from ambiguity to verified delivery. Skills are tiered core / ext in `manifest.toml` and grouped under engineering, productivity, and meta. The pack does not own identity, memory, project truth, runtimes, scheduling, connectors, or global model routing.

This file is the plugin-internal contract read by skill content. The user-facing README lives at the repo root.

## Skills (top-level surface)

Full catalog in `RESOLVER.md` at the repo root. Dev-workflow primitives:

- `/verbs:grill` — adversarial requirement discovery, atomic, no brief output
- `/verbs:grill --brief` — structured close that produces a brief + executable plan
- `/verbs:advisor --panel` — blind cross-model critique of a prepared plan
- `/verbs:review` — risk-adaptive diff review with earned cold-context escalation
- `/verbs:qa` — browser-based QA with structured assertions
- `/verbs:ship` — test + commit + push + PR for completed code work
- `/verbs:careful` — confirm before destructive actions (safety)

Skills are composed explicitly; there is no separate flow layer.

## Scenario flows (single-skill, internally chained)

- `/sprint` — focused 1-2h execution: scope → grill-lite → execute → review → ship
- `/grill --brief` — adversarial intake followed by a written brief + executable plan
- `/advisor --panel` — blind cross-model critique of a prepared plan, deduped + ranked findings, per-finding apply gate

## Learnings

Skills may read the project path configured under `## verbs > learnings` and
emit candidates in `lib/learning-format.md` shape. They do not persist knowledge;
the host/project decides whether and where to store a candidate.

## verbs

test: bash tests/run-all.sh
main: main
tag: none
release: false
deploy: null
learnings: docs/learnings
