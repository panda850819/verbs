---
name: skill-creator
description: |
  Maintainer-only workflow to create or improve Verbs skills, MECE-checked
  against the repo-root RESOLVER.md. `--eval <name>` scores an existing skill
  against the co-located writing-great-skills library and writes eval.md.
version: 1.0.0
user-invocable: false
type: skill
classification: maintainer-only
---

# Skill Creator

Create a new Verbs skill that follows the SKILL-FRONTMATTER.md contract and the hot/cold dispatch rule. Sized to fit between `grill --brief` (idea → brief) and `sprint` (brief → execution).

Native drafting can produce a SKILL.md. This workflow earns its slot by
refusing non-skills, preventing trigger overlap, enforcing hot/cold placement,
and syncing every loader from the manifest source of truth.

## Repository precondition

Resolve the current git root and confirm `manifest.toml` declares
`[product].id = "verbs"` before any write. Also require `RESOLVER.md`,
`SKILL-FRONTMATTER.md`, and `scripts/verbs`. If any contract is absent, stop
with `FAILED: skill-creator requires a Verbs checkout.` These are target-repo
contracts; the installed skill's own runtime references remain co-located.

## `--eval <name>` mode (score an existing skill)

The evaluator half of skill construction — `skill-creator` builds and
self-checks; `--eval` judges an existing skill and leaves a greppable verdict
next to it. Follow [`lib/skill-eval.md`](lib/skill-eval.md), read
[`lib/writing-great-skills.md`](lib/writing-great-skills.md), score all 9 axes,
write `skills/<bucket>/<name>/eval.md`, and confirm
`bash scripts/lint-eval-fresh.sh <name>` passes. `--eval all` fans out one
sub-agent per skill. The workflow stays out of normal runtime discovery.

## Phases

### 1. Identify the gap

Load the co-located `lib/trigger-first-skill-evolution.md` before deciding
whether to create, split, merge, or extract a skill.

What user intent has no existing skill? Be explicit:
- What phrase / trigger will invoke this?
- What is the input shape?
- What is the output shape?
- Why doesn't an existing skill already handle it?

Default to the smallest durable change: tighten trigger text and inline checklist / rubric first. Do not create lens / persona / rubric registries unless the shared rule's extraction threshold is met.

### 2. MECE check

**First, Q0 (refuse-to-build):** apply `lib/skill-decision-tree.md` § "Q0" before
walking the index. If the capability is really knowledge (→ a note in the owner's
configured knowledge store) or one
deterministic step (→ a one-line script / `lib/` helper), stop here — "not a skill"
is a valid outcome, and it kills sprawl upstream of the overlap check below.

Before proposing a new skill or abstraction, consult `docs/out-of-scope/`. If a
precedent matches, surface that entry and stop instead of continuing.

Open `RESOLVER.md`. Enumerate every current catalog heading before comparing
the proposed trigger surface; do not restate a category list here because the
resolver is the source of truth. For each existing skill in scope, ask: does its
trigger surface already cover this intent? If yes, extend that skill.

**subtract-first gate:** before creating a skill, name the existing skill it absorbs/replaces, or why extending an existing skill was rejected. If neither can be named, do not create the skill.

Also read the **Disambiguation** section — it lists known "look-like overlap" pairs (four review skills, requirement-discovery split, etc.). Make sure your new skill doesn't recreate a deliberately-separated split.

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
name: <folder-name>             # plain. no verbs: prefix.
description: |
  <one-paragraph trigger sentence — short, concrete, decision-enabling>
version: 1.0.0                  # optional
user-invocable: true | false    # required
type: skill | flow | lib        # default skill
allowed-tools: <patterns>       # optional
---
```

Body sections in order:
1. **Phases** — numbered workflow
2. **Output Format** — what good output looks like
3. **Anti-Patterns** — 3-5 items; MUST include the hot/cold rule when relevant

### 5. Register in manifest and RESOLVER

Add `[skill.<name>]` to `manifest.toml` with its tier, declared requirements,
and one-line description. Then run `scripts/verbs sync`; the four host loader
JSON files are generated outputs and must never be edited by hand.

Add one resolver row under the matching current category:

```
| `verbs:<name>` | <one-line purpose> | <trigger phrase> |
```

If no existing category fits, add a new section AND justify in commit message. Categories are deliberate — fragmenting the index has cost.

### 6. Verify + near-neighbor route check

Run both procedures in [`lib/verify-and-route-check.md`](lib/verify-and-route-check.md):
- **6. Verify** — `git diff --check` + `scripts/verbs sync --check` + the
  frontmatter linter + `python3 tests/resolver-routes-test.py`. Do not `bun test`
  unless `.test`/`.spec` files exist. Must pass before merge.
- **6.5. Near-neighbor route check** — whenever you add/edit a trigger, manually confirm ~6 confusable pairs still route correctly and your skill did not steal a neighbor's traffic. The check is the gate.

### 7. Construction self-check (generation-moment binding)

Before declaring the skill done, read `lib/writing-great-skills.md` and score
against its scorecard (the construction-quality SSOT). Any axis landing
**weak/fail** with no reason to
keep it → revise before merge. Then run `--eval <name>` (above) to write the
co-located `eval.md` (every skill carries one; `lint-eval-fresh.sh` enforces
it). This mirrors how `lib/quality-rubric.md` binds at the generation moment —
author knows the axes upfront and steers toward them.

## Output Format

```
skills/<bucket>/<name>/   (bucket = engineering | productivity | writing | meta)
├── SKILL.md            ← created
└── eval.md             ← created by --eval
manifest.toml            ← [skill.<name>] entry added
RESOLVER.md              ← row added
loader JSON              ← regenerated only by scripts/verbs sync
```

Verification checks pass (`lint-manifest-sync.sh`, `lint-eval-fresh.sh`, and `resolver-routes-test.py`).

## Anti-Patterns

- **MECE violation** — overlapping an existing skill's trigger surface. Extend, don't add.
- **Premature abstraction** — building lens / persona / rubric registries before `lib/trigger-first-skill-evolution.md` extraction threshold is met.
- **Skipping Phase 3 (hot/cold check)** — data-heavy skill running inline degrades long sessions (evidence cited in Phase 3).
- **foreign semantic fields** — importing routing/runtime claims such as
  `triggers:`, `tools:`, or `mutating:` without mapping them to the current
  frontmatter contract. Stack extensions and advisory audit metadata remain
  valid when `SKILL-FRONTMATTER.md` defines them.
- **Adding a new RESOLVER category without justification** — categories are an MECE budget, not a free namespace.
- **Shipping a one-off skill** — if it won't fire >3 times in the next month, don't ship. Verbs has repeatedly cut low-leverage skills for this reason.

## Related

- `SKILL-FRONTMATTER.md` — the contract this skill enforces
- `RESOLVER.md` — the index this skill updates
- `lib/writing-great-skills.md` — the construction scorecard resource
