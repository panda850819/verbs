# Fresh-run invocation

> One caller-neutral synchronous handoff: validate a bounded request, start a
> fresh Claude or Codex process, wait, validate one compact result, return
> ownership to the original orchestrator.

## Request

Write an exact JSON object. All four fields are required and unknown fields fail
closed:

```json
{
  "goal": "one bounded task, including authorized files and non-goals",
  "acceptance": ["observable check"],
  "working_directory": "/absolute/current/cwd",
  "completed_evidence": ["verified fact from earlier work"]
}
```

`working_directory` must resolve to the supervisor's current directory. Full
conversation history, raw tool output, permissions, model settings, and secrets
never enter this object.

Because file scope is intentionally not a fifth top-level field, `goal` must
name the authorized files or paths plus any non-goals and stop conditions. A
worker flags work outside that scope instead of changing it.

## Command

```bash
python3 /path/to/verbs/scripts/verbs fresh-run \
  --agent {claude|codex} \
  --model {explicit-model} \
  --effort {explicit-effort} \
  --sandbox {read-only|workspace-write} \
  --request /absolute/path/request.json \
  --timeout 600
```

The original orchestrator may select any model accepted by the chosen runtime.
Same-runtime handoff does not imply same-model handoff. Missing or unsupported
runtime/model/effort settings fail; there is no fallback.

## Fresh-process guarantees

- Claude: new `claude -p`, `--no-session-persistence`, no resume/continue/fork,
  no inherited settings sources or MCP servers, and an explicit sandbox that
  fails closed when unavailable and forbids unsandboxed command fallback.
- Codex: new ephemeral `codex exec`, no resume/fork, no inherited user config or
  exec-policy rules, caller thread/session markers cleared.
- Both: only a small system/runtime environment allowlist crosses the process
  boundary; arbitrary caller credentials and session markers do not.
  `VERBS_FRESH_WORKER=1` blocks recursive handoff, so the original process
  remains the only orchestrator.

The worker still loads the selected runtime's repository instructions. Fresh
means no caller conversation turns or provider session ID are supplied.

`workspace-write` requires a clean git repository root. The supervisor records
HEAD and the current branch before launch and rejects the result if the worker
changes either. Runtime sandboxes keep repository metadata read-only; Claude's
isolated settings additionally deny `.git`, `.agents`, `.claude`, and `.codex`
inside the workspace. The original orchestrator then reviews the working-tree
diff and owns git. `read-only` has no git-cleanliness precondition.

Timeout and supervisor cancellation terminate the worker process group. Tasks
that need background or detached processes are outside V1; the worker must
return `partial` instead of starting them. Strong containment for a process that
deliberately creates a new session would require an OS job/cgroup supervisor and
is intentionally deferred.

## Result

Stdout is one exact object:

```json
{
  "status": "success | partial | failed | cancelled",
  "summary": "compact outcome",
  "evidence": ["claim for the orchestrator to verify"],
  "artifacts": [
    {
      "path": "relative/path",
      "sha256": "supervisor-computed digest",
      "media_type": "text/plain",
      "bytes": 123
    }
  ],
  "next_action": "compact recommendation",
  "errors": []
}
```

Artifact paths must stay inside `working_directory`, name regular non-symlink
files, and pass supervisor digesting. Duplicate paths fail. Each artifact is
capped at 16 MiB and all artifacts at 64 MiB; hashing streams bounded chunks.
Result JSON is capped at 16 KiB before artifact normalization. Run ID, selected
runtime/model/effort, CLI version, exit code, and request/result digests are
emitted separately on stderr and are not copied into the next worker request.
Runtime stdout and stderr are drained without unbounded buffering and each is
capped at 1 MiB; the Codex result file is size-checked before JSON parsing.

The command exits zero for `success` and `partial`; all other outcomes exit
nonzero while still returning a schema-shaped failure result.
