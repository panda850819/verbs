#!/usr/bin/env python3
"""Validate one host's JSONL invocation evidence for conformance-smoke.sh."""

import json
import os
import re
import shlex
import sys


ACTIVATION = "CAREFUL mode ON. Will confirm before destructive actions."
FORBIDDEN_CODEX_TOOL_TYPES = {
    "file_change",
    "mcp_tool_call",
    "web_search",
    "image_generation",
    "dynamic_tool_call",
    "tool_call",
}


def load_events(stream):
    events = []
    for raw in stream:
        try:
            events.append(json.loads(raw))
        except json.JSONDecodeError:
            pass
    return events


def skill_path(token):
    return (
        token.startswith("/")
        and token.endswith("/SKILL.md")
        and "/skills/" in token
    )


def readonly_skill_command(command):
    """Return whether a command is a bounded read of skill files."""
    try:
        outer = shlex.split(command)
    except ValueError:
        return False
    if (
        len(outer) == 3
        and os.path.basename(outer[0]) in {"bash", "sh", "zsh"}
        and outer[1] == "-lc"
    ):
        script = outer[2]
    else:
        script = command

    if any(mark in script for mark in ("||", "|", ">", "<", "`", "$(", "\n")):
        return False

    segments = re.split(r"\s*(?:&&|;)\s*", script)
    for segment in segments:
        if not segment:
            continue
        try:
            words = shlex.split(segment)
        except ValueError:
            return False
        if not words:
            continue
        name = os.path.basename(words[0])
        paths = []
        if name == "pwd" and len(words) == 1:
            continue
        if name == "sed" and len(words) >= 4 and words[1] == "-n":
            if not re.fullmatch(r"\d+(?:,\d+)?p", words[2]):
                return False
            paths = words[3:]
        elif name == "wc" and len(words) >= 3 and words[1] == "-l":
            paths = words[2:]
        elif name == "cat" and len(words) >= 2:
            paths = words[1:]
        else:
            return False
        if not paths or not all(skill_path(path) for path in paths):
            return False
    return True


def check_claude(events):
    called = any(
        item.get("type") == "tool_use"
        and item.get("name") == "Skill"
        and item.get("input", {}).get("skill") == "verbs:careful"
        for event in events
        if event.get("type") == "assistant"
        for item in event.get("message", {}).get("content", [])
    )
    launched = any(
        event.get("type") == "user"
        and event.get("tool_use_result", {}).get("success") is True
        and event.get("tool_use_result", {}).get("commandName") == "verbs:careful"
        for event in events
    )
    completed = any(
        event.get("type") == "result"
        and event.get("subtype") == "success"
        and event.get("result") == ACTIVATION
        for event in events
    )
    return called and launched and completed


def check_codex(events):
    messages = [
        event.get("item", {}).get("text")
        for event in events
        if event.get("type") == "item.completed"
        and event.get("item", {}).get("type") == "agent_message"
    ]
    if messages != [ACTIVATION]:
        return False
    if not any(event.get("type") == "turn.completed" for event in events):
        return False

    started_commands = set()
    completed_commands = set()
    for event in events:
        event_type = event.get("type")
        if event_type not in {"item.started", "item.completed"}:
            continue
        item = event.get("item", {})
        item_type = item.get("type")
        if item_type in FORBIDDEN_CODEX_TOOL_TYPES:
            return False
        if item_type != "command_execution":
            continue
        command = item.get("command", "")
        if not readonly_skill_command(command):
            return False
        key = item.get("id") or command
        if event_type == "item.started":
            started_commands.add(key)
            continue
        if item.get("status") != "completed" or item.get("exit_code") != 0:
            return False
        completed_commands.add(key)

    return started_commands <= completed_commands


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in {"claude", "codex"}:
        print("usage: conformance_events.py <claude|codex>", file=sys.stderr)
        return 2
    events = load_events(sys.stdin)
    ok = check_claude(events) if sys.argv[1] == "claude" else check_codex(events)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
