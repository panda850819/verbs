# Verbs Philosophy

## Core Belief

Each unit of engineering work should make subsequent units easier — not harder.

## Principles

### 1. The Model Has Judgment, Skills Carry Lore

The intelligence lives in the model plus the skill's own lore, not in swappable
persona agents. A skill is a short sequence of steps that frames the task, loads the
relevant lore, and manages the learnings loop. Verbs ships skills and thin host
adapters. The host owns agents, identity, memory, and scheduling.

### 2. Close the Loop

`build → review → learning candidate → host decision`

Every review may search a project-provided learning path and surface a new
candidate. The host owns persistence and reuse; the skill owns the evidence and
candidate format.

### 3. Markdown First

Core skills are readable markdown with no package build step. Optional tools are
declared per skill and checked explicitly. The same source is verified on Claude
Code and Codex; Hermes supports selective manual import.

### 4. Less Is More

Don't reinvent the wheel unless the existing one is broken. Reuse what
exists -- tools, patterns, files, conventions -- before creating something new.
The best abstraction is the one you didn't write.

### 5. Just Enough Engineer

Don't over-engineer the harness. Models get smarter every six months.
Today's 800-line prompt is tomorrow's over-engineering. Keep skills thin and
opinionated, let the model do the thinking.

### 6. User Sovereignty

AI recommends. Users decide. Two models agreeing is a signal, not a mandate.
The user always has context that models lack.

### 7. Boil the Lake

AI makes the marginal cost of completeness near-zero. When the complete
implementation costs minutes more than the shortcut — do the complete thing.
Every time.

### 8. Explicit Stage Contracts

When one skill's output feeds another, make the contract explicit — don't
assume the next stage has context it wasn't given.

- **Inputs declared**: each skill declares what prior outputs it reads (e.g.,
  `/review` reads the brief's Problem + Success Metric + Scope).
- **Delegation per pass**: when a skill explicitly delegates, pin the verified
  role anchor for that operation. Model choice outside that skill stays with the host.
- **Gates standardized**: user-facing decisions use the four-option contract
  (approve / edit / reject / skip). See `lib/gate-contract.md`.

Without explicit contracts, quality degrades silently through the chain —
later stages lose nuance from earlier ones (telephone effect) and budget
gets misallocated across passes (model overbuild).

## What Verbs Is Not

- Not a replacement for thinking. It's a tool for structured thinking.
- Not an agent runtime, personal context store, scheduler, or project source of truth.
- Not a fixed pipeline. Skills are composable and readable. Fork or delete what you do not need.
