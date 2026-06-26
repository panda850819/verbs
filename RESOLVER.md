# RESOLVER.md

> Map of every skill / persona / context in pandastack v2.2. Use this as the index when something looks like overlap or you can't tell which skill to invoke.
>
> Companion to PHILOSOPHY.md (the why) and the per-skill SKILL.md files (the how).

## Why this file exists

pandastack v2.2 ships **26 skills** (24 core + 2 ext), 5 personas, and 7 context recipes. **Lifecycle flows are no longer first-class constructs** — what used to live in `flows/*.md` is now either documented inline in the relevant skill (sprint covers dev, ship knowledge covers knowledge close) or has been demoted because it wasn't really a flow (decision was an autonomy contract, research was a knowledge variant, work was a dev variant + work-ship).

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
| `pandastack:careful` | Confirmation gates for production / shared infra | working on prod |
| `pandastack:checkpoint` | Save / resume working state snapshot | pausing work |
| `pandastack:freeze` | Lock editing scope to specific paths | scope discipline |
| `pandastack:qa` | Browser-based UI QA | test this UI |
| `pandastack:review` | Parallel 3-pass review + Codex cross-check | review PR |
| `pandastack:ship` | Test + commit + PR (git mode is default). CLOSES finished work — to hand UNFINISHED work to Codex use `handover`. | code done, ship it |
| `pandastack:handover` | Hand unfinished work to Codex to DO: sync (spawn `codex exec` now) or `--async` (write payload for Hermes). Not `ship` — ship closes, handover delegates. | hand this to codex, let codex finish, 丟給 codex |
| `pandastack:sprint` | Single-track 1-2h focused execution: dojo → grill-lite → execute → review → ship. Replaces the v2.1 `dev` flow spec. `--delegate codex` delegates a ≥3-unit batch via `handover`. | small focused task |
| `pandastack:dojo` | Pre-action prep, surfaces gotchas | before a work session |
| `pandastack:team-orchestrate` | Conductor-driven parallel execution across N independent worktree branches | fan out, run these in parallel |

For multi-step sequential work, run multiple sprints in sequence. v1.x had `execute-plan` as a sequential subagent coordinator; cut in v2.0.0 because it overlapped sprint Phase 3 without earning its complexity.

For greenfield design (DB schema / service topology / ADRs), use `eng-lead` persona inside a sprint. v1.x had a separate `architect` persona; folded into eng-lead in v2.0.0 because Panda's day-to-day is maintenance, not greenfield.

### Retro / session

| Skill | Purpose | Trigger |
|---|---|---|
| `pandastack:retro-week` | Three-phase weekly retro (Auto-scan → Interview → Write). Phase 1 scans vault files directly (rg / find on `Blog/_daily/` + `Inbox/ship-log/`) to fetch retro inputs. | weekly retro |
| `pandastack:retro-month` | Three-phase monthly retro (with weekly retros referenced) | monthly retro |

### Tool wrappers (1:1 with public CLIs)

| Skill | Wraps |
|---|---|
| `pandastack:deepwiki` | DeepWiki repo docs |

`agent-browser` skill archived 2026-06-08 (duplicate of the npm CLI's own docs); `qa` still drives the CLI directly.

Private CLI wrappers (`bird` for X/Twitter) are not in the public package; `notion` and `slack` ops are replaced by Claude.ai MCP servers. v2.2.0 deleted the public `notion` and `slack` skills — use the Notion / Slack MCP via OAuth instead (token doesn't sit on disk).

### Persona thinking frames

(none in public package as of v2.2)

v2.2.0 cut `think-like-naval` and `think-like-alan-chan` — replicating someone else's thinking pattern is mimicry not insight; the 5 role personas (ceo / product-lead / eng-lead / design-lead / ops-lead) cover the cognitive-lens use case. v1.x had `think-like-karpathy`; cut in v2.0.0 because Panda cited Karpathy in notes but did not actively use his frame.

### Multi-lens review

| Skill | Purpose |
|---|---|
| `pandastack:boardroom` | Single-skill 4-voice critique (CEO → product → design → eng) on a plan. Per-finding apply gate. |

### Trust evaluation (NOT code review)

| Skill | Purpose |
|---|---|
| `pandastack:gatekeeper` | Pre-adoption trust check for external agents / MCP / repos / on-chain. NOT a code review skill. STRIDE classification at Step 0. |

### Meta / skill authoring

| Skill | Purpose | Trigger |
|---|---|---|
| `pandastack:skill-creator` | Create new pandastack skills. MECE-checks RESOLVER, enforces hot/cold dispatch, and applies trigger-first skill evolution before creating/extracting abstractions. | "create a skill", "new pandastack skill", "improve this skill" |

---

## Private supplement

Some lifecycles (work alert triage, on-chain trading research, cadence skills like `brief-morning` / `evening-distill` / `bird` / `curate-feeds`) are not in this public index — they need private CLIs. The public index above stays self-contained: anything you can read here, you can install from this repo alone.

v2.2.0 cut 4 skills (bird, brief-morning, evening-distill, curate-feeds) from this manifest. They require private CLIs and could not run for public users anyway.

---

## Disambiguation: where things look like overlap but aren't

### Sprint vs team-orchestrate

| | sprint | team-orchestrate |
|---|---|---|
| Tracks | 1 | N |
| Executor | Main session | N subagents (one per worktree) |
| Use when | Single focused task; for N-step sequential, run N sprints | N truly independent branches, wall-clock parallelism matters |

Different shapes. Sprint = time line. team-orchestrate = space cut. They are not "sprint × N".

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

### Two retro skills

| Skill | When |
|---|---|
| `pandastack:retro-week` | Sunday or end of week. Three phases (Auto-scan / Interview / Write). |
| `pandastack:retro-month` | End of month. References past 4 weekly retros. |

### Three ship modes (single skill)

`/ship` is one skill with three modes:

| Mode | Trigger | What it does |
|---|---|---|
| git (default) | `/ship` (no args) or `/ship <branch-flag>` | test + commit + push + PR |
| knowledge | `/ship knowledge <path>` or `/ship knowledge/...` or `/ship decisions/...` | Close + Extract + Backflow on a knowledge note. Decision-note variant (path matches `decisions/`) handles work-topic close — also writes `Inbox/ship-proposals/` markdown for manual external push. Replaces v2.1 `work-ship`. |

---

## Persona skills (5)

pandastack is **skill-only**. No agent dispatch. The 5 lead personas live as skills under `skills/{persona}/SKILL.md`, share the structure defined in `lib/persona-frame.md`, and are invoked in-session via `/persona` slash or chained from `boardroom`.

| Skill | When |
|---|---|
| `pandastack:ceo` | Strategic decisions, kill/pivot/continue, framework tension |
| `pandastack:ops-lead` | COO-level — systems that run without you, process-when-painful, decision shape (action / owner / deadline) |
| `pandastack:product-lead` | User problems over solutions, metric-driven, says no more often than yes |
| `pandastack:eng-lead` | Build / debug / ship — minimal diff, root cause, no spiral. Also covers tech-stack / DB schema / API contract decisions (was: separate `architect` persona in v1.x, folded in v2.0.0). |
| `pandastack:design-lead` | Intentional over decorative, every element earns its place |

All 5 are READ-ONLY persona skills. They recommend; user decides.

---

## Lifecycle map

3 documented compositions, no separate flow specs (cut in v2.2.0):

| Composition | Driver / chain | Where the lifecycle is documented |
|---|---|---|
| dev | `/sprint` (1-2h) or manual `/office-hours` → `/careful` → build → `/qa` → `/review` → `/ship` | `skills/sprint/SKILL.md` + README "Lifecycle map" |
| writing | `/write` → manual publish (`ship write` retired 2026-06-12, no Blog tree) | `skills/write/SKILL.md` + README "Lifecycle map" |
| knowledge | direct write to vault → `/ship knowledge <path>` | `skills/ship/modes/knowledge.md` + README "Lifecycle map" |

What used to be `flows/<name>.md` is gone. Reasons:
- **dev**: `/sprint` is the executable spec; the long-form `flows/dev.md` was duplicate.
- **writing**, **knowledge**: their lifecycles are short enough to fit inside their respective `/ship` mode files.
- **research**: not a real flow — it's a knowledge variant (Phase 1-3 vary, Phase 4-6 = knowledge ship). The variant lives inline in `/scout`'s SKILL.md (cut in v2.2) and `/ship knowledge`.
- **work**: not a real flow — it's a dev variant + decision-note variant of `/ship knowledge`. The Phase 0 triage and Phase 5 ext-push are now AGENTS.md rules ("external-mutation-is-proposal").
- **decision**: not a flow — it's an async autonomy contract ("cron proposes, Panda decides, Panda executes"). Lives as a rule in `~/.agents/AGENTS.md`, not as a flow spec.
- **retro**: `/retro-week` and `/retro-month` are the executable specs. The cadence (daily close → weekly → monthly) lives in their SKILL.md files.

---

## Contexts (8 recipes)

Each `.toml` file in `contexts/` binds a flow + persona + skill subset to a specific identity. Loaded via `lib/persona-frame.md`.

| Context | Identity | Private |
|---|---|---|
| `personal-developer` | Personal dev work | no |
| `personal-writer` | Personal writing | no |
| `personal-knowledge-manager` | Personal knowledge work | no |
| `personal-trader` | Personal trading | yes |
| `work-yei-ops` | Yei Ops Manager | yes |
| `work-yei-hr` | Yei HR | yes |
| `work-yei-finance` | Yei Finance | yes |

Private contexts (in the private overlay) may reference additional skills beyond this index. Public contexts only reference skills listed above.

---

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

| Origin | Skills (still in v2.2 public package) |
|---|---|
| Built in v0.16 | careful, checkpoint, freeze, init, qa, review, ship |
| Added in v1 from `~/.claude/skills/` (local) | grill, retro-week, retro-month, gatekeeper, deepwiki, agent-browser |
| Persona skills | ceo, eng-lead, design-lead, ops-lead, product-lead |
| Decision/sprint flow | sprint, dojo, office-hours, boardroom, team-orchestrate |
| Meta | using-pandastack, init |
| Writing | write |

---

## Version

This RESOLVER.md is for pandastack v2.2.0. Update when adding / removing / renaming skills.

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
| `tool-browser` | `agent-browser` | v1.4.0 | 2026-08-05 |
| `tool-slack` / `tool-notion` / `tool-summarize` | n/a (skills cut in v2.2.0) | v1.4.0 | n/a after cut |
| `agent-browser` | `tool-browser` | v1.1 (then reverted in v1.4.0) | n/a |
| `content-write` | `write` | v1.1 | expired 2026-08-04 |
| `feed-curator` | `curate-feeds` (now in private overlay) | v1.1 | expired 2026-08-04 |
| `harness-survey` | `scout` (cut v2.2.0) | v1.1 | expired 2026-08-04 |
| `morning-briefing` | `brief-morning` (now in private overlay) | v1.1 | expired 2026-08-04 |
| `slowmist-agent-security` | `gatekeeper` | v1.1 | expired 2026-08-04 |
| `weekly-retro-prep` | `retro-prep-week` (then deleted v2.0.0) | v1.1 → cut v2.0.0 | n/a |

If you have hardcoded old names in cron jobs, launchd plists, Hermes manifests, or context recipes, update before the grace dates above.
