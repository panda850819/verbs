---
name: boardroom
mode: skill
description: |
  Multi-lens plan critique router for prepared plans: sequential CEO, product, design, and engineering review with per-finding Apply? [Y/N/edit] gate. Invoke explicitly via /boardroom, leadership review, 4-voice critique, or review-this-plan. NOT for tactical execution, loose ideas, single-domain review, or ordinary planning.
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

> Replaces persona-pipeline (deleted v1.1). Same outcome, single skill, no agent chain. Each voice loads its own SKILL.md cognitive model + iron laws + on-invoke protocol via `lib/persona-frame.md`, critiques in its own posture, hands off to next voice. User gates each finding.

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

## Stages

### Stage 0: Capability probe + plan load

@../../lib/capability-probe.md

Run probe. Then load the plan from path arg or active context. If no plan path, print "boardroom needs a plan path. Run `/boardroom <plan-path>` or paste the plan inline." and stop.

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

### Stage 2: Sequential voice critique

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

## Voice ordering rationale

CEO → product → design → eng is intentional:

1. **CEO first** — strategic frame: should we even do this? two-way / one-way door?
2. **Product second** — given CEO says yes, what's the user problem? metric? scope discipline?
3. **Design third** — given product frame, what's the UX shape? state coverage? slop avoidance?
4. **Eng last** — given the validated UX shape, what's the implementation approach? minimal diff? 3-strike escalation?

Each voice's framing assumes the previous voice's critique has been considered. Don't reorder unless the plan is dominantly ops (then ops-lead replaces or precedes design).

## Anti-patterns

- ❌ Running all 4 voices in parallel ("save time") — voices are sequential because each builds on previous applied patches
- ❌ Auto-applying all critiques without per-finding gate — defeats outside-voice-rule
- ❌ Letting one voice override another ("eng said no, so we don't even ask CEO") — each voice critiques independently in its own scope
- ❌ Skipping voices because "they don't have anything to add here" — every voice critiques, the user decides what to apply
- ❌ Using boardroom for tactical execution questions — boardroom is for plans, grill is for problems

## Origin

- pandastack persona-pipeline (deleted v1.1) — agent chain replaced by single-skill multi-voice
- pandastack agents/ deleted v1.1 — pandastack is skill-only. No agent dispatch.
- gstack `/plan-ceo-review` + `/plan-eng-review` (separate commands) — pandastack collapses to one boardroom flow
