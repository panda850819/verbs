---
name: careful
description: Confirmation gate before destructive commands or high-risk changes to production, shared infrastructure, or live harness configuration.
user-invocable: true
---
# Careful

Pause the risky action for explicit approval of its exact target, impact, and recovery path. Continue unrelated reversible work. An approval already covering that action need not be requested again.

Require confirmation before:
- Discarding Git changes, force-deleting branches, rebasing shared branches, force-pushing, or pushing to the default branch.
- Overwriting files outside the current project, deleting more than three files, or deleting non-regenerable source, data, or configuration.
- Production mutations, deployments, package publication, schema migrations, or destructive database operations.

Before destructive changes, inspect current state and make a recoverable backup. Approval does not waive secret protection or authorize unrelated account actions.

Removing an explicitly named regenerable artifact (`node_modules`, `.next`, `dist`, `build`, `target`, `.cache`, `.turbo`, `__pycache__`, or lockfile-regenerable dependencies) is exempt from the filesystem gate. Every target must qualify; glob/variable expansion or mixed source/config targets are not exempt.

Before requesting human testing or claiming completion from a built/deployed artifact, apply [artifact identity verification](lib/verify-the-test-loop.md). Missing proof blocks that request or claim, not unrelated work.
