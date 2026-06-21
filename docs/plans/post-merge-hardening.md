---
slug: post-merge-hardening
date: 2026-06-21
type: plan
source: post-merge audit (30-agent workflow)
status: in-progress
---

# Post-merge hardening — make the integration auto-merge streak honestly earnable

After LG (#28) / CC (#30) / T03 (#32) merge, the machinery to auto-merge low-blast work
into `psdrive/integration` exists, but the production loop can't yet run it and the trust
signal it grades on has gaps. This is the backlog to work **low → high blast** BEFORE the
`--merge-auto` ratchet is ever flipped on, then the remaining ladder.

> Human gates the daemon cannot do (out of scope for any agent): authoring ~20 build-ready
> low-blast work-orders (the fuel), approving them, flipping the ratchet, and the 7-day
> non-revert decisions. The items below are what an agent CAN build to make all that safe.

## Done (PR #32 follow-ups)

- **streak anti-cheat** — `rolled_back_shas` (reachability via `git merge-base --is-ancestor`)
  so a silent `git branch -f` / reset / rebase rollback breaks the streak; no phantom 20/20.
- **crash self-heal** — `merge_to_integration` prunes worktrees before the add, so a tick
  SIGKILLed mid-merge can't wedge all future auto-merges.

## Low blast (build first)

- **[in this PR] max-1/tick + kill-switch-under-ratchet** — `--merge-auto` caps `--max` at 1
  until graduation (per-merge attribution the disconfirm depends on); kill-switch proven to
  win above the ratchet flags.
- **T04 — evidence pack into the integration/PR commit body** — inject `verify_cmd` + verify
  tail + acceptance-vs-checked + diff link (fields already in the ledger). Pre-graduation the
  human's 30-sec stamp is only honest if the commit shows the evidence inline.
- **disconfirm WHY capture** — `drive-disconfirm <sha> '<why>'`: revert + append a reason row
  (bad-acceptance / subtly-wrong / misclassified / verify-flake) so a reset streak teaches
  the next round instead of re-rolling the dice. drive-pulse surfaces the last N reasons.
- **daily go/no-go as the C4 ping body** — encode healthy-today: streak climbing, fake-green
  0, no surprise gate/error jump, no silent reset without a disconfirm row.
- **kept-branch reconciliation** — after a human opens/merges/abandons or after an auto-merge,
  retire `psdrive/<ISSUE>` so the issue can be re-driven on a work-order fingerprint rotation
  (else Linear and git silently drift).
- **[latent] git_diff_paths copy (C) guard** — only bites if `-C` is ever added to the diff;
  a copy INTO a high-blast dir must take both source and dest. Add with `-C`, not before.

## Medium blast

- **C5 secrets block at commit** — the driver commits with hooks off; once auto-merge lands
  unattended, a codex-written `.env`/key rides into integration. Add a staged path+content
  matcher that fails closed → gate. Highest-severity of the cross-cutting set.
- **integration refresh toward main** — fast-forward `psdrive/integration` to main when it has
  no un-promoted commits, so clean merges grade against the current tree, not a stale base;
  drive-pulse reports ahead/behind.
- **pre-build sentinel loosening** — the F-A sentinel BLOCKs anything green pre-build, which is
  most low-blast work (refactor, new test, dep bump, idempotent maintenance). Require the
  acceptance to discriminate the diff, not the whole suite, so safe work can flow.
- **align sentinel timeout** — pre-build check uses 600s but the build allows 1800s; a slow but
  real acceptance is misread as a tautological hang. Make the two budgets agree.
- **flaky-verify quarantine** — confirm-on-green (re-run host-verify once) on the merge-eligible
  subset so a one-tick flake can't merge.

## High blast (last; separate PR, human-gated)

- **drive-cron config flags** — `drive-cron.py` hardcodes `--execute --max MAX`; add a
  per-project `~/.config/pandastack/drive-autonomy.json` (default OFF) so the launchd tick can
  build/merge per project. Empty config = today's read-only behavior. THE gap between
  machinery-merged and cron-can-auto-merge. Touches the production scheduler → its own PR, human review.
- **dry-run → ratchet as a config flip** — `{build_auto:true,merge_auto:false}` (dry-run) →
  `{...,merge_auto:true}` (ON), gated on drive-pulse showing streak 20/20 + fake-green 0; the
  flip is git history (when-did-we-ratchet-project-X is answerable from blame).
- **C6 capability-fence lock** — the loop can never self-edit SAFE_SKILLS / high-blast-paths /
  the autonomy config; any such change routes to a human (the PreToolUse guard in CLAUDE.md).

## Then the ladder (post-graduation)

- **T05a** manual promote integration→main + reset (local, no push) — the mechanism the human
  triggers, tested, before the door can ever be automated.
- **graduation gate** — `drive-graduate --check` re-derives streak==20 ∧ fake-green==0 ∧
  reverts==0 from the ledger + git, requires zero open disconfirm rows, writes a dated record;
  only then is T05b eligible. The interlock between earned-the-streak and widen-the-fence.
- **T05b** auto-promote + main-CI read + auto-rollback (the first remote default-branch write;
  careful-mode; rate-limited; post-graduation only).
- **T06 [defer]** Claude backend + Codex→Claude failover; only when Codex quota is the binding
  constraint.
