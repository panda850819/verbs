# Unattended runtime options

Date: 2026-07-30
Entry: Unattended runtime options
Status: resolved
Issue: #274

This entry was chartered as a cited inventory with no decision. It stays one.
The output below is the input for entry 5 (scheduling ownership boundary) and
entry 7 (unattended guardrail mechanism); neither is decided here.

## What has to travel

The Verbs enforcement layer is four hooks, all declared in `hooks/hooks.json`:

- `SessionStart`, matcher `startup|clear|compact` (`hooks/hooks.json:5`) —
  injects `DISPATCH.md`.
- `PreToolUse`, matcher `Bash` (`hooks/hooks.json:17`) — two commands, the
  destructive guard then the ticket-gate guard.
- `Stop` (`hooks/hooks.json:32`) — the verify gate.

Bypasses are environment variables: `VERBS_FORCE=1`
(`hooks/pretooluse-destructive-guard.sh:104`), `PSTICKET_FORCE=1` and
`PANDA_FORCE=1` (`hooks/pretooluse-ticket-gate-guard.sh:58,62`). Guard evidence
goes to an append-only log whose path is overridable with
`VERBS_GUARD_EVENT_LOG` (`hooks/guard_events.py:17`).

The load-bearing fact: none of this lives in the repository. All four hooks
reach a session through host-level plugin installation. A runtime that has no
plugin surface has no Verbs enforcement, and says nothing about it.

## Runtime inventory

Versions used: Claude Code `2.1.220`, `codex-cli 0.146.0`, `gh 2.93.0`.

### `claude -p`, locally or under cron

Secrets: full local credential reach (keychain / OAuth) unless run with
`--bare`. Sandboxing: none beyond `--allowedTools` and `--permission-mode`.
Cost: reported per run in `total_cost_usd`; four trivial probe runs during this
research totalled $1.044.

Hook travel: all four fire. The destructive guard blocked an `rm -rf` probe and
the Stop gate forced an explicit unverified-change statement.

The caveat is `--bare`. Its `--help` text in 2.1.220 reads "Minimal mode: skip
hooks, LSP, plugin sync, attribution, auto-memory, background prefetches,
keychain reads, and CLAUDE.md auto-discovery." Under `--bare` the enforcement
layer is absent and silent.

### `claude schedule` cloud routines

Secrets: environment variables are visible to everyone in the environment;
connectors are attached by default and can write. Sandboxing: trusted-network
allowlist, no permission prompts. Cost: subscription quota plus a per-day run
cap.

Hook travel: **none**. A routine starts from a fresh clone and the documented
extension surface is repository-local skills. There is no plugin installation
step, so no Verbs hook exists to fire. The routine's own PR ceiling (it only
pushes `claude/`-prefixed branches) is a native constraint, not a Verbs one.

### `codex exec`

Secrets: `~/.codex/auth.json` or `OPENAI_API_KEY`. Sandboxing: `read-only`,
`workspace-write`, or `danger-full-access`; under `workspace-write` the `.git`
directory is read-only, which blocks the commit path Verbs assumes. Cost: no
per-run cost field is exposed.

Hook travel: **conditional and silent when absent**. Codex requires persisted
hook trust; `codex exec --help` documents
`--dangerously-bypass-hook-trust` as "Run enabled hooks without requiring
persisted hook trust for this invocation. DANGEROUS." A fresh `CODEX_HOME`
therefore runs with hooks skipped rather than failing.

The `Stop` gate is additionally exempt by design, not by accident.
`hooks/stop-verify-gate.py:9-13` states that a transcript path that is null or
missing is "a transcriptless run (Codex side conversation, codex exec, install
smoke tests)" and that the gate "allows with a stderr notice and a high-signal
guard event instead."

### GitHub Actions (`claude-code-action@v1`)

Secrets: API key or OAuth token in repository secrets; the GitHub App token is
repository-scoped read/write. Sandboxing: runner isolation, plus bubblewrap for
non-write users. Cost: Actions minutes plus tokens; `--max-turns` is the only
built-in brake.

Hook travel: **a supported path exists**. The action accepts `plugin_marketplaces`
and `plugins` inputs and installs them through the same `claude plugin install`
used locally, and it does not pass `--bare`. Whether the hooks then fire inside
the runner is untested here. The OpenAI `codex-action` equivalent exposes no
plugin input at all.

## Named failure modes

1. **Codex hook trust is hash-pinned.** A fresh `CODEX_HOME` skips all four
   hooks silently. Worse for this repository specifically: the release flow bumps
   `[manifest] version` on every skill change, and any edit under `hooks/`
   invalidates trust again. The enforcement layer degrades on the same cadence
   as normal development.

2. **`--bare` removes everything and says nothing.** Verified above from
   `--help`. Today's green local result depends on `-p` defaulting to non-bare.
   This is a default, not a contract, and nothing in the repository detects a
   change to it. (An earlier draft of this note attributed a sentence to
   `--help` saying `--bare` would become the `-p` default in a future release;
   that string is not present in 2.1.220 and has been removed rather than
   reworded. See Gaps.)

3. **Both `PreToolUse` guards match only `Bash`** (`hooks/hooks.json:17`). Any
   write that does not go through a shell command is invisible to them: `Edit`,
   `Write`, and MCP tools. Concretely, `claude-code-action` with
   `use_commit_signing: true` commits through an MCP file-ops tool, so the
   ticket gate never sees the commit that lands the code.

4. **Cloud routines have no plugin surface**, so the absence in that runtime is
   structural rather than configurable.

## Open questions handed to entries 5 and 7

- How a `--bare` or default-flip regression would be detected at all, given
  hook absence is silent in three of the four runtimes.
- Whether the `PreToolUse` matcher should widen beyond `Bash`, or whether the
  ceiling should move to GitHub-side branch protection where it cannot be
  skipped by a runtime choice.
- Who owns the PR ceiling. Cloud routines and the GitHub Action each already
  enforce a harder native ceiling than the Verbs ticket gate does.
- Whether `codex exec`'s pairing of read-only `.git` under `workspace-write`
  with hash-pinned hook trust rules it out as an unattended writer.
- What the bypass variables mean when inherited by an unattended environment
  rather than typed by a human.
- Where guard evidence persists when the runtime is ephemeral;
  `VERBS_GUARD_EVENT_LOG` must point outside the workspace or the audit trail
  evaporates with the runner.

## Gaps

- Whether Verbs hooks actually fire inside a GitHub Actions runner. The
  installation path is established from the action's inputs; no workflow was
  run.
- Whether a cloud routine's setup script can install a plugin such that later
  sessions in that routine inherit it.
- Whether `settings.json`-declared hooks (as opposed to plugin-declared) fire
  under `claude -p`. Only the plugin path was exercised.
- Per-run cost for `codex exec`; no `total_cost_usd` equivalent is exposed.
- Codex documentation has no positive section on hook behaviour under `exec`.
  The trust conclusion rests on the `--dangerously-bypass-hook-trust` help text
  quoted above, not on a documented statement about `exec`.
- Any claim that `--bare` is scheduled to become the `-p` default. Not present
  in 2.1.220 `--help`; treat as unverified until a primary source is found.
