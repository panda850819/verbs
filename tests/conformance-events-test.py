#!/usr/bin/env python3
"""Fixture coverage for scripts/conformance_events.py."""

import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts/conformance_events.py"
ACTIVATION = "CAREFUL mode ON. Will confirm before destructive actions."
STYLE = "/tmp/plugins/cache/style/style/1.0.0/skills/style/SKILL.md"
CAREFUL = "/tmp/plugins/cache/verbs/verbs/0.23.2/skills/engineering/careful/SKILL.md"


def event(item_type, **fields):
    return {"type": "item.completed", "item": {"type": item_type, **fields}}


def run(host, events):
    payload = "".join(json.dumps(row) + "\n" for row in events)
    return subprocess.run(
        ["python3", str(CHECKER), host],
        input=payload,
        text=True,
        capture_output=True,
        check=False,
    ).returncode


def codex_base():
    return [event("agent_message", text=ACTIVATION), {"type": "turn.completed"}]


assert run("codex", codex_base()) == 0, "zero-tool Codex activation must pass"

readonly = [
    event(
        "command_execution",
        command=(
            f'/bin/zsh -lc "sed -n \'1,240p\' {STYLE} && '
            f"sed -n '1,240p' {CAREFUL}\""
        ),
        status="completed",
        exit_code=0,
    ),
    event(
        "command_execution",
        command=f"/bin/zsh -lc 'pwd; wc -l {STYLE}; /bin/cat {STYLE}'",
        status="completed",
        exit_code=0,
    ),
] + codex_base()
assert run("codex", readonly) == 0, "bounded skill-file reads must pass"

no_careful = [
    event(
        "command_execution",
        command=f"/bin/zsh -lc 'cat {STYLE}'",
        status="completed",
        exit_code=0,
    )
] + codex_base()
assert run("codex", no_careful) == 0, "unrelated read-only skill loading must pass"

non_skill_read = [
    event(
        "command_execution",
        command="/bin/zsh -lc 'cat /etc/hosts'",
        status="completed",
        exit_code=0,
    )
] + codex_base()
assert run("codex", non_skill_read) != 0, "arbitrary file reads must fail"

write_command = [
    event(
        "command_execution",
        command=f"/bin/zsh -lc 'cat {CAREFUL} > /tmp/copied-skill'",
        status="completed",
        exit_code=0,
    )
] + codex_base()
assert run("codex", write_command) != 0, "write-capable shell must fail"

failed_command = [
    event(
        "command_execution",
        command=f"/bin/zsh -lc 'cat {CAREFUL}'",
        status="failed",
        exit_code=1,
    )
] + codex_base()
assert run("codex", failed_command) != 0, "failed skill read must fail"

pending_command = [
    {
        "type": "item.started",
        "item": {
            "id": "pending",
            "type": "command_execution",
            "command": f"/bin/zsh -lc 'cat {CAREFUL}'",
        },
    }
] + codex_base()
assert run("codex", pending_command) != 0, "unfinished skill read must fail"

paired_command = [
    {
        "type": "item.started",
        "item": {
            "id": "paired",
            "type": "command_execution",
            "command": f"/bin/zsh -lc 'cat {CAREFUL}'",
        },
    },
    {
        "type": "item.completed",
        "item": {
            "id": "paired",
            "type": "command_execution",
            "command": f"/bin/zsh -lc 'cat {CAREFUL}'",
            "status": "completed",
            "exit_code": 0,
        },
    },
] + codex_base()
assert run("codex", paired_command) == 0, "completed skill read must pass"

for tool_type in (
    "file_change",
    "mcp_tool_call",
    "web_search",
    "image_generation",
    "dynamic_tool_call",
    "tool_call",
):
    assert run("codex", [event(tool_type)] + codex_base()) != 0, tool_type

assert run("codex", [event("agent_message", text="wrong"), {"type": "turn.completed"}]) != 0
assert run(
    "codex",
    [
        event("agent_message", text=ACTIVATION),
        event("agent_message", text=ACTIVATION),
        {"type": "turn.completed"},
    ],
) != 0
assert run("codex", [event("agent_message", text=ACTIVATION)]) != 0

claude_ok = [
    {
        "type": "assistant",
        "message": {
            "content": [
                {
                    "type": "tool_use",
                    "name": "Skill",
                    "input": {"skill": "verbs:careful"},
                }
            ]
        },
    },
    {
        "type": "user",
        "tool_use_result": {"success": True, "commandName": "verbs:careful"},
    },
    {"type": "result", "subtype": "success", "result": ACTIVATION},
]
assert run("claude", claude_ok) == 0, "Claude proof contract changed"
assert run("claude", claude_ok[:-1]) != 0
assert run("unknown", []) == 2

print("conformance event fixtures: ok")
