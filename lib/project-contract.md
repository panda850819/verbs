# Project Contract

The root `AGENTS.md` `## verbs` block is the only authoritative Verbs project
policy. Host compatibility files may symlink to `AGENTS.md`; they must not carry
an independent contract.

## Authority

Resolve conflicts in this order:

1. current user instruction;
2. `AGENTS.md`;
3. confirmed ticket or Work Contract;
4. current repository evidence;
5. GBrain memory.

## Brain First Rule

Before planning, implementing, debugging, reviewing, or shipping, search GBrain
for project-specific decisions, conventions, pitfalls, preferences, and failed
approaches relevant to the work. Retrieved memory is historical evidence, not
policy. Cite memories that materially affect the work and ignore stale,
unrelated, unsupported, or cross-project records.

If GBrain is unavailable, continue from `AGENTS.md`, the work source, and
repository evidence. Report the memory gap; never block ordinary development on
GBrain availability.

## Work Contract

Before implementation, establish and confirm:

- Goal
- Scope
- Out of Scope
- Acceptance Criteria
- Constraints
- Delivery Target

Use the project-configured work source: GitHub Issues, Jira, Linear, a document,
or the current prompt. Provider-specific API access is optional; the contract
semantics stay the same.

## Automatic Grilling Session

When any required Work Contract field is missing, ambiguous, or contradictory,
automatically enter a Grilling Session. This is intake behavior, not a skill the
user must invoke.

1. Retrieve answers available from `AGENTS.md`, GBrain, the repository, and the
   referenced work item before asking.
2. Ask only questions blocking the current decision frontier; group related
   blockers in one numbered round.
3. Record confirmed decisions, contradictions, and explicitly deferred items.
4. Present the completed Work Contract for confirmation.
5. Do not plan implementation or edit code until the contract is confirmed.

Exit only when Goal is explicit, acceptance is testable, scope and exclusions
are bounded, constraints and delivery are known, and the user confirms the
contract. If implementation uncovers a contract conflict, stop and re-enter the
session at that conflict.

## Learning promotion

After verified work, emit only evidence-backed project learning candidates to
GBrain. GBrain owns memory; it cannot mutate `AGENTS.md`.

A candidate may become project policy only after it recurs or has explicit user
evidence, the agent previews the exact `AGENTS.md` change, and the user approves
it. Superseded memories remain provenance and must be marked superseded rather
than silently reused.
