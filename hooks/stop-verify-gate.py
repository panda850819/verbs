#!/usr/bin/env python3
"""Stop-hook verify gate for Verbs.

Blocks the session's first stop when the current turn edited code files but
never ran a test or verify command; the model gets one chance to run the
check or state the change is unverified. The second stop
(stop_hook_active=true) passes to prevent a hook loop. Missing/malformed
verification infrastructure fails closed with a visible block; pure Q&A and
turns with no successful code edit still pass. A transcript_path whose file
is null or whose file does not exist is a transcriptless run (Codex side
conversation, codex exec, install smoke tests). Blocking there can produce no
verification behavior, so the gate allows with a stderr notice and a
high-signal guard event instead.

stdin: Claude Code or Codex Stop-hook JSON (transcript_path, stop_hook_active).
stdout: exactly one {"decision":"block","reason":...} object, or nothing.
Kill switch: VERBS_VERIFY_GATE=off. During the 0.x release line, the adapter
also reads the legacy PANDA_VERBS_VERIFY_GATE and PANDASTACK_VERIFY_GATE names
when the canonical variable is unset. Python 3.9+, stdlib only, no network, no
append-only guard evidence. Design ported from fable-harness verify_gate.py
(MIT).
"""
import json
import os
import sys
import tempfile
from pathlib import Path

try:
    from runtime_events import current_turn_events, is_code_path
    RUNTIME_IMPORT_OK = True
except Exception:
    RUNTIME_IMPORT_OK = False

try:
    from guard_events import safe_append_guard_event
    GUARD_EVENTS_IMPORT_OK = True
except Exception:
    GUARD_EVENTS_IMPORT_OK = False

BLOCK_REASON = (
    "[verbs verify-gate] code changed this turn with no test or verify "
    "run — run the relevant check, or state the change is not yet verified."
)
FAIL_CLOSED_REASON = (
    "[verbs verify-gate] unavailable: malformed or missing hook input; "
    "blocking stop until verification evidence is readable."
)
RUNTIME_FAIL_CLOSED_REASON = (
    "[verbs verify-gate] unavailable: runtime event adapter missing; "
    "blocking once. State that verification is unavailable and reinstall Verbs."
)
TRANSCRIPT_MISSING_NOTICE = (
    "[verbs verify-gate] transcript unavailable; assuming a transcriptless "
    "run; skipping verify gate."
)


def record(payload, decision, reason_code):
    level = os.environ.get("VERBS_GUARD_EVENT_LEVEL", "").strip().lower()
    high_signal_allow = reason_code in ("kill_switch_off", "transcript_missing")
    if decision == "allow" and level != "all" and not high_signal_allow:
        return
    if GUARD_EVENTS_IMPORT_OK:
        safe_append_guard_event(
            payload,
            "Stop",
            "verify-gate",
            decision,
            reason_code,
        )
    else:
        print(
            "[verbs guard-events] unavailable: event helper missing; "
            "decision unchanged.",
            file=sys.stderr,
        )


def block(payload, reason, reason_code):
    record(payload, "deny", reason_code)
    print(json.dumps(
        {"decision": "block", "reason": reason},
        ensure_ascii=False, separators=(",", ":")))


def allow(payload, reason_code):
    record(payload, "allow", reason_code)


def failure_marker_path():
    configured = os.environ.get("VERBS_VERIFY_GATE_FAILURE_MARKER")
    if configured:
        return Path(configured)
    return Path(tempfile.gettempdir()) / (
        "verbs-verify-gate-failure-{}.marker".format(os.getppid())
    )


def clear_failure_marker():
    try:
        failure_marker_path().unlink()
    except FileNotFoundError:
        pass
    except OSError:
        pass


def claim_failure_block():
    """True once per consecutive infrastructure failure, then allow once."""
    path = failure_marker_path()
    try:
        path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        fd = os.open(str(path), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        os.close(fd)
        return True
    except FileExistsError:
        clear_failure_marker()
        return False
    except OSError:
        return False


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
    data = {}
    try:
        gate_setting = os.environ.get("VERBS_VERIFY_GATE")
        if gate_setting is None:
            gate_setting = os.environ.get("PANDA_VERBS_VERIFY_GATE")
        if gate_setting is None:
            gate_setting = os.environ.get("PANDASTACK_VERIFY_GATE", "")
        if gate_setting.strip().lower() == "off":
            allow(data, "kill_switch_off")
            return 0
        data = json.loads(sys.stdin.read() or "{}")
        if not isinstance(data, dict):
            raise ValueError("hook payload must be an object")
        clear_failure_marker()
        if data.get("stop_hook_active"):
            allow(data, "loop_prevention")
            return 0
        if not RUNTIME_IMPORT_OK:
            block(data, RUNTIME_FAIL_CLOSED_REASON, "runtime_adapter_missing")
            return 0
        transcript_path = data.get("transcript_path")
        if transcript_path is None and "transcript_path" in data:
            print(TRANSCRIPT_MISSING_NOTICE, file=sys.stderr)
            allow(data, "transcript_missing")
            return 0
        if not isinstance(transcript_path, str) or not transcript_path:
            raise ValueError("missing transcript_path")
        entries = []
        malformed_lines = 0
        try:
            transcript = open(transcript_path, encoding="utf-8")
        except FileNotFoundError:
            print(TRANSCRIPT_MISSING_NOTICE, file=sys.stderr)
            allow(data, "transcript_missing")
            return 0
        with transcript as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    malformed_lines += 1
                    continue
        if malformed_lines:
            raise ValueError("transcript contains malformed events")
        code_edited, verified = analyze(entries, data)
        if code_edited and not verified:
            block(data, BLOCK_REASON, "code_edit_unverified")
        elif code_edited:
            allow(data, "code_edit_verified")
        else:
            allow(data, "no_code_edit")
    except Exception:
        if claim_failure_block():
            block(data, FAIL_CLOSED_REASON, "verification_input_unavailable")
        else:
            allow(data, "failure_loop_prevention")
    return 0


if __name__ == "__main__":
    sys.exit(main())
