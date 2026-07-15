# QA evidence format

The QA-to-PR handoff is one marker-delimited Markdown block. QA produces it;
`ship` publishes it. The marker is the stable interface used to update an
existing pull-request comment without creating duplicates.

## Artifact identity

Evidence is valid only for the exact content tested. Prefer a committed HEAD
SHA when QA runs after commit. When QA runs before commit, use a stable patch
identity:

1. Resolve the comparison base from the tracking PR, upstream default branch,
   or merge-base.
2. Hash `git diff --binary <base>` with SHA-256 and record it as
   `patch-sha256:<digest>` plus the full base SHA.
3. List relevant untracked files as a gap. A patch hash does not cover them.

`ship` recomputes the base-to-PR-head patch hash before publishing. A mismatch
means the evidence is stale; rerun QA. Never relabel stale evidence as current.

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
  artifact. Name the verification method when proof is visual judgment.
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

1. Read its number and head SHA.
2. Validate the evidence markers, status rules, and artifact identity.
3. Find every comment containing `<!-- verbs-qa-evidence:v1 -->` and resolve
   the authenticated viewer.
4. Zero matches: create one comment from the evidence file. One match owned by
   the viewer: update that comment by id. One foreign-owned match or more than
   one total match: report `QA COMMENT CONFLICT` and do not create or update a
   comment. Never turn an ownership conflict into another duplicate.
5. Read the comment back and verify its marker, artifact identity, acceptance
   status, and URL before claiming publication.

Use `gh pr comment --body-file` for creation and `gh api` for marker-based
lookup and update. Never use `--edit-last`: the last comment may be unrelated.

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
