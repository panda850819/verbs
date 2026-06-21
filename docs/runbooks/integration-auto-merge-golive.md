# Runbook — earning the integration auto-merge streak (Goal A go-live)

The machinery for autonomous low-blast merge into `psdrive/integration` is built, tested,
and shipped **gated OFF** (PRs LG #28 → CC #30 → T03 #32). This runbook is the operational
path by which the loop *earns* the success signal — it cannot be earned in a build session,
only by real work flowing through the loop with you in the loop. Each step is a human gate
by design (`decisions/2026-06-20-pandastack-human-in-loop-boundary`); the loop owns nothing
here until you open it.

## Success signal (the thing being earned)

- **N=20** low-blast builds auto-merged into `psdrive/integration` over a rolling 7 days.
- **Zero fake-green**: `verdict==PASS AND advance/merged AND verify_required AND NOT verify_ran` → count 0.
- **Trust streak 20**: 20 consecutive merges with **no human revert**; the first revert resets it to 0.

Watch all three at any time (read-only, no side effects):

```bash
scripts/drive-pulse ~/site/knowledge/brain/_automation/portfolio-status/drive-log.jsonl \
  --repo ~/site/skills/pandastack --days 7
# → GOAL SIGNAL: fake-green (window) 0 ✓ ; trust streak  k/20 (k merges, r reverts seen)
```

## Step 1 — land the machinery (human merge gate)

Merge in order; #32 is stacked on #28 + #30:

```
gh pr merge 28 --squash   # LG  — ledger / verify_ran
gh pr merge 30 --squash   # CC  — dispatch flock
# rebase #32 onto main (the LG/CC commits drop out), then:
gh pr merge 32 --squash   # T03 — router + integration merge + part-4 measurement
```

## Step 2 — dry-run on real issues (still gated OFF)

Confirm the router classifies your real Building issues correctly **before** any merge.
Run with `--build-auto` but **without** `--merge-auto`: it builds + proposes, never merges.

```bash
scripts/pandastack-drive --execute --build-auto --only pandastack --max 1
# inspect: blast classification, host-verify result, the kept psdrive/<ISSUE> branch.
```

If a low-blast issue is misclassified high (or vice-versa), tune `config/high-blast-paths`
(default-deny: when unsure it stays high-blast = PR-only). Re-run until classification is right.

## Step 3 — turn the ratchet ON (the one-way-door decision — yours)

This widens the autonomy fence. Scope it to **one** project first; never global.

```bash
scripts/pandastack-drive --execute --build-auto --merge-auto --only pandastack --max 1
```

The kill-switch is your out-of-band stop at any moment:

```bash
touch ~/.config/pandastack/STOP     # next tick: zero dispatch, drive-log records suppressed
rm    ~/.config/pandastack/STOP     # resume
```

## Step 4 — earn the streak (real work + your non-revert)

Real low-blast Building issues flow through. Each clean auto-merge into integration adds to
the streak. If you review an auto-merged change and it's wrong, disconfirm it:

```bash
git -C ~/site/skills/pandastack revert --no-edit <merge-sha>   # resets the streak to 0
```

`drive-pulse --repo` reads these reverts from git history automatically. When it shows
**`trust streak 20/20, fake-green 0`** over a rolling 7 days, the verdict is earned — that
is the point you stop cold-reading every diff. Until then, keep reviewing.

## Step 5 — integration → main (still human, until T05b graduates)

`psdrive/integration` accumulates earned low-blast work. Promoting it to `main` is a separate
human step (T05a, not yet built). Auto-promote + CI-red auto-rollback (T05b) graduates only
**after** the 20-streak, per boundary call #3.

## Rollback / reset

- Bad single merge: `git revert <merge-sha>` on integration (also disconfirms the streak).
- Reset integration to main entirely: `git branch -f psdrive/integration main` (discards the
  accumulated auto-merges; the loop rebuilds from a clean base on the next tick).
- Nothing here ever touches `main` or pushes a remote; integration is local and disposable.
