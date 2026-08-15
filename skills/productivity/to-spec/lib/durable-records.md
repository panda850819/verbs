# Durable record hygiene

A durable record must make sense from its current repository or tracker state.
The reader should not need the authoring session, hidden interview numbering,
review thread, or an uncommitted plan to resolve a reference or verify a claim.

## Preserve the proposition

Before trimming or consolidating prose, preserve every relevant actor, action,
condition, timing or ordering rule, obligation, exception, ownership fact,
failure mode, and consequence. Remove derivation transcripts, control-flow
narration, reviewer-addressed justification, and session-only citations only
after their current facts have one resolvable home. Current rationale and
negative guarantees remain when their absence could cause a plausible mistake.

## Classify by future decision value

Age, length, and quotas are discovery aids, never retention criteria. Classify
each record against current authority:

- **Active:** its rationale, alternatives, ownership, durable semantics,
  negative guarantee, security rule, or reopen condition still guides work.
- **Consolidate:** a current owner can absorb every unique decision fact,
  consequence, alternative, and evidence gap; repair inbound references before
  removing the superseded copy.
- **Historical:** the decision is complete and has little current guidance
  value. Keep it only in an existing repository history/archive mechanism and
  never present it as current authority.
- **Guardrail:** retain a rejected direction only while it prevents a tempting,
  plausible mistake and still has a meaningful reopen condition.
- **Delete:** remove obsolete or fully superseded records that no longer guide
  a decision, subject to the repository's own retention and mutation policy.

This guidance does not create an archive, mutate tracker records, or override a
repository's record lifecycle. It only governs the record produced by the
active skill.

## Provenance

Adapted from DeepSeek Harness's MIT-licensed
[`dsh-prose-standard`](https://github.com/deepseek-ai/deepseek-harness/blob/master/.agents/skills/dsh-prose-standard/SKILL.md),
[`dsh-trim-cot-leakage`](https://github.com/deepseek-ai/deepseek-harness/blob/master/.agents/skills/dsh-trim-cot-leakage/SKILL.md), and
[`dsh-archive-agent-notes`](https://github.com/deepseek-ai/deepseek-harness/blob/master/.agents/skills/dsh-archive-agent-notes/SKILL.md).
