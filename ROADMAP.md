# Roadmap

> Verbs is pre-1.0 and personal-first: a public, installable skill pack whose
> primary user is its author. CHANGELOG records shipped work; this file
> records the next evidence gates. Historical milestones live in git history
> and existing tags, not in the active roadmap.

## 0.x — evidence releases

0.x releases may break contracts when real usage exposes a bad boundary; every
breaking change ships with migration notes in the changelog. New skills,
folders, adapters, or policy layers need observed repeated use and must name
the existing surface they replace or extend.

The active work queue is limited to failures found through:

- daily use of the 11 active skills on Claude Code and Codex
- Claude/Codex parity checks (`doctor --strict`, hook truth tables)
- reinstall and version-bump cache-refresh drills

No feature is scheduled only to fill a version milestone. Concrete work lives
in GitHub issues; this roadmap carries gates, not a duplicate backlog.

## v1.0 gate

Cut `v1.0.0` only when all of these are true:

1. The product name, plugin selector, namespace, CLI, manifest schema, and
   install contracts survive two consecutive 0.x releases without a breaking
   rename.
2. Claude Code and Codex both pass fresh install, documented reinstall,
   cold-start invocation, and full hook registration on the author's machines.
3. One model-upgrade audit (capability / context / neither recut) has run
   against the then-current frontier model without finding a load-bearing
   regression.
4. There are no open P0/P1 product-contract failures at the release cut.

## Out of scope

Verbs does not own identity, personal context, brain or memory, project truth,
runtime/model selection, scheduling, autonomous drivers, connectors, or global
routing. Fresh-user certification — multi-persona/OS support matrices and
installer proof for hypothetical users — is out of scope; see
`docs/out-of-scope/fresh-user-certification.md`. A proposal that crosses these
boundaries needs a new product decision before implementation.
