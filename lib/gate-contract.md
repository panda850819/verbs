# Gate Contract

Standard schema for user-facing decision points in pstack skills.

When a skill needs the user to review / decide / approve before proceeding, use this four-option contract. Consistency across skills lowers decision cost — the user learns one pattern, not N.

## The Four Options

| Option | Meaning | Skill continues with |
|---|---|---|
| **approve** | Proceed as-is | Current output unchanged |
| **edit** | Modify and continue | User-provided revision |
| **reject** | Do not proceed | Skill stops, offers rework |
| **skip** | Skip this gate, continue without it | Current output unchanged, gate not re-run |

## When to use

Use a gate at any point where:
- Output commits the skill to a direction that's expensive to unwind (brief scope, chosen approach, pipeline execution)
- Two equally reasonable options exist and the skill cannot judge between them
- External action will follow (ship, deploy, publish)

Do NOT use a gate for purely informational output or for questions the skill can answer itself from context.

## Invocation

Use `AskUserQuestion` with options: `approve | edit | reject | skip`.

- **approve** → continue to the next step as-is
- **edit** → follow up: "What should change?" Apply the edit, then treat as approved
- **reject** → report what was about to happen and stop. Do not retry without user direction
- **skip** → continue without the gated action. Log that it was skipped so downstream steps know

## Gate Log

If the skill produces a persistent artifact (brief, plan, pipeline yaml), record the gate outcome in the artifact itself — a `## Gate Log` section listing which gates were approved / edited / rejected / skipped and any edits applied. This replaces implicit "user already confirmed" assumptions with explicit state that later skills can read.
