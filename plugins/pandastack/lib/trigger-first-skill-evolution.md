# Trigger-first Skill Evolution

> Shared harness-evolution rule. Load when creating, improving, splitting, merging, or reviewing pandastack skills. The goal is to let repeated usage create structure instead of forcing a taxonomy too early.

## Core shape

```text
PangPang Core / host assistant
  → trigger matching
  → task skill
  → inline checklist / rubric
  → periodic harness review
```

## Rule

Start with the smallest durable change:

1. Make the trigger clear.
   - `When to use`
   - counter-triggers / when not to use
   - input shape
   - output shape
2. After a skill triggers, use inline checklist / rubric text first.
3. Do not build lens / persona / rubric registries upfront.
4. Extract shared references only after repeated evidence.
5. Keep the user-facing surface unified. The host assistant chooses internally; the user should not have to pick roles or modes unless the choice changes risk or outcome.

## Extraction threshold

Extract into `lib/` or `references/` only when at least one is true:

- The same checks appear in 3+ skills.
- The duplicated checks start to diverge during maintenance.
- Agents repeatedly miss the same trigger or routing pattern.
- The inline block is making the parent `SKILL.md` hard to scan.

Default extraction target:

- Cross-skill rule → `plugins/pandastack/lib/<rule>.md`
- One-skill large checklist → `plugins/pandastack/skills/<skill>/references/<topic>.md`
- Draft workflow with only one observed use → `_staging/<candidate>/SKILL.md`

## Periodic harness review questions

Use review windows to clean the system instead of redesigning during every task:

- Which triggers often miss?
- Which skills are triggered when they should not be?
- Which checklist / rubric blocks are duplicated across 3+ skills?
- Which abstractions are making responses slower or more brittle?
- Which prompt fragments should merge into an existing skill?
- Which workflows have repeated enough to become a skill?

## Anti-patterns

- Building a lens / persona / rubric registry before repeated trigger evidence exists.
- Creating a new user-facing mode because a checklist has a different perspective.
- Asking the user to choose a role when a task skill can choose internally.
- Promoting a one-off `_staging` skill before cross-domain validation.
- Copying the same checklist into many skills instead of extracting once after the threshold is met.

## Source

- Brain: `~/site/knowledge/brain/learnings/architecture/trigger-first-skill-evolution.md`
- Origin: Panda + PangPang Telegram discussion, 2026-06-01.
