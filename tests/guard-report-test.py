#!/usr/bin/env python3
"""tests/guard-report-test.py — `verbs guard-report` evidence contract.

Offline by design: every case builds its own fixture log under a temp dir. No
network, no host state, no real guard hook is invoked. Failures are asserted on
the report's structured output so a rename of the human-facing prose cannot
silently weaken a guarantee.
"""

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLI = ROOT / "scripts" / "verbs"

failures = []


def check(condition, label):
    if condition:
        print("PASS: {}".format(label))
    else:
        print("FAIL: {}".format(label))
        failures.append(label)


def event(timestamp, **overrides):
    row = {
        "schema": "verbs.guard-event.v1",
        "timestamp": timestamp,
        "runtime": "claude",
        "session_id": "s1",
        "turn_id": None,
        "hook": "PreToolUse",
        "action": "ticket-gate",
        "authority_scope": "/repo",
        "decision": "deny",
        "reason_code": "default_branch_commit",
        "artifact_ref": None,
    }
    row.update(overrides)
    return json.dumps(row, sort_keys=True)


def write_log(directory, lines, name="guard-events.jsonl"):
    path = Path(directory) / name
    path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
    return path


def report(*args, expect_rc=0):
    proc = subprocess.run(
        [sys.executable, str(CLI), "guard-report", "--json", *args],
        capture_output=True, text=True,
    )
    assert proc.returncode == expect_rc, (proc.returncode, proc.stderr)
    if expect_rc != 0:
        return None
    return json.loads(proc.stdout)


def text_report(*args):
    proc = subprocess.run(
        [sys.executable, str(CLI), "guard-report", *args],
        capture_output=True, text=True,
    )
    assert proc.returncode == 0, proc.stderr
    return proc.stdout


with tempfile.TemporaryDirectory() as tmp:
    empty_tests = Path(tmp) / "no-tests"
    empty_tests.mkdir()
    # A fixture corpus, so this file's own reason-code literals cannot count as
    # regression coverage for the cases below.
    fixture_tests = Path(tmp) / "corpus"
    fixture_tests.mkdir()
    (fixture_tests / "covered-test.sh").write_text(
        "# names code_edit_unverified\n", encoding="utf-8"
    )

    # T01 — window boundaries are inclusive and the observed span is reported.
    log = write_log(tmp, [
        event("2026-07-01T00:00:00Z"),
        event("2026-07-02T00:00:00Z"),
        event("2026-07-03T00:00:00Z"),
        event("2026-07-04T00:00:00Z"),
    ])
    data = report("--log", str(log), "--since", "2026-07-02T00:00:00Z",
                  "--until", "2026-07-03T00:00:00Z")
    check(data["events"]["included"] == 2, "window includes both bounds exactly")
    check(data["events"]["out_of_window"] == 2, "out-of-window rows are excluded")
    check(
        data["window"]["first_included"] == "2026-07-02T00:00:00Z"
        and data["window"]["last_included"] == "2026-07-03T00:00:00Z",
        "effective first and last included timestamps are reported",
    )
    check(data["denials"] == 2, "denial count is exact for the selected window")

    # T02 — grouping uses the stable schema fields, not free text.
    log = write_log(tmp, [
        event("2026-07-01T00:00:00Z", hook="Stop", action="verify-gate",
              reason_code="code_edit_unverified"),
        event("2026-07-01T01:00:00Z", hook="Stop", action="verify-gate",
              reason_code="code_edit_unverified", runtime="codex"),
        event("2026-07-01T02:00:00Z", action="destructive-bash",
              reason_code="force_push"),
        event("2026-07-01T03:00:00Z", decision="allow",
              reason_code="panda_force_override"),
        event("2026-07-01T04:00:00Z", action="destructive-bash", decision="allow",
              reason_code="force_ok_override"),
        event("2026-07-01T05:00:00Z", reason_code="default_branch_commit"),
    ], name="grouped.jsonl")
    data = report("--log", str(log))
    check(data["counts"]["runtime"] == {"claude": 5, "codex": 1},
          "counts group by runtime")
    check(data["counts"]["decision"] == {"allow": 2, "deny": 4},
          "counts group by decision")
    check(data["counts"]["action"]["destructive-bash"] == 2,
          "counts group by action")
    check(data["patterns"]["stop_code_edit_unverified"] == 2,
          "Stop code_edit_unverified is a named pattern")
    check(data["patterns"]["ticket_gate_denials"] == 1
          and data["patterns"]["ticket_gate_overrides"] == 1,
          "ticket-gate denials and overrides are counted separately")
    check(data["patterns"]["destructive_guard_denials"] == 1
          and data["patterns"]["destructive_guard_overrides"] == 1,
          "destructive-guard denials and overrides are counted separately")

    # T03 — malformed rows, unsupported schemas, and a missing log are gaps.
    log = write_log(tmp, [
        event("2026-07-01T00:00:00Z"),
        "{not json",
        '{"schema":"verbs.guard-event.v2","timestamp":"2026-07-01T00:00:00Z"}',
        '{"schema":"verbs.guard-event.v1","timestamp":"not-a-time"}',
        "[1,2,3]",
    ], name="dirty.jsonl")
    data = report("--log", str(log))
    check(data["events"]["malformed"] == 3, "malformed rows are counted, not parsed")
    check(data["events"]["unsupported_schema"] == 1,
          "unsupported schema rows are counted separately")
    check(any("malformed" in gap for gap in data["gaps"])
          and any("unsupported schema" in gap for gap in data["gaps"]),
          "malformed and unsupported rows surface as evidence gaps")
    check(data["events"]["included"] == 1, "only v1 rows with a timestamp count")

    missing = report("--log", str(Path(tmp) / "absent.jsonl"))
    check(missing["log_present"] is False
          and any("missing" in gap for gap in missing["gaps"]),
          "a missing log is a visible evidence gap")

    # T04 — zero events with no denominator is inconclusive, never healthy.
    empty = write_log(tmp, [], name="empty.jsonl")
    data = report("--log", str(empty))
    check(data["rate"] == "UNAVAILABLE", "unknown denominator yields Rate: UNAVAILABLE")
    check(data["denominator"] == "UNKNOWN", "denominator state is reported separately")
    check(data["conclusion"].startswith("NO CONCLUSION"),
          "zero events with no denominator yields NO CONCLUSION")
    rendered = text_report("--log", str(empty))
    check("Rate: UNAVAILABLE" in rendered and "NO CONCLUSION" in rendered,
          "text report prints Rate: UNAVAILABLE and NO CONCLUSION")

    data = report("--log", str(empty), "--eligible", "0")
    check(data["rate"] == "UNAVAILABLE" and data["conclusion"].startswith(
        "NO CONCLUSION"), "a zero denominator stays inconclusive")
    data = report("--log", str(empty), "--eligible", "40")
    check(data["rate"] == "0/40" and "NO CONCLUSION" not in data["conclusion"],
          "a known denominator produces a rate instead of NO CONCLUSION")

    # T05 — high-signal capture without allow rows is an explicit gap.
    log = write_log(tmp, [event("2026-07-01T00:00:00Z")], name="denyonly.jsonl")
    data = report("--log", str(log))
    check(any("high-signal" in gap for gap in data["gaps"]),
          "deny-only capture reports that eligible opportunities are unrecorded")

    # T06 — candidates are bounded and classified by mechanism, not frequency.
    covered = [event("2026-07-0{}T00:00:00Z".format(day),
                     reason_code="code_edit_unverified", hook="Stop",
                     action="verify-gate") for day in (1, 2, 3)]
    log = write_log(tmp, covered, name="skill.jsonl")
    data = report("--log", str(log), "--tests-dir", str(fixture_tests))
    check([c["kind"] for c in data["candidates"]] == ["skill"],
          "a repeated denial with existing coverage proposes a Skill candidate")

    log = write_log(tmp, [event("2026-07-0{}T00:00:00Z".format(day),
                                reason_code="verbs_guard_report_uncovered")
                          for day in (1, 2, 3)], name="test.jsonl")
    data = report("--log", str(log), "--tests-dir", str(fixture_tests))
    check([c["kind"] for c in data["candidates"]] == ["test"],
          "a repeated pattern with no regression coverage proposes a test candidate")

    # Only a record that itself traces a defect earns a hook candidate.
    log = write_log(tmp, [event("2026-07-0{}T00:00:00Z".format(day),
                                decision="error", reason_code="guard_unavailable")
                          for day in (1, 2, 3)], name="hook.jsonl")
    data = report("--log", str(log), "--tests-dir", str(fixture_tests))
    check([c["kind"] for c in data["candidates"]] == ["hook"],
          "repeated guard-unavailable records propose a hook candidate")

    # kill_switch_off bounds coverage, but an operator's deliberate off switch
    # never proposes a hook change.
    log = write_log(tmp, [event("2026-07-0{}T00:00:00Z".format(day),
                                decision="allow", hook="Stop",
                                action="verify-gate",
                                reason_code="kill_switch_off")
                          for day in (1, 2, 3)], name="killswitch.jsonl")
    data = report("--log", str(log), "--tests-dir", str(fixture_tests))
    check(data["candidates"] == [] and data["patterns"]["coverage_evidence"] == 3,
          "kill_switch_off is coverage evidence, never a hook candidate")

    # One unrelated error sharing an action must not reclassify a denial
    # pattern as a hook defect.
    log = write_log(tmp, [event("2026-07-0{}T00:00:00Z".format(day),
                                reason_code="uncovered_parser_defect")
                          for day in (1, 2, 3)]
                    + [event("2026-07-04T00:00:00Z", decision="error",
                             reason_code="guard_unavailable")],
                    name="adjacent.jsonl")
    data = report("--log", str(log), "--tests-dir", str(fixture_tests))
    check([c["kind"] for c in data["candidates"]] == ["test"],
          "an adjacent error does not make a denial pattern a hook candidate")

    log = write_log(tmp, [event("2026-07-0{}T00:00:00Z".format(day))
                          for day in (1, 2)], name="below.jsonl")
    data = report("--log", str(log), "--tests-dir", str(fixture_tests))
    check(data["candidates"] == [],
          "a pattern below the repeat threshold proposes nothing")

    log = write_log(tmp, [event("2026-07-0{}T00:00:00Z".format(day),
                                reason_code="code_edit_unverified", hook="Stop",
                                action="verify-gate") for day in (1, 2, 3)],
                    name="notrace.jsonl")
    data = report("--log", str(log), "--tests-dir", str(empty_tests))
    check([c["kind"] for c in data["candidates"]] == ["NEEDS TRACE"],
          "an unreadable coverage index preserves NEEDS TRACE")
    check(any("coverage index unavailable" in gap for gap in data["gaps"]),
          "an unreadable coverage index is an evidence gap")

    rows = []
    for index, code in enumerate(
        ["uncovered_a", "uncovered_b", "uncovered_c", "uncovered_d"]
    ):
        rows.extend(event("2026-07-0{}T0{}:00:00Z".format(index + 1, hour),
                          reason_code=code) for hour in range(3))
    log = write_log(tmp, rows, name="bounded.jsonl")
    data = report("--log", str(log), "--tests-dir", str(fixture_tests))
    check(len(data["candidates"]) == 3 and data["candidates_omitted"] == 1,
          "candidates stay bounded and the omitted count is not silent")

    # T06b — the cap keeps the heaviest evidence, whatever its kind.
    rows = [event("2026-07-01T0{}:00:00Z".format(hour), hook="Stop",
                  action="verify-gate", reason_code="code_edit_unverified")
            for hour in range(6)]
    rows += [event("2026-07-02T0{}:00:00Z".format(hour), decision="error",
                   reason_code="guard_unavailable") for hour in range(3)]
    log = write_log(tmp, rows, name="ranked.jsonl")
    data = report("--log", str(log), "--tests-dir", str(fixture_tests))
    check([c["kind"] for c in data["candidates"]] == ["skill", "hook"],
          "a heavier skill pattern outranks a lighter hook candidate")

    # T06c — offset timestamps are normalized before the window is applied.
    log = write_log(tmp, [
        event("2026-07-03T09:00:00+08:00"),
        event("2026-07-01T00:00:00Z"),
    ], name="offset.jsonl")
    data = report("--log", str(log), "--since", "2026-07-02T00:00:00Z")
    check(data["events"]["included"] == 1
          and data["window"]["first_included"] == "2026-07-03T01:00:00Z",
          "non-UTC timestamps are normalized to UTC for windowing")

    # T07 — bad invocation input fails loud instead of guessing a window.
    report("--log", str(empty), "--since", "yesterday", expect_rc=2)
    report("--log", str(empty), "--since", "2026-07-05T00:00:00Z",
           "--until", "2026-07-01T00:00:00Z", expect_rc=2)
    print("PASS: invalid window arguments exit nonzero")

    # T08 — the report never writes to the log it reads.
    before = Path(log).read_bytes()
    report("--log", str(log))
    check(Path(log).read_bytes() == before, "the report leaves the event log intact")

if failures:
    print("\n{} guard-report contract failure(s)".format(len(failures)))
    sys.exit(1)
print("\nOK: guard-report keeps counts, gaps, and candidates honest.")
