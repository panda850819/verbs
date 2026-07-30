# Unattended guardrail mechanism

Date: 2026-07-31
Entry: Unattended guardrail mechanism
Status: resolved
Issue: #279

The entry asked how to make the permission envelope enforceable rather than
prose, and named three candidate mechanisms: labels plus a PreToolUse guard, an
allowlist, or branch rules. The answer is that the choice was never between
those three. It is between accepting that one specific boundary cannot be
enforced on this repository, or paying a cost that changes how the author works.

## What is enforced today

Measured against the live repository on 2026-07-31, not from documentation:

```
enforce_admins:   false
rulesets:         []
required reviews: null
PR #273 reviews:  0
PR #275 reviews:  0
PR #278 reviews:  0
```

`main` carries classic branch protection with one required status check
(`test`). With `enforce_admins` disabled, none of it applies to an admin
identity, and an unattended agent runs under the author's admin identity. No
merged pull request in the recent history was reviewed.

The Verbs side is no better. `unattended`, `PR ceiling`, `maintenance-class`,
and `never merge` return zero matches across `skills/`, `README.md`,
`DISPATCH.md`, and `RESOLVER.md`. The envelope exists only in `docs/briefs/`.
`DISPATCH.md` itself reaches a session through the SessionStart hook
(`hooks/hooks.json:3-14`), so the `claude schedule` lane — which has no plugin
surface at all
([02-unattended-runtime-options](02-unattended-runtime-options.md)) — never
loads it.

So both the standing rule "merge is always a human gate" and gate G-A's "0
boundary violations" are currently unenforced statements.

## The structural limit

On a user-owned repository, repo admin is the ceiling. There is no organisation
ruleset or enterprise policy above it, and any credential carrying
`Administration: write` can delete every guardrail from inside the session it is
supposed to constrain.

Merging and pushing are both `Contents: write`. No token scope expresses "may
open a pull request, may not merge". That is the fact that collapses the
original three-way framing: a guard, an allowlist, and a branch rule all fail
the same way, because the agent holds the credential that outranks them.

Two exits existed, and both were rejected on cost rather than on mechanism:

- **Fork lane.** Give the unattended agent write access only to a fork; it then
  has zero permission on the base repository and cannot merge regardless of any
  setting. Rejected because GitHub does not allow forking a repository into its
  own owner's account, so this requires standing up an organisation to hold the
  fork.
- **Required approvals, no bypass actor.** A real merge gate, but a solo author
  cannot approve their own pull request, so it gates the author exactly as hard
  as it gates the agent.

## Decision

The merge gate stays soft, and is documented as soft. Every boundary beneath it
becomes server-enforced, where the enforcement point is outside any session's
reach.

**Server-side** — none of this costs the attended flow anything:

- Enable `enforce_admins`, so branch protection applies to the identity the
  agent actually runs as.
- A ruleset requiring a pull request to reach `main`, with no bypass actor.
  This closes direct pushes to `main`, which is open today independently of
  anything unattended.
- A file-path ruleset covering `hooks/`, `.github/`, and `manifest.toml`. This
  is the only native scope ceiling GitHub offers, and it is what prevents an
  agent from editing the constraints that govern it.
- A required status check binding each pull request to a maintenance-labelled
  Issue and asserting the diff stays within the scope that ticket declares. It
  must trigger on `pull_request_target`; on `pull_request` the workflow runs
  from the agent's own branch, where the agent can edit the gate.

**Verbs-side** — after #278 this is the whole of what Verbs owns on this line:

- State the envelope in the `sprint` and `ship` skill bodies. Today it is in
  `DISPATCH.md`, which one lane never loads and which is not repository-local
  for any other project.
- A maintenance-class label scheme. This is greenfield: no Issue in this
  repository carries any label today, so nothing constrains the design and
  nothing can be assumed to already work.
- A claim protocol and a write-back format. Note the collision: `assignees` is
  the only field that is close to atomic and readable from both `gh issue list
  --json` and `gh api`, but `to-tickets` currently forbids claiming
  (`skills/productivity/to-tickets/SKILL.md:131-132`). Entry 6 owns that
  conflict; this entry only records that a claim protocol needs it settled.

## What this buys and what it does not

An unattended agent can still merge its own pull request. That is the residual
hole, it is named rather than papered over, and closing it requires a second
identity.

What the decision buys is that every other boundary moves to a point the session
cannot reach: it cannot push to `main`, cannot touch its own guardrails, cannot
land a diff outside a declared ticket scope, and cannot do any of it invisibly.

## Consequence for G-A

Gate G-A promises "0 boundary violations". Under a soft merge gate that is not
provable, so G-A must state that it tests the server-enforced boundaries and
that merge remains a human responsibility. Leaving an unmeasurable gate on the
map is the defect entry 5 was closed for eight days ago; it should not be
reintroduced here.

## Gaps

- What credential a `claude schedule` cloud routine presents to GitHub. This is
  the highest-value unknown on this line: if that lane is forced to carry the
  author's full identity, the server-side rules above are the only thing
  standing between it and `main`. Only the local token was verified.
- Whether push rulesets are available on a personal, non-organisation
  repository.
- That an admin can push directly to `main` today is inferred from
  `enforce_admins: false` plus documented behaviour; it was not tested, because
  testing it means writing to `main`.
- Whether Verbs hooks fire inside a GitHub Actions runner. Carried over
  unchanged from [02-unattended-runtime-options](02-unattended-runtime-options.md).
- Whether this repository turning private would move branch protection or
  rulesets behind a paid plan. The owner plan is not readable from the API.
