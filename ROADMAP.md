# Roadmap

> Verbs is pre-1.0. CHANGELOG records shipped work; this file records the next
> evidence gates. Historical pandastack milestones remain in git history and
> existing tags, not in the active roadmap.

## v0.5.0 — product baseline

Status: shipped on 2026-07-11 as
[`v0.5.0`](https://github.com/panda850819/verbs/releases/tag/v0.5.0).

The baseline is deliberately small:

- one product name: **Verbs**
- one public selector and namespace: `verbs@verbs`, `/verbs:*`
- 14 composable skills with manifest, resolver, eval, and test coverage
- verified marketplace installs for Claude Code and Codex
- selective manual import for Hermes
- exact-tag extracted-package preflight and rollback proof
- release notes with install commands and no redundant custom assets

`v0.5.0` begins the Verbs version epoch. Existing `v1.*` and
`v4.0.0-rc.1` tags/releases are immutable legacy history. The transition from
`4.0.0-rc.1` requires explicit uninstall/reinstall because SemVer sorts
`0.5.0` below the RC.

## v0.6.0 — portable skills, native hooks

Status: shipped on 2026-07-11 as
[`v0.6.0`](https://github.com/panda850819/verbs/releases/tag/v0.6.0).

The same 14-skill payload now has two explicit install surfaces:

- the recommended Marketplace Plugin for Claude Code and Codex, registering
  SessionStart dispatch, the Bash PreToolUse destructive guard, and the Stop
  verification gate
- a self-contained, hook-free `npx skills` install for portable use

One host profile uses one surface; native and portable installs do not coexist.
Hermes continues to use selective manual import. The host still owns identity,
brain or memory, scheduling, project truth, and global model routing. The public
release remains metadata-only with zero custom release assets.

## 0.x — evidence releases

0.x releases may break contracts when real usage exposes a bad boundary. Every
breaking change must include migration and rollback instructions. New skills,
folders, adapters, or policy layers need observed repeated use and must name the
existing surface they replace or extend.

The active work queue is limited to failures found through:

- fresh install and first-session attempts
- native Marketplace Plugin and portable `npx skills` install attempts
- repeated use of the existing 14 skills
- Claude/Codex parity checks
- release, reinstall, and rollback drills

No feature is scheduled only to fill a version milestone. Concrete work lives
in GitHub issues; this roadmap carries gates, not a duplicate backlog.

## v1.0 gate

Cut `v1.0.0` only when all of these are true:

1. The product name, plugin selector, namespace, CLI, manifest schema,
   repository and install contracts, and canonical environment prefix survive
   two consecutive 0.x releases without a breaking rename.
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
