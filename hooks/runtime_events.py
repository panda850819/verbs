#!/usr/bin/env python3
"""Normalize Claude Code and Codex hook events for the Stop verify gate."""

from dataclasses import dataclass
import json
import os
from pathlib import Path, PurePath
import re
import shlex
from typing import Any, Dict, List, Optional, Sequence, Tuple


CODE_EXTS = {
    ".py", ".ipynb", ".js", ".ts", ".tsx", ".jsx", ".mjs", ".cjs",
    ".sh", ".bash", ".zsh", ".ps1", ".psm1", ".vbs",
    ".go", ".rs", ".java", ".c", ".cc", ".cpp", ".h", ".hpp",
    ".cs", ".rb", ".sql", ".php", ".swift", ".kt", ".lua", ".pl",
}

TEST_CMD_RE = re.compile(
    r"((^|[;&|\n]\s*)(uv\s+run\s+|poetry\s+run\s+)?pytest\b"
    r"|python[3]?(\.exe)?\s+-m\s+pytest\b"
    r"|python[3]?(\.exe)?\s+(-m\s+unittest|(\S*[/\\])?(test\S*\.py|\S*_test\.py))"
    r"|npm\s+(run\s+)?test\b|yarn\s+test\b|pnpm\s+(run\s+)?test\b|bun\s+test\b|node\s+--test"
    r"|go\s+test|cargo\s+test"
    r"|(^|[;&|\n]\s*)(npx\s+|bunx\s+|yarn\s+|pnpm\s+)?(vitest|jest)\b"
    r"|mvnw?(\.cmd)?\s+(\S+\s+)*test(\s|$)|gradlew?(\.bat)?\s+(\S+\s+)*test(\s|$)|dotnet\s+test(\s|$)"
    r"|\brspec\b|\bphpunit\b|\bctest\b|make\s+test\b|rake\s+(\S+\s+)*test\b|mix\s+test\b"
    r"|(^|[;&|]\s*)(tox|nox)\b|deno\s+test|rails\s+test"
    r"|\b(ba)?sh\s+(\S*[/\\])?tests?[/\\]\S+\.sh"
    r"|\b(ba)?sh\s+(\S*[/\\])?lint-\S+\.sh)",
    re.IGNORECASE,
)

VERIFY_NOOP_RE = re.compile(
    r"(?:^|\s)(?:--help|--version|--collect-only|--co|--listTests|--no-run|-h|-V)(?:\s|$)",
    re.IGNORECASE,
)
VERIFY_SINGLE_PIPE_RE = re.compile(r"(?<!\|)\|(?!\|)")
VERIFY_BACKGROUND_AMP_RE = re.compile(r"(?<![<>&])&(?![>&0-9])")

CLAUDE_EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
CLAUDE_SHELL_TOOLS = {"Bash", "PowerShell"}
LOCAL_COMMAND_PREFIXES = (
    "<command-name>", "<local-command-stdout>",
    "<local-command-stderr>", "<local-command-caveat>",
)
PATCH_PATH_RE = re.compile(r"^\*\*\* (?:Add|Update|Delete) File:\s*(.+?)\s*$")
PATCH_MOVE_RE = re.compile(r"^\*\*\* Move to:\s*(.+?)\s*$")
EXIT_CODE_RE = re.compile(r"^Process exited with code\s+(-?\d+)\s*$", re.I | re.M)
SESSION_ID_RES = (
    re.compile(r"Process running with session ID\s+(\d+)", re.I),
    re.compile(r"session_id[\"']?\s*[:=]\s*[\"']?(\d+)", re.I),
)


@dataclass(frozen=True)
class RuntimeEvent:
    kind: str
    call_id: str
    success: Optional[bool]
    paths: Tuple[str, ...] = ()
    command: str = ""


def is_code_path(path: str) -> bool:
    return PurePath(path).suffix.lower() in CODE_EXTS


def is_verify_command(command: str) -> bool:
    """Return true only when a recognized runner controls shell status."""
    match = TEST_CMD_RE.search(command)
    if not match or VERIFY_NOOP_RE.search(command):
        return False
    if "||" in command:
        return False

    suffix = command[match.end():]
    if re.search(r"(?:;|\n)\s*\S", suffix):
        return False
    if VERIFY_BACKGROUND_AMP_RE.search(suffix):
        return False
    if VERIFY_SINGLE_PIPE_RE.search(suffix):
        return False
    return True


def _absolute_path(path: str, cwd: str) -> str:
    expanded = Path(path).expanduser()
    if not expanded.is_absolute():
        expanded = Path(cwd or os.getcwd()) / expanded
    return str(expanded.resolve(strict=False))


def parse_patch_paths(command: str, cwd: str) -> List[str]:
    """Return all source and destination paths declared by an apply_patch."""
    paths: List[str] = []
    for line in command.splitlines():
        match = PATCH_PATH_RE.match(line) or PATCH_MOVE_RE.match(line)
        if match:
            path = _absolute_path(match.group(1), cwd)
            if path not in paths:
                paths.append(path)
    return paths


def normalize_pretool(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Normalize a PreToolUse payload without applying policy."""
    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {})
    cwd = payload.get("cwd") or os.getcwd()
    paths: List[str] = []

    if tool_name in CLAUDE_EDIT_TOOLS and isinstance(tool_input, dict):
        direct = tool_input.get("file_path") or tool_input.get("notebook_path")
        if isinstance(direct, str) and direct:
            paths.append(_absolute_path(direct, cwd))
        edits = tool_input.get("edits")
        if isinstance(edits, list):
            for edit in edits:
                if not isinstance(edit, dict):
                    continue
                path = edit.get("file_path") or edit.get("notebook_path")
                if isinstance(path, str) and path:
                    absolute = _absolute_path(path, cwd)
                    if absolute not in paths:
                        paths.append(absolute)
    elif tool_name == "apply_patch":
        if isinstance(tool_input, dict):
            command = (
                tool_input.get("command")
                or tool_input.get("patch")
                or tool_input.get("input")
                or ""
            )
        else:
            command = tool_input
        if isinstance(command, str):
            paths = parse_patch_paths(command, cwd)
    else:
        return {"kind": "other", "tool_name": tool_name, "paths": []}

    return {"kind": "edit", "tool_name": tool_name, "paths": paths}


def _is_real_claude_prompt(entry: Dict[str, Any]) -> bool:
    if entry.get("type") != "user":
        return False
    if entry.get("isMeta") is True:
        return False
    content = entry.get("message", {}).get("content")
    if isinstance(content, str):
        return not content.lstrip().startswith(LOCAL_COMMAND_PREFIXES)
    if isinstance(content, list):
        # A genuine user turn may arrive block-form (image paste, image+text,
        # or text blocks). It is a real prompt when it carries a non-tool_result
        # block; a tool_result-only entry is tool output, not a new turn.
        found = False
        for block in content:
            if not isinstance(block, dict):
                continue
            block_type = block.get("type")
            if block_type == "tool_result":
                continue
            if block_type == "text":
                text = block.get("text", "")
                if isinstance(text, str) and not text.lstrip().startswith(LOCAL_COMMAND_PREFIXES):
                    found = True
            else:
                found = True
        return found
    return False


def _claude_window(entries: Sequence[Dict[str, Any]]) -> Sequence[Dict[str, Any]]:
    start = 0
    for index, entry in enumerate(entries):
        if _is_real_claude_prompt(entry):
            start = index + 1
    return entries[start:]


def _claude_events(
    entries: Sequence[Dict[str, Any]], hook_payload: Dict[str, Any]
) -> List[RuntimeEvent]:
    calls: List[Tuple[str, Dict[str, Any]]] = []
    outcomes: Dict[str, bool] = {}
    background: set = set()
    cwd = hook_payload.get("cwd") or os.getcwd()

    for entry in _claude_window(entries):
        entry_type = entry.get("type")
        content = entry.get("message", {}).get("content")
        if entry_type == "assistant" and isinstance(content, list):
            for block in content:
                if not isinstance(block, dict) or block.get("type") != "tool_use":
                    continue
                name = block.get("name", "")
                tool_input = block.get("input", {}) or {}
                call_id = block.get("id", "")
                if name in CLAUDE_EDIT_TOOLS or name == "apply_patch":
                    intent = normalize_pretool({
                        "tool_name": name, "tool_input": tool_input, "cwd": cwd,
                    })
                    calls.append((call_id, {
                        "kind": "edit", "paths": tuple(intent["paths"]), "command": "",
                    }))
                elif name in CLAUDE_SHELL_TOOLS and isinstance(tool_input, dict):
                    command = tool_input.get("command", "")
                    if isinstance(command, str) and is_verify_command(command):
                        # A backgrounded run returns only a launch ack, not the
                        # runner's exit status, so its outcome is unknown — mirror
                        # the Codex still-running path and keep success=None.
                        if tool_input.get("run_in_background"):
                            background.add(call_id)
                        calls.append((call_id, {
                            "kind": "verify", "paths": (), "command": command,
                        }))
        elif entry_type == "user" and isinstance(content, list):
            for block in content:
                if not isinstance(block, dict) or block.get("type") != "tool_result":
                    continue
                call_id = block.get("tool_use_id", "")
                outcomes[call_id] = not bool(block.get("is_error", False))

    return [
        RuntimeEvent(
            kind=data["kind"], call_id=call_id,
            success=None if call_id in background else outcomes.get(call_id),
            paths=data["paths"], command=data["command"],
        )
        for call_id, data in calls
    ]


def _json_dict(value: Any) -> Dict[str, Any]:
    if isinstance(value, dict):
        return value
    if isinstance(value, str):
        try:
            parsed = json.loads(value)
        except json.JSONDecodeError:
            return {}
        if isinstance(parsed, dict):
            return parsed
    return {}


def _command_text(value: Any) -> str:
    if isinstance(value, str):
        return value
    if isinstance(value, list) and all(isinstance(part, str) for part in value):
        return shlex.join(value)
    return ""


def _extract_exit_code(output: Any) -> Optional[int]:
    if isinstance(output, dict):
        for key in ("exit_code", "exitCode", "return_code", "returnCode"):
            value = output.get(key)
            if isinstance(value, int):
                return value
        for value in output.values():
            code = _extract_exit_code(value)
            if code is not None:
                return code
        return None
    if not isinstance(output, str):
        return None
    match = EXIT_CODE_RE.search(output)
    if match:
        return int(match.group(1))
    return None


def _extract_session_id(output: Any) -> Optional[str]:
    if isinstance(output, dict):
        value = output.get("session_id") or output.get("sessionId")
        if isinstance(value, (str, int)):
            return str(value)
        for nested in output.values():
            session_id = _extract_session_id(nested)
            if session_id is not None:
                return session_id
        return None
    if not isinstance(output, str):
        return None
    try:
        parsed = json.loads(output)
    except json.JSONDecodeError:
        parsed = None
    if parsed is not None and parsed != output:
        session_id = _extract_session_id(parsed)
        if session_id is not None:
            return session_id
    for pattern in SESSION_ID_RES:
        match = pattern.search(output)
        if match:
            return match.group(1)
    return None


def _codex_window(
    entries: Sequence[Dict[str, Any]], hook_payload: Dict[str, Any]
) -> Sequence[Dict[str, Any]]:
    contexts = [
        (index, entry.get("payload", {}).get("turn_id"))
        for index, entry in enumerate(entries)
        if entry.get("type") == "turn_context"
    ]
    if not contexts:
        return entries

    selected = hook_payload.get("turn_id") or contexts[-1][1]
    if selected is None:
        return entries[contexts[-1][0] + 1:]
    matching = [index for index, entry_turn in contexts if entry_turn == selected]
    if not matching:
        return []
    # Compaction may repeat a context for the same turn. Preserve events from
    # its first boundary and stop only when a different turn begins.
    start = matching[0] + 1
    end = len(entries)
    for index in range(start, len(entries)):
        if entries[index].get("type") == "turn_context" and \
                entries[index].get("payload", {}).get("turn_id") != selected:
            end = index
            break
    return entries[start:end]


def _codex_events(
    entries: Sequence[Dict[str, Any]], hook_payload: Dict[str, Any]
) -> List[RuntimeEvent]:
    calls: List[Tuple[str, Dict[str, Any]]] = []
    outputs: Dict[str, Any] = {}
    patch_outcomes: Dict[str, bool] = {}
    exec_outcomes: Dict[str, bool] = {}
    write_calls: List[Tuple[str, str]] = []
    direct_edit_ids = set()
    cwd = hook_payload.get("cwd") or os.getcwd()

    for entry in _codex_window(entries, hook_payload):
        entry_type = entry.get("type")
        payload = entry.get("payload", {})
        if entry_type == "response_item" and isinstance(payload, dict):
            item_type = payload.get("type")
            call_id = payload.get("call_id", "")
            name = payload.get("name", "")
            if item_type == "custom_tool_call" and name == "apply_patch":
                intent = normalize_pretool({
                    "tool_name": "apply_patch",
                    "tool_input": {"command": payload.get("input", "")},
                    "cwd": cwd,
                })
                calls.append((call_id, {
                    "kind": "edit", "paths": tuple(intent["paths"]), "command": "",
                }))
                direct_edit_ids.add(call_id)
            elif item_type == "function_call":
                arguments = _json_dict(payload.get("arguments"))
                if name == "apply_patch":
                    command = arguments.get("command") or arguments.get("patch") or ""
                    intent = normalize_pretool({
                        "tool_name": "apply_patch",
                        "tool_input": {"command": command},
                        "cwd": cwd,
                    })
                    calls.append((call_id, {
                        "kind": "edit", "paths": tuple(intent["paths"]), "command": "",
                    }))
                    direct_edit_ids.add(call_id)
                elif name == "exec_command":
                    command = _command_text(arguments.get("cmd") or arguments.get("command"))
                    if command and is_verify_command(command):
                        calls.append((call_id, {
                            "kind": "verify", "paths": (), "command": command,
                        }))
                elif name == "write_stdin":
                    session_id = arguments.get("session_id") or arguments.get("sessionId")
                    if isinstance(session_id, (str, int)):
                        write_calls.append((call_id, str(session_id)))
            elif item_type in {"function_call_output", "custom_tool_call_output"}:
                outputs[call_id] = payload.get("output")
        elif entry_type == "event_msg" and isinstance(payload, dict):
            call_id = payload.get("call_id", "")
            if payload.get("type") == "patch_apply_end" and isinstance(payload.get("success"), bool):
                if call_id in direct_edit_ids:
                    patch_outcomes[call_id] = payload["success"]
                else:
                    # Codex App wraps nested apply_patch in custom_tool_call
                    # name=exec, so its patch event has a different call ID.
                    changes = payload.get("changes")
                    if isinstance(changes, dict) and changes:
                        paths = tuple(
                            _absolute_path(str(path), cwd) for path in changes
                        )
                        calls.append((call_id, {
                            "kind": "edit", "paths": paths, "command": "",
                            "success": payload["success"],
                        }))
            elif payload.get("type") == "exec_command_end":
                code = _extract_exit_code(payload)
                if code is not None:
                    exec_outcomes[call_id] = code == 0

    session_outcomes: Dict[str, bool] = {}
    for call_id, session_id in write_calls:
        output = outputs.get(call_id)
        if _extract_session_id(output) is not None:
            continue
        code = _extract_exit_code(output)
        if code is not None:
            session_outcomes[session_id] = code == 0

    for call_id, data in calls:
        if data["kind"] != "verify" or call_id in exec_outcomes:
            continue
        output = outputs.get(call_id)
        session_id = _extract_session_id(output)
        if session_id is not None:
            if session_id in session_outcomes:
                exec_outcomes[call_id] = session_outcomes[session_id]
            continue
        code = _extract_exit_code(output)
        if code is not None:
            exec_outcomes[call_id] = code == 0

    events: List[RuntimeEvent] = []
    for call_id, data in calls:
        success = data.get("success")
        if success is None:
            success = (
                patch_outcomes.get(call_id)
                if data["kind"] == "edit"
                else exec_outcomes.get(call_id)
            )
        events.append(RuntimeEvent(
            kind=data["kind"], call_id=call_id, success=success,
            paths=data["paths"], command=data["command"],
        ))
    return events


def current_turn_events(
    entries: Sequence[Dict[str, Any]], hook_payload: Dict[str, Any]
) -> List[RuntimeEvent]:
    """Return ordered edit/verify events for the current runtime turn."""
    if any(entry.get("type") in {"turn_context", "response_item"} for entry in entries):
        return _codex_events(entries, hook_payload)
    return _claude_events(entries, hook_payload)
