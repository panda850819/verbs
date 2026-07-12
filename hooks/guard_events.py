#!/usr/bin/env python3
"""Append privacy-minimal Verbs guard decisions to one durable JSONL stream."""

import argparse
import datetime as dt
import json
import os
import sys
from pathlib import Path


SCHEMA = "verbs.guard-event.v1"
OFF_VALUES = {"off", "false", "0", "none"}


def _log_path():
    configured = os.environ.get("VERBS_GUARD_EVENT_LOG")
    if configured and configured.strip().lower() in OFF_VALUES:
        return None
    if configured:
        return Path(configured).expanduser()
    state_home = os.environ.get("XDG_STATE_HOME")
    if state_home:
        return Path(state_home).expanduser() / "verbs" / "guard-events.jsonl"
    return Path.home() / ".local" / "state" / "verbs" / "guard-events.jsonl"


def _runtime(payload):
    explicit = payload.get("runtime") or payload.get("host")
    if isinstance(explicit, str) and explicit:
        return explicit
    if payload.get("turn_id") or payload.get("thread_id"):
        return "codex"
    if payload.get("session_id"):
        return "claude"
    if os.environ.get("CODEX_SESSION_ID") or os.environ.get("CODEX_THREAD_ID"):
        return "codex"
    if os.environ.get("CLAUDECODE"):
        return "claude"
    return "unknown"


def _string(payload, *keys):
    for key in keys:
        value = payload.get(key)
        if isinstance(value, str) and value:
            return value
    return None


def _bounded(value, limit=512):
    if not isinstance(value, str):
        return None
    return value[:limit]


def append_guard_event(
    payload, hook, action, decision, reason_code, artifact_ref=None
):
    """Write one fsynced O_APPEND record. Returns True when disabled/written."""
    path = _log_path()
    if path is None:
        return True
    if not isinstance(payload, dict):
        payload = {}
    scope = _bounded(_string(payload, "cwd", "workdir"))
    event = {
        "schema": SCHEMA,
        "timestamp": dt.datetime.now(dt.timezone.utc).isoformat().replace(
            "+00:00", "Z"
        ),
        "runtime": _runtime(payload),
        "session_id": _bounded(
            _string(payload, "session_id", "thread_id"), 256
        ),
        "turn_id": _bounded(_string(payload, "turn_id"), 256),
        "hook": hook,
        "action": action,
        "authority_scope": scope,
        "decision": decision,
        "reason_code": reason_code,
        "artifact_ref": _bounded(artifact_ref),
    }
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_APPEND
    fd = os.open(str(path), flags, 0o600)
    try:
        line = json.dumps(
            event, ensure_ascii=False, separators=(",", ":"), sort_keys=True
        ).encode("utf-8") + b"\n"
        if len(line) > 4096:
            raise ValueError("guard event exceeds the atomic append limit")
        written = os.write(fd, line)
        if written != len(line):
            raise OSError("partial guard event append")
        os.fsync(fd)
    finally:
        os.close(fd)
    return True


def safe_append_guard_event(*args, **kwargs):
    try:
        return append_guard_event(*args, **kwargs)
    except Exception as exc:
        print(
            "[verbs guard-events] unavailable: {}; decision unchanged.".format(exc),
            file=sys.stderr,
        )
        return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hook", required=True)
    parser.add_argument("--action", required=True)
    parser.add_argument("--decision", required=True)
    parser.add_argument("--reason-code", required=True)
    parser.add_argument("--artifact-ref")
    args = parser.parse_args()
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw or "{}")
    except (TypeError, ValueError):
        payload = {}
    return 0 if safe_append_guard_event(
        payload,
        args.hook,
        args.action,
        args.decision,
        args.reason_code,
        args.artifact_ref,
    ) else 1


if __name__ == "__main__":
    sys.exit(main())
