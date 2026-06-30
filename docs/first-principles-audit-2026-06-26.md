# First-Principles Audit — pandastack repo (2026-06-26)

> **Status: historical snapshot (2026-06-26), superseded.** This audit predates the driver-platform split (PR #92) and the persona-layer removal (PR #100/#101). It still describes `skills/doing/` paths (now `skills/engineering/`), the `drive-*` driver platform (since removed), `lib/persona-frame.md` + the 5 persona skills (since removed), and a 28-skill count (current: 23). Kept as the reasoning record behind those cuts; do not treat its file inventory as current state.

> Question asked of every file: *if I deleted this, would the skills pack stop working?* Verdicts: **KEEP** (the irreducible pack), **SEPARATE** (real, but a different product fused in — move to its own repo), **CUT** (dead/cruft/finished-migration, safe to delete). Verdicts are grounded in grep, not assumption: `skill_referenced` = some live `SKILL.md`/`lib` actually invokes it; `cron_wired` = a scheduler/launchd job runs it (so move-don't-delete even when separating).

## 1. ESSENCE

pandastack at its irreducible core is a **skills pack**: 28 live, triggerable skills (doing/meta/thinking/writing) plus the thin machinery that makes them discoverable and safe — the loader (`.claude-plugin/plugin.json`), the dispatch table (`DISPATCH.md`, injected into every session by `hooks/session-start`), two PreToolUse safety guards, the shared `lib/` persona+gate primitives, and the discovery/spec docs (`RESOLVER.md`, `SKILL-FRONTMATTER.md`, `manifest.toml`). That is the whole product: *match a verb to a skill, run it, keep the user gated and safe.*

Bolted onto it is a **second, separable product: an autonomous driver platform.** The `drive-*` cluster autonomously steps Linear work-items, auto-merges low-blast diffs to a local `psdrive/integration` branch, tracks a trust streak, and gates a one-way graduation to `main` — with its own config (`config/high-blast-paths`), its own state root (`.pandastack/`, gitignored, absent here), its own launchd job, its own ~33-file `drive-*` test suite, and its own shared `pslib.py` kill-switch/streak library (imported by 14 files, all of them driver-internal). The **Linear automation** (`pandastack-linear-*`) and the **multi-host capability map** (`pandastack.toml`, `docs/capabilities.md`) are part of this same platform, not the pack. Critically: **the skills pack imports none of it** — verified by grepping `skills/` and `lib/`. The only live coupling is three guarded calls from skills into platform scripts (`sprint`/`handover` → `pandastack-state`; `retro-week` → `drive-log-distill` + `learning-refresh`), each `[ -f ]`/`2>/dev/null`-guarded so the skill degrades gracefully if the script vanishes. So the driver platform is a clean lift-out, not a tangle.

**Headline move: split the driver/Linear/autonomy platform into its own repo.** The pack keeps the directory *conventions* (`docs/plans`, `docs/briefs`, `Inbox/`, `_staging/`); the *instance files* of the platform buildout travel with the platform.

## 2. KEEP — the minimal pack that functions

### Loader + enforcement (most load-bearing)
- `.claude-plugin/plugin.json` — THE loader; lists all 28 skills the runtime mounts. Without it the pack does not install.
- `.claude-plugin/marketplace.json` — marketplace manifest for `/plugin install` distribution.
- `hooks/hooks.json` — wires the SessionStart dispatch injection + 2 PreToolUse guards.
- `hooks/session-start` — injects brain-first rule + the `DISPATCH.md` table into every session (the dispatch-discovery mechanism).
- `hooks/pretooluse-destructive-guard.sh` — hard-blocks force-push / `rm -rf` / `reset --hard` / DROP at exit-2. The one active enforcement firewall. **Never cut.**
- `hooks/pretooluse-ticket-gate-guard.sh` — structural enforcement of the ticket-gated-worktree rule.

### Skills (the product itself)
- `skills/` — all 28 active skills (doing/meta/thinking/writing). Each is a live triggerable unit listed in `plugin.json` + `manifest.toml`; cutting any breaks discovery for that verb.
  - **FUSION-SEAM caveat** (keep the skill, fix the path on split): `skills/doing/sprint/SKILL.md:217` and `skills/doing/handover/SKILL.md:98` call `pandastack-state append`; `skills/meta/retro-week/SKILL.md` calls `drive-log-distill` + `learning-refresh`. When the platform separates, these calls must stay reachable or degrade (they already `2>/dev/null`-guard).

### Discovery / spec docs (single sources)
- `manifest.toml` — SSOT for skill tier + CLI deps; read by `bootstrap.sh` + capability-probe. *Drift to fix: declares 26 skills/v2.2 vs `plugin.json` 28/v3.1.*
- `DISPATCH.md` — THE process-axis routing table, injected verbatim into every session.
- `RESOLVER.md` — MECE skill-overlap index; `skill-creator` checks against it. *Stale: says v2.2/26 and claims `persona-frame` loads `contexts/` (it does not).*
- `SKILL-FRONTMATTER.md` — frontmatter contract; `lint-manifest-sync.sh` validates against it.
- `PHILOSOPHY.md` — design contract (zero-deps, agents-have-judgment, gate-contract).
- `README.md` — entry doc + lifecycle map (RESOLVER demotes `flows/` into README sections).
- `CHANGELOG.md` — release history; `ADDING_A_HOST` + manifest-sync require changes recorded here.
- `CLAUDE.md` / `AGENTS.md` (symlink) — plugin-internal instruction file read by skill content; the runtime-agnostic entry point for non-Claude hosts.

### Shared lib (persona + gate primitives, all above the 3-use bar unless noted)
- `lib/persona-frame.md` — @-imported by 18 files incl. all 5 lead personas + boardroom. Highest-use.
- `lib/quality-rubric.md` — artifact-quality SSOT bound by 10 refs.
- `lib/bad-good-calibration.md` — voice calibration, 5 persona SKILL.md + office-hours.
- `lib/escape-hatch.md` — push-back/enough protocol, 5 SKILL.md.
- `lib/capability-probe.md` — degraded-mode check, 5 SKILL.md.
- `lib/gate-contract.md` — the four-option approve/edit/reject/skip gate (PHILOSOPHY-mandated).
- `lib/skill-decision-tree.md` — Q0 refuse-to-build gate, 4 SKILL.md.
- `lib/verify-the-test-loop.md` — verify-before-done loop, 4 SKILL.md.
- `lib/stop-rule.md` — stopping discipline, 4 SKILL.md.
- `lib/trigger-first-skill-evolution.md` — trigger-first authoring, 4 SKILL.md.
- `lib/push-once.md` — single-push-back, 3 SKILL.md.
- `lib/outside-voice-rule.md` — advisory-finding rule, 2 SKILL.md + eval (borderline; fold into persona-frame if it stays at 2).
- `lib/learning-format.md` — learning-loop entry format, 2 SKILL.md (the close-the-loop feature).
- `lib/goal-mapping.md` — goal decomposition, 2 SKILL.md (watch for a 3rd user).
- `lib/confidence.md` — confidence-decay, 1 SKILL.md (review). Over-extracted; inline candidate, but live — do not cut.
- `lib/lint-mermaid-grounding.sh` — mermaid linter for the deepwiki skill (single-skill helper, ships with it).

### Pack infrastructure (install / health / verification gates)
- `scripts/pandastack` — the pack's own doctor/init front-door (manifest drift, skills scan, host-install hints).
- `scripts/pandastack-state` — **skill-referenced** (sprint:217, handover:98); cutting it breaks two core skills.
- `scripts/bootstrap.sh` — fresh-install onboarding; reads `manifest.toml` as source of truth.
- `scripts/conformance-smoke.sh` — verifies each host discovers skills + session-start emits valid JSON (quarantined from CI only because it costs an LLM call).
- `scripts/retro-scan.sh` — **skill-referenced** (retro-week:23, retro-month:21).
- `scripts/lint-manifest-sync.sh` — guards manifest ↔ skills sync; the merge gate.
- `scripts/lint-eval-fresh.sh` — enforces every skill carries an eval.md matching its current SKILL.md hash.
- `scripts/lint-refs-resolve.py` — checks every internal path in a SKILL.md resolves (born from the flat→bucket restructure).
- `docs/state-schema.md` — **skill-referenced** (sprint:212, handover:94); travels with `pandastack-state`.

### Pack-side docs
- `docs/OPENCLAW.md`, `docs/HERMES.md`, `docs/ADDING_A_HOST.md` — multi-host *consumption* contracts (how a host mounts the pack); README links all three. (Multi-host *consumption* stays with the pack; the multi-host *capability-map runtime* separates — see below.)
- `docs/firewall-l5.md` — documents the retired L5 firewall + what `reads/writes/forbids` frontmatter means now; cross-linked from SKILL-FRONTMATTER. Removing it breaks the frontmatter spec's link.
- `docs/loop-kickoffs.md` — **[CORRECTION APPLIED: was DECIDE/SEPARATE, now KEEP]** `DISPATCH.md:16` routes a live pack capability to it (*"Run a bounded coding loop … → hardened kickoff in docs/loop-kickoffs.md"*). The dispatch table is loaded into every session by the SessionStart hook, so this doc is an active routing target, not inert docs. Grep confirms zero driver coupling (no `pandastack-drive`/`drive-cron`/`psdrive`/`integration` in the body) and its header says it is for the hand-run `/loop`, explicitly NOT the cron driver. A doc backing a live dispatch-routed pack capability with no autonomy dependency belongs WITH the pack.
- `docs/learnings/` (dir + convention) — the configured `/ship knowledge` Stage-3 backflow path (`lib/learning-format.md` default).
- `docs/learnings/pitfalls/2026-06-21-shell-danger-guard-command-vs-data.md` — pitfall learning about the active destructive-guard hook; guard-design memory.

### Eval harness (the pack's own quality loop)
- `evals/2026-06-26-skill-quality-baseline.md` — corpus construction-quality baseline; `lint-eval-fresh.sh` fails on drift.
- `evals/2026-06-02-skill-ab-eval.md` — A/B eval measuring which skills earn their tokens.
- `evals/browser-integration/` — side-effect harness for the qa skill.

### Tests (deterministic suite for pack-owned subjects)
- `tests/run-all.sh` — the single CI entrypoint (`.github/workflows/ci.yml`).
- `tests/pandastack-cli.sh` — front-door tests for the doctor/init CLI.
- `tests/state-store.sh` — round-trip/reducer tests for `pandastack-state`.
- `tests/resolver-golden.md` — 30 prompts × expected-skill regression set; guards dispatch correctness.

### Live convention dirs (keep the dir, separate/cut the stale instance files)
- `_staging/` — skill-evolution lifecycle dir (`trigger-first-skill-evolution.md` + `skill-creator` enforce it).
- `Inbox/` — live skill-output dir (grill/dojo/office-hours/boardroom write here).
- `docs/plans/`, `docs/briefs/`, `docs/handoffs/`, `docs/runbooks/` — conventions skills read/write; only the platform-buildout *instances* inside separate out.

## 3. SEPARATE — real, but a different product (move to its own repo)

> Cut-safety note: every item below is test- or driver-referenced (none safely CUT). `cron_wired:true` items are run by the launchd scheduler → **move, never delete in place.**

### Autonomous driver loop
- `scripts/pandastack-drive` — the 58KB driver core (autonomy config → per-item invocations, auto-merge to `psdrive/integration`). The platform's heart. **cron_wired.**
- `scripts/drive-cron.py` — the launchd entry point (`com.pandastack.drive.plist`). **cron_wired.**
- `scripts/drive-pulse` — computes trust streak / reverts / fake-green. **cron_wired.**
- `scripts/agent-worker` — flow↔runtime backend adapter (codex|test); called by `pandastack-drive`. **cron_wired.**
- `scripts/pslib.py` — shared kill-switch predicate + streak math; imported by 14 driver-internal files. Deleting it breaks the whole loop. **cron_wired. SEPARATE, never CUT.**
- `scripts/drive-disconfirm` — human revert + reason-ledger, resets the streak.
- `scripts/drive-graduate` — earned-the-streak interlock (PRO-63) before auto-promote-to-main may enable.
- `scripts/drive-promote` — T05a manual promote `psdrive/integration` → `main` (human-only).
- `scripts/drive-log-distill` — **BRIDGE** (also called by live `retro-week`; guarded). Move with platform, *record retro-week as a known consumer.* **cron_wired.**
- `scripts/learning-refresh` — **BRIDGE** (referenced only by live `retro-week`; guarded). Move with platform, flag the dependency.
- `docs/driver-autonomy.md` — the `pandastack-drive` four-mode contract doc.
- `docs/agent-worker.md` — protocol doc for `scripts/agent-worker`.
- `config/` (only `high-blast-paths`) — default-deny blast-radius policy consumed by the driver.
- `pandastack.toml` — capability-role manifest (hosts/workers/operators) read by the driver/capability layer, distinct from `manifest.toml`.
- `.pandastack/` — platform runtime state root (absent here, gitignored); conceptually separates.

### Linear automation (zero SKILL.md/lib refs; consumed only by the driver + its own tests)
- `scripts/pandastack-linear-reduce` — the driver's deterministic WBS decision core; imported by `pandastack-drive:40`.
- `scripts/pandastack-linear-advance` — Linear writeback; emitted by `pandastack-drive` (L763/L944).
- `scripts/pandastack-linear-comment` — append-only Linear ledger helper.
- `scripts/pandastack-pr-review-comment` — posts review output as a GitHub PR artifact for the linkback loop.
- `docs/linear-contract.md` — Linear-as-WBS contract for the headless scheduler.
- `docs/linear-linkback.md` — PR↔Linear linkback protocol.

### Multi-host capability-map runtime
- `docs/capabilities.md` — runtime capability-map (`pandastack.toml` + `capabilities.json` + `runtimes.json`) for orchestration code (PRO-17/18).
- `tests/pandastack-capabilities.sh` — contract tests for the capability map; travel with it.

### Platform tests (~33 of 45 test files)
- `tests/drive-*.sh`, `tests/drive-*.py` (33 files) — the entire autonomous-loop suite (killswitch, merge router, retry, ledger, pulse, graduate, etc.); all import `pslib` or target driver scripts. **cron-adjacent.**
- `tests/linear-reduce.sh`, `tests/linear-linkback.sh` — track the SEPARATE Linear core/helpers.
- `tests/verify-strict.sh` — tests `pandastack-drive`'s materialized verify.sh under strict mode.
- `tests/agent-worker.sh`, `tests/learning-refresh.sh` — target the driver/learning-platform scripts.

### Platform buildout instance files (conventions stay in pack; these instances move)
- `docs/plans/coding-agent-autonomy-rungs.md` — auto-merge ladder plan.
- `docs/plans/post-merge-hardening.md` — driver auto-merge hardening backlog.
- `docs/plans/pro-15-pandastack-cli-doctor.md` — doctor CLI plan (install/platform track).
- `docs/plans/pro-17-capability-map.md` — capability-map plan.
- `docs/plans/scheduler-wbs-linear.md` — Linear-as-WBS scheduler plan (status: done).
- `docs/plans/ticket-gated-worktree-pipeline.md` — harness-substrate plan (AGENTS.md/CLAUDE.md rule).
- `docs/briefs/2026-06-13-scheduler-wbs-linear.md` — brief behind the scheduler.
- `docs/briefs/2026-06-19-coding-agent-autonomy-rungs.md` — brief behind the auto-merge ladder.
- `docs/briefs/2026-06-19-ticket-gated-worktree-pipeline.md` — brief behind the ticket-gate rule.
- `docs/runbooks/integration-auto-merge-golive.md` — operator runbook to turn the auto-merge ratchet ON.

### Misfiled draft skill (different pack)
- `_staging/skill-sector-fan-out-build/SKILL.md` — draft for brain/stocks universe ingest (台股族群, Yei protocols). A gbrain-domain skill, not a pandastack dev-workflow verb. Move to the brain side; keep the `_staging/` dir.

## 4. CUT — dead / cruft / finished migration (verified safe to delete)

- `skills/.archive/` (8 dead skills: `agent-browser-duplicate`, `inbox-triage`, `scout`, `summarize`, `think-like-naval`, `think-like-alan-chan`, `tool-web-extract`, `work-ship`) — already archived, not in `plugin.json`/`manifest`, not loaded by the runtime. `agent-browser-duplicate` confirmed a dup of the npm CLI docs. Formalize the deletion.
- `scripts/backfill-learning-first-seen` — self-described ONE-TIME idempotent corpus migration (PRO-39); referenced only by its own test (`tests/backfill-learning.sh`). Migration has run. (Archive with the platform's migration history if desired.)
- `tests/backfill-learning.sh` — test for the above finished migration; dies with it.
- `docs/skill-context-schema.md` — documents the RETIRED L5 PreToolUse firewall; the doc itself states *"nothing reads them at runtime."* Dead spec, no consumer.
- `docs/handoffs/88-forkb-spike-report.md` — spike report for the very layout decision under audit (issue #88); superseded scratch once the layout is decided. Not referenced by any skill/README/script.
- `Inbox/sprint-ticket-gated-worktree-pipeline-2026-06-19.md` — a single PAUSED sprint-state checkpoint from the ticket-gate dogfood. Personal working state, should never have been committed. The `Inbox/` convention stays.

## 5. ITEMS NEEDING A DECISION (called out, not auto-resolved)

- `contexts/` (4 `.toml` recipes: developer/knowledge-manager/trader/writer) — referenced only by `RESOLVER.md` + `README.md`, which *claim* `persona-frame` loads them, but no SKILL.md or `lib/persona-frame.md` actually reads them. Orphan recipe layer. **Decide:** wire into `persona-frame`, or CUT as a stale subsystem (and fix the RESOLVER claim either way).
- `ROADMAP.md` — mixed. The v1.x/v2 public-readiness sections are legit pack roadmap; ~40% (the Scheduler/driver-autonomy section + symphony feature-map + `drive-*` task ladder) is platform planning. **Decide:** keep `ROADMAP.md`, SPLIT the scheduler/driver-autonomy section out to the platform's own roadmap.
- Version-drift reconcile (cosmetic but should ship together): `plugin.json` v3.1.0/28-skills vs `manifest.toml` + `RESOLVER.md` v2.2/26-skills.

## 6. WHAT THIS GETS YOU

The pack goes from **~95 tracked files to roughly ~55**: it sheds the entire driver platform — ~10 `scripts/` (`pandastack-drive`, `drive-*`, `pslib.py`, `agent-worker`, `pandastack-linear-*`), ~33 `drive-*` tests + the linear/capability tests, ~10 platform plan/brief/runbook instances, the driver config + `pandastack.toml`, and 6 CUT items (8-skill `.archive/`, the finished backfill migration + its test, the retired-firewall spec, the spike report, the stale Inbox checkpoint).

**Headline: split the autonomous driver + Linear automation + capability-map into their own repo.** What remains is a clean, self-contained skills pack — 28 skills, the loader + 2 safety hooks, the `lib/` primitives, the discovery specs, the eval/lint gates, and the multi-host *consumption* docs — coupled to the lifted-out platform only through three already-guarded, gracefully-degrading script calls.
