---
name: skill-creator
description: |
  Create new pandastack skills. MECE-checks against existing skills via the pandastack RESOLVER.md (RESOLVER.md at the repo root — the skill-overlap index, NOT the brain filing-tree RESOLVER.md). First applies lib/skill-decision-tree.md Q0 (refuse-to-build: should this be a brain page / one-line script instead). Enforces the hot/cold dispatch rule (skills reading >5K tokens dispatch a sub-agent). Triggers: "create a skill", "new pandastack skill", "improve this skill", "扩 skill".
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

Open `RESOLVER.md`. Walk every category (Knowledge / Writing / Dev workflow / Retro-session / Tool wrappers / Personas / Multi-lens review / Trust evaluation). For each existing skill in scope, ask: does its trigger surface already cover this intent? If yes, extend that skill instead of adding new.

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

This rule is non-negotiable. Skills that violate it silently degrade long-session recall (see `learnings/patterns/long-session-evals` for evidence; observed in Arize Alyx and Claude Code source, converged solution).

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

### 6. Verify

Run the checks that exist in this repo. Pandastack currently has a manual resolver golden file, not Bun test files.

```bash
cd "$PANDASTACK_ROOT"

git diff --check

python - <<'PY'
from pathlib import Path
import re, sys
root = Path('skills')
errors = []
for p in root.rglob('SKILL.md'):
    s = p.read_text()
    if not s.startswith('---'):
        errors.append(f'{p}: missing frontmatter start')
        continue
    if '\n---\n' not in s[3:]:
        errors.append(f'{p}: missing frontmatter close')
if errors:
    print('\n'.join(errors))
    sys.exit(1)
print('OK skill frontmatter')
PY

# If you changed routing / descriptions, manually run the affected cases in:
# tests/resolver-golden.md
```

Do not use `bun test tests/` unless actual `.test` / `.spec` files have been added. If a check fails, read the error and fix the frontmatter / RESOLVER / body before merging.

### 6.5. Near-neighbor route check (manual — deliberately NOT a CI gate)

Whenever you add or edit a skill's trigger / description, manually confirm it did
not start stealing a **near-neighbor's** traffic (route confusion). This is a
~5-minute manual pass, not a runner + fixture + CI gate — at pandastack's N the
infra would cost more than it saves and would rot in a solo repo.

1. Pick ~6 **confusable pairs** whose trigger surfaces sit closest to the one you
   touched. Sources for the candidates: `RESOLVER.md` Disambiguation
   section, `DISPATCH.md`, each SKILL.md's `Skip` / `NOT for` frontmatter, and
   `lib/skill-decision-tree.md`. Standing examples: sprint vs team-orchestrate,
   grill vs office-hours, the four review skills, ship vs handover.
2. For each pair, write ~1 short prompt that *should* route to each side (≈6
   prompts total). Read each prompt against the two descriptions and confirm it
   routes to the intended skill — and that your edited skill does NOT now also
   match the neighbor's prompt.
3. If a prompt routes wrong or matches both, tighten the trigger/`Skip` wording
   (smallest durable change) and re-check. Log nothing; the check is the gate.

This is the cheap, solo-durable version of yao-meta-skill's route-confusion guard:
steal the mechanism, refuse its harness shape.

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
- **Skipping Phase 3 (hot/cold check)** — data-heavy skill running inline degrades long sessions. See `learnings/patterns/long-session-evals`.
- **gbrain-flavored frontmatter** — `triggers:` array, `tools:`, `mutating:`. Pandastack uses description-sentence + optional `allowed-tools`.
- **Adding a new RESOLVER category without justification** — categories are an MECE budget, not a free namespace.
- **Shipping a one-off skill** — if it won't fire >3 times in the next month, don't ship. Pandastack tightened 38 → 26 for this reason.

## Related

- `SKILL-FRONTMATTER.md` — the contract this skill enforces
- `RESOLVER.md` — the index this skill updates
- `learnings/patterns/long-session-evals` — why the hot/cold rule exists
