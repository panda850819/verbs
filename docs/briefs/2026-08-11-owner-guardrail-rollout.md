# Owner credential PR/CI guardrail rollout

Date: 2026-08-11  
Issue: [#354](https://github.com/panda850819/verbs/issues/354)  
Status: disposable proof passed; `main` change awaits explicit approval

## Fresh `main` snapshot before writes

A sanitized read-back was captured before creating either disposable branch.
The current state differs from the earlier #352 observation:

```json
{
  "required_status_checks": {
    "strict": false,
    "checks": [{"context": "test", "app_id": 15368}]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false,
  "allow_fork_syncing": false
}
```

There are no repository rulesets. The only collaborator is the owner/admin.
Repository workflow defaults remain read-only and workflow PR approvals remain
disabled.

## Disposable proof

The test used `guardrail-smoke-354` at `main` merge commit
`a160e3ffe64a04736ddd128d3b00898623b25ffe`. Its protection payload changed only
the two intended controls:

- `enforce_admins: true`;
- `required_pull_request_reviews` was an object with zero approvals,
  `dismiss_stale_reviews: false`, `require_code_owner_reviews: false`, and
  `require_last_push_approval: false`.

The required `test` check remained bound to GitHub Actions app ID `15368`; force
pushes and deletion remained disabled. API read-back matched that shape.

Three owner-credential probes then ran against the protected disposable branch:

| Probe | API result | Branch result |
|---|---|---|
| Fast-forward direct update | HTTP 422: changes must be made through a pull request; `test` expected | unchanged |
| Forced non-fast-forward update | HTTP 422: changes must be made through a pull request; `test` expected | unchanged |
| Delete protected branch | HTTP 422: cannot delete this branch | unchanged |

The protected branch stayed at the original `main` SHA after every probe. After
evidence capture, its protection and both disposable branches were removed.
Both branch lookups returned HTTP 404. A final `main` read-back still matched the
starting snapshot, so the disposable test did not alter default-branch policy.

## Proposed `main` diff

Only these fields change:

```diff
- "enforce_admins": false,
- "required_pull_request_reviews": null,
+ "enforce_admins": true,
+ "required_pull_request_reviews": {
+   "dismiss_stale_reviews": false,
+   "require_code_owner_reviews": false,
+   "required_approving_review_count": 0,
+   "require_last_push_approval": false
+ },
```

Every other field in the starting snapshot remains unchanged. In particular,
`test` stays bound to app ID `15368`, and force pushes and deletion stay blocked.

## Apply and verify

After explicit approval:

1. read `main` again and stop if it differs from the starting snapshot;
2. apply the complete payload, not partial endpoint edits;
3. read the result back and compare every captured field;
4. push this evidence document through a real PR targeting `main`;
5. verify the latest exact PR commit receives `test` from app ID `15368`, zero
   approvals are required, and the owner can merge through the normal path;
6. read `main` protection once more after merge.

The real PR is part of the verification: it must not be merged through an admin
bypass. If GitHub reports the PR unmergeable despite a green exact-SHA check,
roll back before any other repository work.

## Rollback

Restore the complete starting payload shown above. Roll back immediately if:

- the exact-SHA `test` check from app ID `15368` does not satisfy the rule;
- the owner cannot merge a green zero-approval PR through the normal path;
- direct update, force-push, or deletion protection differs from the approved
  payload; or
- any non-target field changes.

This guardrail reduces accidental owner-token writes. It is not a human-only
security boundary: the owner identity can still edit protection or merge, and an
agent holding the same credential cannot be distinguished from the maintainer.
