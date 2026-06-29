---
name: skill-creator
description: |
  Create new pandastack skills, MECE-checked against the pandastack RESOLVER.md at the repo root (the skill-overlap index, NOT the brain filing-tree RESOLVER.md). Triggers: "create a skill", "new pandastack skill", "improve this skill", "扩 skill".
version: 1.0.0
user-invocable: true
type: skill
---

# Skill Creator

Create a new pandastack skill that follows the SKILL-FRONTMATTER.md contract and the hot/cold dispatch rule. Sized to fit between `office-hours` (idea → brief) and `sprint` (brief → execution).

## Phases

### 1. Identify the gap

Load `lib/trigger-first-skill-evolution.md` (repo root) before deciding whether to create, split, merge, or extract a skill.

What user intent has no existing skill? Be explicit:
- What phrase / trigger will invoke this?
- What is the input shape?
- What is the output shape?
- Why doesn't an existing skill already handle it?

Default to the smallest durable change: tighten trigger text and inline checklist / rubric first. Do not create lens / persona / rubric registries unless the shared rule's extraction threshold is met.

### 2. MECE check

**First, Q0 (refuse-to-build):** apply `lib/skill-decision-tree.md` § "Q0" before
walking the index. If the capability is really knowledge (→ a brain page) or one
deterministic step (→ a one-line script / `lib/` helper), stop here — "not a skill"
is a valid outcome, and it kills sprawl upstream of the overlap check below.

Open `RESOLVER.md`. Walk every category (Knowledge / Writing / Dev workflow / Retro / session / Tool wrappers / Trust evaluation / Meta / skill authoring). For each existing skill in scope, ask: does its trigger surface already cover this intent? If yes, extend that skill instead of adding new.

Also read the **Disambiguation** section — it lists known "look-like overlap" pairs (sprint vs team-orchestrate, four review skills, requirement-discovery split, etc.). Make sure your new skill doesn't recreate a deliberately-separated split.

### 3. Decide hot or cold (mandatory)

```
Will this skill read >5K tokens of data per invocation?
   ┌─────────────────────┴─────────────────────┐
   │                                           │
  NO (HOT)                                    YES (DATA-HEAVY)
   │                                           │
Normal skill.                          MUST dispatch sub-agent
Body executes in main                  for the heavy read.
agent context.                         Main agent only sees
                                       the returned summary.

                                       Wrong: skill reads 50 docs
                                              inline, builds answer
                                              in main context
                                       Right: dispatch Agent
                                              (subagent_type='Explore')
                                              → 200-token return
                                              → main agent reasons
                                                over the summary
```

This rule is non-negotiable. Skills that violate it silently degrade long-session recall (evidence: `evals/2026-06-26-skill-quality-baseline.md`; observed in Arize Alyx and Claude Code source, converged solution).

### 3.5. Decide inline vs extract

Use `lib/trigger-first-skill-evolution.md`:

- New / uncertain workflow → keep checks inline in the skill.
- Same checks repeated in 3+ skills or diverging during maintenance → extract to `lib/` or `references/`.
- One observed use only → keep in `_staging/`, not production.

### 4. Write SKILL.md

Frontmatter must match `SKILL-FRONTMATTER.md`:

```yaml
---
name: <folder-name>             # plain. no pandastack: prefix.
description: |
  <one-paragraph trigger sentence — short, concrete, decision-enabling>
version: 1.0.0                  # optional
user-invocable: true | false    # default false
type: skill | flow | lib        # default skill
allowed-tools: <patterns>       # optional
---
```

Body sections in order:
1. **Phases** — numbered workflow
2. **Output Format** — what good output looks like
3. **Anti-Patterns** — 3-5 items; MUST include the hot/cold rule when relevant

### 5. Add to RESOLVER.md

Place under the matching category:

```
| `pandastack:<name>` | <one-line purpose> | <trigger phrase> |
```

If no existing category fits, add a new section AND justify in commit message. Categories are deliberate — fragmenting the index has cost.

### 6. Verify + near-neighbor route check

Run both procedures in [`skills/meta/skill-creator/lib/verify-and-route-check.md`](skills/meta/skill-creator/lib/verify-and-route-check.md):
- **6. Verify** — `git diff --check` + the frontmatter linter (exits non-zero on a missing/unclosed frontmatter); manually run any affected `tests/resolver-golden.md` cases. Do not `bun test` unless `.test`/`.spec` files exist. Must pass before merge.
- **6.5. Near-neighbor route check** — whenever you add/edit a trigger, manually confirm ~6 confusable pairs still route correctly and your skill did not steal a neighbor's traffic. The check is the gate.

### 7. Construction self-check (generation-moment binding)

Before declaring the skill done, score it against the [`../writing-great-skills/SKILL.md`](../writing-great-skills/SKILL.md) scorecard (the construction-quality SSOT). Any axis landing **weak/fail** with no reason to keep it → revise before merge. Then run `/skill-eval <name>` to write the co-located `eval.md` (every skill carries one; `lint-eval-fresh.sh` enforces it). This mirrors how `lib/quality-rubric.md` binds at the generation moment — author knows the axes upfront and steers toward them.

## Output Format

```
skills/<bucket>/<name>/   (bucket = engineering | productivity | writing | meta)
├── SKILL.md            ← created
└── eval.md             ← created by /skill-eval
.claude-plugin/plugin.json ← "./skills/<bucket>/<name>" added to skills array
manifest.toml            ← [skill.<name>] entry added
RESOLVER.md              ← row added
```

Verification checks pass (`lint-manifest-sync.sh`, `lint-eval-fresh.sh`), and any affected resolver-golden cases are noted.

## Anti-Patterns

- **MECE violation** — overlapping an existing skill's trigger surface. Extend, don't add.
- **Premature abstraction** — building lens / persona / rubric registries before `lib/trigger-first-skill-evolution.md` extraction threshold is met.
- **Skipping Phase 3 (hot/cold check)** — data-heavy skill running inline degrades long sessions (evidence cited in Phase 3).
- **gbrain-flavored frontmatter** — `triggers:` array, `tools:`, `mutating:`. Pandastack uses description-sentence + optional `allowed-tools`.
- **Adding a new RESOLVER category without justification** — categories are an MECE budget, not a free namespace.
- **Shipping a one-off skill** — if it won't fire >3 times in the next month, don't ship. Pandastack tightened 38 → 26 for this reason.

## Related

- `SKILL-FRONTMATTER.md` — the contract this skill enforces
- `RESOLVER.md` — the index this skill updates
