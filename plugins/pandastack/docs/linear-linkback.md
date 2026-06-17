# Linear-backed PR linkback protocol

Use this when a GitHub PR is produced from a Linear work item by a scheduler,
agent loop, or assisted sprint.

## Contract

A PR is not enough evidence by itself. The loop must leave an audit trail in both
systems:

1. **Linear comment as append-only ledger**
   - Append one comment whenever the agent learns or changes material state:
     kickoff/context read, plan decision, build attempt, verification result,
     review finding, content/doc update, PR update, blocked state, and final
     retrospective.
   - Include run id if present, Linear issue id, repo, branch, commit SHA, PR URL,
     CI/check result, PandaStack review comment URL, and verdict.
   - Do not use the issue description as the running log. Keep the description as
     the work order.

2. **PandaStack PR review as an artifact**
   - Post PandaStack review output as a GitHub PR comment or review.
   - Capture the resulting comment/review URL.
   - Link that URL back to Linear in the ledger comment.
   - Final review, retrospective, or content/doc updates must be mirrored to both
     places: a PR comment/update and a Linear ledger comment.

3. **Autonomy boundary**
   - Auto loops may open PRs only when the repo/project is allowlisted for branch
     push + PR creation.
   - Auto loops must not auto-merge.
   - Decision, publish, external-write, shared-infra, or ambiguous work stays
     human-gated.

## Helpers

```bash
scripts/pandastack-pr-review-comment \
  --repo panda850819/pandastack \
  --pr 123 \
  --body-file /tmp/pandastack-review.md

scripts/pandastack-linear-comment \
  --issue PRO-26 \
  --repo panda850819/pandastack \
  --branch feat/example \
  --commit abc1234 \
  --pr https://github.com/panda850819/pandastack/pull/123 \
  --checks "tests green" \
  --review-url https://github.com/panda850819/pandastack/pull/123#issuecomment-1 \
  --verdict "ready for human review"
```

Use `--dry-run` on both helpers for test/non-writing flows.

## Minimum Linear ledger comment

```markdown
Agent loop update

- Run: <run-id or n/a>
- Repo: <owner/repo>
- Branch: `<branch>`
- Commit: `<sha>`
- PR: <url>
- Checks: <summary>
- PandaStack review: <GitHub review/comment URL>
- Verdict: <ready for human review | blocked | needs decision | failed>
```

## Pitfalls

- A PR body saying "reviewed" is not a durable review artifact. Post the review
  as a GitHub comment/review and link it.
- Linear issues with zero comments after automated work are an audit gap.
- Brain ideas should produce candidate Backlog items only. They should not jump
  to Building without Goal + Context + runnable acceptance.
