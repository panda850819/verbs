---
name: boardroom
mode: skill
description: |
  Multi-lens plan critique router for prepared plans: sequential CEO, product, design, and engineering review with per-finding Apply? [Y/N/edit] gate; `--panel` runs the voices as independent, mutually-blind parallel critics for high-stakes plans. Invoke explicitly via /boardroom, leadership review, 4-voice critique, or review-this-plan. NOT for tactical execution, loose ideas, single-domain review, or ordinary planning.
reads:
  - repo: lib/persona-frame.md
  - repo: lib/outside-voice-rule.md
  - repo: lib/stop-rule.md
  - repo: lib/escape-hatch.md
  - repo: lib/capability-probe.md
  - repo: skills/ceo/SKILL.md
  - repo: skills/product-lead/SKILL.md
  - repo: skills/design-lead/SKILL.md
  - repo: skills/eng-lead/SKILL.md
  - repo: skills/ops-lead/SKILL.md  # invoked only when ops-dominant
writes:
  - vault: Inbox/boardroom-*.md
  - cli: stdout
domain: shared
classification: lifecycle-flow
capability_required:
  - agents.md
  - vault
  - lib/persona-frame.md
  - lib/outside-voice-rule.md
  - lib/stop-rule.md
  - skills/ceo
  - skills/product-lead
  - skills/design-lead
  - skills/eng-lead
---

# Boardroom — 4-voice plan critique

> Replaces persona-pipeline (deleted v1.1). Default mode is single-skill sequential voice-switching (no agent files): each voice loads its own SKILL.md cognitive model + iron laws + on-invoke protocol via `lib/persona-frame.md`, critiques in its own posture, hands off to next voice. `--panel` mode (high-stakes) dispatches the voices as cold, mutually-blind subagents via the same `persona-frame.md` inline pattern for genuine independence. User gates each finding in both modes.

## Routing Boundary

Use this as the multi-lens router only when there is a plan, proposal, PRD, or strategy draft ready for cross-functional critique. It coordinates role lenses; it is not a default persona layer.

Do not invoke for loose ideas that still need shaping, tactical execution, code debugging, ordinary planning, or single-domain review. Use the single role lens directly when only one lens is needed.

## When to invoke

- Plan / proposal / PRD draft is ready for cross-functional critique
- Pre-stakeholder presentation
- Major scope change before commitment
- User says "review this plan", "boardroom", "4-voice critique"

## When to skip

- Single-domain decisions (use one persona skill directly: `/eng-lead` or `/product-lead`)
- Tactical execution questions (use `/grill` instead — boardroom is for plans, not problems)
- Revisions to a plan already boardroom-reviewed (use atomic persona skill on the diff)

## Modes

Two modes, same voices, opposite mechanism. Pick by stakes.

| | **default (sequential)** | **`--panel` (independent)** |
|---|---|---|
| Mechanism | one model, one context, voices in order; each sees prior applied patches | N cold subagents in parallel, blind to each other, each sees only the original plan |
| Optimizes | coherence of the revised plan | independence — uncorrelated errors across lenses |
| Cost | cheap, in-session, fast | N× context startup + latency, cross-model |
| Use for | quick lens check while shaping | high-stakes / one-way-door / pre-commitment plans |
| Fixes | "did I miss an angle?" | "all four voices share the same blind spot" |

`--panel` is opt-in; default stays sequential. The core voices (Stage 1 scope) all run in the panel, same as default — no voice is skipped. The independence gate applies only when deciding whether to ADD an optional extra voice beyond Stage 1 scope: add it only if it can *independently* see a failure the core voices would miss — otherwise it is one mind in another hat.

## Stages

### Stage 0: Capability probe + plan load

@../../lib/capability-probe.md

Run probe. Then load the plan from path arg or active context. If no plan path, print "boardroom needs a plan path. Run `/boardroom <plan-path>` or paste the plan inline." and stop.

**Mode detection.** If the invocation carries `--panel`, run Stage 2-PANEL (independent parallel critique) instead of the default sequential Stage 2. All other stages are shared. Announce the mode: `boardroom mode: panel (independent)` or `boardroom mode: default (sequential)`.

### Stage 1: Voice scope detection

Determine which voices to invoke. Default: CEO + product + design + eng (4 voices, in order).

Add ops-lead **only if** plan is dominantly process / coordination / multi-team handoff. Detection rule:

```
ops_dominant = (plan mentions: process, SOP, handoff, coordination, weekly cadence, owner assignment)
                AND NOT (plan dominant frame is: feature, code, UX, architecture)
```

Print scope decision:
```
Voices to invoke: [ceo, product-lead, design-lead, eng-lead]
Skipped: [ops-lead — plan is feature-frame not coordination-frame]
```

User can override with `--voices ceo,eng-lead,ops-lead` or similar.

### Stage 2 (default): Sequential voice critique

Default mode only. If `--panel` was given, skip to Stage 2-PANEL.

For each voice in order:

1. Load `skills/{voice}/SKILL.md` — extract Soul / Iron Laws / Cognitive Models / On Invoke / Anti-patterns sections via `lib/persona-frame.md` contract.
2. Print voice header:
   ```
   ─── {voice} ───
   {Soul one-liner}
   ```
3. Apply voice's On Invoke protocol to the plan. Output 3-5 critiques in voice's posture.
4. Each critique formatted per `lib/outside-voice-rule.md`:
   ```
   ## {voice} Finding {n}: {summary}
   **Voice says**: {critique in posture}
   **Verdict (informational)**: agree / disagree / partial / unknown
   **Suggested patch**: {concrete change to plan}

   Apply to final plan? [Y / N / edit]
   ```
5. Wait for user response per finding (per `lib/stop-rule.md` — no batched gates).
6. If user triggers escape-hatch (per `lib/escape-hatch.md`), log remaining voice's findings as `[not asked, user stopped after voice {N}]`, proceed to Stage 3.
7. Move to next voice. Each voice sees previous voices' applied patches (not raw critiques) so each voice builds on the evolving plan, not the original.

### Stage 2-PANEL: Independent parallel critique (`--panel` only)

Engineers independence — the deliberate opposite of default Stage 2. No voice sees another voice's output or any evolving plan; every voice critiques the **original** plan from a cold context.

1. **Dispatch all in-scope voices in parallel as cold subagents.** For each voice, build the subagent prompt via the `lib/persona-frame.md` "Inline-from-skill dispatch pattern": resolve `skills/{voice}/SKILL.md`, extract the 6 contract sections (Soul / Iron Laws / Cognitive Models / On Invoke / Anti-patterns + BAD/GOOD calibration), inline them as the persona block at the TOP of the prompt. Below the fence, paste ONLY the original plan plus the adversarial mandate. Inline the relevant hard rules (Panda's voice, no em dash, no Co-Authored-By) — subagents do not read substrate.

2. **Adversarial mandate, not descriptive.** Each subagent's task: "Find the strongest reasons this plan FAILS from the {voice} lens. Default to 'this has a fatal flaw' and try to justify it. Return 3-5 findings; for each: severity (blocker / major / minor), the failure it would cause, and a concrete patch. Do not soften, do not list what's good." Mirrors the adversarial-verify discipline (default-to-reject).

3. **Model diversity (best-effort, never blocking).** Dispatch the Claude-side voices via the Agent tool per the `persona-frame.md` model heuristic (ceo=opus for strategic depth, others=sonnet). For genuine cross-provider diversity, route at least one voice through Codex: write that voice's full inlined persona + plan + adversarial-mandate prompt to a temp file and run `codex exec --skip-git-repo-check -c 'sandbox_mode="read-only"' < prompt` (probe `command -v codex` first). If `codex` is not on PATH, skip cross-provider and proceed single-model — do NOT block the panel on Codex. Either way record the outcome in synthesis; single-model means `panel independence: weak (single model)`.

4. **Voices are blind to each other.** Never feed one voice's output into another's prompt. They run concurrently and return independently. (This is exactly what default Stage 2 forbids; here it is the point.)

5. **Collect and quorum-aggregate.** Pool all findings. Cluster findings that name the same underlying risk (same target + same failure mode). For each cluster, count `k` = how many DISTINCT voices independently raised it. Let `N` = invoked voices and `M` = strict majority = `floor(N/2) + 1`. Tag every cluster with exactly one bucket:
   - `k == 1` → `[investigate: 1 voice — {voice}]` — a single-lens catch, often the highest-value finding (the thing only that angle sees)
   - `2 ≤ k < M` → `[corroborated: k voices]` — more than one lens, not yet a majority
   - `k ≥ M` → `[high-confidence: k voices]`
   Never drop single-voice findings — uncorrelated single-lens catches are the entire reason to run a panel.

Then proceed to Stage 3 with the quorum-tagged findings.

### Stage 3: Synthesis

After all voices done (or escape-hatch), produce synthesis output:

```markdown
---
date: {YYYY-MM-DD}
type: boardroom
flow: review
plan: {plan-path}
voices_invoked: [ceo, product-lead, ...]
tags: [boardroom, multi-lens]
---

# Boardroom — {plan-name} — {date}

## Voices invoked

{list with one-line scope decision}

## Applied patches (Y)

- {voice} F{n}: {summary} — patch: {concrete change}
- ...

## Edited patches (edit)

- {voice} F{n}: {summary} — user-modified patch: {change}
- ...

## OPEN_QUESTIONS (N)

- {voice} F{n}: {summary} — user rejected because {reason if stated}
- ...

## Skipped (escape-hatch)

- {voice} F{n}: {summary} — not asked, user stopped after voice {N}
- ...

## Gate Log

- Voice scope decision: {applied/overridden}
- {voice}: {n applied / n edited / n rejected / n skipped}
- ...

## Final plan diff

{diff of original plan vs final plan after all applied patches}
```

Save to `Inbox/boardroom-{plan-slug}-{date}.md`.

### Stage 3 — panel-mode additions

In `--panel` mode each finding is an independent outside-voice finding. Gate it through `lib/outside-voice-rule.md` (informational only, per-finding `Apply? [Y/N/edit]`, N → OPEN_QUESTIONS), and:

- Prefix each finding's gate with its Stage 2-PANEL quorum tag: `[high-confidence: k voices]`, `[corroborated: k voices]`, or `[investigate: 1 voice — {voice}]`.
- The gate results populate the same `## Applied patches (Y)` / `## Edited patches` / `## OPEN_QUESTIONS (N)` sections as default mode — panel mode just moves the gating from Stage 2 to here (after collection), because the voices ran blind.
- Add a `## Disagreements` section: where two voices' findings or patches on the same point are mutually incompatible (one says cut X, another treats X as load-bearing), surface BOTH — never average to consensus. A conflict is signal, not noise.
- Record `voices_invoked`, `models_used`, and (if single-model) a `panel independence: weak (single model)` note in the frontmatter.

## Voice ordering rationale (default mode)

Ordering applies to default sequential mode only — `--panel` runs all voices at once with no ordering (independence is the point). In default mode, CEO → product → design → eng is intentional:

1. **CEO first** — strategic frame: should we even do this? two-way / one-way door?
2. **Product second** — given CEO says yes, what's the user problem? metric? scope discipline?
3. **Design third** — given product frame, what's the UX shape? state coverage? slop avoidance?
4. **Eng last** — given the validated UX shape, what's the implementation approach? minimal diff? 3-strike escalation?

Each voice's framing assumes the previous voice's critique has been considered. Don't reorder unless the plan is dominantly ops (then ops-lead replaces or precedes design).

## Anti-patterns

- ❌ Running all 4 voices in parallel in **default mode** ("save time") — default voices are sequential because each builds on previous applied patches. Parallel is correct ONLY in `--panel` mode, where mutual blindness is the goal (see Modes).
- ❌ Auto-applying all critiques without per-finding gate — defeats outside-voice-rule
- ❌ Letting one voice override another ("eng said no, so we don't even ask CEO") — each voice critiques independently in its own scope
- ❌ Skipping voices because "they don't have anything to add here" — every voice critiques, the user decides what to apply
- ❌ Using boardroom for tactical execution questions — boardroom is for plans, grill is for problems

## Origin

- pandastack persona-pipeline (deleted v1.1) — agent chain replaced by single-skill multi-voice
- pandastack agents/ deleted v1.1 — pandastack is skill-only. No agent dispatch.
- gstack `/plan-ceo-review` + `/plan-eng-review` (separate commands) — pandastack collapses to one boardroom flow
