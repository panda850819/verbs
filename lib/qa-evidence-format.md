# QA evidence format

The QA-to-PR handoff is one marker-delimited Markdown block. QA produces it;
`ship` publishes it. The marker is the stable interface used to update an
existing pull-request comment without creating duplicates.

## Artifact identity

Evidence is valid only for the exact content and material execution provenance
tested. Prefer a committed HEAD SHA when QA runs after commit. Record the served
origin or artifact source, runtime/build mode, and transport (`real`, `fixture`,
`mock`, or a precise equivalent); use `n/a` only when a field cannot affect the
claim. These fields bound what the evidence proves and do not imply stronger
environment coverage. When QA runs before commit, use a stable patch identity:

1. Resolve the comparison base from the tracking PR, upstream default branch,
   or merge-base.
2. Hash `git diff --binary <base>` with SHA-256 and record it as
   `patch-sha256:<digest>` plus the full base SHA.
3. List relevant untracked files as a gap. A patch hash does not cover them.

`ship` recomputes the base-to-PR-head patch hash before publishing. A changed
or rewritten head, hash mismatch, or material provenance change makes affected
evidence stale; rerun those checks. Never relabel stale evidence as current.

## Evidence block

Write the block to stdout and, inside a Git repository, to the path returned by
`git rev-parse --git-path verbs/qa-evidence.md`. Git metadata keeps the handoff
available across skill invocations without dirtying the working tree.

```markdown
<!-- verbs-qa-evidence:v1 -->
## QA acceptance evidence

Acceptance: VERIFIED | NOT VERIFIED
Intent: <issue URL, brief path, or exact user-request label>
Artifact: <full commit SHA | patch-sha256:digest>
Base: <full base SHA | n/a for committed-head identity>
Origin: <served URL, worktree/tree source, or n/a with reason>
Runtime: <development, built artifact, production-like, or precise equivalent>
Transport: <real, fixture, mock, or precise equivalent>
Run: <ISO-8601 UTC timestamp>

| Criterion | Status | Proof |
|---|---|---|
| AC-1: <verbatim or faithful criterion> | PASS | STEP_PASS id + deterministic value / snapshot / screenshot path |
| AC-2: <criterion> | FAIL | STEP_FAIL id + expected -> actual |
| AC-3: <criterion> | UNPROVEN | missing, skipped, or stale proof |

Tests: <N> | Passed: <N> | Failed: <N> | Skipped: <N> | Pass rate: <N>%
Gaps: <none | concrete untested states, environments, or untracked files>
<!-- /verbs-qa-evidence -->
```

Status rules:

- `PASS` requires evidence that directly proves the criterion on the recorded
  artifact under the recorded material provenance. Name the verification method
  when proof is visual judgment.
- `FAIL` means observed behavior contradicts the criterion.
- `UNPROVEN` means the step was skipped, the evidence is indirect, the intent
  source is missing, or artifact identity cannot be established.
- `Acceptance: VERIFIED` is legal only when every criterion is `PASS` and the
  artifact identity is current. Any `FAIL` or `UNPROVEN` row forces
  `Acceptance: NOT VERIFIED`.
- Preserve criterion wording closely enough that a reviewer can compare the
  implementation with the requested outcome. Test totals alone are not proof
  that the intended behavior shipped.

## Pull-request upsert

`ship` owns the GitHub write. After a PR exists:

1. Read its repository identity, number, and head SHA.
2. Acquire an atomic per-repository, per-PR lock before the first marker lookup.
   Use `mkdir` on a lock directory under
   `$(git rev-parse --git-common-dir)/verbs/qa-comment-locks/`, keyed by the
   repository identity and PR number, so concurrent worktrees in the same clone
   serialize the complete lookup-and-write sequence. Record holder metadata.
   If acquisition fails, wait for a bounded interval and retry; if the lock
   remains held or its ownership cannot be established, report
   `QA COMMENT LOCKED` and do not write. Never delete an unverified lock.
   Crash recovery is a manual fail-closed operation: inspect the holder metadata,
   exact lock path, and repository/PR identity; confirm the recorded process is
   no longer running and no `ship` process for that repository/PR is active in
   any linked worktree; then remove only that exact stale lock directory. Missing
   or contradictory metadata cannot prove staleness, so leave the lock in place
   and report the manual blocker.
3. While holding the lock, validate the evidence markers, status rules, and
   artifact identity.
4. Find every comment containing `<!-- verbs-qa-evidence:v1 -->` and resolve
   the authenticated viewer.
5. Zero matches: create one comment from the evidence file. One match owned by
   the viewer: update that comment by id. One foreign-owned match or more than
   one total match: report `QA COMMENT CONFLICT` and do not create or update a
   comment. Never turn an ownership conflict into another duplicate.
6. After creation or update, re-list every marker comment on the PR. Claim
   publication only when exactly one marker comment exists and that comment has
   the expected owner, artifact identity, provenance, acceptance status, and URL. Zero or
   multiple matches report `QA COMMENT CONFLICT`; do not claim success. This
   post-write invariant detects a create race from a separate clone.
7. Release only the lock acquired by this run, including on failure.

Use `gh pr comment --body-file` for creation and `gh api` for marker-based
lookup and update. Never use `--edit-last`: the last comment may be unrelated.
The local lock serializes writers sharing a Git common directory; marker
conflict detection and read-back remain the fail-closed guard for external
writers.

## Source

The provenance and freshness rules adapt the evidence-chain principles from
DeepSeek Harness's MIT-licensed
[`record-browser-gif`](https://github.com/deepseek-ai/deepseek-harness/blob/master/.agents/skills/record-browser-gif/SKILL.md)
and outgoing-head invalidation from
[`dsh-pre-push-checks`](https://github.com/deepseek-ai/deepseek-harness/blob/master/.agents/skills/dsh-pre-push-checks/SKILL.md).

## Screenshot on failure

Every `STEP_FAIL` gets a screenshot captured at the moment of failure. Store it
in `.context/ui-test-screenshots/<step-id>.png`.

## Bug report format

```text
[BUG] page/flow - description
  Steps to reproduce: ...
  Expected: ...
  Actual: ...
  Screenshot: .context/ui-test-screenshots/<step-id>.png
  Action: AUTO-FIX | ASK
```

`AUTO-FIX` is for mechanical bugs such as CSS, a missing null check, or a wrong
URL. `ASK` is for design or architecture decisions.
