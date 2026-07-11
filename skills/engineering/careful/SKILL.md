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
  - cli: npm publish
  - cli: cargo publish
domain: shared
classification: exec
user-invocable: false
---
# Careful Mode

Ordinary model caution can still proceed without an answer. Careful blocks the
listed destructive or high-risk action until explicit confirmation arrives.

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
- Before asking a human to test a build, or claiming done from that test, apply
  the complete proof and stopping contract in `lib/verify-the-test-loop.md`.
  An unproven artifact identity blocks the request and the completion claim.

## Confirmation Format

```
CAREFUL: About to {action}.
  Target: {what}
  Reversible: yes/no
  Proceed? [y/n]
```

## Stopping discipline

The destructive-action gates above are the *only* automatic pauses. Before any other stop, run the self-check in `skills/engineering/careful/lib/stopping-discipline.md`. Ask only when credentials, a preference, or a judgment unavailable from project evidence changes the outcome.

## Deactivate

User says "careful off" or starts a new session. Announce: "CAREFUL mode OFF."

## Common Rationalizations

Anti-bypass table tying each shortcut to the failure it causes: `@skills/engineering/careful/lib/rationalizations.md`.
