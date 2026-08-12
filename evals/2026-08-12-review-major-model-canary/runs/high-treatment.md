Review scope: `31b055b..14f4cd5` | 13 files | risk: high

Changed: `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `CHANGELOG.md`, `DISPATCH.md`, `README.md`, `RESOLVER.md`, `hooks/hooks.json`, both guards, both manifests, and two tests.

## Findings

- [P1] Quote stripping creates default-branch bypasses — [hooks/pretooluse-ticket-gate-guard.sh:127–159](hooks/pretooluse-ticket-gate-guard.sh:127)
  Trigger: On `main`, `git 'commit' -m msg` or `git 'push' origin main`.
  Mechanism: `sed` deletes quoted strings before determining the Git subcommand, so valid quoted argv tokens disappear.
  Consequence: Both probes returned exit 0, allowing commits or pushes the guard promises to block.
  Direction: Perform shell-aware tokenization that preserves quoted argument values while distinguishing commands from inert string data; add quoted-subcommand/refspec tests.

- [P1] Repo resolution can inspect the wrong repository — [hooks/pretooluse-ticket-gate-guard.sh:98–113](hooks/pretooluse-ticket-gate-guard.sh:98)
  Trigger: From another payload cwd, `cd <main-repo> && git commit`; also `git -C invalid status | git commit`.
  Mechanism: Resolution ignores preceding `cd` and uses the first `-C` across an entire pipe segment rather than resolving each Git invocation independently.
  Consequence: Both probes returned exit 0 while a direct commit against the identical repo returned exit 2.
  Direction: Resolve each Git invocation’s effective cwd independently, accounting for `cd`, pipelines, and dequoted `-C` arguments; add blocking regression cases.

- [P2] Token matching misclassifies safe Git operations — [hooks/pretooluse-ticket-gate-guard.sh:135–159](hooks/pretooluse-ticket-gate-guard.sh:135)
  Trigger: On `main`, `git push origin feat/203-guard` or `git log --grep=commit`.
  Mechanism: Any push without a recognized main token is treated as bare, and any segment containing the word `commit` is treated as the commit subcommand.
  Consequence: Both safe operations returned exit 2, encouraging routine bypass use and blocking the intended feature-branch workflow.
  Direction: Identify the actual Git subcommand after global options, then distinguish an absent push refspec from an explicit non-default refspec.

- [P3] Public hook inventory omits the new guard — [README.md:49–50](README.md:49)
  Trigger: An operator checks which enforcement hooks the Marketplace Plugin installs.
  Mechanism: The README still says there are three adapters and names only the destructive PreToolUse guard; the same stale inventory appears in `INSTALL_FOR_AGENTS.md`, `PHILOSOPHY.md`, and `ROADMAP.md`.
  Consequence: Operators are not told that ticket-gate enforcement is active.
  Direction: Update the public hook inventories to include both PreToolUse guards.

Coverage: `bash -n` passed for both guards and changed shell tests; `hooks.json` parsed; `git diff --check HEAD^..HEAD` passed; versions agree on `0.7.1`; targeted guard probes verified normal blocking, fail-open envelopes, and the triggers above. The fixture suites could not run validly because the read-only sandbox denied temporary-repository creation; their resulting failures are environmental, not test evidence. Worktree remained clean.

Scope drift: none.

Cold review: completed in an isolated context; its independently traced findings agreed with the observed mechanisms.

Self-refute: I challenged the assumption that quote stripping removes only inert data. Against the same `main` repo, ordinary `git commit` returned 2 while valid `git 'commit'` returned 0, disproving that assumption.
