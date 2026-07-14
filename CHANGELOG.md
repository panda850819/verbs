# Changelog

## v0.9.5 — Pilot worker model-tier default

### Changed

- `DISPATCH.md` Agent Worker protocol: read-only pilot workers now default
  to the cheapest model tier (`model: haiku`), reserving higher tiers for
  workers whose task itself needs judgment. Closes the gap where read-only
  research workers silently inherited the main-session frontier model and
  burned premium quota on reconnaissance. Pattern verified against a live
  probe (built-in Explore resolved to Opus 4.8 under a Fable 5 session);
  prior art: Nanako0129/pilotfish role tiering.

## v0.9.4 — Verify-gate headless allowance

### Fixed

- `stop-verify-gate.py` no longer fail-closes when the payload's
  `transcript_path` points to a file that does not exist. Headless runs
  (codex exec, install smoke tests) never write a transcript, so the block
  could not produce any verification behavior — five spurious
  `verification_input_unavailable` denies over 2026-07-12/13. The gate now
  allows with a stderr notice and records a high-signal
  `transcript_missing` guard event so headless skips stay observable.
  Malformed transcript content, missing `transcript_path` in the payload,
  and unreadable hook stdin still fail closed. (#238)

## v0.9.3 — Ticket-gate cd tracking

### Fixed

- `ticket_gate.py` now tracks `cd`/`pushd`/`popd` targets across the command
  chain, so `cd <repo> && git commit` is judged against the cd target instead
  of the session cwd. Before: committing to an opted-out repo from a gated cwd
  was falsely denied, and `cd <gated-repo> && git commit` from elsewhere
  escaped the gate. Tracking models shell semantics — subshell/backtick
  scoping, pipe and background cancellation, failed cd keeping the directory,
  `cd -` via OLDPWD, a real pushd stack — and anything not statically
  resolvable (`cd "$VAR"`, two-arg cd) reverts to the session cwd, so the
  gate never judges against a weaker repo than the pre-tracking guard.
  Posture hardened after a Codex cross-model review found the initial
  fail-open-on-unknown design allowed subshell/pipe/`cd -` bypasses. (#236)
- `git -C ~/path` values and cd targets are now `expanduser`'d; tilde paths
  previously never resolved to a repo and silently failed open. (#236)

## v0.9.2 — Invocation axis fix

### Fixed

- All 14 skills flipped `user-invocable: false` → `true`. The field gates the
  HUMAN channel in Claude Code (manual slash invocation), not model dispatch;
  the old spec defined it as an exclusive binary and every skill inherited the
  inverted value, blocking manual invocation across the whole pack. (#234)
- `maintainer/SKILL-FRONTMATTER.md`: invocation semantics rewritten as two
  independent axes (`user-invocable` gates the human,
  `disable-model-invocation` gates the model; defaults both open, per Claude
  Code docs); Description cost rule and Dependency rule re-keyed to
  `disable-model-invocation`; `writing-great-skills.md` mechanics line
  corrected. Policy adopted from the mattpocock/skills invariant: the human is
  never blocked. (#234)

## v0.9.1 — Wayfinder charting bootstrap

### Changed

- `wayfinder` now supports both entry modes: it delegates a new large, fuzzy
  effort to `grill --brief` to create a decision map and stop, or works one
  frontier entry from an existing map per session. (#231)
- DISPATCH and the skill catalog now route large multi-session efforts through
  `wayfinder` while keeping atomic fuzzy-scope discovery on `grill`. (#231)

## v0.9.0 — Discipline Cores

Released: 2026-07-13

### Added

- `codebase-design` (engineering, core): deep-module design vocabulary —
  module / interface / seam / adapter / depth-as-leverage / locality, the
  deletion test, one-adapter-means-a-hypothetical-seam, and
  testability-through-the-interface rules. Adapted from mattpocock/skills
  (MIT, THIRD_PARTY_NOTICES). (#225)
- `prototype` (engineering, core): throwaway prototype answering ONE design
  question — logic branch drives a terminal state model (`LOGIC.md`); UI
  branch renders N structurally different variants behind `?variant=`
  (`UI.md`). Verdict lands on the tracking issue/brief; the prototype lands
  on a `prototype/<slug>` branch, never the default branch. (#225)
- `wayfinder` (productivity, core): cross-session decision-map worker.
  grill's wayfinder exit writes the map; wayfinder walks it — one frontier
  entry per session, resolved by type (research / grilling / prototype /
  task), decision written back, fog graduated. Composes grill + prototype.
  (#228)

### Changed

- `grill`: facts-vs-decisions protocol rule (derivable answers are legwork,
  the human gets only genuine forks); brief scaffold gains a Seams section;
  one-time offer to mint the tracking issue from the brief; Stage C+
  granularity confirm; wide-refactor expand → migrate → contract exception.
  (#227)
- `ship`: gate 8 release truth gate — generated notes verified against the
  tagged tree (cited PRs/SHAs must be tag ancestors; add/remove claims must
  match `git diff prev..tag --stat`); on mismatch fix the notes, never
  re-tag. (#227)
- `writing-great-skills` + glossary: Negation principle — positive target
  behaviour wherever a positive form exists; prohibitions only as hard
  guardrails, paired with the replacement behaviour. (#227)
- `ui`: description now routes divergent throwaway variant exploration to
  `prototype`. (#225)
- DISPATCH: rows for `prototype` and `wayfinder`. (#225, #228)
- Repo config truth-up: `## verbs` block in CLAUDE.md / AGENTS.md now
  `tag: semver` + `release: true`, matching actual release practice;
  RESOLVER.md version line un-drifted (was still v0.7.3). (#229)

## v0.8.0 — Personal-First Slim

Released: 2026-07-12

### Removed

- The fresh-user certification layer: `release-preflight.sh` and its test,
  the preflight `release.yml` pipeline and `release-workflow-test.sh` (a
  minimal tag → generated-notes workflow replaces it), `installer-smoke.sh` and its
  structural test, the portable `npx skills` surface with
  `portable-skills-test.py` and the pinned external installer proof,
  `legal-files-test.sh`, and the per-skill `eval.md` hash-freshness ceremony
  (`lint-eval-fresh.sh`, `lint-eval-quotes.py`, `lint-eval-verdict-test.sh`,
  11 co-located `eval.md` files). Rationale recorded in
  `.out-of-scope/fresh-user-certification.md`. (#220)
- Dead weight: four orphaned `lib/` modules (`bad-good-calibration`,
  `capability-probe`, `escape-hatch`, `mermaid-grounding`) plus
  `lib/lint-mermaid-grounding.sh`, top-level `lib/skill-eval.md` and
  `lib/quality-rubric.md` duplicates, `archive/retired-skills/`, two frozen
  historical eval snapshots and the unwired browser-integration harness,
  executed `docs/plans/`, shipped brief/session records, and the two
  superseded audits.
- The `maintainer/skill-creator` machinery. Skill-writing lore lives directly
  at `maintainer/writing-great-skills.md` with its glossary and the artifact
  `quality-rubric.md`.
- The `grill` goal-mapping pre-step and `lib/goal-mapping.md`; review's
  Pass 8 quality-rubric ritual (Pass 4-7 stay signal-gated).

### Changed

- `ship` and `qa` rewritten in invariant form. Every hard gate is kept —
  branch-before-commit, review gate, scope check, closure evidence, the
  STEP_PASS assertion protocol, the verification rigor order, and report
  routing — while step-by-step coaching that current models carry natively is
  removed.
- Docs describe the Marketplace-Plugin-only surface; completed v3/RC migration
  playbooks compressed to a pointer at git history; the v1.0 gate is
  personal-first (author-machine install proof and a model-upgrade audit
  instead of three-non-author-user certification).
- Doc surface consolidated for AI iteration (upstream mattpocock/skills
  shape): `CLAUDE.md` rewritten as the repo iteration contract (layout, sync
  obligations, verify, authoring bar); `INSTALL_FOR_AGENTS.md` and
  `ROADMAP.md` folded into `README.md`; `docs/HERMES.md` folded into
  `docs/ADDING_A_HOST.md`; `docs/firewall-l5.md` folded into the frontmatter
  spec, which moved to `maintainer/SKILL-FRONTMATTER.md`;
  `docs/out-of-scope/` relocated to `.out-of-scope/`. Root markdown surface
  10 → 7 files.

### Kept deliberately

- All four hooks with their truth-table tests, `doctor --strict` runtime
  parity, `verbs sync` determinism, the structural lint suite, the offline
  conformance adapter smoke, and `codex-hook-smoke.py`. Everything protecting
  live enforcement on the author's machines stays.

## v0.7.3 — Guard Evidence and Native Workers

Released: 2026-07-12

### Added

- One fsynced, append-only `verbs.guard-event.v1` JSONL stream records
  privacy-minimal deny, error, and override decisions from Claude Code and
  Codex without storing shell command payloads. Set
  `VERBS_GUARD_EVENT_LEVEL=all` for full allow tracing.
- Regression coverage makes ticket-gate absence, verify-gate fail-open,
  command-vs-data confusion, hook drift, and event-log loss red-capable.
- `tests/ticket-gate-guard-test.sh` expands its offline fixture-repo suite from
  29 to 52 cases.
- Explicit Agent Worker requests use at most two depth-one, read-only native
  subagents with a shared WorkOrder and WorkerResult contract; no new runner,
  scheduler, queue, or state machine is introduced.
- Blocking tests prove that both Claude and Codex SessionStart payloads inject
  the Agent Worker protocol and reject missing contract fields.

### Changed

- Stop verification fails closed when its input or runtime adapter is
  unavailable, while loop prevention and pure Q&A still pass.
- Agent Worker metrics are coordinator-owned and accepted only when exposed by
  the runtime; worker estimates cannot become telemetry evidence.
- Anthropic advisor routes retain the previously verified `opus/high` seat, and
  model-anchor tests reject the expired Fable selector.

## v0.7.2 — Four-Hook Smoke Truth

Released: 2026-07-12

### Fixed

- `scripts/codex-hook-smoke.py` still asserted "exactly three Verbs hooks";
  v0.7.1 registers four (second PreToolUse = ticket-gate), so the live proof
  failed against a correct install. Expected inventory is now the four-entry
  list (duplicate preToolUse/Bash pair) compared as a sorted multiset.

## v0.7.1 — Ticket-Gate Guard Reinstated

Released: 2026-07-12

### Added

- `hooks/pretooluse-ticket-gate-guard.sh`: hard-blocks `git commit` on the
  default branch (main/master), `git push` with an explicit main/master
  refspec, and bare `git push` while on main. GitHub-issue-keyed flow (Linear
  retired in substrate v0.9.13). Bypass `PSTICKET_FORCE=1` / `PANDA_FORCE=1`;
  kill switch `VERBS_TICKET_GATE=off`; per-repo opt-out via a
  `.verbs-ticket-gate-off` file at the repo toplevel; fails open on
  guard-internal ambiguity. Branch naming stays advisory. (#203)
- `tests/ticket-gate-guard-test.sh`: offline fixture-repo suite (29 cases).

### Changed

- `pretooluse-destructive-guard.sh` parses hook input with a single python3
  invocation (was two) — lower fixed overhead on every Bash tool call.
- DISPATCH.md: `qa` gains a routing row (was orphaned — reachable only via
  frontmatter matching); the 3+-files row no longer names nonexistent
  "grill-lite".

## v0.7.0 — Current-Model Surface Recut

Released: 2026-07-12

### Changed

- The default runtime surface is 11 skills. `writing-great-skills` is now a
  maintainer library, `skill-creator` is maintainer-only, and `write` moved to
  Panda's personal overlay with default exposure disabled.
- Construction/eval guidance no longer consumes a normal-session skill slot.
- The installed plugin and portable manifests are generated from the reduced
  active set; retired names must not appear in cold discovery.

### Compatibility

- Engineering, safety, review, delivery, browser QA, UI, and cross-model
  capabilities retain their existing names and contracts.
- Pack maintenance starts from `maintainer/skill-creator/SKILL.md`.

## v0.6.1 — Runtime Parity and Live Trust

Released: 2026-07-11

### Fixed

- Claude transcript reduction no longer treats a background verification launch
  acknowledgement as a completed green check.
- List-form user prompts now reset the Claude turn window, preventing verified
  work from an earlier turn from leaking into the current Stop decision.

### Added

- `scripts/verbs doctor --host codex --strict --live-hooks` now asks the live
  Codex app-server for the installed Verbs hook inventory and fails when any of
  the three hooks lacks persisted trust.
- The live hook verifier supports an inventory-only trust gate while preserving
  the existing explicit bypass path used by isolated installer automation.

### Verified

- The blocking suite covers trusted and untrusted live-inventory outcomes with
  a synthetic app-server boundary and keeps the default doctor path offline.

## v0.6.0 — Portable Skills, Native Hooks

Released: 2026-07-11

### Added

- The recommended Marketplace Plugin surface for Claude Code and Codex now
  registers the SessionStart dispatch adapter, Bash PreToolUse destructive
  guard, and Stop verification gate.
- The full 14-skill pack is self-contained for portable installation. Each
  skill carries its declared resources and composition edges without depending
  on shared root files.

### Install

Recommended Marketplace Plugin:

```bash
claude plugin marketplace add panda850819/verbs --scope user
claude plugin install verbs@verbs --scope user

codex plugin marketplace add panda850819/verbs --json
codex plugin add verbs@verbs --json
```

Portable, hook-free skills:

```bash
npx skills@latest add panda850819/verbs -a claude-code codex -g -y
```

Choose one surface per host profile. Installing both creates duplicate skill
discovery and an ambiguous hook contract.

### Boundary

- Verbs owns the skill pack and its narrow native hook adapters. The host owns
  identity, brain or memory, scheduling, project truth, and global model
  routing. Hermes remains a selective manual import.

### Distribution

- The GitHub release remains metadata-only with zero custom release assets.
  GitHub's standard source archives remain available.

### Verified

- The public `npx skills` command found and installed all 14 skills into
  disposable Claude Code and Codex targets. All 36 declared resources and 7
  directional companion edges resolved inside the installed payload.
- Claude Code and Codex both passed a same-profile
  `v0.5.0 → v0.6.0 → v0.5.0` reinstall cycle. The installed v0.6 hook tree
  passed all 27 contract checks; Claude's component inventory reported exactly
  three registered hooks, and Codex discovered the same three hooks and
  triggered SessionStart from the installed plugin.

## v0.5.0 — Verbs

Released: 2026-07-11

### Changed

- The product name is **Verbs**. The repository, display name, and canonical
  environment prefix are now `panda850819/verbs`, `Verbs`, and `VERBS_`.
- The active roadmap now tracks a small 0.x evidence line and explicit v1.0
  gates. The retired persona, vault, personal-OS, and lifecycle milestones no
  longer appear as current work.
- `v0.5.0` begins a new Verbs version epoch. Existing `v1.*` and
  `v4.0.0-rc.1` tags/releases remain immutable legacy history.

### Install

Claude Code:

```bash
claude plugin marketplace add panda850819/verbs --scope user
claude plugin install verbs@verbs --scope user
```

Codex:

```bash
codex plugin marketplace add panda850819/verbs --json
codex plugin add verbs@verbs --json
```

Generic `npx skills` installation is not advertised yet. It discovers the 14
skills but drops shared root contracts when it installs each skill directory in
isolation. Self-contained generic installs are tracked in
[#189](https://github.com/panda850819/verbs/issues/189).

### Compatibility

- Moving from `4.0.0-rc.1` to `0.5.0` is an explicit uninstall/reinstall;
  SemVer sorts `0.5.0` below the RC, so an ordinary upgrade is unsafe.
- `VERBS_*` is canonical. Documented `PANDA_VERBS_*` path and verify-gate
  variables remain read-only fallbacks through v0.5.x. The retired
  `scripts/pandastack` shim also forwards its two legacy path variables.
- The plugin selector and namespace stay `verbs@verbs` and `/verbs:*`.

Claude Code reinstall:

```bash
claude plugin uninstall verbs@verbs --scope user --keep-data
claude plugin marketplace remove verbs --scope user
claude plugin marketplace add panda850819/verbs --scope user
claude plugin install verbs@verbs --scope user
```

Codex reinstall:

```bash
codex plugin remove verbs@verbs --json
codex plugin marketplace remove verbs
codex plugin marketplace add panda850819/verbs --json
codex plugin add verbs@verbs --json
```

### Distribution

- GitHub Releases contain the changelog and install commands, with no custom
  tarball or checksum. GitHub's standard source archives remain available.
- Exact-tag archive extraction stays an internal test of the packaged tree; an
  asset is added only when a separate consumer needs its own format.

### Verified

- Manifest-driven Claude, Codex, and Agents metadata agree on version `0.5.0`,
  repository identity, and the exact 14-skill surface.
- Release preflight extracts and tests the exact tagged tree before the
  annotated tag is pushed, while the public release remains metadata-only.
- Disposable Claude and Codex profiles install and invoke the exact tagged
  artifact; real profiles use the same explicit reinstall path.

## v4.0.0-rc.1 — Verbs

Released: 2026-07-11

> **Release candidate.** Panda Verbs is the public skill pack. Personal context,
> memory, runtimes, schedulers, connectors, and project truth stay with the host.

### Breaking

- Product, repository, plugin, and namespace rename to **Panda Verbs**,
  `panda-verbs`, `verbs@verbs`, and `/verbs:*`.
- `/pandastack:*` has no alias. Claude Code and Codex must remove the old plugin
  before installing `verbs@verbs`; otherwise stale v3 policies remain active.
- `/ship knowledge` and the `knowledge-ship` alias moved out of the public pack.
  Knowledge lifecycle and persistence belong to the host's knowledge system.
- `scripts/verbs-state`, `scripts/pandastack-state`, and the project lifecycle
  store are removed. State belongs to the host/project.

### Changed

- The product definition is now one sentence: "An opinionated skill pack for
  taking software work from ambiguity to verified delivery."
- `manifest.toml` owns the complete product dictionary. `scripts/verbs sync`
  deterministically generates all Claude, Codex, and Agents loader metadata.
- Automatic plugin hooks are removed. `DISPATCH.md` and the reference guard
  scripts remain available for hosts that opt in explicitly.
- `verbs doctor` checks the 14-skill source surface and installed plugin parity.
  The retired capability map, ticket/worktree policy hook, lifecycle state
  helper, and `/loop` driver kickoff are gone.
- Claude Code and Codex both use their real local marketplace installers.
  Hermes remains selective manual import; OpenClaw is experimental.

### Compatibility

- `scripts/pandastack` remains a one-line RC forwarding shim with a deprecation
  notice on stderr. The old state CLI has no v4 replacement.
- `PANDASTACK_VERIFY_GATE` remains an RC fallback when the new variable is
  unset for hosts that wire the optional verify adapter.
- GitHub's old repository URL redirects after the rename. Recreating the old
  repository name is intentionally unsupported because it breaks that redirect.
- Migration pins v3.4.2 commit
  `8d9a382b74d5b3e0ef0b6e91375fab3a172a916f` as an immutable rollback
  checkout through the RC dogfood window.

### Verified

- Generated metadata fails red on product id, repository, hero, category,
  version, or skill-surface drift.
- Automated preflight proves the packaged tree and synthetic cache scanner.
  The RC operator gate separately installs the exact tagged checkout in
  disposable Claude and Codex profiles before the tag is pushed.
- Prerelease tags publish with `--prerelease --latest=false`; archives and their
  SHA-256 checksums use the `panda-verbs-v<version>` prefix.

## v3.4.2 — Parity

Released: 2026-07-10

### Added

- Deterministic tag preflight and a tag-only, least-privilege GitHub Actions
  release workflow produce exact release metadata, an archive, and its SHA-256
  checksum. Publishing stays draft-only until every asset upload succeeds.
- Root `LICENSE` and `THIRD_PARTY_NOTICES.md` files make the project terms and
  third-party notices visible in both fresh clones and release archives.

### Fixed

- Runtime discovery now exposes the same exact 14-skill set in Claude and
  Codex; four retired skills moved outside every plugin discovery root.
- Ticket and verify gates share one Claude/Codex event normalizer. Codex
  `apply_patch`, successful tool outcomes, async exits, same-turn compaction,
  later edits, and failure-masking test commands now have regression coverage.
- `pandastack doctor --strict` compares installed skill names, plugin version,
  `DISPATCH.md`, and the complete hook tree with source. Conformance smoke now
  rejects missing, extra, retired, and foreign-namespace skills.

### Verified

- Offline Claude/Codex gate truth tables cover allowed and blocked edits,
  passing and failing verification, stale green, and edit-after-green.
- Synthetic source/cache fixtures fail red on skill, version, dispatch, and
  hook drift; the canonical offline suite remains the release gate.

## v3.4.1 — 2026-07-10

### Changed

- Added `lib/model-anchors.md` as the shared execution contract for `advisor`,
  `handover`, and sprint Codex delegation. Every delegated call now pins model,
  effort, minimum CLI version, and permission guard instead of inheriting host
  defaults.
- Bootstrap readiness is version-aware for handover and both advisor directions;
  older installed CLIs report `outdated` instead of a false-green `ready`.
- Anchored judgment calls to Sol/high or Opus/high, mechanical handover to
  Luna/medium, and risk-sensitive handover to Sol/high. Advisor panel critics
  now use role keys instead of model names in the skill body.
- Async handoffs now embed a `<runtime>` block. Direct headless dispatch is the
  verified default; Hermes must prove its adapter applied both model and effort
  or fail loud.

### Verified

- Codex CLI 0.144.1: direct read-only fixed-token probes passed for Sol/high,
  Terra/medium, and Luna/medium.
- Claude Code 2.1.206: direct Opus/high fixed-token probe passed with tools
  disabled and session persistence off.
- Claude Code 2.1.206: direct Sonnet/medium fixed-token probe passed with tools
  disabled and session persistence off; nested calls clear `CLAUDECODE`.
- Companion limitation remains explicit: Luna/medium and Sol above high were
  rejected on the app-server path, so pandastack does not route those calls
  through the companion.

## v3.3.0 — 2026-06-30

### Changed
- **retro-week / retro-month moved to the personal overlay** (`~/.agents/skills/`); public pack 25 → **23 skills** (21 core / 2 ext). They are brain-centric personal reflection (PKM), not coding-agent skills. With the new event-driven `lib/learning-recall.md` (recall at every dev-unit opener — `review` / `sprint` / `debug`), compounding now happens continuously in the dev flow rather than via a calendar retro. The shared `retro-scan.sh` engine moved with them. `lint-manifest-sync` stale-count regex tightened to `2[4-9] skills`.
- **Single-sourced version + skill count** (#122): `manifest.toml` is the one hand-edited place; new `scripts/pandastack sync` regenerates `version` + the "N skills" description into `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, and `.claude-plugin/marketplace.json`. `lint-manifest-sync.sh` now adds `.codex-plugin/plugin.json` to its scan set and runs `sync --check`, closing the hole that let the Codex loader fall behind to 3.2.0 / "25 skills".
- **Doc reconciliation to 23 skills / v3.3.0** (#122): fixed the Codex plugin loader, the `CLAUDE.md` lifecycle list, `RESOLVER.md` (provenance row, version pointer, dead Retro/session table, `tool-browser` alias), the `README.md` Core count + empty Reflect table, and stale present-tense "25 skills" claims in `ROADMAP.md` / `evals/` / the first-principles audit.

## v3.2.0 — 2026-06-29

> **Persona layer removed; doc surface reconciled to 25 skills.** The 5 role-persona skills are cut (the model holds those frames natively); their durable lore moves into function-named skills (`debug`, `ui`) and the intake skills. `advisor --panel` is rebuilt persona-free. Skill count is now **25 (23 core / 2 ext)**. This release also consolidates the post-2.2.0 work below (handover split, ship write-mode retirement, pdctx/overlay doc strip).

### Removed

- **Persona layer** (PR #100/#101): the 5 role-persona skills (`ceo`, `product-lead`, `eng-lead`, `design-lead`, `ops-lead`) plus `lib/persona-frame.md` and `lib/outside-voice-rule.md`. Role-persona lenses were a uniform wrapper over frames the model already holds; eng-lead debug lore → new `debug`, design-lead craft → new `ui`, scope-judgment / delete-first → `grill` / `grill --brief`, ops-lead → retro-week / cron. git history is the archive.
- `ship` write mode retired (`references/modes/write-mode.md` deleted, `write-ship` alias dropped). The mode's entire input tree (obsidian-vault `Blog/_daily` / `Blog/Drafts` / `Blog/Published`) no longer exists after the 2026-06 machine rebuild, and brain owns daily content — the mode pointed at a dead path. Writing composition is now `/write` → manual publish; README lifecycle map + RESOLVER updated. Companion W24-retro GC in the same sprint scrubbed the remaining `Blog/_daily` references from `ship` SKILL.md / knowledge mode / `DISPATCH.md contract`.
- `pandastack-private` overlay and `pdctx` references stripped from user-facing docs: README collapsed to a single self-contained surface (no public/private tier split, no pdctx context-dispatch), `docs/telemetry.md` deleted (it documented the pdctx-only audit timeline), `docs/HERMES.md` rewritten to direct skill import. The v2.2.0 "moved to overlay" entry below is unchanged release history.

### Added

- `handover` skill — hand UNFINISHED work to Codex to DO. `/handover [slug]` (sync) spawns `codex exec` now and collects the structured result; `/handover --async [slug]` writes a payload to `docs/handoffs/` for Hermes / offline. Splits cleanly from `/ship`: ship CLOSES finished work, handover DELEGATES unfinished work. Owns the single Codex-invocation SSOT (`references/codex-invocation.md`): XML payload, verified `codex exec`, sandbox-escape gate, result classification.
- `lib/trigger-first-skill-evolution.md` — shared rule for skill evolution: trigger clarity first, inline checklist / rubric before extraction, no lens / persona / rubric registry until repeated evidence exists.
- `debug`, `ui`, `advisor --panel` skills — function-named (lore + reflex-overrides, not a persona frame). `advisor --panel` is the deleted persona-router rebuilt as a ~30-line blind-critic forcing function: mutually-blind parallel plan critique, no persona voices.
- Doc reconciliation + `lint-manifest-sync.sh` guard hardening (PR #103): every living doc aligned to 25 skills (23 core / 2 ext); persona / `contexts/` / pre-flatten `plugins/pandastack/` refs purged; the broken `.codex/INSTALL.md` `codex-tools.md` path fixed; the stale-claim guard now catches `26`/`28 skills` + persona refs across README / CLAUDE.md / INSTALL / marketplace / PHILOSOPHY / DISPATCH.md contract so the drift can't silently reappear.

### Changed

- `ship` no longer carries a `codex` mode — moved to the new `/handover` skill (handover ≠ ship). `/ship codex` is removed; use `/handover --async`.
- `sprint --delegate codex` is now explicit-opt-in only (never auto-triggered); the mechanical-unit threshold dropped from 5 to 3 but is **advisory** — at ≥3 it's worth surfacing the flag, the switch stays the explicit `--delegate codex`. Delegation now runs each batch via `handover`'s invocation SSOT; `sprint/references/codex-delegation.md` keeps only the batch loop + circuit breaker. Rationale: Codex runs on ChatGPT-subscription quota (separate from Claude), so it is NOT the metered-API path `prefer-cc-subagents` guards against — but delegating to a second runtime has side effects, so it stays opt-in rather than inferred from unit count.

- `skill-creator` now loads the trigger-first rule before creating, splitting, merging, or extracting skills.
- `skill-creator` verification now reflects the repo's real check surface: `git diff --check`, SKILL frontmatter scan, and manual `tests/resolver-golden.md` cases when routing changes. It no longer points at absent Bun tests.
- `DISPATCH.md contract` now points harness edits at the trigger-first rule so skill-library changes evolve from observed use instead of upfront taxonomy.
- `RESOLVER.md` skill-creator row now reflects the trigger-first abstraction gate.
- `plugin.json` (Claude + Codex) aligned to the current manifest — 26 skills (24 core / 2 ext), no personal tier, no flow count — and bumped 2.1.2 → 2.2.0; dropped the stale `agents` keyword (pandastack is skill-only).
- Hermes consumption documented as direct skill import into `~/.hermes/skills/` (Runtime support, Per-host install, Updating); the pdctx dispatch path is retired.

## v2.2.0 — 2026-05-09

> **Scope tightening**. Public package shrinks 38 → 26 skills, 7 → 0 lifecycle flow specs. The personal tier moves out of this manifest entirely (lives in `pandastack-private` overlay). Notion / Slack ops migrate to MCP. Philosophy shifts from "personal AI operator OS that manages your retro / research / work / decisions" to "**skill library that ships verbs; the brain keeps state; lifecycle discipline is your job, not the package's**".

### Removed (8 skills archived to `_archive/`)

- **`think-like-naval`, `think-like-alan-chan`** — replicating someone else's thinking pattern is mimicry, not insight. The 5 role personas (ceo / product-lead / eng-lead / design-lead / ops-lead) cover the cognitive-lens use case at the right abstraction.
- **`inbox-triage`** — a pre-brain-era vault hygiene skill. With `gbrain` connected, `mcp__gbrain__find_orphans` + `find_anomalies` + a 5-minute manual Inbox/ glance covers the same ground.
- **`scout`** — ad-hoc `gh repo view` + `WebFetch` is sufficient. Skills should earn their existence; reconnaissance over public repos is something Claude does fluently without a Skill wrapper.
- **`summarize`** — gbrain ingest paths (`voice-note-ingest`, `media-ingest`, `idea-ingest`) replace standalone summarization. If you want raw transcript without ingest, use the underlying CLI directly.
- **`work-ship`** — folded into `/ship knowledge` as the **decision-note variant** (triggered when path matches `decisions/`). A decision page IS a knowledge note about a decision; the shape (frontmatter + body + cross-link) is identical, only the Extract questions and one Stage 1 side-effect (writing `Inbox/ship-proposals/` for manual external push) differ. Deprecated alias `work-ship` resolves until 2026-08-07.

### Removed (2 skills hard-deleted; use MCP instead)

- **`notion`, `slack`** — Claude.ai Notion / Slack MCP via OAuth replaces the local-CLI-with-keychain-token model. Token doesn't sit on disk. Use `mcp__claude_ai_Notion__*` / `mcp__claude_ai_Slack__*` directly.

### Moved to `pandastack-private` overlay (4 skills)

- **`bird`, `brief-morning`, `evening-distill`, `curate-feeds`** — all require private CLIs (bird, gog, feed-server) that cannot ship in a public package. The overlay is now their canonical home. Public users see `bootstrap.sh` reporting nothing missing; private overlay users get them by installing `pandastack-private`.

### Removed (lifecycle flow specs)

- **`plugins/pandastack/flows/`** entire directory deleted (7 `.md` files: dev / writing / knowledge / research / work / retro / decision). Lifecycle docs collapse into:
  - **Per-skill SKILL.md**: `/sprint` covers dev; `/ship knowledge` covers knowledge close (incl. decision-note variant); `/ship write` covers writing close; `/retro-week` and `/retro-month` cover retro cadence.
  - **README "Lifecycle map" section**: 30-second visual + cross-flow router for the 3 first-class compositions (dev / writing / knowledge).
  - **Demoted because not real flows**: `research` (knowledge variant), `work` (dev variant + decision-note variant of ship knowledge), `decision` (autonomy contract → `~/.agents/AGENTS.md` rule).

### Added

- **`/ship knowledge` decision-note variant** — when path matches `decisions/`, the skill writes both the decision note frontmatter AND an `Inbox/ship-proposals/<date>-<slug>.md` markdown file with `[ ]` checkboxes for manual Notion / Jira / Linear / Slack push. Stage 2 questions become decision-specific (decision/cycle/counterfactual/scope) instead of knowledge-specific. Replaces v2.1 `/work-ship`.
- **Common Rationalizations tables** in 4 critical skills (`/sprint`, `/careful`, `/review`, `/ship`) — 2-column "rationalization | reality" tables with 5-7 entries each, voiced for Panda's actual failure modes (patch-and-pray, skip careful on prod, ship without review on hotfix). Format adapted from addyosmani/agent-skills.

### Manifest

- Tier model simplified: `core` (23) + `ext` (3). Personal tier removed from public manifest. Anything that needed `private:*` requirements moved to `pandastack-private`.
- `version = "2.2.0"`, `updated = "2026-05-09"`.

### Why

Three signals over the v2.1 cycle convinced this was right:

1. **Brain co-evolution**: as `gbrain` matured (timeline, salience, recent-transcripts, find_orphans), several pandastack skills became wrappers around brain-equivalent operations. Better to remove the wrapper than keep two paths to the same outcome.
2. **Public-vs-private ambiguity**: 6 personal-tier skills lived in the public manifest but couldn't run for public users (private CLIs). This was a wart — public package now self-contained.
3. **Flow spec drift**: 7 flow specs in `flows/*.md` plus `/sprint` SKILL.md plus README "How skills connect" plus the briefly-added `FLOWS.md` meant 4-5 places describing the dev lifecycle. One source of truth (per-skill SKILL.md + README map) is enough.

The mental model shift: **pandastack ≠ "personal AI operator OS that manages your life". pandastack = "skill library you compose ad-hoc."** Lifecycle discipline (retro / research / work / decision) belongs to your individual cron jobs, brain queries, and AGENTS.md rules — not to a one-size-fits-all flow spec.

### Not changed

- 5 role personas (ceo / product-lead / eng-lead / design-lead / ops-lead) stay as cognitive lenses
- `/sprint`, `/grill --brief`, `/grill`, `/dojo`, `/careful`, `/freeze`, `/review`, `/qa`, `/checkpoint`, `/done`, retired project setup, `/advisor --panel`, `/team-orchestrate`, `/gatekeeper`, `/write` all unchanged in shape
- `/ship` git mode + write mode unchanged; only knowledge mode added the decision-note variant
- `retro-week`, `retro-month` stay (per Panda's call: cadence/interview value still belongs in pandastack at this point)

### Migration

- **`/work-ship` users**: now run `/ship knowledge <decisions/path>`. Alias `work-ship` resolves until 2026-08-07.
- **`/notion`, `/slack` users**: switch to Claude.ai Notion / Slack MCP. The MCP equivalents (`mcp__claude_ai_Notion__*`, `mcp__claude_ai_Slack__*`) cover read + write + search ops with OAuth (no local token).
- **Cron jobs referencing `/brief-morning`, `/evening-distill`, `/curate-feeds`, `/bird`**: install `pandastack-private` to keep them. The skills moved, not changed shape.
- **References to `flows/<name>.md`**: gone. Look in the corresponding skill's SKILL.md or README "Lifecycle map" instead.

## v2.1.1 — 2026-05-07

> Small decoupling pass. Three loose ends from the v2.1.0 audit: `gog` hard-fail, Hermes-specific scheduler wording, and CLAUDE.md / AGENTS.md asymmetry.

### Changed

- **`gog` graceful degrade** in `brief-morning` + `evening-distill`. If `gog` is not on PATH, the calendar + Gmail sources now emit `(source unavailable: gog not installed)` instead of hard-aborting the whole skill. The remaining sources (yesterday/today's daily note, writing seeds) still run. If `gog` is installed but has no default account, the actionable `gog` error appears in those sections and the skill continues.
- **Scheduler-agnostic wording**. Skill descriptions for `brief-morning` (`Hermes cron 0 8 * * *` → `any cron scheduler at ~08:00 local`) and `evening-distill` (`Hermes cron 0 22 * * *` → `any cron scheduler at ~22:00 local`). README's `Hermes jobs` section renamed to `Cron jobs` with explicit "use whichever Tier 3 scheduler you prefer (launchd / system crontab / Hermes / Claude CronCreate)" note. RESOLVER's brief-morning + evening-distill trigger column updated from "Hermes 8am cron" / "Hermes 10pm cron" to scheduler-agnostic.
- **CLAUDE.md / AGENTS.md parity**. `init`, `checkpoint`, `qa`, `review`, `ship` previously hardcoded `CLAUDE.md` for project config reads, breaking parity with Codex / other agent runtimes that use `AGENTS.md`. All five now accept either file. `init` Step 3 explicitly picks the runtime's canonical file (CLAUDE.md for Claude Code, AGENTS.md for Codex / others). `review` + `ship` frontmatter `reads:` list adds `AGENTS.md`.

### Why

These three were called out in the v2.1.0 audit as "still coupled but small enough to fix in a patch". `gog` hard-fail was the highest user-impact: a fresh install without gog would crash both daily cron jobs. Hermes wording was honestly substrate-coupling-as-documentation — the skills don't depend on Hermes, they depend on any cron. CLAUDE.md/AGENTS.md asymmetry was a Claude-Code-first artifact that broke Codex users silently. None justified a minor version bump on its own; bundled together as a patch.

### Not changed

Skill prompts still reference Panda's vault conventions (`Blog/_daily/`, `Inbox/ship-log/`, `Inbox/feeds/`, `docs/learnings/`, `knowledge/`). These are convention defaults written into prompt text, not code-level coupling — an LLM agent can adapt to a different vault layout per session, or the user can edit skill text. The only real code-level path is `curate-feeds.ts`'s `RAW_ROOT`, which already accepts any vault with `.obsidian/` or `Inbox/`. The v2 multi-vault provider abstraction was removed from ROADMAP on the same day this patch shipped — it was over-engineered for prompt-based skills.

## v2.1.0 — 2026-05-07

> Substrate-agnostic cut. Drops the `gbq` / `gbrain` dependency that fresh installs couldn't satisfy. Cuts `deep-research` (gbrain-core) and `work-sommet-abyss-po` context. 39 → 38 skills, 8 → 7 contexts.

### Removed

- **Skill: `deep-research`** — required `gbrain` CLI + brain index. pandastack v2.1.0 stops assuming a brain index; vault scans now run via `rg` / `find`. Two-layer planner+researcher pattern can be re-introduced later as a generic skill that doesn't depend on a specific index.
- **Context: `work-sommet-abyss-po`** — Sommet Abyss inactive; if revived, will land in a separate plugin (`sommet-stack`).
- **Substrate dependency: `gbq` / `gbrain`** across `brief-morning`, `evening-distill`, `dojo`, `done`, `retro-week`, `flows/decision.md`, `flows/knowledge.md`, `flows/research.md`, `flows/work.md`. Replaced with direct file scans (`rg` / `find` on `Blog/_daily/`, `Inbox/ship-log/`, `knowledge/`, `docs/sessions/`).
- **Capability probe checks**: `gbq` and `pdctx` removed from `lib/capability-probe.md` (8 checks → 6 checks).

### Changed

- `manifest.toml`: removed `[skill.deep-research]` entry. PERSONAL count 7 → 6. Total skills 39 → 38.
- `RESOLVER.md`: dropped `pandastack:deep-research` row from Knowledge / research section. Updated v2.1.0 cut summary table. Aliases section notes `deep-research` cut. Drop `work-sommet-abyss-po` row from Contexts table.
- `README.md`: skill counts 39 → 38, contexts 8 → 7. Personal listing dropped `deep-research`. All `gbq` mentions in skill descriptions replaced with vault scan equivalents. Optional private overlay skills list and tier=personal CLI list trimmed (`gbq` / `gbrain` removed).
- `ROADMAP.md`: skill counts updated. Onboarding scaffold note updated to reflect brain-index assumption removal.
- `scripts/bootstrap.sh`: personal listing dropped `deep-research`; CLI hint dropped `gbq` / `gbrain`. (6 personal skills now.)
- `DISPATCH.md contract/SKILL.md`: research-trigger row replaces `deep-research` with `scout`.
- `.codex/INSTALL.md`: skill count 48 → 38; `gbq` removed from local-CLI list.
- `flows/*.md`: `gbq` references replaced with `rg` / `find` direction.
- `contexts/*.toml` (personal): `[gbrain]` blocks removed. Sommet entries in firewall lists removed.
- `skills/work-ship/SKILL.md`: domain options simplified to `yei | other`.
- `skills/ship/modes/knowledge.md`: work keyword check no longer references `sommet` / `abyss`. Suggestion text uses `rg -l` instead of `gbq`.

### Why

`gbq` / `gbrain` is a personal CLI requiring a brain index that fresh installs can't replicate without separate setup. Skills that called it were silently failing for non-author users. Replacing with `rg` / `find` on standard vault paths makes the substrate self-contained: any clone with a markdown vault works without a side index.

The `work-sommet-abyss-po` context was inactive and pulled the substrate footprint into a side product. Cutting it keeps pandastack focused on Panda's personal + work contexts.

`deep-research` was the only skill that was fundamentally gbrain-shaped. Cutting it (rather than rewriting) is honest: a substrate-agnostic deep-research belongs to a future iteration, not a forced port.

## v2.0.1 — 2026-05-07

> Cut the env var requirement. Skills now derive everything from natural sources: vault from cwd, Google account from `gog config set default_account`, plugin path from host resolver / relative resolution. Bootstrap output drops 3 warnings that were ceremonial.

### Removed (env var dependencies)

- `PANDASTACK_VAULT` — skills run from vault root (`cd <vault> && /<skill>`). `curate-feeds.ts` script now reads cwd + sanity-checks for `.obsidian/` or `Inbox/`.
- `PANDASTACK_USER_EMAIL` — `brief-morning` and `evening-distill` use `gog`'s default account (`gog config set default_account <email>` once).
- `PANDASTACK_HOME` — persona dispatch uses host plugin-resolver + plugin-relative paths. Overlay resolution checks for sibling `pandastack-private/` directory.
- `PANDASTACK_WORK_VAULT` — `work-ship` runs from work-vault root.

### Changed

- `manifest.toml`: dropped all `config = ["env:..."]` lines from skill entries. Header doc updated to reflect cwd-based resolution.
- `scripts/bootstrap.sh`: removed env var checks from substrate section. Only verifies `~/.agents/AGENTS.md`. Personal skill listing updated.
- `skills/brief-morning/SKILL.md`, `skills/evening-distill/SKILL.md`: `gog calendar` and `gog gmail` calls drop the `--account "${PANDASTACK_USER_EMAIL}"` flag; rely on `gog` default.
- `skills/curate-feeds/SKILL.md` + `scripts/curate-feeds.ts`: vault detected from cwd; aborts with vault-not-found error if cwd lacks `.obsidian/` or `Inbox/`.
- `lib/persona-frame.md`: persona path resolution rewritten — host resolver → plugin-relative → cwd walk-up. No env var fallback.
- `DISPATCH.md contract/SKILL.md`: overlay resolution checks for sibling `pandastack-private/` first; `PANDASTACK_OVERLAY` kept as escape hatch only.
- `contexts/personal-writer.toml`: dropped `google_account = "${PANDASTACK_USER_EMAIL}"` line.
- `README.md`: substrate config section rewritten — only `~/.agents/AGENTS.md` required.

### Why

The 3 env vars created cognitive load (bootstrap warnings on every fresh shell) without earning their keep. Vault path lives in the cron plist or shell cwd, account lives in `gog` config, plugin path lives in the host resolver. Pushing those into env vars was duplicating state. Removing them simplifies fresh-clone setup to "run bootstrap, see AGENTS.md status, install".

## v2.0.0 — 2026-05-07

> Major cut. Aligns the stack to Panda's 6 actual lifecycles (work / writing / dev / knowledge / decision / ops-retro) plus security as a discipline. 48 → 39 skills. Aliases keep old names resolving for 90 days.

### Removed (7 orphan skills)

| Skill | Why |
|---|---|
| `atomize` | atoms.jsonl pattern died; not invoked since Q1. |
| `architect` | Greenfield design rare; folded into `eng-lead` (which now covers tech-stack / DB schema / API contract decisions). |
| `execute-plan` | Sequential subagent coordinator overlapped sprint Phase 3. For N-step sequential work, run N sprints in sequence. `team-orchestrate` remains for true parallel branches. |
| `think-like-karpathy` | Frame referenced in notes but not actively used to think; Naval + Alan-Chan cover the live frames. |
| `process-decisions` | `[x]` walker for cron-reports; cron-reports sparse since launchd disable, ad-hoc execution via `inbox-triage` + relevant skills is faster. |
| `wiki-lint` | All 4 lint signals (orphan / stale / superseded / dead redirect) are now `gbq` queries against the brain index, no dedicated skill needed. |
| `retro-prep-week` | Pre-fetch retro inputs; `retro-week` Phase 1 now calls gbq + gog directly, saving a separate cron. |

### Merged (`/ship` is now multi-mode)

`knowledge-ship` and `write-ship` merged into `/ship` as modes. One verb, one mental model:

| Invocation | What it does |
|---|---|
| `/ship` (no args) or git-mode flags | git mode (default): test + commit + push + PR |
| `/ship knowledge <path>` or `/ship knowledge/...` | knowledge mode: Close + Extract + Backflow on a knowledge note |
| `/ship write <draft>` or `/ship Blog/_daily/...` | write mode: Close + Extract + Backflow on a Blog draft |

The merged mode bodies live at `skills/ship/modes/knowledge.md` and `skills/ship/modes/write.md`. `/knowledge-ship` and `/write-ship` continue to resolve via `aliases:` frontmatter for 90 days (until 2026-08-05).

`work-ship` stays separate (different artifact: external system push proposals). Long-term plan (T2) is to move work-ship + slack + notion to a separate `yei-stack` plugin so pandastack stays purely personal.

### Kept (after re-audit pushback)

| Skill | Why kept |
|---|---|
| `team-orchestrate` | Active use case in companyos-style multi-branch parallel work (5/6 merge train). Different shape from sprint (space cut vs time line), not collapsible. |
| `design-lead` | Boardroom 4-voice signature stays intact. Panda's call: design-lead is a product framing decision, not just an engineering one. |

### Skill choreography updates

- `lib/skill-decision-tree.md`: rewrote from 3-question test to 2-question test. Sprint vs team-orchestrate is now the only execution-locus axis. Persona routing table loses `architect` (folded into eng-lead).
- `lib/persona-frame.md`: dispatch examples updated (`execute-plan` removed from list; model heuristic example switched from architect=opus to ceo=opus).
- `flows/decision.md`: rewrote Phase 3 from "process-decisions walks all `[x]` items" to "Panda walks each `[x]` manually using whichever skill matches" (inbox-triage / sprint / notion / slack ad-hoc).
- `flows/knowledge.md`: ship phase points at `/ship knowledge`; lint phase changed from cron-driven `wiki-lint` to on-demand `gbq` queries.
- `flows/writing.md` + `flows/research.md`: ship references updated to `/ship write` / `/ship knowledge`.
- `flows/work.md` + `flows/retro.md`: process-decisions references replaced with `inbox-triage` + manual notion/slack walks.
- `grill --brief/SKILL.md` Stage 5: routing block now covers sprint and team-orchestrate only (no execute-plan).
- `sprint/SKILL.md` Stage 3: persona routing table loses architect row; eng-lead absorbs tech-stack / DB schema / API contract signals.
- `team-orchestrate/SKILL.md`: scope table rewritten from 3-row (sprint / execute-plan / team-orchestrate) to 2-row (sprint / team-orchestrate); "fall back to execute-plan" advice replaced with "fall back to N sequential sprints".
- `DISPATCH.md contract/SKILL.md`: lifecycle map updated; red-flag table updated.
- `inbox-triage/SKILL.md`: cron-report flow updated; related_skills tightened.
- `work-ship/SKILL.md`: process-decisions references replaced with manual proposal walks.

### Counts

| Tier | v1.4.2 | v2.0.0 |
|---|---|---|
| core | 35 | 27 |
| ext | 5 | 5 |
| personal | 8 | 7 |
| **total** | **48** | **39** |

### Why a major bump

Prior bumps (v1.4.x) were mechanical (rename, alias, cleanup). v2.0.0 is the first cut that changes the public surface in a way that breaks downstream automation if you have hardcoded skill names. Aliases cushion the break for 90 days, but tier counts, manifest entries, RESOLVER catalog, and several flow files all shift, so the major bump signals "audit your context recipes / cron jobs / launchd plists before updating".

## v1.4.2 — 2026-05-07

> Third-pass audit on v1.4.x. Fixes leftover staleness from the rename + tier work: false L5 enforcement claim in README, env-var `forbids:` on 17 SKILL.md (the L5 hook does not expand env vars, so the line was dead weight), tier=personal skills still listed in three public context recipes, broken doc link, stale `/tool-bird` references in `write-ship`, and eval.json `generated_from` pointing at deleted paths.

### Removed

- `README.md`: L5 firewall section. The previous version walked through frontmatter contract + status. The frontmatter is real; the README claim was confusing because L5 enforcement is a private overlay (`pdctx-l5-allowlist` hook), not a public feature. Replaced with a short Telemetry opt-out section.
- `forbids: ${PANDASTACK_WORK_VAULT}/**` removed from 17 SKILL.md files. The L5 hook (when it loads via private overlay) reads literal paths with `vault:` / `file:` prefixes per `docs/firewall-l5.md`; env-var-style placeholders never matched. Removing dead config.
- Tier=personal skills pulled from public context lists:
  - `personal-developer.toml`: removed `pandastack:deep-research`, `pandastack:bird`, `pandastack:notion` (already moved to private overlay).
  - `personal-knowledge-manager.toml`: removed `pandastack:deep-research`, `pandastack:curate-feeds`, `pandastack:bird`.
  - `personal-writer.toml`: removed `pandastack:bird`, `pandastack:brief-morning`, `pandastack:evening-distill`, `pandastack:retro-prep-week`.
- `RESOLVER.md`: removed `pandastack:pdf` row from "Tool wrappers" table (skill was deleted in v1.4.1; row was missed).

### Changed

- `docs/skills.md`: the README link previously pointed at `README.md` skill list. Now points at `plugins/pandastack/manifest.toml` which is the SSOT.
- `README.md` line 234: skill count "39 skills grouped by lifecycle" → "48 skills grouped by lifecycle (35 core / 5 ext / 8 personal — see plugins/pandastack/manifest.toml)".
- `plugins/pandastack/skills/write-ship/SKILL.md` lines 146, 213: `/tool-bird` → `/bird`.
- `plugins/pandastack/skills/bird/evals/eval.json`, `plugins/pandastack/skills/notion/evals/eval.json`: `generated_from` updated to current paths (`<skills-dir>/bird/SKILL.md`, `<skills-dir>/notion/SKILL.md`).
- `personal-developer.toml` notes: stale comment about `grill --mode structured` (deprecated in v1.2) replaced with current behavior description.
- `tests/resolver-golden.md`: header bumped to `v1.4.x`; added test cases T17, T19a–T19f for new aliases (`/tool-browser` → agent-browser, `/tool-bird` → bird, etc.); pdf removal noted in Origin section.

### Why this batch

User's third audit caught issues that survived v1.4.0 + v1.4.1 because each prior cut focused on a different surface. This pass walks the whole tree once and verifies every claim against actual file state. Specifically: (a) `forbids:` env-var lines that never enforced anything; (b) public context recipes still loading personal-tier skills (would 404 on fresh install); (c) eval.json paths pointing at directories that were renamed or deleted; (d) docs link rot. Bumping minor patch instead of folding into v1.4.1 because the L5 README change is user-visible and worth its own entry.

## v1.4.1 — 2026-05-07

> Removed `pdf` skill. Python pipeline (pypdf / pdfplumber / reportlab / pytesseract / pdf2image + poppler + tesseract) was a heavy dependency stack for a wrapper that mostly duplicated `pdftotext` + standard library workflows. Skill count 49 → 48.

### Removed

- `plugins/pandastack/skills/pdf/` — including `scripts/extract_form_structure.py`, `scripts/fill_fillable_fields.py`, `scripts/fill_pdf_form_with_annotations.py`. PDF work now goes through `pandastack:summarize` (which handles PDF -> markdown extraction) or direct CLI use of `pdftotext` / `tesseract` per `~/.claude/rules/url-routing.md`.

### Migration

- If you had `pandastack:pdf` in any context recipe (`personal-developer`, `personal-knowledge-manager`, `personal-trader` had it), it has already been removed in this commit. No replacement needed for read-only PDF flows; use `summarize` for content extraction or invoke `pdftotext` directly.

## v1.4.0 — 2026-05-07

> Follow-up audit on v1.3.0. Drops the `tool-` prefix on 7 wrapper skills; documents the L5 firewall as planned-not-shipped (was previously claimed as enforced); makes the `DISPATCH.md contract` overlay fallback explicit; pulls personal-tier skills out of the `personal:trader` public skill list; rewrites bootstrap's core skill listing to read from the manifest dynamically. Plugin descriptions and the Stability-scope framing in README are also synced to current reality. Skill count: 49 (unchanged).

### Renamed (90-day alias grace via SKILL.md `aliases:`)

| Old name | New name | Note |
|---|---|---|
| `tool-pdf` | `pdf` | tier=ext, requires Python pipeline + poppler/tesseract |
| `tool-bird` | `bird` | tier=personal, private CLI |
| `tool-slack` | `slack` | tier=personal, private CLI |
| `tool-notion` | `notion` | tier=personal, private CLI |
| `tool-repo-docs` | `lib/mermaid-grounding.md capability` | tier=ext |
| `tool-summarize` | `summarize` | tier=ext, brew-installable |
| `tool-browser` | `agent-browser` | tier=ext, name reflects upstream `agent-browser` CLI it wraps |

The `tool-` cluster prefix was dropped because the names already disambiguate via `pandastack:` namespace and slash-command form (`/pdf`, `/bird`). `agent-browser` keeps its long name because that's the actual upstream CLI name (npm package). Old names continue to resolve via `aliases:` frontmatter through 2026-08-05.

### Changed

- `lib/persona-frame.md`, `execute-plan/SKILL.md`, `scout/SKILL.md`: persona path resolution chain unchanged (`${PANDASTACK_HOME}/skills/<persona>/SKILL.md`); scout's hardcoded layer-mapping cheat sheet removed in favor of an abstract layer description.
- `DISPATCH.md contract/SKILL.md`: overlay fallback was previously a silent fallback to `pandastack-private`. Now the SessionStart hook MUST log which step matched (env var / repo overlay / no overlay loaded). No silent fallback.
- `personal-trader.toml`: stripped `pandastack:deep-research` and `pandastack:bird` from the public skill list; both are tier=personal and load via overlay only.
- `scripts/bootstrap.sh`: core skill list is now read from `manifest.toml` at probe time (was hardcoded). Renames don't drift it. Also fixed the macOS BSD `awk` incompatibility (`gensub`) that broke the previous version.
- `manifest.toml`: tool-* skill entries renamed; `pdf` requires now correctly lists `python3 + poppler + tesseract + pip:pypdf,pdfplumber,reportlab,pytesseract,pdf2image` (was incorrectly only `brew:poppler` + `brew:tesseract`).
- `README.md` Layer model section: L5 firewall explicitly marked **frontmatter only, no runtime enforcement**. The L5 hook implementation was claimed in v1.0 but `docs/firewall-l5.md` does not exist; treat skill `forbids` / `reads` / `writes` as audit metadata until the hook ships.
- `README.md` skill-count and version messaging synced to v1.4.0 / 49 skills.
- `plugin.json` and `marketplace.json` descriptions updated to current 49 skill count.
- `ROADMAP.md` v2 scope: Onboarding scaffold and Public capability-probe defaults marked `[partial: shipped in v1.3.0/v1.4.0]`. Multi-vault provider abstraction and Fresh A-user dogfood criteria remain v2.

### Why this batch

User audit on v1.3.0 surfaced: (a) `tool-` prefix is filler, names work without it; (b) L5 firewall was claimed but doc + hook missing — pretending it enforces is dishonest; (c) silent overlay fallback in `DISPATCH.md contract` makes fresh-user state invisible; (d) personal-trader context loads tier=personal skills that fail on public install; (e) bootstrap hardcoded skill list drifts on rename; (f) plugin metadata claims `~37 skills` and `~50 skills` simultaneously across files. v1.4.0 fixes all six in one cut.

## v1.3.0 — 2026-05-07

> Fresh-install hardening. Tier model + bootstrap script + decoupled hardcoded data. Goal: a fresh A-class clone runs Core skills without author hand-holding. Personal-CLI skills become opt-in via private overlay rather than baked into public skills. Skill count 50 → 49 (removed `tool-railway`).

### Added

- `plugins/pandastack/manifest.toml` — single source of truth for skill tier (`core` / `ext` / `personal`) + dependency declarations (`requires` + `config`). Read by `scripts/bootstrap.sh` and capability-probe.
- `scripts/bootstrap.sh` — fresh-clone onboarding: probes substrate, lists 35 core skills runnable now, prints exact `brew install` / `npm install -g` per ext skill, marks personal skills as needing the private overlay. Single entrypoint replaces the previous 4-section README install dance.
- `plugins/pandastack/skills/curate-feeds/scripts/curate-feeds.ts` — script moved in-tree from `~/site/cli/feed-server/scripts/curate-feeds.ts`. Skill is now self-contained on the script side; the feed-server daemon stays a separate concern (HTTP-only contract). Script also patched to require `PANDASTACK_VAULT` env var (was: hardcoded vault path) and accept `PANDASTACK_FEED_SERVER` override.
- `plugins/pandastack/skills/gatekeeper/` — gatekeeper bumped 0.2.0 → 0.3.0 with DeFi protocol governance / admin risk review (`reviews/defi-protocol.md` + `templates/report-defi-protocol.md`). Triggers on "看這個協議的中央化風險" and pre-deposit due diligence on lending / yield / RWA / stableswap protocols.

### Changed

- **Hardcoded data extracted to env vars** (was: baked into SKILL.md body):
  - `pandap.d819@gmail.com` → `${PANDASTACK_USER_EMAIL}` in `brief-morning`, `evening-distill`, `personal-writer.toml`
  - `/Users/panda/site/knowledge/work-vault/**` → `${PANDASTACK_WORK_VAULT}/**` in 17 skill frontmatter `forbids`
  - `/Users/panda/site/knowledge/obsidian-vault/...` → `<vault>/...` in `atomize/SKILL.md`
  - `~/site/skills/pandastack/plugins/pandastack/skills/<persona>/SKILL.md` → `${PANDASTACK_HOME}/skills/<persona>/SKILL.md` resolution chain in `lib/persona-frame.md`, `execute-plan/SKILL.md`, `scout/SKILL.md`
- **Work-context leakage cleaned out of public surface**:
  - `tool-railway` deleted (leaked `natural-joy (Yei Sentinel)` project name and Railway service topology)
  - `think-like-naval`, `think-like-karpathy`, `think-like-alan-chan` example dialogues rewritten with generic operator dilemmas (was: pstack / Yei / Abyss / DeFi protocol ops)
  - `execute-plan` risk classification table: `Yei/Abyss protocol ops` → `Production protocol ops (smart contracts, treasury, governance, on-chain writes)`
  - Context TOML deny comments: `Sommet ticketing` / `Yei ticketing (Jira)` → `work issue tracker` (generic)
- **Private skill refs decoupled from public flows**:
  - `flows/work.md` and `flows/decision.md` now mark `yei-alert-triage`, `misalignment`, `harness-slim` as `[private overlay, optional]`. Public flow runs without them.
- **README install section collapsed**: 4 host-specific sections (~80 lines) → one bootstrap-driven flow + per-host one-liner table. Quick-start now points at `bash scripts/bootstrap.sh --claude`.
- `personal-writer.toml`, `personal-trader.toml`, `personal-knowledge-manager.toml`: removed dangling `pandastack:tool-web-extract` reference (skill was archived in v1.2.1).

### Removed

- `plugins/pandastack/skills/tool-railway/` — leaked work-context project name (`natural-joy (Yei Sentinel)`) into a generic Railway skill. Railway docs / common diagnosis flow not unique enough to justify a tool wrapper; users can read Railway's official CLI docs directly.

### Migration

- **Set env vars** in your shell rc (`~/.zshrc` / `~/.bashrc`):
  ```bash
  export PANDASTACK_VAULT=$HOME/path/to/your/vault
  export PANDASTACK_HOME=/absolute/path/to/pandastack/plugins/pandastack
  export PANDASTACK_USER_EMAIL=you@example.com           # only for brief-morning / evening-distill
  export PANDASTACK_WORK_VAULT=$HOME/path/to/work-vault  # only if separate work vault
  ```
- **Run** `bash scripts/bootstrap.sh` to verify state.
- **If you had `pandastack:tool-railway` in any context recipe or cron**: remove it. No replacement; use Railway's own docs.
- **L5 firewall behavior**: skills that previously had hardcoded `forbids: /Users/panda/...` now use `${PANDASTACK_WORK_VAULT}`. If your firewall implementation does not do env-var expansion in TOML/YAML, set the env var to your work-vault path; if you don't have a work vault, leave the env var unset and the forbid pattern simply doesn't match anything (pass-through).

### Why this batch

Audit 2026-05-07 surfaced that v1.2 was honest about being personal-substrate-stable (`0 fresh installs`) but didn't lower the install bar. Tier model + bootstrap script ship the structural fix needed for fresh-install viability. Author launchd jobs disabled in same session (operational, not in scope of this changelog).

## v1.2.2 — 2026-05-06

> Stability scope clarified: v1 = personal-substrate stable, v2 = public-ready. README and capability-probe reframed to reflect 0 fresh-user installs over 6 months and the v1 dogfood reality (1 user, the author). No skill content changes; documentation reframe only.

### Why this reframing

Original v1.0 README presented pandastack as fresh-user-ready. 6-month dogfood window (2026-04-30 → 2026-05-07) confirmed: 0 fresh A-class users (Obsidian + Coding Agent power users) successfully ran `/plugin install` end-to-end without author intervention. The TA stated in v1 README was aspiration, not validated reality. Continuing to ship v1 stable while claiming public-readiness misrepresents the substrate's actual maturity.

Two paths considered and rejected:
1. **Hold v1 cut** until 1-3 fresh users complete install + 1 week of use. Rejected: Sommet PO + companyos Phase 1 sprint backlog leaves no bandwidth for active outreach; finding fresh users on a deadline is not in the author's control.
2. **Ship v1 stable as-is, accept TA gap**. Rejected: gaps that are not visible cannot be fixed. Without an explicit v2 scope, the public-readiness work would never get prioritized.

Chosen: reframe v1 as personal-substrate stable, scope public-readiness to v2 with explicit roadmap. Ship 5/7 stable cut on schedule with the corrected framing. See `docs/briefs/2026-05-06-pandastack-v1-stable-cut.md` (vault-side brief) for full reasoning, alternatives considered, and gate log.

### Changed

- `README.md`:
  - Line 7 area: "v1.0.0 stable" claim split into two scopes. v1 = personal-substrate stable (author's daily use, dogfooded across 4 of 7 lifecycles). Public-readiness deferred to v2 with explicit `0 fresh-user installs` data point.
  - New "Stability scope (read this first)" callout added before "Who this is for" — makes the scope distinction load-bearing rather than buried.
  - "Quick start" section: dev-mode notice prepended. Tells fresh users that substrate (vault, gbq, pdctx) must be set up separately and that capability-probe will surface gaps rather than fail silently.
  - "Who this is for": added 4th bullet stating v1 dogfood reality (1 user, author).
- `plugins/pandastack/lib/capability-probe.md`: fresh-clone dev-mode hint appended to "Action by probe result" → "Degraded mode rules". Tells fresh users that substrate degradation is expected on v1 and points at v2 roadmap.

### Added

- `ROADMAP.md` (new, repo root) — explicit v2 scope: onboarding scaffold, multi-vault provider abstraction (Logseq / Roam / Notion), fresh A-user dogfood criteria. Open questions on v2 timeline (when to start; conditional on fresh user inbound vs scheduled). Companion to this CHANGELOG entry; lives in repo so version-controlled rather than in vault-only briefs.

### Migration

No code or skill changes. Existing v1.x users: no action needed; behavior is identical. Fresh-clone users: read the "Stability scope" section in README before installing. The `pandastack:init` flow already runs capability-probe; degraded states now point at the v2 roadmap rather than implying the install is broken.

## v1.2.1 — 2026-05-05

> Surface area slim: `tool-web-extract` archived, routing folded into `~/.claude/rules/url-routing.md`. Skill count 51 → 50 active.

### Removed

- `tool-web-extract` skill (56 lines, archived to `skills/_archive/tool-web-extract-2026-05-05/`). Skill was a thin wrapper over Defuddle CLI flags; routing already lived in `~/.claude/rules/url-routing.md` Fallback Chain section. Defuddle command reference (the only procedural value the skill held) folded into the same rule file under new "Defuddle command reference" subsection.

### Cross-reference updates

- `RESOLVER.md` — removed `pandastack:tool-web-extract` row + updated "Added in v1" list to note removal.
- `plugins/pandastack/skills/DISPATCH.md contract/references/codex-tools.md` — defuddle row points at url-routing rule instead of skill.
- `plugins/pandastack/flows/research.md` — Phase 3 + skill choreography updated to invoke `defuddle parse <url> --md` directly per url-routing rule. Same pass also fixed a stale `feed-curator` reference to `curate-feeds` (v1.1 rename followup).

### Migration

If any downstream skill or doc still references `pandastack:tool-web-extract`, the replacement is the rule reference: `~/.claude/rules/url-routing.md` § "Defuddle command reference" + § "Fallback Chain".

## v1.2.0 — 2026-05-05

> Surface area cleanup + decision-tree completeness. Two changes: (a) `grill --mode structured` removed, structured-brief role consolidated into `grill --brief --quick`; (b) `team-orchestrate` skill built early to fill the Q3 hole in `lib/skill-decision-tree.md`. Net skill count unchanged (-1, +1).

### Added

- `skills/team-orchestrate/SKILL.md` — Conductor-driven parallel execution. Dispatches N independent branches to subagents in a single message, each in its own git worktree, gates each branch as it returns. Mirrors `execute-plan` Phase 0-3 structure but parallel. Fills the Q3 destination of `lib/skill-decision-tree.md` (was marked "future / two-strike pending"; built early because the architecture had a structural hole, not an emergent pattern).
- `skills/grill --brief/SKILL.md` `--quick` flag — skips Stage 1 (capability probe + gbq load + goal mapping) when context is pre-loaded in-session. Reduces total time from ~30 min to ~10-15 min. Replaces the structured-brief role formerly under `grill --mode structured`.

### Removed

- `grill --mode structured` body removed (was lines 162-309 of `skills/grill/SKILL.md`). Grill returns to atomic adversarial-only positioning. The "5-step structured brief flow" content is no longer needed because `grill --brief` already covers the same 5 stages with better staging (capability probe → premise challenge → alternatives → premise refresh → output) and `--quick` mode handles the case where context is already loaded.

### Why this consolidation

`grill --mode structured` (added v1.1 to absorb deprecated `pandastack:brief`) and `grill --brief` (5-stage flow) overlapped ~70% by the dogfood window: both did Load Context → Premise Challenge → Alternatives → Brief output. The middle ground was a naming smell — "grill" but with brief output. Single canonical structured-brief skill is `grill --brief` going forward.

### Cross-reference updates

- `RESOLVER.md` (rows 52, 124, 207) — split grill / grill --brief rows, removed `--mode structured`.
- `plugins/pandastack/CLAUDE.md` (lines 12, 42) — split skill list, updated goal-mapping note.
- `plugins/pandastack/lib/push-once.md` — removed `--mode structured` from skill list.
- `plugins/pandastack/lib/stop-rule.md` — `--mode structured` Step 4 → `grill --brief` Stage 3.
- `plugins/pandastack/lib/escape-hatch.md` — split grill / grill --brief skill rows.
- `plugins/pandastack/lib/skill-decision-tree.md` — removed "future / two-strike pending" qualifiers from team-orchestrate (5 places).
- `plugins/pandastack/lib/persona-frame.md` — removed "future" qualifier from team-orchestrate mention.
- `plugins/pandastack/skills/execute-plan/SKILL.md` line 21 — `pandastack:grill --mode structured` → `pandastack:grill --brief`.
- `plugins/pandastack/skills/scout/SKILL.md` line 206 — same swap.
- `plugins/pandastack/skills/grill/SKILL.md` — frontmatter description, in-body refs, Origin section all updated.
- `plugins/pandastack/skills/grill --brief/SKILL.md` — frontmatter description, Modes section, Stage 1 skip-on-quick, Stage 5 routing.
- `plugins/pandastack/flows/dev.md` — Phase 1 + skill choreography updated.
- `tests/resolver-golden.md` T08 — `/grill --mode structured` → `/grill --brief --quick`.

### Migration

- If you previously ran `/grill --mode structured`, run `/grill --brief --quick` instead (when context is already loaded) or `/grill --brief` (full mode, when starting cold).
- No alias period — `--mode structured` was added v1.1.0 (2026-05-04), removed v1.2.0 (2026-05-05). 1-day lifecycle inside dogfood window means alias overhead not justified.

## v1.1.0 — 2026-05-04

> Skill-only redesign. agents/ + commands/ + persona-pipeline deleted. 9 new skills + 7 new lib/ modules + 1 regression test file. 7 skill renames with 90-day alias period through 2026-08-04. Codex review patches integrated (Q3 reverted by user, Q4 / Q6 / Q7 / Q9 + 2 blind spots applied).



### Renamed (v1.1 B0, 2026-05-04, 90-day alias period through 2026-08-04)

7 skill directory renames; old names remain valid via SKILL.md `aliases:`
frontmatter and RESOLVER.md Aliases section through 2026-08-04. After that
the alias entries will be removed and old names will fail.

| Old | New | Reason |
|---|---|---|
| `agent-browser` | `tool-browser` | cluster `tool-*` |
| `content-write` | `write` | drop redundant prefix |
| `feed-curator` | `curate-feeds` | verb-first |
| `harness-survey` | `scout` | metaphor (Layer 2) |
| `morning-briefing` | `brief-morning` | verb-first |
| `slowmist-agent-security` | `gatekeeper` | metaphor (Layer 2), drop brand |
| `weekly-retro-prep` | `retro-prep-week` | cluster `retro-*` |

Cross-reference updates in same batch:
- `RESOLVER.md`: 7 skill rows updated + new "Aliases" section listing all v1.1 renames.
- `README.md`: 3 cron-job table entries + Hermes example dispatch updated.
- `plugins/pandastack/contexts/personal-writer.toml`: 5 skill refs updated
  (`content-write` → `write`, `morning-briefing` → `brief-morning`,
  `weekly-retro-prep` → `retro-prep-week`, plus 2 footer notes).
- `plugins/pandastack/contexts/personal-knowledge-manager.toml`:
  `feed-curator` → `curate-feeds`.
- `~/.agents/AGENTS.md` (Tier 1 substrate): `agent-browser` → `tool-browser`
  in Tool Routing table + Fallback chain.
- `vault/AGENTS.md`: `feed-curator` → `curate-feeds` (3 references).
- `~/.codex/agents/morning-briefing.toml` → `brief-morning.toml` (file rename).

### Removed (v1.1, 2026-05-04)

pandastack is **skill-only** as of v1.1. agents/ and commands/ entirely deleted, no alias period.

- `agents/`: full directory deleted. Previously held 5 lead persona agents
  (`ceo / eng / design / ops / product`, renamed to `*-lead` in B2.5 then
  deleted). Persona content lives in `skills/{persona}/SKILL.md` only.
- `commands/`: full directory deleted. 5 files removed:
  `sprint.md` → replaced by `skills/sprint/SKILL.md`,
  `brainstorm.md` → replaced by `skills/grill --brief/SKILL.md`,
  `fix.md` / `quick.md` / `design.md` → folded into `skills/sprint/SKILL.md`
  (auto-detect bug context, `--quick` mode, design-lead auto-invoke on UI scope).
- `skills/persona-pipeline/`: deleted. Replaced by `skills/advisor --panel/SKILL.md`
  (single-skill 4-voice critique, no agent chain).

Rationale: user direction (2026-05-04) — pandastack is skill-first, no agent
overhead for in-session quick-lens use. Single execution model, single
resolver path, fewer contracts. If genuinely need cold-context parallel
critique, the built-in `Agent` tool can dispatch with a persona skill as
system prompt — no separately-maintained agent file needed.

Resolver impact: prompts that previously fired `persona-pipeline` or any of
the 5 persona agents now route to the corresponding persona skill instead.
Persona content identical (same Soul / Iron Laws / Cognitive Models / On
Invoke / Anti-patterns), now lives only in `skills/{persona}/SKILL.md`.

Codex Q3 (hybrid: keep agents alongside skills) was applied earlier in this
session, then rejected by user — user direction was skill-only from the
start. Hybrid was a regression. This batch reverses the hybrid attempt.

### Added

- `lib/outside-voice-rule.md`: new "Prior-direction conflict rule" section.
  When a codex / external-voice finding contradicts a prior explicit user
  statement (in session, in `~/.agents/AGENTS.md`, in project AGENTS.md, in
  validated memory), the integrating skill must surface the conflict via
  `[reverse / hold / edit]` gate instead of standard `[Y/N/edit]`. The standard
  Y is ambiguous between "agree with codex" and "ack the input"; reverse/hold
  forces explicit reversal-or-hold. Origin: 2026-05-04 session, codex Q3 hybrid
  applied via standard Y gate, ate ~30 min of work that was reverted at session
  end. Learning at `docs/learnings/architecture/2026-05-04-skill-only-vs-hybrid-pandastack.md`.

- `skills/done/SKILL.md` Step 4 Commit handoff (v3.2.0):
  `/done` now closes the session by proposing a commit of the artifacts it
  writes (session.md / daily-note updates / memory entries / optional learnings)
  plus any working-tree code changes from the session. Auto-detects logical
  units (vault writes vs learnings vs code) and offers `[approve / edit /
  split / skip]` gate. Vault writes default to approve (auto-resolve scope per
  AGENTS.md Routing Principles); code changes wait for explicit approve. Skips
  silently when working tree is clean. Solves the "operator forgets to commit
  artifacts at end of session" gap, which led to long-running working trees
  with mixed session work.

- **B6** — `skills/sprint/SKILL.md`: focused 1-2 hour execution flow, 7 stages
  (capability probe → dojo → grill lite → execute → review → ship gate →
  terminal state). 4 explicit terminal states (codex Q4 patch):
  `SHIPPED / PAUSED / FAILED / ABORTED_BY_USER`. Only SHIPPED triggers
  ship/extract/backflow. Modes: default / `--quick` / `--design`. Replaces
  deleted `commands/sprint.md` + `commands/fix.md` + `commands/quick.md` +
  `commands/design.md`. Auto-invokes `design-lead` skill on UI scope detection.

- **B5** — `skills/grill --brief/SKILL.md`: 30-min structured pressure cooker,
  5 internal stages (capability probe + load context → premise challenge with
  push-once menu → forced alternatives 2-3 named approaches with stop-rule
  per-approach gate → premise refresh → write brief). Replaces deleted
  `commands/brainstorm.md`. Distilled from gstack `/grill --brief` 943 lines
  into ~250 lines + 5 lib refs.

- **B4** — `skills/advisor --panel/SKILL.md`: multi-voice plan critique. Single
  skill swaps between 4 voices (CEO → product → design → eng) sequentially
  via `lib/persona-frame.md` voice-switching contract. Per-finding `Apply?
  [Y/N/edit]` gate with rejected → OPEN_QUESTIONS. Replaces deprecated
  `persona-pipeline` agent chain. Optional 5th voice (`ops-lead`) when plan
  is ops-dominant. Voice ordering rationale documented inline.

- **B3** — `skills/dojo/SKILL.md`: lifecycle Stage 0 — pre-action prep.
  5 internal stages (capability probe → past-case gbq → lib + pattern load →
  gotcha surface → output prep brief). Used by `/sprint`, `/grill --brief`,
  any flow needing past-case lookup. Aliased as `/prep`. Codex Q6 patch
  systematizes the pre-action context that CE / gstack do implicitly.

- **B2.5** — Persona naming reconciliation, then deletion. `agents/` dir
  renamed (`{eng,design,product,ops}.md` → `*-lead.md`) to align with skill
  names, then entire `agents/` directory deleted in same batch. pandastack
  is skill-only from v1.1 forward. The codex Q3 hybrid (keep agents alongside
  skills) was rejected by user — original direction was no agents, hybrid
  was a regression.

- **B2** — 6 new shared `lib/` modules + 5 new lead persona skills.

  Lib modules (each ~80-150 lines, all under `plugins/pandastack/lib/`):
  - `escape-hatch.md` — 2-strike user-impatience hard cap. Ref'd by grill / grill --brief / advisor --panel / gatekeeper / dojo.
  - `bad-good-calibration.md` — 4 BAD → GOOD voice posture pairs (mirrors `~/.agents/AGENTS.md` Voice section). Ref'd by grill / grill --brief / advisor --panel / review / write / brief-morning / evening-distill.
  - `outside-voice-rule.md` — third-party finding integration with per-finding `[Y/N/edit]` gate, OPEN_QUESTIONS routing for N. Ref'd by review (Step 6.5) / advisor --panel / gatekeeper / scout.
  - `stop-rule.md` — per-decision AskUserQuestion gate enforcement. "A clearly winning option is still a decision." Ref'd by grill (Step 4) / review / advisor --panel / sprint / grill --brief.
  - `persona-frame.md` — 6-section shared structure (Soul / Iron Laws / Cognitive Models / On Invoke / Anti-patterns) for the 5 lead personas. Defines skill-mode vs agent-mode equivalence. Ref'd by 5 lead skills + advisor --panel (B4 will use it for voice switching).
  - `capability-probe.md` — 8-check substrate availability probe with degraded-mode rules and abort messages (codex Q6 patch). Ref'd by all Layer 1 flow skills (sprint / grill --brief / advisor --panel / dojo / prep) at startup.

  5 lead persona skills (each ~80-100 lines):
  - `skills/ceo/SKILL.md` — strategic advisor (no `-lead` suffix; CEO already exec).
  - `skills/eng-lead/SKILL.md` — staff engineer.
  - `skills/design-lead/SKILL.md` — senior designer.
  - `skills/product-lead/SKILL.md` — VP Product.
  - `skills/ops-lead/SKILL.md` — COO.

  Each lead skill refs `lib/persona-frame.md` for shared 6-section contract (Soul / Iron Laws / Cognitive Models / On Invoke / Anti-patterns) and `lib/bad-good-calibration.md` for voice posture. Cognitive model + iron law content was lifted from the (now deleted) agents/ directory and is the single source of truth in skill files.

- **B-test** — `tests/resolver-golden.md`: 30-prompt regression test
  covering direct slash invocation (12), old-name aliases (7), natural
  language triggers (8), and capability-probe degradation (3). Acceptance
  criteria: ≥27/30 pass on slash+alias+probe, ≥6/8 on natural language.
  Failure response protocol documented. Codex Blind Spot 2 patch — pandastack
  had no regression test, all dogfood was manual; 39 → 12 layer-1 + 9 renames
  + 4 new flows is high regression surface.

- `lib/push-once.md` (B7): new shared module. 5 named pushback patterns
  (具體一點 / 證據檢查 / 反命題 / 邊界條件 / 自由發問) extracted from
  gstack grill --brief residue, refed by `grill` (now), `grill --brief` (B5),
  `advisor --panel` (B4). Replaces ad-hoc improvised pushes with a fixed menu so
  the model's pushback choice is logged + audit-able instead of drifting
  every session. Selection rules table (which pattern matches which symptom),
  output protocol (menu print → user picks → model uses literal prompt),
  anti-patterns, and relationship to the escape hatch documented inline.
- `skills/grill/SKILL.md` Protocol section: replaced the ad-hoc 3-prompt
  example with the lib/push-once.md 5-pattern menu. Frontmatter `reads:`
  added `lib/push-once.md`.

- `skills/gatekeeper/SKILL.md` Step 0 STRIDE Classification (B1):
  6-category threat taxonomy (Spoofing / Tampering / Repudiation /
  Information Disclosure / DoS / Elevation of Privilege) classifier
  protocol with `none / suspect / confirmed` per category, frontmatter
  output `stride_categories: [...]`, risk floor rules (≥1 confirmed
  = 🔴 HIGH minimum, ≥2 suspect = 🟡 MEDIUM minimum), worked example
  for npm install case.
- `skills/gatekeeper/templates/report-skill.md`: new STRIDE
  CLASSIFICATION block between FILES SCANNED and RED FLAGS, exposes
  6-row classifier output + computed risk floor in the standardized
  ASCII report. Other 4 report templates (repository / url-document /
  onchain / product-service / message-share) to be backfilled in
  follow-up batch.

- `skills/harness-survey/`: new skill, two-strike promoted via `/done`
  Step 3b on 2026-05-04. Pattern: search public ecosystem
  (`gh search repos`) → fetch top-N READMEs → triage with vault
  dedup + layer-aware mapping → deep-read top picks → distill to
  substrate diff → execute approved batches. 6 phases, 5-7 patches
  cap per run, parks remainder as `[NEXT_BATCH]` in session note
  for retro-week pickup. Built-in discipline: feedback-log
  2026-05-01 layer mapping rule (mandatory before triage),
  AGENTS.md "No phantom quotes" rule (grep -F verify on every
  Before:/Source: quote), 5-7 patches cap, no auto-push to
  external systems. Prior strikes:
  `2026-04-18-harness-architecture-instinct-loop` +
  `2026-05-03-gstack-distillation-substrate-patches`.

### Removed

- `skills/brief/`: deleted. `grill --mode structured` had already
  replaced it (see grill SKILL.md line 5 — "replaces the deprecated
  /brief"); the directory was a zombie. References in
  `commands/sprint.md`, `commands/design.md`, and grill SKILL.md
  body updated to point at `/grill --mode structured`.

### Changed

- `skills/grill/SKILL.md` default (adversarial) mode Protocol:
  added "Expect rehearsed first answers" rule. First reply on any
  axis is the polished version; push once minimum before switching
  axes. Concrete push prompts: 具體一點？/ 你看過嗎？/ 拿掉這個假設會怎樣？
- `skills/grill/SKILL.md` Stopping rule replaced with Escape hatch
  protocol (hard cap): first push-back acknowledge + ask 2 most
  critical remaining axes; second push-back stop immediately, log
  unprocessed axes as OPEN_QUESTIONS, do not ask third time.
- `skills/grill/SKILL.md` Step 4 Alternatives hardened to
  MANDATORY: minimum 2 approaches (minimal viable + ideal
  architecture, equal weight, no minimal-viable-by-default bias),
  optional creative/lateral third, per-approach AskUserQuestion
  gate (not batched), explicit STOP rule preventing chat-prose
  recommendation + silent continuation.
- `skills/review/SKILL.md` gains **Step 0 System Audit** as fixed
  opener: 5 commands (git log -30, git diff --stat, git stash list,
  TODO/FIXME grep, recently touched files) + read CLAUDE.md /
  AGENTS.md / TODOS.md, report findings in 5 bullets max.
- `skills/review/SKILL.md` Step 6.5 Codex Adversarial Review:
  Outside Voice Integration Rule added — codex findings are
  **informational only**, no auto-boost on cross-model consensus,
  per-finding `Apply to final report? [Y/N/edit]` gate, N
  responses route to OPEN_QUESTIONS rather than discarded.
- `skills/review/SKILL.md` gains **Step 8 Completion Summary**:
  single ASCII box covering Step 0 audit, brief alignment, pass
  findings by priority, cold review hits, codex catches + apply
  count, learnings written, OPEN_QUESTIONS, CRITICAL_GAPS, files
  reviewed. Printed even on user-aborted runs (unrun steps marked
  `skipped (user)`).

### Added

- `lib/goal-mapping.md` — shared module documenting goal-hierarchy
  pre-step. Reads user's L1 (long horizon) / L2 (this season) /
  L3 (this week) goals from `<memory-dir>/`, maps the current task to
  each layer, picks the dominant layer, and feeds downstream Clarify +
  Alternatives steps so questions adapt to the user's actual goal
  hierarchy instead of running generic forcing questions in a goal
  vacuum.

### Changed

- `README.md`: install surface rewritten around host model instead of Claude-only plugin framing. Added runtime support matrix, Claude local-marketplace author loop, Hermes and OpenClaw status/installation guidance, user update paths, maintainer release loop, and explicit PR / issue contribution instructions.
- `plugins/pandastack/.claude-plugin/plugin.json` and `plugins/pandastack/.codex-plugin/plugin.json`: version markers bumped from `1.0.0-rc.2` to `1.0.0` to match the stable cut.

- `skills/brief/SKILL.md` and `skills/grill/SKILL.md` (`--mode
  structured`): inserted **Step 1.5 Goal Mapping** between Load
  Context and Clarify. Step 2 Clarify now smart-skips forcing
  questions answered by goal mapping. Step 3 Premise Challenge adds a
  fourth premise checking dominant-layer framing. Step 4 Alternatives
  filters options to the dominant layer and flags constraint
  violations from non-dominant layers. Gate Log gains a Goal Mapping
  line.
- `skills/grill/SKILL.md` default (adversarial) mode: added "Pre-step:
  Goal Mapping (recommended)" pointer so adversarial drilling lands
  with awareness of what is actually being protected.
- All public skill content went through a personal-info hygiene pass
  (separate `chore(hygiene)` commit): hardcoded vault / CLI / memory /
  skills paths replaced with `<placeholder>` tokens; team handles,
  Slack workspace IDs, and Yei repo names replaced with generics;
  README gained a "Path tokens" section documenting the convention
  for external users to bind via private overlay.
- `commands/sprint.md`, `commands/fix.md`, `commands/design.md`:
  replaced `/ps-compound` references with `/pandastack:knowledge-ship`
  or `/pandastack:work-ship` (compound logic was absorbed in v1.0.0
  but the composite commands still pointed at the dead skill).
- `plugins/pandastack/CLAUDE.md`: refreshed from stale `pstack`-era
  content. Removed references to deleted skills, updated to v1
  composite command names, mentioned new goal-mapping pre-step.
- `README.md`: removed `/pandastack:learn` from Dev workflow primitives
  table; removed `solo.md` / `full.md` mentions from Lifecycle Flows
  (those files are deleted); fixed a stale `/pandastack:retro` ref to
  `/pandastack:retro-week`.
- `RESOLVER.md`: removed `pandastack:learn` from Dev workflow table;
  noted `solo.md` + `full.md` removed; updated Provenance to reflect
  the v1.0.0-rc.3 trim.

### Removed (over-scaffold trim)

Audit pass identified zombie skills, orphan lib modules, and
old-version flow files. Removed:

| Removed | Why |
|---|---|
| `skills/compound/` | Logic absorbed into knowledge-ship/work-ship Stage 3 in v1.0.0; SKILL.md remained as a zombie |
| `skills/retro/` | Logic absorbed into retro-week Phase 1 in v1.0.0; SKILL.md remained as a zombie |
| `skills/learn/` | 0 dispatches anywhere; "search learnings" function is LLM-native (just grep + read) |
| `lib/stop-check.md` | Orphan — 0 references; advisory checks rebuildable from prompt if needed |
| `flows/full.md` | Earlier-version reference per README; superseded by `flows/dev.md` |
| `flows/solo.md` | Earlier-version reference per README; superseded by `flows/dev.md` |

### Why this matters

`docs/sessions/2026-05-01` audit found ~12-15 dead-weight files in the
public stack: 3 zombie skills (CHANGELOG declared removed but files
still shipping), 1 orphan lib module, 2 old-version flow files, plus
several stale dispatch references in composite commands. Trimming
~20-30% of the dead surface area before alpha testers see the stack.
The remaining substrate (pdctx hooks, memory firewall, DISPATCH.md contract
contract, careful gate, etc.) was audited and judged justified — each
solves something the model cannot do reliably from prompting alone.

## v1.0.0 — 2026-05-03

Stable cut. Dogfood window 2026-04-29 → 2026-05-03 complete. API and schema frozen from this version forward.

### Added

- 39 skills across dev, knowledge, writing, work, research, retro, and decision lifecycles
- 8 context recipes (4 public + 4 work contexts via private overlay)
- 5 personas: eng, design, ceo, ops, product
- 7 lifecycle flows: dev, knowledge, writing, work, research, retro, decision
- JSONL session timeline (Track B): one event per action to `~/.pdctx/audit/timeline-YYYY-MM-DD.jsonl`; opt-out via `PDCTX_TIMELINE_DISABLED=1`
- Skill context metadata schema (Track C): optional `reads / writes / forbids / domain / classification` frontmatter fields
- Layer 5 firewall (Track D): per-skill tool-argument allowlist enforced at PreToolUse; opt-out via `PDCTX_L5_DISABLED=1`
- 3 Hermes cron jobs: morning-briefing (daily 8 AM), evening-distill (daily 10 PM), weekly-retro-prep (Fri 9 AM)
- 3 new skills: `morning-briefing`, `evening-distill`, `weekly-retro-prep`
- pdctx CLI 1.0.0: `--cwd`, `--sandbox`, `--allow-network`, `--writable-roots` flags
- Public README with Three-Tier architecture diagram, install instructions, and telemetry/firewall documentation

### Schema

- Skill frontmatter adds optional `reads`, `writes`, `forbids`, `domain`, `classification` fields. Backward compatible: skills without these are treated as `domain: shared, classification: read`. `pdctx skill-validate` warns on missing metadata instead of failing.

### Removed

- `qmd` retired 2026-05-02; `gbq` (gbrain hybrid search) replaces it

### Known Issues

- L5 false-positive on stale `active-skill.json` (P2 — Stop hook needed to clear on session end)
- `vault:` prefix assumes single vault root; multi-vault setups need explicit `file:` entries (P2)

---

## v1.0.0-rc.2 — 2026-04-30

Codex CLI multi-CLI support. Skill content stays Claude-first; Codex consumes via tool-name mapping injected at session start. Modeled on Superpowers v5.0.7's per-CLI shim pattern.

### Added

- `plugins/pandastack/.codex-plugin/plugin.json` — Codex native plugin manifest
- `plugins/pandastack/.codex/INSTALL.md` — clone + symlink install path for Codex 0.124.0+
- `plugins/pandastack/AGENTS.md` — symlink to `CLAUDE.md` (Codex convention)
- `plugins/pandastack/skills/DISPATCH.md contract/references/codex-tools.md` — Claude → Codex tool-name mapping (`Skill` / `Agent` / `TaskCreate` → native skill load / `spawn_agent` / `update_plan`), local CLI dependency notes, named subagent dispatch workaround

### Changed

- `plugins/pandastack/hooks/session-start` — 3-platform output envelope (Cursor / Claude Code / Codex+Copilot+default), all paths emit valid JSON
- README: tagline + new "Other runtimes" subsection pointing at `.codex/INSTALL.md`

### Verified

- End-to-end on Codex CLI 0.124.0 via `~/.codex/skills/pandastack` symlink: all 40 skills enumerated, SKILL.md frontmatter readable.
- Audit: 17/40 SKILL.md fully portable, 22/40 needs Codex tool-mapping adapter, 7% Claude-only by definition (hooks mechanic, subagent format, slash command format).

## v1.0.0-rc.1 — 2026-04-29

Major scope expansion. The stack grows from a dev-only workflow (brief → build → review → ship → compound) into a 7-lifecycle personal AI operator OS.

### Added

**Skills (+15 from old `~/.claude/skills/`, +11 from `claude-skills` repo, total ~37 skills now):**

- Knowledge / research: `deep-research`, `feed-curator`, `knowledge-ship`, `wiki-lint`, `tool-summarize`, `tool-web-extract`
- Writing: `content-write`, `write-ship`
- Work execution: `work-ship`, `process-decisions`
- Retro / session: `retro-week`, `retro-month`, `done`
- Tool wrappers: `tool-bird`, `tool-notion`, `tool-railway`, `tool-repo-docs`, `tool-pdf`, `tool-slack`, `agent-browser`
- Persona thinking: `think-like-naval`, `think-like-alan-chan`, `think-like-karpathy`
- Multi-lens: `persona-pipeline`
- Trust evaluation: `slowmist-agent-security`

**Agents (+1):**

- `ops` — COO / operations lead. Build systems that run without you, process when there's real pain.

**Lifecycle flows (+7):**

- `flows/dev.md` — original dev workflow, now formal flow spec
- `flows/knowledge.md` — capture → distill → verify → ship → lint
- `flows/writing.md` — capture → structure → draft → ship → distribute
- `flows/work.md` — triage → context → execute → ship → push (vault-only)
- `flows/research.md` — scope → fetch → dive → distill → ship
- `flows/retro.md` — daily / weekly / monthly cadence
- `flows/decision.md` — cron-driven decision triage

**Context recipes (+8):**

`contexts/*.toml` — bind flow + persona + skill subset to identity. Read by future pdctx loader. Eight recipes covering personal dev / writer / knowledge-manager / trader and work yei-ops / yei-hr / yei-finance / sommet-abyss-po.

**Other:**

- `RESOLVER.md` at repo root — disambiguation index for the larger surface area. Read this when two skills look like they overlap.

### Changed

**`grill` skill** now has two modes:

- Default: adversarial requirement discovery (unchanged from v0.16-era)
- `--mode structured`: 5-step structured brief flow that **replaces the deprecated `pandastack:brief`**

**`retro-week` and `retro-month` skills** are now three-phase:

- Phase 1: Auto-scan (git log + learnings/ + daily highlights — replaces standalone `pandastack:retro`)
- Phase 2: Interactive interview
- Phase 3: Write retro to `docs/retros/{weekly,monthly}/`

**`knowledge-ship` and `work-ship` Stage 3 Backflow** added a row that writes to `docs/learnings/<category>/<slug>.md` — **replaces standalone `pandastack:compound`**.

### Removed (from v0.16)

These three skills are gone in v1; their logic was absorbed into other skills:

| Removed | Absorbed into |
|---|---|
| `pandastack:brief` | `pandastack:grill --mode structured` |
| `pandastack:retro` | `pandastack:retro-week` Phase 1 (Auto-scan) |
| `pandastack:compound` | `pandastack:knowledge-ship` and `pandastack:work-ship` Stage 3 |

### Migration from v0.16

If you're upgrading from v0.16:

```bash
# Update the plugin
/plugin marketplace update pandastack
/plugin update pandastack@pandastack
```

**Breaking changes**: none for skill INVOCATION — the three removed skills' logic still runs, just via the absorbing skills. Specifically:

- If you previously ran `/pandastack:brief`, run `/pandastack:grill --mode structured` instead.
- If you previously ran `/pandastack:retro`, run `/pandastack:retro-week` (its Phase 1 does what the old skill did).
- If you previously ran `/pandastack:compound`, run `/pandastack:knowledge-ship` or `/pandastack:work-ship` and answer the Extract-stage questions.

No agent renames in this release. The 4 v0.16 agents (`ceo`, `design`, `eng`, `product`) keep their names. The new `ops` is additive.

### Plugin description

Old: `4 agent personas, 11 skills, 5 composite commands. brief → build → review → ship → compound.`
New: `5 agent personas, ~37 skills, 7 lifecycle flows, 8 context recipes. Personal AI operator OS for dev / knowledge / writing / work / research / retro / decision lifecycles.`

---

## v0.16.0 — earlier

(Pre-changelog releases. See git log for older history.)
