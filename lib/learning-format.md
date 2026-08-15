# GBrain Project Learning Format

Verbs stores reusable project memory in GBrain. The root `AGENTS.md` remains the
authoritative Project Contract; memory is historical evidence and cannot change
policy without a preview and explicit human approval.

## Brain First Rule

Before planning, implementing, debugging, reviewing, or shipping, search GBrain
for relevant project decisions, conventions, pitfalls, preferences, and failed
approaches. Cite memories that materially affect the work. If GBrain is
unavailable, continue from `AGENTS.md`, the work source, and repository evidence
and report the memory gap.

## Record

```yaml
type: decision | convention | pitfall | preference | failed-approach
project: owner/repo
scope: repository | module | path
key: short-kebab-case-name
summary: concise reusable statement
evidence:
  - commit, pull request, ticket, command output, or file path
context: when this applies
exceptions: when this does not apply
confidence: candidate | confirmed | superseded
observed_at: YYYY-MM-DD
source: observed | user-confirmed
```

Never store secrets, credentials, personal data, unsupported inference, routine
task detail, or a duplicate of policy already present in `AGENTS.md`.

## Write gate

- Emit a candidate only when evidence shows it would save time or prevent a
  repeated failure in a future session.
- Search GBrain for the same project, scope, and key before writing.
- A duplicate appends current evidence; it does not create a competing record.
- User-confirmed or repeated evidence may promote a candidate to `confirmed`.
- Changed policy marks conflicting memory `superseded`.
- GBrain failure is fail-soft: report the unwritten candidate and continue.

## Policy promotion

A confirmed memory becomes Project Contract policy only when:

1. it is stable beyond one task or explicitly declared by the user;
2. the exact `AGENTS.md` diff is previewed;
3. the user approves the mutation;
4. the updated contract is read back and verified.

GBrain never edits `AGENTS.md` autonomously.
