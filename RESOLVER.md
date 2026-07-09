# RESOLVER.md

> Map of every skill in pandastack. Use this as the index when something looks like overlap or you can't tell which skill to invoke.
>
> Companion to PHILOSOPHY.md (the why) and the per-skill SKILL.md files (the how).

## Why this file exists

pandastack ships the skills cataloged in `manifest.toml` (core + ext tiers). **Lifecycle flows are no longer first-class constructs** — what used to live in `flows/*.md` is now either documented inline in the relevant skill (sprint covers dev, ship knowledge covers knowledge close) or has been demoted because it wasn't really a flow (decision was an autonomy contract, research was a knowledge variant, work was a dev variant + work-ship).

This is the pattern used by gstack and alirezarezvani: monorepo + RESOLVER.md beats multi-repo split, because the categorization lives next to the content.

---

## Skill catalog (by lifecycle, not alphabetical)

### Knowledge

| Skill | Purpose | Trigger |
|---|---|---|
| `pandastack:ship knowledge <path>` | Close + Extract + Backflow on a knowledge note (incl. decision-note variant for work-topic close, replaces v2.1 `work-ship`) | ship this note, close out this decision |

Vault hygiene (orphans / stale / superseded / dead redirects) is a direct file scan (`rg` / `find`) or — when `gbrain` is connected — a brain query (`mcp__gbrain__find_orphans` etc), not a dedicated skill. v2.2.0 cut `inbox-triage` (brain replaces); v2.0.0 cut `wiki-lint`.

### Writing

| Skill | Purpose | Trigger |
|---|---|---|
| `pandastack:write` | Voice-aware drafting + slop detection | help me write |

`brief-morning` and `evening-distill` (daily cadence) were cut from the public package in v2.2.0 — they require private CLIs (gog).

### Dev workflow

| Skill | Purpose | Trigger |
|---|---|---|
| `pandastack:grill` | Adversarial requirement discovery, atomic 5-10 min, surfaces unknown unknowns. For structured-brief output use `office-hours`. | grill me, stress test, what am I missing |
| `pandastack:office-hours` | Structured 5-stage flow producing a brief in `docs/briefs/`. `--quick` mode skips capability probe + goal mapping. | office hours, draft a brief, structured intake |
| `pandastack:boardroom` | Mutually-blind parallel critique of a PREPARED plan: N blind critics on distinct risk-surface lenses, keep every lone finding, per-finding gate. Repackaged from the deleted persona-voice boardroom (no persona). NOT diff review (`review`) or fuzzy ideas (`office-hours`). | critique this plan, red-team this, 多角度審 |
| `pandastack:careful` | Confirmation gates for production / shared infra | working on prod |
| `pandastack:ui` | Build/fix UI with a point of view: 4 override reflexes (lock direction + anti-slop, verify render not source, build past happy path, decompose cited products) + craft lore in references (fonts, CJK+Latin type, OKLCH, CSS bans, omissions). NOT browser-test (`qa`) or render-bug (`debug`). | design, 做頁面, 不好看, 很醜, 排版 |
| `pandastack:qa` | Browser-based UI QA | test this UI |
| `pandastack:review` | Parallel 3-pass review + Codex cross-check | review PR |
| `pandastack:debug` | Systematic root-cause debugging: one-sentence root-cause gate, hypothesis-explains-every-symptom, instrument-first by bug class, bisect, scope-blast (举一反三), known bug classes. NOT diff review (`review`) or UI taste (`ui`). | bug, crash, regression, 報錯, 跑不通, used to work |
| `pandastack:ship` | Test + commit + PR (git mode is default). CLOSES finished work — to hand UNFINISHED work to Codex use `handover`. | code done, ship it |
| `pandastack:handover` | Hand unfinished work to Codex to DO: sync (spawn `codex exec` now) or `--async` (write payload for Hermes). Not `ship` — ship closes, handover delegates. | hand this to codex, let codex finish, 丟給 codex |
| `pandastack:advisor` | Pull a decorrelated second opinion from a DIFFERENT model into the current session on a load-bearing judgment. Zero-config self-locate seat (Claude→codex/GPT, Codex→`claude -p`). `--panel` = blind cross-model critics on a prepared plan (absorbed `boardroom`). The inbound half of the cross-runtime pair; `handover` is the outbound half. | second opinion, red-team this, 多角度審, am I sure about this |
| `pandastack:sprint` | Single-track 1-2h focused execution: scope → grill-lite → execute → review → ship. Replaces the v2.1 `dev` flow spec. `--delegate codex` delegates a ≥3-unit batch via `handover`. | small focused task |

For multi-step sequential work, run multiple sprints in sequence. v1.x had `execute-plan` as a sequential subagent coordinator; cut in v2.0.0 because it overlapped sprint Phase 3 without earning its complexity.

Greenfield design (DB schema / service topology / ADRs) is rare for Panda's maintenance-heavy work; scope it in `office-hours`, then build in a sprint.

### Tool wrappers (1:1 with public CLIs)

| Skill | Wraps |
|---|---|
| `pandastack:deepwiki` | GitHub repo docs from a local clone |

`agent-browser` skill archived 2026-06-08 (duplicate of the npm CLI's own docs); `qa` still drives the CLI directly.

Private CLI wrappers (`bird` for X/Twitter) are not in the public package; `notion` and `slack` ops are replaced by Claude.ai MCP servers. v2.2.0 deleted the public `notion` and `slack` skills — use the Notion / Slack MCP via OAuth instead (token doesn't sit on disk).

### Trust evaluation (NOT code review)

| Skill | Purpose |
|---|---|
| `pandastack:gatekeeper` | Pre-adoption trust check for external agents / MCP / repos / on-chain. NOT a code review skill. STRIDE classification at Step 0. |

### Meta / skill authoring

| Skill | Purpose | Trigger |
|---|---|---|
| `pandastack:skill-creator` | Create new pandastack skills. MECE-checks RESOLVER, enforces hot/cold dispatch, and applies trigger-first skill evolution before creating/extracting abstractions. | "create a skill", "new pandastack skill", "improve this skill" |
| `pandastack:writing-great-skills` | Reference + scorecard for well-constructed skills. The construction-quality SSOT (scores the SKILL.md, not its artifact — that's `lib/quality-rubric.md`). `skill-creator` self-checks against it; `skill-eval` binds it. | "how do I write a skill", "what makes a skill good", consulted while authoring |
| `pandastack:skill-eval` | Score an existing skill against the writing-great-skills scorecard and write a co-located `eval.md` verdict (hash-stamped; `lint-eval-fresh.sh` catches drift). Evaluator counterpart to skill-creator. | "eval this skill", "score this skill", "is this skill well-written" |
| `pandastack:instruction-audit` | Audit the live instruction corpus (AGENTS.md / CLAUDE.md / judgment-compact / skill bodies) for six defect classes: model-era compensation, overtrigger language, step-list bloat, cross-layer duplicates, admission-test failures, growth-budget breach. Read-only — outputs a candidate delete/rewrite/merge list; the human applies. NOT one skill's construction score (`skill-eval`) or artifact review (cross-modal-review). | manual `/instruction-audit`, at retro-week or before adding a new rule |
| `pandastack:using-pandastack` | Session-start cognitive contract: forces the skill-check before any response or action. Loaded automatically at session open. | (automatic at session start) |
| `pandastack:init` | One-time pandastack init per project: detects project type, writes config to the project CLAUDE.md / AGENTS.md. | set up pandastack here, init this project |

> **skill-creator vs skill-eval vs writing-great-skills**: writing-great-skills is the criteria (read); skill-creator builds skills and self-checks against it; skill-eval judges existing skills against it and leaves the verdict. Same SSOT, generator/evaluator split — mirrors how `lib/quality-rubric.md` binds `write`/`ui` (generate) and `review` (evaluate).

---

## Private supplement

Some lifecycles (work alert triage, on-chain trading research, cadence skills like `brief-morning` / `evening-distill` / `bird` / `curate-feeds`) are not in this public index — they need private CLIs. The public index above stays self-contained: anything you can read here, you can install from this repo alone.

v2.2.0 cut 4 skills (bird, brief-morning, evening-distill, curate-feeds) from this manifest. They require private CLIs and could not run for public users anyway.

---

## Disambiguation: where things look like overlap but aren't

### Four "review" skills

| Skill | What it reviews |
|---|---|
| Built-in `/review` | Generic PR review (Claude Code platform default) |
| Built-in `/security-review` | Branch code for security issues |
| `pandastack:review` | YOUR code via parallel 3-pass + Codex cross-check |
| `pandastack:gatekeeper` | EXTERNAL agents / MCP / repos BEFORE you adopt them — adoption gate, not code review |

If you're reviewing your own PR → `pandastack:review`. If you're deciding whether to install someone else's MCP server / clone their skill repo → `pandastack:gatekeeper`.

### Requirement-discovery skills (split by output)

- `pandastack:grill` — adversarial, one-question-at-a-time, surfaces unknown unknowns. Atomic 5-10 min, no brief output (just `Inbox/grill-*.md` log).
- `pandastack:office-hours` — structured 5-stage flow that produces a brief in `docs/briefs/`. Default ~30 min; `--quick` mode (~10-15 min) skips capability probe + goal mapping when context is pre-loaded.

### Two ship modes (single skill)

`/ship` is one skill with two modes:

| Mode | Trigger | What it does |
|---|---|---|
| git (default) | `/ship` (no args) or `/ship <branch-flag>` | test + commit + push + PR |
| knowledge | `/ship knowledge <path>` or `/ship knowledge/...` or `/ship decisions/...` | Close + Extract + Backflow on a knowledge note. Decision-note variant (path matches `decisions/`) handles work-topic close — also writes `Inbox/ship-proposals/` markdown for manual external push. Replaces v2.1 `work-ship`. |

---

## Lifecycle map

3 documented compositions, no separate flow specs (cut in v2.2.0):

| Composition | Driver / chain | Where the lifecycle is documented |
|---|---|---|
| dev | `/sprint` (1-2h) or manual `/office-hours` → `/careful` → build → `/qa` → `/review` → `/ship` | `skills/engineering/sprint/SKILL.md` + README "Lifecycle map" |
| writing | `/write` → manual publish (`ship write` retired 2026-06-12, no Blog tree) | `skills/writing/write/SKILL.md` + README "Lifecycle map" |
| knowledge | direct write to vault → `/ship knowledge <path>` | `skills/engineering/ship/modes/knowledge.md` + README "Lifecycle map" |

What used to be `flows/<name>.md` is gone. Reasons:
- **dev**: `/sprint` is the executable spec; the long-form `flows/dev.md` was duplicate.
- **writing**, **knowledge**: their lifecycles are short enough to fit inside their respective `/ship` mode files.
- **research**: not a real flow — it's a knowledge variant (Phase 1-3 vary, Phase 4-6 = knowledge ship). The variant lives inline in `/scout`'s SKILL.md (cut in v2.2) and `/ship knowledge`.
- **work**: not a real flow — it's a dev variant + decision-note variant of `/ship knowledge`. The Phase 0 triage and Phase 5 ext-push are now AGENTS.md rules ("external-mutation-is-proposal").
- **decision**: not a flow — it's an async autonomy contract ("cron proposes, Panda decides, Panda executes"). Lives as a rule in `~/.agents/AGENTS.md`, not as a flow spec.
- **retro**: moved to the personal overlay (`~/.agents/skills/`) on 2026-06-30 — brain-centric PKM, not a coding-agent skill. Compounding now lives in the dev flow via `lib/learning-recall.md`, not a calendar retro.

---

## v3.2.0 — persona layer removed (2026-06-29, PR #100/#101)

| Action | Items | Reason |
|---|---|---|
| Deleted | `ceo`, `product-lead`, `ops-lead`, `design-lead`, `eng-lead` | Role-persona lenses were a uniform wrapper over pretrained frames; a skill earns its slot only by lore + the reflexes the model gets wrong despite understanding. eng-lead debug lore → new `debug`; design-lead craft → new `ui`; scope-judgment + delete-first → `grill` / `office-hours`; ops-lead covered by retro-week / cron / minion. `lib/outside-voice-rule.md` deleted (substrate covers it). git history is the archive. |
| Added | `debug`, `ui`, `boardroom` | Function-named: lore + reflex-overrides, not a persona frame. `boardroom` is the deleted persona-router rebuilt tiny — its one real capability (mutually-blind parallel plan critique) as a ~30-line forcing-function skill, no persona voices. |

## v3.4.0 — Fable 5 harness cut (2026-07-02)

Public package shrinks 23 → 19 skills. The cut removes skills whose main value was model-judgment scaffolding or orchestration now covered by native workflows.

| Action | Items | Reason |
|---|---|---|
| Archived | `team-orchestrate` | Native Workflow + worktree isolation cover the parallel branch shape. |
| Archived | `freeze` | Scope lock should be a code gate when needed, not a prose gate. |
| Archived | `checkpoint`, `dojo` | Downgraded from active runtime skills; native context handling plus `sprint`'s own intake covers the routine use case. |

## v2.2.0 cut summary

Public package shrinks 38 → 26 skills. 7 lifecycle flow specs → 0 (collapsed into per-skill SKILL.md and README "Lifecycle map").

| Action | Items | Reason |
|---|---|---|
| Archived (true cuts) | `think-like-naval`, `think-like-alan-chan` | Mimicry not insight; 5 role personas cover the cognitive-lens use case |
| Archived (true cuts) | `inbox-triage` | gbrain `find_orphans` + manual 5-min Inbox/ glance replaces |
| Archived (true cuts) | `scout` | Ad-hoc `gh repo view` + `WebFetch` suffices; no need for a Skill wrapper |
| Archived (true cuts) | `summarize` | gbrain ingest paths (`voice-note-ingest`, `media-ingest`, `idea-ingest`) replace |
| Archived (folded into `/ship`) | `work-ship` | Decision page is a knowledge note about a decision; folded as `/ship knowledge` decision-note variant |
| Deleted (use MCP) | `notion`, `slack` | Claude.ai Notion / Slack MCP via OAuth replaces local-CLI-with-keychain-token model. Token doesn't sit on disk. |
| Moved to private overlay | `bird`, `brief-morning`, `evening-distill`, `curate-feeds` | All require private CLIs (bird, gog, feed-server). Cannot ship in a public package. The overlay is now their canonical home. |
| Cut flow specs | All `flows/*.md` (7 files) | dev → `/sprint`; writing/knowledge → `/ship` modes; research/work/decision → not real flows; retro → `/retro-{week,month}` SKILL.md |

## v2.1.0 cut summary

| Action | Items | Reason |
|---|---|---|
| Cut skill | `deep-research` | gbrain-core: required `gbrain` CLI + brain index; pandastack v2.1.0 stops assuming a brain index |
| Cut context | `work-sommet-abyss-po` | Sommet Abyss inactive; will land in a separate plugin if revived |
| Cut substrate dependencies | `gbq` / `gbrain` calls across `brief-morning`, `evening-distill`, `dojo`, `done`, `retro-week`, all `flows/*.md` | substrate-agnostic: vault scan via `rg` / `find` works on any clone, no brain prerequisite |

## v2.0.0 cut summary

| Action | Skills | Reason |
|---|---|---|
| Cut (orphan / overlap / replaced) | `atomize`, `architect`, `execute-plan`, `think-like-karpathy`, `process-decisions`, `wiki-lint`, `retro-prep-week` | atoms.jsonl pattern died; greenfield rare → fold into eng-lead; sequential subagent overlapped sprint Phase 3; Karpathy frame referenced not used; cron-reports sparse → manual walk; vault lint → file scan; retro pre-fetch → fold into retro-week Phase 1 |
| Merged into `/ship` | `knowledge-ship`, `write-ship` → `/ship knowledge`, `/ship write` | one verb, one mental model |
| Renamed in v1.4.0 (still aliased) | `tool-pdf`→`pdf` (then deleted v1.4.1), `tool-bird`→`bird`, `tool-slack`→`slack`, `tool-notion`→`notion`, `tool-deepwiki`→`deepwiki`, `tool-summarize`→`summarize`, `tool-browser`→`agent-browser` | drop tool- prefix, names already disambiguate via `pandastack:` namespace |

## Provenance: how skills came to live here

| Origin | Skills (still in the current public package) |
|---|---|
| Built in v0.16 | careful, init, qa, review, ship |
| Added in v1 from `~/.claude/skills/` (local) | grill, gatekeeper, deepwiki |
| Decision/sprint flow | sprint, office-hours |
| Meta | using-pandastack, init, skill-creator, writing-great-skills, skill-eval |
| Writing | write |

---

## Version

This RESOLVER.md is for pandastack v3.4.0. Update when adding / removing / renaming skills.

---

## Aliases (90-day grace)

The following skill names were renamed/merged across versions. Old names still resolve via `aliases:` frontmatter for 90 days from each rename. After grace period, alias entries are removed and old names will fail.

| Old name (alias) | New name | Renamed in | Grace until |
|---|---|---|---|
| `work-ship` | `ship knowledge <decisions/path>` | v2.2.0 (2026-05-09) | 2026-08-07 |
| `knowledge-ship` | `ship knowledge` | v2.0.0 (2026-05-07) | 2026-08-05 |
| `write-ship` | n/a (`ship write` mode retired 2026-06-12 — Blog tree gone post-rebuild) | v2.0.0 (2026-05-07) | retired 2026-06-12 |
| `tool-bird` | `bird` (now in private overlay) | v1.4.0 | 2026-08-05 |
| `tool-deepwiki` | `deepwiki` | v1.4.0 | 2026-08-05 |
| `tool-browser` | n/a (`agent-browser` archived 2026-06-08) | v1.4.0 | n/a after archive |
| `tool-slack` / `tool-notion` / `tool-summarize` | n/a (skills cut in v2.2.0) | v1.4.0 | n/a after cut |
| `agent-browser` | `tool-browser` | v1.1 (then reverted in v1.4.0) | n/a |
| `content-write` | `write` | v1.1 | expired 2026-08-04 |
| `feed-curator` | `curate-feeds` (now in private overlay) | v1.1 | expired 2026-08-04 |
| `harness-survey` | `scout` (cut v2.2.0) | v1.1 | expired 2026-08-04 |
| `morning-briefing` | `brief-morning` (now in private overlay) | v1.1 | expired 2026-08-04 |
| `slowmist-agent-security` | `gatekeeper` | v1.1 | expired 2026-08-04 |
| `weekly-retro-prep` | `retro-prep-week` (then deleted v2.0.0) | v1.1 → cut v2.0.0 | n/a |

If you have hardcoded old names in cron jobs, launchd plists, or Hermes manifests, update before the grace dates above.
