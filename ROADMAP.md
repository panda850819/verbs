# Roadmap

> Verbs is pre-1.0. CHANGELOG records shipped work; this file records the next
> evidence gates. Historical pandastack milestones remain in git history and
> existing tags, not in the active roadmap.

## v0.5.0 — product baseline

Status: shipping.

The baseline is deliberately small:

- one product name: **Verbs**
- one public selector and namespace: `verbs@verbs`, `/verbs:*`
- 14 composable skills with manifest, resolver, eval, and test coverage
- verified marketplace installs for Claude Code and Codex
- selective manual import for Hermes
- deterministic archives, checksums, exact-tag preflight, and rollback proof

`v0.5.0` begins the Verbs version epoch. Existing `v1.*` and
`v4.0.0-rc.1` tags/releases are immutable legacy history. The transition from
`4.0.0-rc.1` requires explicit uninstall/reinstall because SemVer sorts
`0.5.0` below the RC.

## 0.x — evidence releases

0.x releases may break contracts when real usage exposes a bad boundary. Every
breaking change must include migration and rollback instructions. New skills,
folders, adapters, or policy layers need observed repeated use and must name the
existing surface they replace or extend.

The active work queue is limited to failures found through:

- fresh install and first-session attempts
- repeated use of the existing 14 skills
- Claude/Codex parity checks
- release, reinstall, and rollback drills

No feature is scheduled only to fill a version milestone. Concrete work lives
in GitHub issues; this roadmap carries gates, not a duplicate backlog.

## v1.0 gate

Cut `v1.0.0` only when all of these are true:

1. The product name, plugin selector, namespace, CLI, manifest schema,
   repository contract, archive naming, and canonical environment prefix
   survive two consecutive 0.x releases without a breaking rename.
2. Claude Code and Codex both pass exact-tag fresh install, documented
   upgrade/reinstall, cold-start invocation, and rollback proof.
3. At least three people other than the author complete installation without
   live help and use Verbs for seven days; their failures are captured as issues.
4. At least one non-author completes the documented software-work path from
   clarification through verified delivery on each first-class host.
5. There are no open P0/P1 product-contract failures at the release cut.

Hermes packaged parity is not a v1.0 gate. Its supported contract remains
selective manual import until evidence justifies a first-class adapter.

## Out of scope

Verbs does not own identity, personal context, brain or memory, project truth,
runtime/model selection, scheduling, autonomous drivers, connectors, or global
routing. Those concerns stay with the host or project. A proposal that crosses
this boundary needs a new product decision before implementation.
