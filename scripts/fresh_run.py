"""One synchronous fresh-context worker invocation for the Verbs CLI."""

import hashlib
import json
import mimetypes
import os
import re
import selectors
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path


REQUEST_FIELDS = {
    "goal",
    "acceptance",
    "working_directory",
    "completed_evidence",
}
RESULT_FIELDS = {
    "status",
    "summary",
    "evidence",
    "artifacts",
    "next_action",
    "errors",
}
RESULT_STATUSES = {"success", "partial", "failed", "cancelled"}
MAX_RESULT_BYTES = 16 * 1024
MAX_REQUEST_BYTES = 16 * 1024
MAX_ARTIFACT_BYTES = 16 * 1024 * 1024
MAX_ARTIFACT_TOTAL_BYTES = 64 * 1024 * 1024
MAX_PROCESS_OUTPUT_BYTES = 1024 * 1024
MINIMUM_VERSIONS = {"claude": (2, 1, 206), "codex": (0, 144, 1)}
WORKER_ENV_KEYS = {
    "CODEX_HOME",
    "HOME",
    "LANG",
    "LC_ALL",
    "LC_CTYPE",
    "LOGNAME",
    "PATH",
    "SHELL",
    "SSL_CERT_DIR",
    "SSL_CERT_FILE",
    "TEMP",
    "TERM",
    "TMP",
    "TMPDIR",
    "USER",
    "XDG_CACHE_HOME",
    "XDG_CONFIG_HOME",
    "XDG_DATA_HOME",
}

WORKER_RESULT_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "required": sorted(RESULT_FIELDS),
    "properties": {
        "status": {"type": "string", "enum": sorted(RESULT_STATUSES)},
        "summary": {"type": "string", "maxLength": 4096},
        "evidence": {
            "type": "array",
            "maxItems": 32,
            "items": {"type": "string", "maxLength": 1024},
        },
        "artifacts": {
            "type": "array",
            "maxItems": 32,
            "items": {"type": "string", "maxLength": 1024},
        },
        "next_action": {"type": "string", "maxLength": 2048},
        "errors": {
            "type": "array",
            "maxItems": 32,
            "items": {"type": "string", "maxLength": 1024},
        },
    },
}


class FreshRunError(Exception):
    """A bounded failure safe to report without a traceback."""

    def __init__(self, message, status="failed"):
        super().__init__(message)
        self.status = status


def add_parser(subparsers):
    parser = subparsers.add_parser(
        "fresh-run",
        help="Run one bounded task in a fresh Claude or Codex process",
    )
    parser.add_argument("--agent", choices=["claude", "codex"], required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument(
        "--effort",
        choices=["low", "medium", "high", "xhigh", "max", "ultra"],
        required=True,
    )
    parser.add_argument(
        "--sandbox",
        choices=["read-only", "workspace-write"],
        required=True,
    )
    parser.add_argument(
        "--request",
        required=True,
        help="Request JSON path, or - for stdin",
    )
    parser.add_argument("--timeout", type=int, default=600)
    parser.set_defaults(handler=run)
    return parser


def run(args):
    run_id = str(uuid.uuid4())
    try:
        result, metadata = execute(args, run_id)
    except FreshRunError as exc:
        result = _failure_result(str(exc), exc.status)
        _emit(result)
        print(
            "[verbs fresh-run] " + json.dumps({
                "agent": args.agent,
                "effort": args.effort,
                "model": args.model,
                "run_id": run_id,
                "status": exc.status,
            }, sort_keys=True),
            file=sys.stderr,
        )
        return 1

    _emit(result)
    print(
        "[verbs fresh-run] " + json.dumps(metadata, sort_keys=True),
        file=sys.stderr,
    )
    return 0 if result["status"] in {"success", "partial"} else 1


def execute(args, run_id):
    if os.environ.get("VERBS_FRESH_WORKER") == "1":
        raise FreshRunError("recursive fresh-run from a worker is forbidden")
    if args.timeout < 1:
        raise FreshRunError("timeout must be at least one second")

    request = _read_request(args.request)
    working_directory = _validate_request(request)
    runtime = shutil.which(args.agent)
    if not runtime:
        raise FreshRunError("{} CLI not found".format(args.agent))
    if args.agent == "claude" and args.effort == "ultra":
        raise FreshRunError("Claude does not support ultra effort")
    env = _worker_environment(run_id)
    runtime_version = _runtime_version(runtime, env)
    _require_runtime_version(args.agent, runtime_version)

    request_digest = _digest_json(request)
    prompt = _build_prompt(request)
    git_baseline = None
    if args.sandbox == "workspace-write":
        git_baseline = _git_workspace_baseline(working_directory)
    with tempfile.TemporaryDirectory(prefix="verbs-fresh-run-") as scratch:
        scratch_path = Path(scratch)
        schema_path = scratch_path / "result-schema.json"
        result_path = scratch_path / "result.json"
        claude_settings_path = scratch_path / "claude-settings.json"
        _write_private_json(schema_path, WORKER_RESULT_SCHEMA)
        _write_private_json(
            claude_settings_path, _claude_settings(working_directory)
        )

        if args.agent == "codex":
            command = _codex_command(
                runtime, args, working_directory, schema_path, result_path
            )
        else:
            command = _claude_command(
                runtime, args, schema_path, claude_settings_path
            )

        completed = _run_process(
            command,
            prompt,
            working_directory,
            env,
            args.timeout,
        )
        if git_baseline is not None:
            _verify_git_workspace_baseline(working_directory, git_baseline)
        if completed["returncode"] != 0:
            raise FreshRunError(
                _safe_exit_error(
                    args.agent, completed["returncode"],
                    completed["stdout"], completed["stderr"],
                )
            )

        if args.agent == "codex":
            worker_result = _load_json_file(result_path, "Codex result")
        else:
            worker_result = _claude_result(completed["stdout"])

        result = _normalize_result(worker_result, working_directory)

    result_digest = _digest_json(result)
    metadata = {
        "agent": args.agent,
        "effort": args.effort,
        "exit_code": completed["returncode"],
        "model": args.model,
        "request_sha256": request_digest,
        "result_sha256": result_digest,
        "run_id": run_id,
        "runtime_version": runtime_version,
    }
    return result, metadata


def _read_request(source):
    try:
        if source == "-":
            raw = sys.stdin.read(MAX_REQUEST_BYTES + 1)
        else:
            path = Path(source)
            if path.stat().st_size > MAX_REQUEST_BYTES:
                raise FreshRunError("request exceeds 16 KiB")
            raw = path.read_text(encoding="utf-8")
        if len(raw.encode("utf-8")) > MAX_REQUEST_BYTES:
            raise FreshRunError("request exceeds 16 KiB")
        value = json.loads(raw)
    except FreshRunError:
        raise
    except (OSError, ValueError) as exc:
        raise FreshRunError("invalid request JSON: {}".format(exc))
    return value


def _validate_request(request):
    if not isinstance(request, dict):
        raise FreshRunError("request must be a JSON object")
    _require_exact_fields(request, REQUEST_FIELDS, "request")
    if not isinstance(request["goal"], str) or not request["goal"].strip():
        raise FreshRunError("request.goal must be a non-empty string")
    if len(request["goal"]) > 4096:
        raise FreshRunError("request.goal exceeds 4096 characters")
    _string_list(
        request["acceptance"], "request.acceptance", require_one=True,
        max_items=32, max_length=1024,
    )
    _string_list(
        request["completed_evidence"], "request.completed_evidence",
        max_items=32, max_length=1024,
    )
    if not isinstance(request["working_directory"], str):
        raise FreshRunError("request.working_directory must be a string")

    cwd = Path.cwd().resolve()
    working_directory = Path(request["working_directory"]).expanduser().resolve()
    if not working_directory.is_dir():
        raise FreshRunError("request.working_directory must exist")
    if working_directory != cwd:
        raise FreshRunError(
            "request.working_directory must equal the supervisor cwd"
        )
    return working_directory


def _build_prompt(request):
    return """You are a fresh bounded worker. Complete only the supplied request.
Do not invoke Verbs handover or fresh-run and do not delegate to another agent.
Do not commit, push, open a pull request, or modify repository metadata.
Do not start background or detached processes. Return partial if they are needed.
Stay inside working_directory. Treat goal as the complete authorized file scope;
flag anything outside it instead of changing it. Run the acceptance checks you can
observe, and never weaken, skip, or fake them. Verify again after the final edit.
Return one JSON object matching the supplied schema. Do not include markdown.
Artifact paths must be relative to working_directory. Do not include transcripts,
raw tool logs, environment variables, credentials, or secret values.

REQUEST:
{}""".format(json.dumps(request, indent=2, sort_keys=True))


def _codex_command(runtime, args, cwd, schema_path, result_path):
    return [
        runtime,
        "exec",
        "--ephemeral",
        "--ignore-user-config",
        "--ignore-rules",
        "-C",
        str(cwd),
        "-m",
        args.model,
        "-c",
        'model_reasoning_effort="{}"'.format(args.effort),
        "-s",
        args.sandbox,
        "--output-schema",
        str(schema_path),
        "-o",
        str(result_path),
        "-",
    ]


def _claude_command(runtime, args, schema_path, settings_path):
    permission_mode = "plan" if args.sandbox == "read-only" else "acceptEdits"
    return [
        runtime,
        "-p",
        "--setting-sources",
        "",
        "--settings",
        str(settings_path),
        "--strict-mcp-config",
        "--mcp-config",
        '{"mcpServers":{}}',
        "--model",
        args.model,
        "--effort",
        args.effort,
        "--permission-mode",
        permission_mode,
        "--no-session-persistence",
        "--output-format",
        "json",
        "--json-schema",
        schema_path.read_text(encoding="utf-8"),
    ]


def _run_process(command, prompt, cwd, env, timeout):
    process = subprocess.Popen(
        command,
        cwd=str(cwd),
        env=env,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
    streams = {process.stdout: "stdout", process.stderr: "stderr"}
    buffers = {"stdout": bytearray(), "stderr": bytearray()}
    exceeded = set()
    selector = selectors.DefaultSelector()
    for stream in streams:
        selector.register(stream, selectors.EVENT_READ)
    previous_handlers = {}

    def cancel_from_signal(_signum, _frame):
        raise KeyboardInterrupt

    for handled_signal in (signal.SIGHUP, signal.SIGTERM):
        previous_handlers[handled_signal] = signal.signal(
            handled_signal, cancel_from_signal
        )
    try:
        try:
            process.stdin.write(prompt.encode("utf-8"))
            process.stdin.close()
        except BrokenPipeError:
            pass
        deadline = time.monotonic() + timeout
        while selector.get_map():
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise FreshRunError(
                    "worker timed out after {} seconds".format(timeout)
                )
            for key, _events in selector.select(min(remaining, 0.1)):
                chunk = os.read(key.fd, 64 * 1024)
                if not chunk:
                    selector.unregister(key.fileobj)
                    continue
                label = streams[key.fileobj]
                room = MAX_PROCESS_OUTPUT_BYTES + 1 - len(buffers[label])
                if room > 0:
                    buffers[label].extend(chunk[:room])
                if len(buffers[label]) > MAX_PROCESS_OUTPUT_BYTES:
                    exceeded.add(label)
        process.wait(timeout=max(0.1, deadline - time.monotonic()))
    except subprocess.TimeoutExpired:
        raise FreshRunError("worker timed out after {} seconds".format(timeout))
    except KeyboardInterrupt:
        raise FreshRunError("worker cancelled by supervisor", status="cancelled")
    finally:
        selector.close()
        _terminate_process_group(process)
        for handled_signal, previous in previous_handlers.items():
            signal.signal(handled_signal, previous)
    if exceeded:
        raise FreshRunError(
            "worker {} exceeds 1 MiB".format(" and ".join(sorted(exceeded)))
        )
    return {
        "returncode": process.returncode,
        "stdout": buffers["stdout"].decode("utf-8", errors="replace"),
        "stderr": buffers["stderr"].decode("utf-8", errors="replace"),
    }


def _terminate_process_group(process):
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    deadline = time.monotonic() + 2
    while _process_group_exists(process.pid) and time.monotonic() < deadline:
        process.poll()
        time.sleep(0.05)
    if _process_group_exists(process.pid):
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except (PermissionError, ProcessLookupError):
            return
    if process.poll() is None:
        process.wait()


def _process_group_exists(process_group_id):
    try:
        os.killpg(process_group_id, 0)
    except (PermissionError, ProcessLookupError):
        return False
    return True


def _claude_result(stdout):
    try:
        envelope = json.loads(stdout)
    except ValueError as exc:
        raise FreshRunError("Claude result envelope is invalid JSON: {}".format(exc))
    if not isinstance(envelope, dict):
        raise FreshRunError("Claude result envelope must be an object")
    if envelope.get("is_error") is True:
        raise FreshRunError("Claude reported an error result")
    result = envelope.get("structured_output")
    if result is None and set(envelope) == RESULT_FIELDS:
        result = envelope
    if result is None:
        raise FreshRunError("Claude result is missing structured_output")
    return result


def _safe_exit_error(agent, returncode, stdout, stderr):
    if agent == "claude":
        try:
            envelope = json.loads(stdout)
        except ValueError:
            envelope = None
        if isinstance(envelope, dict) and envelope.get("api_error_status"):
            return "claude worker exited {}; api_error_status={}".format(
                returncode, envelope["api_error_status"]
            )
    if "--json-schema is not a valid JSON Schema" in (stderr or ""):
        return "{} worker rejected the result schema".format(agent)
    return "{} worker exited {}".format(agent, returncode)


def _normalize_result(result, cwd):
    encoded = json.dumps(result, separators=(",", ":")).encode("utf-8")
    if len(encoded) > MAX_RESULT_BYTES:
        raise FreshRunError("worker result exceeds 16 KiB")
    if not isinstance(result, dict):
        raise FreshRunError("worker result must be a JSON object")
    _require_exact_fields(result, RESULT_FIELDS, "worker result")
    if (
        not isinstance(result["status"], str)
        or result["status"] not in RESULT_STATUSES
    ):
        raise FreshRunError("worker result has an invalid status")
    if not isinstance(result["summary"], str):
        raise FreshRunError("worker result.summary must be a string")
    if len(result["summary"]) > 4096:
        raise FreshRunError("worker result.summary exceeds 4096 characters")
    _string_list(
        result["evidence"], "worker result.evidence",
        max_items=32, max_length=1024,
    )
    _string_list(
        result["artifacts"], "worker result.artifacts",
        max_items=32, max_length=1024,
    )
    if not isinstance(result["next_action"], str):
        raise FreshRunError("worker result.next_action must be a string")
    if len(result["next_action"]) > 2048:
        raise FreshRunError("worker result.next_action exceeds 2048 characters")
    _string_list(
        result["errors"], "worker result.errors",
        max_items=32, max_length=1024,
    )

    normalized_artifacts = []
    seen_artifacts = set()
    total_bytes = 0
    for item in result["artifacts"]:
        reference = _artifact_reference(cwd, item, seen_artifacts)
        total_bytes += reference["bytes"]
        if total_bytes > MAX_ARTIFACT_TOTAL_BYTES:
            raise FreshRunError("worker artifacts exceed 64 MiB in total")
        normalized_artifacts.append(reference)

    normalized = dict(result)
    normalized["artifacts"] = normalized_artifacts
    return normalized


def _artifact_reference(cwd, relative, seen_artifacts):
    candidate = Path(relative)
    if candidate.is_absolute() or ".." in candidate.parts:
        raise FreshRunError("artifact path is not confined: {}".format(relative))
    unresolved = cwd / candidate
    if unresolved.is_symlink():
        raise FreshRunError("artifact must not be a symlink: {}".format(relative))
    resolved = unresolved.resolve()
    try:
        canonical = resolved.relative_to(cwd).as_posix()
    except ValueError:
        raise FreshRunError("artifact path escapes working_directory: {}".format(relative))
    if canonical in seen_artifacts:
        raise FreshRunError("worker result.artifacts contains duplicate paths")
    seen_artifacts.add(canonical)
    try:
        descriptor = os.open(str(resolved), os.O_RDONLY | os.O_NOFOLLOW)
    except OSError as exc:
        raise FreshRunError("artifact cannot be opened safely: {}".format(relative))
    digest = hashlib.sha256()
    size = 0
    try:
        metadata = os.fstat(descriptor)
        if not stat.S_ISREG(metadata.st_mode):
            raise FreshRunError(
                "artifact must be a regular file: {}".format(relative)
            )
        if metadata.st_size > MAX_ARTIFACT_BYTES:
            raise FreshRunError("artifact exceeds 16 MiB: {}".format(relative))
        while True:
            chunk = os.read(descriptor, 64 * 1024)
            if not chunk:
                break
            size += len(chunk)
            if size > MAX_ARTIFACT_BYTES:
                raise FreshRunError("artifact exceeds 16 MiB: {}".format(relative))
            digest.update(chunk)
    finally:
        os.close(descriptor)
    return {
        "bytes": size,
        "media_type": mimetypes.guess_type(str(resolved))[0]
        or "application/octet-stream",
        "path": canonical,
        "sha256": digest.hexdigest(),
    }


def _require_exact_fields(value, expected, label):
    actual = set(value)
    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    if missing or extra:
        parts = []
        if missing:
            parts.append("missing " + ", ".join(missing))
        if extra:
            parts.append("unknown " + ", ".join(extra))
        raise FreshRunError("{} fields: {}".format(label, "; ".join(parts)))


def _string_list(
    value, label, require_one=False, max_items=None, max_length=None
):
    if not isinstance(value, list) or any(
        not isinstance(item, str) or not item.strip() for item in value
    ):
        raise FreshRunError("{} must contain only non-empty strings".format(label))
    if require_one and not value:
        raise FreshRunError("{} must contain at least one item".format(label))
    if max_items is not None and len(value) > max_items:
        raise FreshRunError("{} exceeds {} items".format(label, max_items))
    if max_length is not None and any(len(item) > max_length for item in value):
        raise FreshRunError(
            "{} contains an item over {} characters".format(label, max_length)
        )


def _write_private_json(path, value):
    descriptor = os.open(
        str(path), os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600
    )
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        json.dump(value, handle, separators=(",", ":"), sort_keys=True)


def _load_json_file(path, label):
    try:
        if path.stat().st_size > MAX_RESULT_BYTES:
            raise FreshRunError("{} exceeds 16 KiB".format(label))
        with path.open("r", encoding="utf-8") as handle:
            raw = handle.read(MAX_RESULT_BYTES + 1)
        if len(raw.encode("utf-8")) > MAX_RESULT_BYTES:
            raise FreshRunError("{} exceeds 16 KiB".format(label))
        return json.loads(raw)
    except FreshRunError:
        raise
    except (OSError, ValueError) as exc:
        raise FreshRunError("{} is missing or invalid: {}".format(label, exc))


def _worker_environment(run_id):
    env = {
        key: value for key, value in os.environ.items()
        if key in WORKER_ENV_KEYS
    }
    env["VERBS_FRESH_WORKER"] = "1"
    env["VERBS_FRESH_RUN_ID"] = run_id
    return env


def _claude_settings(cwd):
    return {
        "sandbox": {
            "enabled": True,
            "allowUnsandboxedCommands": False,
            "failIfUnavailable": True,
            "filesystem": {
                "denyWrite": [
                    str(cwd / ".agents"),
                    str(cwd / ".claude"),
                    str(cwd / ".codex"),
                    str(cwd / ".git"),
                ]
            },
        }
    }


def _git_workspace_baseline(cwd):
    top_level = _git_output(cwd, ["rev-parse", "--show-toplevel"])
    if Path(top_level).resolve() != cwd:
        raise FreshRunError(
            "workspace-write must run from the git repository root"
        )
    status = _git_output(
        cwd, ["status", "--porcelain=v1", "--untracked-files=all"]
    )
    if status:
        raise FreshRunError("workspace-write requires a clean git baseline")
    return {
        "head": _git_output(cwd, ["rev-parse", "HEAD"]),
        "ref": _git_output(cwd, ["symbolic-ref", "-q", "HEAD"], allow_one=True),
    }


def _verify_git_workspace_baseline(cwd, baseline):
    current = {
        "head": _git_output(cwd, ["rev-parse", "HEAD"]),
        "ref": _git_output(cwd, ["symbolic-ref", "-q", "HEAD"], allow_one=True),
    }
    if current != baseline:
        raise FreshRunError("worker changed git HEAD or branch ownership")


def _git_output(cwd, arguments, allow_one=False):
    try:
        completed = subprocess.run(
            ["git", "-C", str(cwd)] + arguments,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired):
        raise FreshRunError("workspace-write git preflight failed")
    allowed = {0, 1} if allow_one else {0}
    if completed.returncode not in allowed:
        raise FreshRunError("workspace-write requires a git repository")
    return completed.stdout.strip()


def _runtime_version(runtime, env):
    try:
        completed = subprocess.run(
            [runtime, "--version"],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.TimeoutExpired):
        return "unknown"
    return _bounded_text(completed.stdout, 256) or "unknown"


def _require_runtime_version(agent, output):
    match = re.search(r"(\d+)\.(\d+)\.(\d+)", output)
    if not match:
        raise FreshRunError("{} version is unparseable: {}".format(agent, output))
    found = tuple(int(part) for part in match.groups())
    required = MINIMUM_VERSIONS[agent]
    if found < required:
        raise FreshRunError(
            "{} {} is older than required {}".format(
                agent,
                ".".join(str(part) for part in found),
                ".".join(str(part) for part in required),
            )
        )


def _digest_json(value):
    encoded = json.dumps(
        value, separators=(",", ":"), sort_keys=True
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _bounded_text(value, limit=1024):
    return " ".join((value or "").split())[:limit]


def _failure_result(message, status="failed"):
    return {
        "status": status,
        "summary": "Fresh worker did not return an accepted result.",
        "evidence": [],
        "artifacts": [],
        "next_action": "Inspect the error and decide whether to dispatch a new run.",
        "errors": [_bounded_text(message)],
    }


def _emit(value):
    print(json.dumps(value, indent=2, sort_keys=True))
