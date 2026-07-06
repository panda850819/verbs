#!/usr/bin/env python3
"""Stop-hook verify gate for the pandastack plugin.

Blocks the session's first stop when the current turn edited code files but
never ran a test or verify command; the model gets one chance to run the
check or state the change is unverified. Soft gate: the second stop
(stop_hook_active=true) always passes, and any internal failure fails open
with exit 0 and no output — the gate must never break a session.

stdin: Claude Code Stop-hook JSON (transcript_path, stop_hook_active).
stdout: exactly one {"decision":"block","reason":...} object, or nothing.
Kill switch: PANDASTACK_VERIFY_GATE=off. Python 3.9+, stdlib only, no
network, no file writes. Design ported from fable-harness verify_gate.py
(MIT).
"""
import json
import os
import re
import sys
from pathlib import PurePath

CODE_EXTS = {
    ".py", ".ipynb", ".js", ".ts", ".tsx", ".jsx", ".mjs", ".cjs",
    ".sh", ".ps1", ".psm1", ".vbs",
    ".go", ".rs", ".java", ".c", ".cpp", ".h", ".hpp", ".cs", ".rb", ".sql", ".php",
}

# Test / verify commands across ecosystems, plus this repo's own conventions
# (bash tests/<x>.sh suites, bash scripts/lint-<x>.sh linters). Word/position
# anchors keep look-alikes out (make testdata, npm run testbed, cat tox.ini).
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

EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
SHELL_TOOLS = {"Bash", "PowerShell"}
LOCAL_COMMAND_PREFIXES = (
    "<command-name>", "<local-command-stdout>",
    "<local-command-stderr>", "<local-command-caveat>",
)

BLOCK_REASON = (
    "[pandastack verify-gate] code changed this turn with no test or verify "
    "run — run the relevant check, or state the change is not yet verified."
)


def is_real_user_prompt(entry):
    """A turn boundary is a user entry with plain-string content that is not
    a local-command echo. tool_result lists arrive as type=user too and must
    not count."""
    if entry.get("type") != "user":
        return False
    content = entry.get("message", {}).get("content")
    if not isinstance(content, str):
        return False
    return not content.lstrip().startswith(LOCAL_COMMAND_PREFIXES)


def iter_tool_uses(entries):
    for entry in entries:
        if entry.get("type") != "assistant":
            continue
        content = entry.get("message", {}).get("content")
        if not isinstance(content, list):
            continue
        for block in content:
            if isinstance(block, dict) and block.get("type") == "tool_use":
                yield block.get("name", ""), block.get("input", {}) or {}


def analyze(entries):
    """Return (code_edited, verified) for the window after the last real
    user prompt. A test run before that prompt is stale green and does not
    count — and a code edit AFTER the last test run resets verification
    (a green recorded before a change proves nothing about the code after
    it), so only a verify that follows the final code edit counts."""
    last_prompt_idx = -1
    for i, entry in enumerate(entries):
        if is_real_user_prompt(entry):
            last_prompt_idx = i
    code_edited = False
    verified = False
    for name, tool_input in iter_tool_uses(entries[last_prompt_idx + 1:]):
        if name in EDIT_TOOLS:
            path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
            if PurePath(path).suffix.lower() in CODE_EXTS:
                code_edited = True
                verified = False  # later edit voids the earlier green
        elif name in SHELL_TOOLS:
            if TEST_CMD_RE.search(tool_input.get("command", "")):
                verified = True
    return code_edited, verified


def main():
    try:
        if os.environ.get("PANDASTACK_VERIFY_GATE", "").strip().lower() == "off":
            return 0
        data = json.loads(sys.stdin.read() or "{}")
        if data.get("stop_hook_active"):
            return 0
        entries = []
        with open(data["transcript_path"], encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
        code_edited, verified = analyze(entries)
        if code_edited and not verified:
            print(json.dumps(
                {"decision": "block", "reason": BLOCK_REASON},
                ensure_ascii=False, separators=(",", ":")))
    except Exception:
        pass  # fail-open: a broken gate must never block the session
    return 0


if __name__ == "__main__":
    sys.exit(main())
