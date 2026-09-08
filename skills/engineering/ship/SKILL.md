---
name: ship
description: On authorization to ship completed code, verify tests and review, commit scoped changes on a non-default branch, and publish the PR with current QA evidence.
user-invocable: true
---
# Ship

Read the repository's `## verbs` configuration for tests, default branch, tags, and releases. Delivery requires user authorization; this skill does not grant account access or permission to publish.

## Before committing

- Inspect branch, dirty state, base-to-head diff, and upstream state. Do not blindly pull into a dirty worktree. Run the project's real test/build command after the final edit; failure blocks delivery.
- Compare the full diff with the authorized scope and current review. Resolve scope drift and post-review changes before proceeding. Run `review` on the current diff; skipping it requires explicit approval.
- Search configured project learnings for pitfalls whose `files:` touch changed files. Skip only what an earlier read this session already listed by this same query. Running `review` is not itself evidence: its topic query takes the top 3-5, and drops effective confidence below 3. Same store, different query. Apply any remaining relevant pitfalls.
- Create the required non-default branch before staging or committing. Stage only relevant files; an empty staged diff needs no commit. Use Conventional Commits, preserve hooks, and never amend pushed commits.

## Publish

Push the authorized branch and resolve or create its single PR with what changed, why, and how it was tested. Do not force-push the default branch.

Tags and releases require repository configuration and authorization. Derive the configured semver bump from commits; before publication, prove cited SHAs are tag ancestors and release claims match the previous-tag diff. A mismatch blocks publication; never silently re-tag.

When `qa` ran, read its artifact-bound handoff and follow [QA comment upsert](lib/qa-evidence-format.md), including locking, owner checks, conflict handling, and read-back. Stale, malformed, `FAIL`, or `UNPROVEN` evidence must not become verified evidence. Missing required browser evidence blocks a ready/done claim; non-UI work does not need a fabricated QA report.

Before asking a human to validate a built/deployed artifact, apply [artifact proof](lib/verify-the-test-loop.md). Completion requires the pushed commit/branch and PR URL, plus the verified QA comment URL when applicable. Report concrete gaps rather than claiming delivery.
