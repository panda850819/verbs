---
name: setup-verbs
description: |
  Resolve ambiguity and approval for a repository's Verbs issue-tracker
  setting. Use when setup is requested or `scripts/verbs setup` reports a
  document, tracker, or Git-identity conflict.
reads:
  - repo: AGENTS.md
  - repo: CLAUDE.md
  - repo: .git/config
  - cli: scripts/verbs setup
writes:
  - repo: AGENTS.md
  - repo: CLAUDE.md
forbids:
  - repo: .verbs.toml
domain: shared
classification: tool
user-invocable: true
---

# Setup Verbs

The deterministic setup contract belongs to `scripts/verbs setup`. This skill
owns only ambiguity resolution and the human approval boundary. GitHub is the
only supported tracker; repository identity always comes from Git remotes.

## Procedure

1. Run `scripts/verbs setup --check` in the target repository.
2. If it reports a document ambiguity, ask the human to choose `AGENTS.md` or
   `CLAUDE.md` as canonical. Do not create a parallel config surface or guess.
   If neither exists, ask which canonical document to create, create only that
   empty document after approval, then rerun the check.
3. If it reports no or conflicting GitHub repository identities, surface the
   exact remotes and stop until the human repairs Git configuration. If it
   reports a tracker other than `github`, surface the conflict and stop; do not
   overwrite or translate it.
4. Run `scripts/verbs setup --preview` and show its exact target and diff. Ask
   once: `[approve / reject / skip]`.
5. On `approve`, run `scripts/verbs setup --apply --approve`. On `reject` or
   `skip`, make no change and stop. Never edit the document independently of the
   CLI preview.
6. Run `scripts/verbs setup --check` again and report the selected file,
   `tracker: github`, and Git-derived repository identity.

A configured repository is a no-op: the check succeeds, no preview is needed,
and no approval prompt appears. The CLI preserves surrounding content and
existing keys, rejects duplicate blocks or settings, and never writes
`.verbs.toml`.
