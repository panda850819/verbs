---
name: careful
description: |
  Use when working on production code, shared infrastructure, or
  unfamiliar codebases. Adds confirmation gates before destructive
  commands (force push, rm -rf, publish, DROP).
writes:
  - cli: stdout
forbids:
  - cli: git push --force
  - cli: git reset --hard
  - cli: git clean -f
  - cli: rm -rf
  - cli: npm publish
  - cli: cargo publish
domain: shared
classification: exec
---

# Careful Mode

Adds a confirmation gate before destructive or high-risk actions.

## On Invoke

Announce: "CAREFUL mode ON. Will confirm before destructive actions."

## While Active

Before executing any of the following, pause and ask the user for explicit confirmation:

### Git
- `git push --force`, `git reset --hard`, `git clean -f`
- `git branch -D` (force delete)
- `git checkout .` or `git restore .` (discard all changes)
- `git rebase` on shared branches
- Any push to main/master

### Filesystem
- `rm -rf` on an **unscoped / non-reinstallable** path: anything outside the current project, a path with a glob/variable that could expand wrong, or removal of source / data / config that isn't trivially regenerable
- Deleting more than 3 files at once
- Overwriting files outside the current project

**Exemption (does NOT trigger the gate, regardless of where the path lives):** removal of a directory whose **basename** names a trivially-reinstallable artifact — `node_modules`, `.next`, `dist`, `build`, `target`, `.cache`, `.turbo`, `__pycache__`, or a lockfile-regenerable deps dir. Key off the artifact NAME, not project membership: `rm -rf /anywhere/node_modules` is exempt because reinstall restores it. Do NOT use "is this the current project?" as the test — you often cannot resolve the cwd vs the target path, and an absolute foreign-looking path must not re-trigger the gate. The only conditions are: (1) basename is a regenerable artifact above, and (2) the path is explicit, no glob/variable that could expand wrong. **Multi-path:** if the command removes more than one path, EVERY path must independently satisfy (1) and (2) — a single foreign or non-artifact path (e.g. `rm -rf node_modules ../../prod-data`) re-arms the gate for the whole command. The gate is for irreversible / shared-state damage, not routine cleanup.

### External
- Any API call that mutates external state (POST/PUT/DELETE to production)
- Publishing packages (`npm publish`, `cargo publish`)
- Deploying to production environments

### Database
- DROP, TRUNCATE, DELETE without WHERE
- Schema migrations on production

### Verification integrity (@../../../lib/verify-the-test-loop.md)
- Before asking a human to manually test a build, or claiming done based
  on their manual test: prove the deployed artifact embeds the change
  (content marker / source-not-newer / pinned path / stable identity).
  Unproven ⇒ the bug is the pipeline; fix the loop, don't ask them to
  re-test. ("BUILD SUCCEEDED" is not deploy-proof.)
- Instrumentation you added not visible in their output ⇒ STOP, that is
  a pipeline alarm, not a fluke.
- 3 same-shape failures ⇒ switch abstraction / re-verify the loop, not a
  4th variant of the same approach.

## Confirmation Format

```
CAREFUL: About to {action}.
  Target: {what}
  Reversible: yes/no
  Proceed? [y/n]
```

## Stopping discipline

The destructive-action gates above are the *only* legit pauses. A stop-to-ask that is neither a gate nor a genuine external dependency (credentials / preference / judgment call) is a Lopopolo "continue" failure: context I should have pulled myself. Before any such stop, run the self-check, and log every genuine ask — see `skills/engineering/careful/lib/stopping-discipline.md`.

## Deactivate

User says "careful off" or starts a new session. Announce: "CAREFUL mode OFF."

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's not really production" | If it has prod data, prod users, or shared infra (DNS, OAuth, public packages), it's prod. The blast radius defines the gate, not the label. |
| "I've done this rebase a hundred times" | Muscle memory is precisely how branches get nuked. The confirm gate is 3 seconds; recovering a force-pushed branch is 30 minutes when it's recoverable at all. |
| "Force push is fine, it's my branch" | Anyone who pulled has a divergent local copy. They will silently rebase onto the wrong head and ship phantom commits. Force push to a shared remote is never local. |
| "The migration is read-only / SELECT only" | A long SELECT on a hot table acquires locks. Read-only on a replica is OK; read-only against prod primary at peak is not. |
| "I'll just `rm -rf node_modules` real quick" | Typo'd `rm -rf node_modules /` once. Confirm even when the path looks obvious — the typo lives in the half-second between intent and enter. |
| "Careful is for when I'm tired, not now" | The decision to skip the gate is itself a tiredness signal. The gate is cheap; the override is what should be expensive. |
| "I'll just ask the user one quick question to be sure" | If you can read a file or run a command to answer instead, that one quick question is a Lopopolo "continue" failure. The user's attention is more expensive than your tool calls. |
| "Asking is safer than guessing" | Sometimes. But "safer than guessing" cannot also mean "safer than checking". Check first; ask only when checking can't decide. |
