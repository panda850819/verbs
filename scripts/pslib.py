"""Shared lifecycle + readiness logic for pandastack-drive and pandastack-linear-reduce.

Single source for the Linear state<->phase map, per-phase readiness, acceptance
parsing, work-order completeness, and the codex RESULT parser — so the reduce
(decision core) and drive (executor) cannot drift (review finding K).
"""
import os
import re

# Linear workflow state -> pandastack 7-phase (docs/linear-contract.md lifecycle-map),
# incl. the stock-state fallback (Todo / In Progress) for teams without custom states.
STATE_PHASE = {"Backlog": "DEFINE", "Planning": "PLAN", "Needs Decision": "GATE",
               "Building": "BUILD", "Verifying": "VERIFY", "In Review": "REVIEW", "Done": "SHIP"}
STOCK_FALLBACK = {"Todo": "PLAN", "In Progress": "BUILD"}
NEXT_PHASE = {"DEFINE": "PLAN", "PLAN": "GATE", "GATE": "BUILD", "BUILD": "VERIFY",
              "VERIFY": "REVIEW", "REVIEW": "SHIP", "SHIP": "(done)"}

_ACC_RE = re.compile(r"```acceptance\s*\n(.+?)\n```", re.DOTALL)
_EVIDENCE_RE = re.compile(r"```evidence\s*\n(.+?)\n```", re.DOTALL)
# a machine-checkable acceptance reads like a runnable check, not human prose
# ("語音聽起來自然"). Heuristic; upgrade: a structured acceptance schema.
_RUNNABLE_HINT = re.compile(
    r"[`]|[<>=]=|\b(tests?|runs?|exit|assert|grep|prints?|returns?|equals?|status|"
    r"curl|https?|node|python\d?|pytest|npm|pnpm|cargo|go|make|sh|bash|true|false|"
    r"stdout|stderr|output|\d{3})\b", re.I)
# work-order field labels — tolerate leading markdown markers (## Goal, **Goal:**, - Goal:)
_GOAL_RE = re.compile(r"(?im)^[\s#*\->]*goal\b")
_CONTEXT_RE = re.compile(r"(?im)^[\s#*\->]*context\b")
# a real diff/artifact ref (URL / path / branch / sha), NOT bare prose like "PR 5"
_ARTIFACT_RE = re.compile(r"(https?://\S+|/pull/\d+|/merge_requests/\d+|psdrive/\S+|\b[0-9a-f]{7,40}\b)")
# verdict: own line, word-boundaried, PASS|FAIL|BLOCKED only (not PASSED)
_RESULT_RE = re.compile(r"^\s*RESULT:\s*(PASS|FAIL|BLOCKED)\b\s*[—-]?\s*(.*)$", re.M)


def phase_of(state):
    return STATE_PHASE.get(state) or STOCK_FALLBACK.get(state)


def next_phase(state):
    return NEXT_PHASE.get(phase_of(state) or "")


def acceptance_block(desc):
    m = _ACC_RE.search(desc or "")
    return m.group(1).strip() if m else ""


def acceptance_runnable(desc):
    """Acceptance block present AND looks machine-checkable (not human prose)."""
    b = acceptance_block(desc)
    return bool(b and _RUNNABLE_HINT.search(b))


def evidence_block(desc):
    m = _EVIDENCE_RE.search(desc or "")
    return m.group(1).strip() if m else ""


def evidence_named(desc):
    b = evidence_block(desc)
    return len(b.split()) >= 2


def acceptance_lane(desc):
    if acceptance_runnable(desc):
        return "machine"
    if evidence_named(desc):
        return "evidence"
    return None


def readiness_gap(state, desc):
    """Per-phase readiness keyed on the TO-RUN (next) phase — the input the driver
    actually consumes (review finding D). VERIFY (next, from Building) needs a runnable
    acceptance or named evidence block; REVIEW (next, from Verifying) needs a
    diff/artifact. PLAN (next, grill) bootstraps from a title, so it is not gated
    — grill self-reports BLOCKED if it cannot plan. GATE/SHIP-next are human steps,
    no machine readiness."""
    nxt = next_phase(state)
    desc = desc or ""
    if nxt == "VERIFY" and not acceptance_lane(desc):
        return "next=VERIFY: missing runnable acceptance or named evidence"
    if nxt == "REVIEW" and not _ARTIFACT_RE.search(desc):
        return "next=REVIEW: missing diff/artifact"
    return None


def work_order_complete(desc):
    """BUILD autonomy conditions 2+3 (driver-autonomy.md): Goal AND Context AND a
    runnable acceptance. Matches the PLAN gate's AND and the doc's runnable requirement."""
    desc = desc or ""
    return bool(_GOAL_RE.search(desc) and _CONTEXT_RE.search(desc) and acceptance_runnable(desc))


def parse_result(output, returncode=0):
    """Parse a codex RESULT verdict robustly: a nonzero exit is an executor ERROR;
    otherwise take the LAST RESULT line (a model may restate it while reasoning),
    word-boundaried so 'PASSED' never reads as PASS, and only from a line-start
    RESULT: token so an echoed prompt/description string cannot spoof it."""
    if returncode != 0:
        return "ERROR", f"codex exited {returncode}"
    ms = list(_RESULT_RE.finditer(output or ""))
    if not ms:
        return "UNKNOWN", (output or "").strip()[-160:]
    m = ms[-1]
    return m.group(1), m.group(2).strip()[:160]


def stop_flag_path():
    """Kill-switch flag path. `touch` it to halt autonomous dispatch on the next
    tick; `rm` it to resume. Env override (PSDRIVE_STOP_FLAG) for tests. (PRO-36)"""
    return os.environ.get("PSDRIVE_STOP_FLAG",
                          os.path.expanduser("~/.config/pandastack/STOP"))


def drive_suppressed():
    """True when the kill-switch flag is present — the driver must do zero dispatch.
    Checked UNCONDITIONALLY at every loop boundary (the drive-cron launchd tick and
    a direct `--execute`); the loop never decides whether to obey the stop."""
    return os.path.exists(stop_flag_path())
