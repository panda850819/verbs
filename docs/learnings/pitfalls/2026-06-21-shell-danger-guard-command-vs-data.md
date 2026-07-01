---
type: pitfall
key: shell-danger-guard-command-vs-data
confidence: 9
source: observed
skill: debug
files:
  - plugins/pandastack/hooks/pretooluse-destructive-guard.sh
  - tests/destructive-guard-test.sh
first_seen: 2026-06-21
recurrence: 1
status: active
created: 2026-06-21
last_seen: 2026-06-21
---

## Problem

A PreToolUse danger-guard that greps each command segment for patterns (`rm`,
`-rf`, `DROP TABLE`) as a raw substring over-blocks: the same token appearing as
DATA (inside `python3 -c '...'`, an `echo`, a commit message, a heredoc value, a
Linear description) false-triggers `exit 2`. The behavioral cost is the real one
— habitual over-blocking trains the operator to reflexively add bypass markers,
which disarms the guard for the genuinely dangerous commands it exists to catch.

## What Didn't Work

First fix attempt: bind each rule to the segment's parsed **leading executable**
(skip `sudo`/`xargs`/env-assigns, fire only when `lead == rm`/`git`). It passed
its own 29 tests, but adversarial review (3 reviewers generating concrete
break-attempts, each fed through the guard) showed it opened a wide band of
false-NEGATIVES the prior whole-segment scan had caught: `sudo -u USER rm -rf`
(option ARGUMENT `USER` mistaken for the lead), `nice -n N rm -rf`, `timeout 5
rm -rf`, `( rm -rf )`, `x=$(rm -rf)`, `flock`/`parallel rm -rf`. A strict
leading-exe whitelist is defeated by any wrapper/grouping/substitution that
moves the danger word off the head position. Fixing a false-positive must not
silently open a false-negative on a guard the autonomy loop trusts.

## Solution

The two danger families are structurally opposite, so detect them differently:

- **rm/git (danger is the COMMAND word, unquoted):** strip quoted strings first,
  then scan the segment. `python3 -c 'rm -rf /'` → `python3 -c ` → passes; real
  `rm -rf` behind any wrapper/grouping/substitution is unquoted → still caught.
  Anchor flag detection to a token boundary so a PATH containing an `-r..`/`-f..`
  substring isn't read as the flags.
- **SQL (danger is the PAYLOAD fed to a client):** quote-stripping would delete
  the `DROP` payload, so instead gate command-scope: block only when a
  `DROP/TRUNCATE` statement (seen raw) co-occurs with an actually-invoked client
  (`psql`/`mysql`, seen stripped). A bare mention with no client passes.

## Prevention

- For any "detect dangerous X in a shell string" guard, decide per rule whether
  the danger is the COMMAND (strip quotes, scan) or the PAYLOAD (need an executor
  signal) — a single substring scan conflates them and is the bug.
- A guard passing its own tests is not evidence it is correct. Generate
  adversarial break-attempts and feed each through the real guard, observing the
  exit code; never trust the reviewer's predicted behavior or the suite you wrote
  to confirm your own design.
- Keep negative tests (a real force-push / recursive-force-rm / DROP still
  blocks) alongside every false-positive fix, or the usability fix becomes a
  security regression.
