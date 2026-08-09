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

Add one server-side default-branch control through #354:
make the existing required `test` check apply to the owner/admin path and, if a
user-owned public repository ruleset can express it without locking out the solo
maintainer, require a pull request with zero approving reviews. Keep force-push
and deletion blocked. The rollout must prove behavior with a disposable branch
and include an exact settings snapshot and rollback.

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
- No user crontab entry, LaunchAgent, or active launch label referencing Verbs
  or this GitHub repository was found.
- The repository contains no scheduled workflow. Recent Actions runs are PR CI
  and tag-triggered releases.

This proves an attended agent/admin path and a shared-host credential exposure
surface. It does not prove that an unattended scheduler is currently pushing to
the repository.

### Current default-branch controls

`main` has classic branch protection with:

- required status check `test`, expected from GitHub Actions;
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

- Repository default workflow permission is read-only; workflows cannot approve
  pull requests.
- `ci.yml` runs offline tests on `pull_request` to `main` and declares no write
  permission.
- `release.yml` runs only on a pushed `v*` tag and explicitly grants
  `contents: write` to create a GitHub Release.
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

1. Prefer a branch ruleset targeting only `main` that requires a pull request
   with zero approvals, requires the `test` check from GitHub Actions, applies
   with no bypass actor, and blocks force pushes and deletion.
2. If that exact rule is unavailable on this user-owned public repository, use
   the narrower classic-protection fallback: remove the independent-review
   requirement, enable administrator enforcement for the existing `test` check,
   retain force-push/deletion blocks, and explicitly record that a commit with a
   pre-existing successful check can still be pushed directly.
3. Push a disposable topic branch and open a test PR. Prove `test` is required
   and the owner can still merge through the normal solo path.
4. Attempt a non-destructive direct update to a disposable protected test branch
   with the same rule shape, rather than experimenting on `main`. Record the
   rejection.
5. Apply the proven rule to `main`, read it back, and verify the next real PR.
6. Roll back immediately if normal solo PR merge becomes impossible.

Rollback must restore the captured classic branch-protection payload and remove
only the newly created ruleset, if any. It must not weaken force-push or deletion
protection below the starting state.

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
- GitHub makes public user-repository push path restrictions available;
- the PR/CI guard creates recurring maintainer friction disproportionate to the
  prevented risk.
