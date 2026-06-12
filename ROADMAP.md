# Roadmap

> Living document for pandastack scope ahead of `main`. Each milestone has a clear gate. CHANGELOG records what shipped; ROADMAP records what is planned and why.

## v1.x, personal-substrate stable (current)

Status: stable since 2026-04-29 (`aab8f49`). API, schema, and skill content are stable for the author's daily use. Dogfooded across 4 of 7 lifecycle flows (ship / work / knowledge / review). Three lifecycles unfired during the dogfood window (dev / write / retro / grill) are not v1 cut blockers; personal-substrate stable does not require all 7 lifecycles covered.

What v1 is:

- 38 skills (27 core / 5 ext / 6 personal) covering dev / knowledge / writing / work / research / retro / decision lifecycles
- 5 personas (eng / design / ceo / ops / product) replaceable per project
- 4 personal contexts + private overlay for work contexts
- 5-layer firewall (L1 voice / L2 fs chmod / L3 MCP deny / L4 context recipe / L5 per-skill allowlist)
- Multi-CLI runtime support: Claude Code first-class, Codex CLI native, Hermes via `pdctx`

What v1 is **not**:

- Public-ready for fresh users. As of 2026-05-06, the count of fresh A-class users (Obsidian + Coding Agent power users) who have run `/plugin install` end-to-end without author intervention is 0. The v1 README "Quick start" section ships in dev-mode framing for this reason.
- Onboarding-scaffold-bundled. v1 assumes the user brings their own vault and pdctx config. capability-probe will surface gaps; v1 does not paper over them.

Maintenance window through v2: skill content can iterate (new skills, refactors, lib extractions) under v1.x minor versions as long as Tier 1 substrate primitives (persona / context / skill-as-markdown) stay stable. Breaking changes to the three primitives go behind a v2.0 cut, not v1.x.

## v2, public-ready (planned)

Goal: a fresh A-class user can `/plugin install pandastack@pandastack` and reach a productive first session without reading the full README or asking the author. v2 is the public-readiness gate.

Scope:

- **Onboarding scaffold** `[partial — shipped in v1.3.0 / v1.4.0; env-var requirement removed in v2.0.1; brain-index assumption removed in v2.1.0]`. Bootstrap script (`scripts/bootstrap.sh`) + manifest-driven tier model (`plugins/pandastack/manifest.toml`) replaced the previous 4-section README install dance. Skills derive vault path from cwd and Google account from `gog` defaults — no env vars to set, no brain index to bootstrap. Remaining for v2.x: vault scaffolding (auto-create `Inbox/`, `Blog/_daily/`, `docs/learnings/atoms/` if absent), pdctx context picker, first-session walkthrough.
- **Fresh A-user dogfood criteria**. v2 cut requires real-user validation, not author-only. Concrete bar: 3 fresh A-class users complete install + 1 week of daily use without author hand-holding. Below that, v2 stays in pre-release. v1.3.0+ structural fix opens the verification window — before this, the install bar was too high to ask anyone to try.
- **Public capability-probe defaults** `[partial — shipped in v1.3.0]`. Manifest tier metadata + bootstrap.sh probe table now route fresh users through "what runs now / what to install / what is private overlay" rather than a "you're on your own" dump. Remaining for v2: capability-probe itself (the in-skill `lib/capability-probe.md` invocation) needs to consume manifest data and emit the same actionable framing rather than the current generic gap dump.
- **L5 firewall hook**. README v1.4.0 was honest about L5 currently being frontmatter-only metadata with no runtime enforcement. v2 should ship the actual PreToolUse hook that reads `reads` / `writes` / `forbids` / `classification` from each SKILL.md and enforces them — or formally retire L5 as a design choice and update the architecture doc accordingly.

Out of v2 scope (deferred or rejected):

- B-class TA (no vault, want to start from zero). Bundling a vault-less mode adds a second product surface; not worth the complexity in v2.
- D-class TA (no vault, just want multi-CLI persona switching). pdctx already does this standalone; pandastack does not need to compete with itself.
- Hosted SaaS variant. Cofounder.co occupies that surface; pandastack stays self-hosted personal-OS by design.
- Vault-provider abstraction (Logseq / Roam / Notion adapter layer). Removed from v2 scope on 2026-05-07 after re-audit. pandastack skills are LLM prompts, not compiled code — path conventions in skill text are defaults the agent can override per-session. The only real code-level path coupling is `curate-feeds.ts`'s `RAW_ROOT`, which already accepts any vault with `.obsidian/` or `Inbox/`. Building a vault-provider interface for prompt-based skills was over-engineered: a non-Obsidian user adapts conventions in conversation or by editing skill text, not by swapping a backend. If Logseq / Roam / Notion users show up, the right move is to document convention overrides, not to ship an interface.

## Open questions (v2 timeline)

These are not yet decided. Each affects v2 priority but does not block v1 cut.

- **When does v2 work start?** Three plausible triggers: (a) companyos Phase 1 sprints close to free up author bandwidth; (b) ≥1 fresh A-class user reaches out organically and asks for install help (signals real demand); (c) calendar-driven start at 2026 Q3. No commitment yet.
- **What do the 50 補丁 skills look like under v1.x stable?** The three substrate primitives (persona / context / skill-as-markdown) are locked. The补丁 layer (curate-feeds, gatekeeper, retro-week, etc.) iterates inside v1.x minor versions. Open: should a subset (careful / grill / sprint / review / ship) be promoted to substrate-tier and frozen, or stay iterable?
- **Cofounder.co follow-up**. Cofounder shipped 1:1 architecture (Departments / Agents / Skills) as a closed-platform SaaS on 2026-05-04. Their multi-CLI / self-host stance at 2026-11 (6-month look-ahead) influences v2 priority: if they open self-host, pandastack's v2 differentiation narrows; if they stay closed-platform, pandastack's open-substrate position holds.

## v2.1.0 cut (2026-05-07)

Substrate-agnostic cut. Removed `gbq` / `gbrain` assumption from all skills (was personal-CLI dependency that fresh installs couldn't satisfy without separate brain index). Vault scans now use `rg` / `find` directly. Cut `deep-research` skill (gbrain-core) and `work-sommet-abyss-po` context. Net: 39 → 38 skills, 8 → 7 contexts. See `CHANGELOG.md` v2.1.0.

## Decision rationale

Full reasoning, alternatives considered, and gate log live in the office-hours brief at `docs/briefs/2026-05-06-pandastack-v1-stable-cut.md` (vault-side, author-only). CHANGELOG v1.2.2 entry summarizes the public-facing version. This file lives at repo root for version control and visibility from `/plugin install`.

## How to read this

- v1.x = stable, iterate the补丁 layer, lock the three primitives
- v2 = explicit re-cut for public-readiness, not a free version bump
- Open questions = not decisions; they get resolved as data arrives, not on a schedule

- [ ] 2026-06-12 (PR #7 deferred): dojo SKILL.md still greps `Blog/_daily/` in its past-case scan path — dead dir post write-mode retirement, harmless but should be dropped next time dojo is touched.
