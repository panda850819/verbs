# Agent-worker protocol

`agent-worker` is the repo-local boundary between pandastack flow logic and concrete AI runtimes.

Flow code decides **what** should run: Linear item, phase, worktree, prompt, policy, and acceptance. Backend adapters decide **how** a runtime is invoked: CLI flags, sandbox mode, output capture, logs, and result parsing.

## Command

```bash
scripts/agent-worker run \
  --backend codex|test \
  --job-dir <path> \
  --worktree <path> \
  --prompt <path> \
  --out <path>
```

The protocol command is intentionally generic. Backend-specific flags such as `codex exec -s read-only`, `-s workspace-write`, and `sandbox_workspace_write.network_access=false` live inside `scripts/agent-worker`, not in scheduler or skill-flow code.

## Job directory contract

```text
job/
  spec.md              # human-readable job context
  prompt.md            # prompt handed to the backend
  request.json         # generic policy knobs, not backend flags or flow metadata
  metadata.json        # optional flow metadata such as issue/project/phase
  test.json            # optional deterministic fixture data for the test backend only
  acceptance.md        # human-readable acceptance criteria
  verify.sh            # optional host verifier; ignored unless request allows it
  output/result.json   # normalized result JSON
  output/diff.patch    # reviewable worktree diff, including untracked text files
  output/*             # backend raw output files
  logs/stdout.jsonl    # append-only adapter events
```

Callers that need post-run audit must keep the job directory durable. `pandastack-drive` stores its worker jobs under `~/.local/state/pandastack/worker-jobs` by default, or `PSDRIVE_WORKER_JOB_ROOT` in tests.

`request.json` currently supports:

```json
{
  "mode": "read-only | workspace-write",
  "network_access": false,
  "timeout_seconds": 1200,
  "allow_host_verify": false
}
```

Host `verify.sh` execution is opt-in through `allow_host_verify` and runs with the same allowlisted environment used for backend subprocesses. Boolean policy fields are strict booleans; string values such as `"false"` are rejected. Workspace-write jobs require `network_access=false`. For workspace-write jobs, callers must keep `job-dir` outside `worktree`; the adapter rejects job directories inside the writable tree so the backend cannot rewrite verifier or request artifacts. `--out` must stay under `job-dir/output` and outside the worktree. Worker subprocesses receive only runtime basics such as PATH/HOME/TMPDIR/LANG/TERM; credential-shaped environment variables are not forwarded.

The `test` backend additionally supports deterministic fixture fields such as `test_status`, `test_summary`, `write_file`, and `write_text` in `test.json`. It never calls external CLIs. `test.json` is test-only; production backends must not add backend flags to `request.json`.

## Result schema

`output/result.json`:

```json
{
  "schema_version": 1,
  "backend": "codex",
  "status": "PASS | FAIL | BLOCKED | ERROR | UNKNOWN",
  "ok": true,
  "summary": "one-line summary",
  "returncode": 0,
  "changed_files": ["path/from/git-status"],
  "verification": {
    "ran": true,
    "ok": true,
    "command": "job/verify.sh",
    "returncode": 0,
    "stdout_tail": "...",
    "stderr_tail": "..."
  },
  "logs": {
    "stdout_jsonl": "job/logs/stdout.jsonl",
    "raw_output_path": "job/output/agent-worker-codex-...txt",
    "stdout_tail": "...",
    "stderr_tail": "...",
    "raw_output_tail": "..."
  },
  "artifacts": {
    "job_dir": "job",
    "result_json": "job/output/result.json",
    "diff_patch": "job/output/diff.patch",
    "stdout_jsonl": "job/logs/stdout.jsonl"
  },
  "request": {
    "mode": "workspace-write",
    "network_access": false,
    "timeout_seconds": 1800,
    "allow_host_verify": false
  }
}
```

`diff.patch` captures the post-verification worktree delta against `HEAD`, including staged changes. For workspace-write jobs it also includes nested untracked text files up to 1 MiB each. Read-only jobs do not persist untracked local files. Git diff is invoked with external diff and textconv disabled; untracked symlinks are skipped rather than dereferenced so ignored local files are not copied into artifacts.

If the backend returns `PASS` but `verify.sh` fails, the adapter demotes the normalized status to `FAIL`.

## Current backends

| Backend | Purpose |
|---|---|
| `codex` | Production executor. Wraps `codex exec`, sandbox selection, network-off build mode, output file parsing, and RESULT line parsing. |
| `test` | Offline deterministic backend for protocol and driver tests. |

## Boundary rule

Any future direct `claude -p`, `codex exec`, Hermes one-shot, Omnigent, ACP, or MCP runtime invocation must be implemented as an `agent-worker` backend adapter. Flow code may pass only generic policy via `request.json`.
