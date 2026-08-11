# Unattended credential guardrail reassessment

Date: 2026-08-09  
Issue: [#352](https://github.com/panda850819/verbs/issues/352)  
Status: IMPLEMENT through explicitly approved infrastructure Issue [#354](https://github.com/panda850819/verbs/issues/354)

## Decision

A current credential path creates demonstrated accidental-write risk. The local
agent environment is authenticated to GitHub as the repository owner with a
token that includes `repo` and `workflow`; this assessment session used that
identity to read and update Issues. Fresh workers preserve `HOME` and
`XDG_CONFIG_HOME`, and managed agent panes run under the same user environment,
so prose alone must not be treated as the boundary whenever such a worker has
network access.

Add one server-side default-branch control through #354: update classic branch
protection so a pull request remains required with zero approving reviews,
administrator enforcement is enabled, and `test` remains bound to GitHub
Actions app ID `15368`. Keep force-push and deletion blocked. The rollout must
prove behavior with a disposable branch and include an exact settings snapshot
and rollback.

This control is worthwhile because normal maintenance already uses a PR and CI,
so its convenience cost is low. It reduces accidental direct pushes and
untested updates to `main`. It cannot stop the owner credential from changing
or deleting the rule, merging its own PR, creating a release tag, or changing a
workflow in a commit. Do not describe it as a human-only merge boundary.

Do not add a protected-path or approval scheme now. GitHub documents push
ruleset path restrictions for private/internal repositories, while this
repository is public and user-owned. Team-based path reviewers are unavailable
on user-owned repositories. The only collaborator is the owner; a required
independent approval with administrator enforcement would lock out ordinary solo
merges. No second trusted identity, organisation lane, or fork lane is currently
established.

## Read-only inventory

### Credential and actor paths

- Repository owner: personal user account `panda850819`.
- Collaborators: only `panda850819`, role `admin`.
- Current local GitHub CLI: active owner account in the system keyring with
  `repo` and `workflow` scopes. Token value was not read or recorded.
- A second inactive local GitHub CLI account exists, but it is not a repository
  collaborator and is not treated as an available approval identity.
- No repository deploy keys, webhooks, Actions secrets, or environments were
  found.
- Full GitHub App installation inventory is unavailable to the current classic
  OAuth token: `GET /user/installations` returned HTTP 403 and the repository
  installation endpoint returned HTTP 404. Observed repository integrations
  include GitHub Actions and CodeRabbit, but their complete effective
  permissions cannot be established from this credential and remain out of
  scope for this read-only decision.
- No user crontab entry, LaunchAgent, or active launch label referencing Verbs
  or this GitHub repository was found.
- The repository contains no scheduled workflow. Recent Actions runs are PR CI
  and tag-triggered releases.

This proves an attended agent/admin path and a shared-host credential exposure
surface. It does not prove that an unattended scheduler is currently pushing to
the repository.

### Current default-branch controls

`main` has classic branch protection with:

- required status check `test`, bound to GitHub Actions app ID `15368`;
- loose status mode;
- one required approving review;
- force pushes disabled;
- deletion disabled;
- administrator enforcement disabled;
- conversation resolution disabled;
- no push restrictions;
- no repository rulesets.

Because administrator enforcement is disabled and the sole collaborator is an
administrator, the required check and review do not constrain the credential
available to local agent sessions. The current rule mainly protects a
hypothetical non-admin collaborator.

### GitHub Actions

- Repository `default_workflow_permissions` is `read`.
- `can_approve_pull_request_reviews` is separately disabled; this is not
  inferred from the default token permission.
- `ci.yml` runs offline tests on `pull_request` to `main`, declares no override,
  and therefore receives the repository's effective read-only `GITHUB_TOKEN`.
- `release.yml` runs only on a pushed `v*` tag and overrides the default with
  effective `contents: write` solely to create a GitHub Release. It does not
  receive pull-request approval permission.
- Actions are enabled for all actions and SHA pinning is not required.

The release token is ephemeral and event-scoped, but an owner credential can
create tags and alter workflow source. Default-branch protection does not solve
that residual release path. No current incident justifies expanding this Issue
into action allowlisting, SHA pinning, tag protection, or release approval.
Those need separate evidence and must not be bundled into the first guardrail.

### Other server-side controls

- Secret scanning and push protection are enabled.
- No rulesets are configured.
- No auto-merge is enabled.
- Repository visibility is public.

## Proposed infrastructure acceptance

The follow-up Issue should perform no change until it has captured the complete
current branch-protection JSON and confirmed rollback access. Then:

1. Create a disposable protected branch with the proposed classic payload:
   `required_pull_request_reviews` remains an object with
   `required_approving_review_count: 0`; `enforce_admins: true`;
   `required_status_checks.checks` contains `test` with `app_id: 15368`;
   `allow_force_pushes: false`; and `allow_deletions: false`.
2. Against that disposable protected branch, explicitly test owner direct
   push, force push, and deletion. All three must be rejected regardless of
   check state because the pull-request requirement remains enabled. Keep every
   destructive probe scoped to that disposable branch and pre-authorize its
   cleanup.
3. Present the observed evidence and exact `main` payload diff for explicit
   approval before changing `main`.
4. Apply the proven classic payload to `main` and read it back.
5. Verify through the next real PR targeting `main`, which the existing workflow
   supports: the latest exact commit SHA receives `test` from GitHub Actions app
   ID `15368`, zero human approvals are required, and the owner can merge through
   the normal solo path. A successful result attached to another SHA is
   insufficient.
6. Roll back immediately if normal solo PR merge becomes impossible, another
   actor can satisfy `test`, or any force-push/deletion flag changes.

`required_pull_request_reviews: null` is not the proposed fallback because it
would remove the pull-request requirement. The zero-approval object preserves a
required PR without imposing an unavailable second reviewer.

Rollback must restore the captured classic branch-protection payload. It must
not weaken force-push or deletion protection below the starting state.

## Residual boundary

The owner credential remains repository admin. It can edit server settings and
merge its own pull request. GitHub cannot distinguish the maintainer typing with
that credential from an agent using the same credential. Strong enforcement of
“agent may open a PR but only a human may merge” requires a second identity or
an organisation policy outside the credential's authority. Neither exists now.

The proposed guardrail therefore protects against accidental direct push and
missing CI. It does not provide credential separation, protected-path approval,
or a non-bypassable human merge gate.

## Reassessment triggers

Reassess the broader design when any of these becomes true:

- an unattended scheduler or external runtime receives repository write access;
- a second trusted identity or organisation is available;
- an accidental direct push, ruleset edit, release-tag action, or workflow edit
  occurs;
- `default_workflow_permissions`, `can_approve_pull_request_reviews`, or either
  workflow's effective permission block changes;
- a repository GitHub App gains or changes write access;
- GitHub makes public user-repository push path restrictions available;
- the PR/CI guard creates recurring maintainer friction disproportionate to the
  prevented risk.
