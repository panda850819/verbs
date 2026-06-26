# pstack Philosophy

## Core Belief

Each unit of engineering work should make subsequent units easier — not harder.

## Principles

### 1. Agents Have Judgment, Skills Are Triggers

The intelligence lives in agent personas, not in skill prompts. A skill is a short
sequence of steps that triggers an agent and manages the learnings loop. Agent files
are replaceable — swap `agents/eng.md` to change how reviews work across all skills.

### 2. Close the Loop

```
build → review → learn → apply
  ↑                        ↓
  └────────────────────────┘
```

Every review searches past learnings. Every review can write new learnings.
The system gets smarter with every cycle. This is the only feature that matters.

### 3. Zero Dependencies

Pure markdown. No compiled binaries, no runtime requirements, no build step.
If you have Claude Code and git, pstack works.

### 4. Less Is More

Don't reinvent the wheel unless the existing one is broken. Reuse what
exists -- tools, patterns, files, conventions -- before creating something new.
The best abstraction is the one you didn't write.

### 5. Just Enough Engineer

Don't over-engineer the harness. Models get smarter every six months.
Today's 800-line prompt is tomorrow's over-engineering. Keep skills thin,
keep agents opinionated, let the model do the thinking.

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
- **Model per pass**: when a skill runs multiple passes, hint which model
  fits each pass (correctness→sonnet, architecture→opus). Don't pay Opus
  tokens for mechanical work; don't starve synthesis with Haiku.
- **Gates standardized**: user-facing decisions use the four-option contract
  (approve / edit / reject / skip). See `lib/gate-contract.md`.

Without explicit contracts, quality degrades silently through the chain —
later stages lose nuance from earlier ones (telephone effect) and budget
gets misallocated across passes (model overbuild).

## What pstack Is Not

- Not a replacement for thinking. It's a tool for structured thinking.
- Not a fixed pipeline. Skills are composable. Use what you need.
- Not a framework that locks you in. Every file is readable markdown.
  Fork it, change it, delete what you don't need.
