#!/usr/bin/env python3
"""Stop-hook verify gate for the pandastack plugin.

Blocks the session's first stop when the current turn edited code files but
never ran a test or verify command; the model gets one chance to run the
check or state the change is unverified. Soft gate: the second stop
(stop_hook_active=true) always passes, and any internal failure fails open
with exit 0 and no output — the gate must never break a session.

stdin: Claude Code or Codex Stop-hook JSON (transcript_path, stop_hook_active).
stdout: exactly one {"decision":"block","reason":...} object, or nothing.
Kill switch: PANDASTACK_VERIFY_GATE=off. Python 3.9+, stdlib only, no
network, no file writes. Design ported from fable-harness verify_gate.py
(MIT).
"""
import json
import os
import sys

from runtime_events import current_turn_events, is_code_path

BLOCK_REASON = (
    "[pandastack verify-gate] code changed this turn with no test or verify "
    "run — run the relevant check, or state the change is not yet verified."
)


def analyze(entries, hook_payload=None):
    """Return (code_edited, verified) for the window after the last real
    user prompt. A test run before that prompt is stale green and does not
    count — and a code edit AFTER the last test run resets verification
    (a green recorded before a change proves nothing about the code after
    it), so only a verify that follows the final code edit counts."""
    code_edited = False
    verified = False
    for event in current_turn_events(entries, hook_payload or {}):
        if event.kind == "edit":
            if event.success is True and any(is_code_path(path) for path in event.paths):
                code_edited = True
                verified = False  # later edit voids the earlier green
        elif event.kind == "verify" and code_edited:
            # A failed later verify invalidates an earlier green. Unknown/custom
            # wrappers never become green because their success is None.
            verified = event.success is True
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
        code_edited, verified = analyze(entries, data)
        if code_edited and not verified:
            print(json.dumps(
                {"decision": "block", "reason": BLOCK_REASON},
                ensure_ascii=False, separators=(",", ":")))
    except Exception:
        pass  # fail-open: a broken gate must never block the session
    return 0


if __name__ == "__main__":
    sys.exit(main())
