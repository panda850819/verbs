#!/usr/bin/env python3
"""Aggregate verbs.guard-event.v1 records into read-only audit evidence.

`harness-slim` asks for guard telemetry; this is the deterministic seam that
answers it. The report counts denials in a stated window, groups them by the
stable schema fields, names every evidence gap, and proposes at most a bounded
set of improvement candidates. It never mutates a Skill, test, hook, or the
event log itself.

A count is not a rate. Default guard logging is high-signal and does not record
every eligible opportunity, so the denominator is reported separately and zero
denials without a denominator stays inconclusive.
"""

import argparse
import datetime as dt
import json
import os
import sys
from pathlib import Path

SCHEMA = "verbs.guard-event.v1"
OFF_VALUES = {"off", "false", "0", "none"}
GROUP_FIELDS = ("runtime", "hook", "action", "decision", "reason_code")
OVERRIDE_SUFFIX = "_override"
# Reason codes that describe the guard not observing, rather than the agent
# reaching a guarded operation. Coverage evidence bounds what the counts prove.
COVERAGE_CODES = (
    "guard_unavailable",
    "transcript_missing",
    "kill_switch_off",
    "verification_input_unavailable",
    "runtime_adapter_missing",
)
# The subset that traces a defect. `kill_switch_off` is a deliberate operator
# choice, so it bounds coverage without ever proposing a hook change.
DEFECT_CODES = tuple(
    code for code in COVERAGE_CODES if code != "kill_switch_off"
)
# A pattern must repeat before it can propose anything at all.
REPEAT_THRESHOLD = 3
MAX_CANDIDATES = 3
NO_CONCLUSION = "NO CONCLUSION"
NEEDS_TRACE = "NEEDS TRACE"


class ReportError(Exception):
    """Bad invocation input. Never raised for a merely empty or absent log."""


# ---------------------------------------------------------------------------
# Input resolution
# ---------------------------------------------------------------------------

def resolve_log_path(explicit=None):
    """Resolve the event log the way hooks/guard_events.py writes it.

    Returns None only when logging is explicitly disabled.
    """
    if explicit:
        return Path(explicit).expanduser()
    configured = os.environ.get("VERBS_GUARD_EVENT_LOG")
    if configured and configured.strip().lower() in OFF_VALUES:
        return None
    if configured:
        return Path(configured).expanduser()
    state_home = os.environ.get("XDG_STATE_HOME")
    if state_home:
        return Path(state_home).expanduser() / "verbs" / "guard-events.jsonl"
    return Path.home() / ".local" / "state" / "verbs" / "guard-events.jsonl"


def parse_timestamp(value):
    """Parse an ISO-8601 timestamp, tolerating a trailing Z. None on failure."""
    if not isinstance(value, str) or not value:
        return None
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        parsed = dt.datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def parse_window_bound(value, flag):
    if value is None:
        return None
    parsed = parse_timestamp(value)
    if parsed is None:
        raise ReportError("{} is not an ISO-8601 timestamp: {}".format(flag, value))
    return parsed


def _iso(moment):
    return moment.isoformat().replace("+00:00", "Z")


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

def load_events(path, since=None, until=None):
    """Read the log into included rows plus every evidence gap observed.

    The window is inclusive on both bounds. Rows that are unreadable, carry an
    unsupported schema, or lack a usable timestamp never become counts; they
    become named gaps.
    """
    result = {
        "log_path": str(path) if path else None,
        "log_present": False,
        "rows": [],
        "parsed": 0,
        "malformed": 0,
        "unsupported_schema": 0,
        "unsupported_schemas": [],
        "out_of_window": 0,
        "first_included": None,
        "last_included": None,
    }
    if path is None or not path.is_file():
        return result
    result["log_present"] = True
    schemas = set()
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except ValueError:
                result["malformed"] += 1
                continue
            if not isinstance(row, dict):
                result["malformed"] += 1
                continue
            schema = row.get("schema")
            if schema != SCHEMA:
                result["unsupported_schema"] += 1
                if isinstance(schema, str) and schema:
                    schemas.add(schema)
                else:
                    schemas.add("<missing>")
                continue
            moment = parse_timestamp(row.get("timestamp"))
            if moment is None:
                result["malformed"] += 1
                continue
            result["parsed"] += 1
            if (since and moment < since) or (until and moment > until):
                result["out_of_window"] += 1
                continue
            row["_moment"] = moment
            result["rows"].append(row)
    result["unsupported_schemas"] = sorted(schemas)
    if result["rows"]:
        moments = [row["_moment"] for row in result["rows"]]
        result["first_included"] = _iso(min(moments))
        result["last_included"] = _iso(max(moments))
    return result


# ---------------------------------------------------------------------------
# Aggregation
# ---------------------------------------------------------------------------

def _field(row, name):
    value = row.get(name)
    return value if isinstance(value, str) and value else "unknown"


def _is_override(row):
    return _field(row, "reason_code").endswith(OVERRIDE_SUFFIX)


def count_groups(rows):
    counts = {field: {} for field in GROUP_FIELDS}
    for row in rows:
        for field in GROUP_FIELDS:
            key = _field(row, field)
            counts[field][key] = counts[field].get(key, 0) + 1
    return {field: dict(sorted(value.items())) for field, value in counts.items()}


def _matches(row, hook=None, action=None, decision=None, reason_code=None):
    if hook is not None and _field(row, "hook") != hook:
        return False
    if action is not None and _field(row, "action") != action:
        return False
    if decision is not None and _field(row, "decision") != decision:
        return False
    if reason_code is not None and _field(row, "reason_code") != reason_code:
        return False
    return True


def named_patterns(rows):
    """Count the patterns an audit must always see, present or absent."""
    coverage = [
        row for row in rows
        if _field(row, "decision") == "error"
        or _field(row, "reason_code") in COVERAGE_CODES
    ]
    return {
        "stop_code_edit_unverified": [
            row for row in rows
            if _matches(row, hook="Stop", decision="deny",
                        reason_code="code_edit_unverified")
        ],
        "ticket_gate_denials": [
            row for row in rows if _matches(row, action="ticket-gate", decision="deny")
        ],
        "ticket_gate_overrides": [
            row for row in rows
            if _field(row, "action") == "ticket-gate" and _is_override(row)
        ],
        "destructive_guard_denials": [
            row for row in rows
            if _matches(row, action="destructive-bash", decision="deny")
        ],
        "destructive_guard_overrides": [
            row for row in rows
            if _field(row, "action") == "destructive-bash" and _is_override(row)
        ],
        "coverage_evidence": coverage,
    }


def _repeated(rows, keep):
    """Group matching rows by the stable fields that identify one pattern."""
    buckets = {}
    for row in rows:
        if not keep(row):
            continue
        key = (_field(row, "hook"), _field(row, "action"), _field(row, "reason_code"))
        buckets.setdefault(key, []).append(row)
    patterns = [
        {
            "hook": key[0],
            "action": key[1],
            "reason_code": key[2],
            "count": len(value),
            "runtimes": sorted({_field(row, "runtime") for row in value}),
        }
        for key, value in buckets.items()
        if len(value) >= REPEAT_THRESHOLD
    ]
    patterns.sort(key=lambda item: (-item["count"], item["reason_code"]))
    return patterns


def repeated_denials(rows):
    """Repeating denial patterns: the agent reached a guarded operation."""
    return _repeated(rows, lambda row: _field(row, "decision") == "deny")


def repeated_defects(rows):
    """Repeating patterns whose own record traces a guard defect.

    Either the guard failed to decide (`error`), or the reason code itself
    names an unobserved guard. Adjacency to an unrelated denial is not
    evidence of a defect.
    """
    return _repeated(
        rows,
        lambda row: _field(row, "decision") == "error"
        or _field(row, "reason_code") in DEFECT_CODES,
    )


# ---------------------------------------------------------------------------
# Candidates
# ---------------------------------------------------------------------------

def covered_reason_codes(tests_dir):
    """Reason codes that already appear in the repository's test sources.

    Returns None when the test corpus cannot be read; a missing corpus is an
    evidence gap, never an assumption that coverage exists.
    """
    if tests_dir is None or not tests_dir.is_dir():
        return None
    corpus = []
    for entry in sorted(tests_dir.iterdir()):
        if entry.suffix not in (".sh", ".py"):
            continue
        try:
            corpus.append(entry.read_text(encoding="utf-8", errors="replace"))
        except OSError:
            continue
    if not corpus:
        return None
    return "\n".join(corpus)


def _label(pattern):
    return "{}/{}/{}".format(
        pattern["hook"], pattern["action"], pattern["reason_code"]
    )


def _evidence(pattern, noun):
    return "{} {} across {}".format(
        pattern["count"], noun, ", ".join(pattern["runtimes"])
    )


def classify_candidates(patterns, defects, coverage_corpus):
    """Classify each repeated pattern exactly once, most-mechanical first.

    A parser or enforcement defect outranks a coverage gap, which outranks an
    instruction or routing gap; frequency alone never reaches `hook`, and a
    denial is never called a defect because an unrelated error shares its
    action. Anything whose mechanism is unproven stays NEEDS TRACE.
    """
    candidates = [
        {
            "kind": "hook",
            "pattern": _label(defect),
            "evidence": _evidence(defect, "records")
            + "; the guard itself failed to observe or decide",
        }
        for defect in defects
    ]
    defect_labels = {candidate["pattern"] for candidate in candidates}
    for pattern in patterns:
        label = _label(pattern)
        if label in defect_labels:
            continue
        evidence = _evidence(pattern, "denials")
        if coverage_corpus is None:
            candidates.append({
                "kind": NEEDS_TRACE,
                "pattern": label,
                "evidence": evidence + "; regression coverage index unavailable",
            })
            continue
        if pattern["reason_code"] not in coverage_corpus:
            candidates.append({
                "kind": "test",
                "pattern": label,
                "evidence": evidence + "; no regression test names this reason code",
            })
            continue
        if "unknown" in (pattern["reason_code"], pattern["hook"], pattern["action"]) \
                or pattern["runtimes"] == ["unknown"]:
            candidates.append({
                "kind": NEEDS_TRACE,
                "pattern": label,
                "evidence": evidence + "; mechanism fields are unresolved",
            })
            continue
        candidates.append({
            "kind": "skill",
            "pattern": label,
            "evidence": evidence
            + "; guarded operation reached repeatedly with existing coverage",
        })
    omitted = max(0, len(candidates) - MAX_CANDIDATES)
    return candidates[:MAX_CANDIDATES], omitted


# ---------------------------------------------------------------------------
# Report assembly
# ---------------------------------------------------------------------------

def build_report(events, since, until, eligible, coverage_corpus):
    rows = events["rows"]
    denials = [row for row in rows if _field(row, "decision") == "deny"]
    allows = [row for row in rows if _field(row, "decision") == "allow"]
    patterns = repeated_denials(rows)
    defects = repeated_defects(rows)
    candidates, omitted = classify_candidates(patterns, defects, coverage_corpus)

    gaps = []
    if events["log_path"] is None:
        gaps.append("guard event logging is disabled by VERBS_GUARD_EVENT_LOG")
    elif not events["log_present"]:
        gaps.append("log file missing: {}".format(events["log_path"]))
    if events["malformed"]:
        gaps.append("{} malformed row(s) skipped".format(events["malformed"]))
    if events["unsupported_schema"]:
        gaps.append("{} row(s) with unsupported schema: {}".format(
            events["unsupported_schema"], ", ".join(events["unsupported_schemas"])
        ))
    if rows and not allows:
        gaps.append(
            "capture is high-signal only (no allow rows); eligible opportunities "
            "are not recorded"
        )
    if coverage_corpus is None:
        gaps.append("regression coverage index unavailable")

    if eligible is None:
        denominator = "UNKNOWN"
        rate = "UNAVAILABLE"
    else:
        denominator = str(eligible)
        rate = "{}/{}".format(len(denials), eligible) if eligible else "UNAVAILABLE"

    if eligible is None and denials:
        conclusion = (
            "{} denial(s) observed; rate stays UNAVAILABLE without a "
            "denominator".format(len(denials))
        )
    elif eligible is None:
        conclusion = "{} (no eligible-opportunity denominator)".format(NO_CONCLUSION)
    elif not eligible:
        conclusion = "{} (eligible-opportunity denominator is zero)".format(
            NO_CONCLUSION
        )
    elif denials:
        conclusion = "{} denial(s) in {} eligible opportunities".format(
            len(denials), eligible
        )
    else:
        conclusion = "0 denials in {} eligible opportunities".format(eligible)

    return {
        "log_path": events["log_path"],
        "log_present": events["log_present"],
        "window": {
            "requested_since": _iso(since) if since else None,
            "requested_until": _iso(until) if until else None,
            "first_included": events["first_included"],
            "last_included": events["last_included"],
        },
        "events": {
            "parsed": events["parsed"],
            "included": len(rows),
            "out_of_window": events["out_of_window"],
            "malformed": events["malformed"],
            "unsupported_schema": events["unsupported_schema"],
        },
        "counts": count_groups(rows),
        "patterns": {
            name: len(value) for name, value in named_patterns(rows).items()
        },
        "repeated_denials": patterns,
        "repeated_defects": defects,
        "denials": len(denials),
        "denominator": denominator,
        "rate": rate,
        "conclusion": conclusion,
        "candidates": candidates,
        "candidates_omitted": omitted,
        "gaps": gaps,
    }


def render_text(report):
    out = ["Verbs guard report"]
    out.append("Log: {}".format(report["log_path"] or "DISABLED"))
    window = report["window"]
    out.append("Window requested: {} .. {} (inclusive)".format(
        window["requested_since"] or "ALL", window["requested_until"] or "ALL"
    ))
    out.append("Window observed: {} .. {}".format(
        window["first_included"] or "none", window["last_included"] or "none"
    ))
    counters = report["events"]
    out.append(
        "Events: parsed={parsed} included={included} out_of_window={out_of_window} "
        "malformed={malformed} unsupported_schema={unsupported_schema}".format(
            **counters
        )
    )
    for field in GROUP_FIELDS:
        pairs = report["counts"][field]
        rendered = ", ".join(
            "{}={}".format(key, value) for key, value in pairs.items()
        ) or "none"
        out.append("By {}: {}".format(field, rendered))
    out.append("Patterns:")
    for name, count in report["patterns"].items():
        out.append("  {}: {}".format(name, count))
    out.append("Denominator: eligible_opportunities={}".format(report["denominator"]))
    out.append("Rate: {}".format(report["rate"]))
    out.append("Conclusion: {}".format(report["conclusion"]))
    out.append("Evidence gaps:")
    if report["gaps"]:
        out.extend("  - {}".format(gap) for gap in report["gaps"])
    else:
        out.append("  none")
    out.append("Candidates (propose-only):")
    if report["candidates"]:
        for candidate in report["candidates"]:
            out.append("  [{}] {} — {}".format(
                candidate["kind"], candidate["pattern"], candidate["evidence"]
            ))
    else:
        out.append("  none")
    if report["candidates_omitted"]:
        out.append("  omitted={} (bounded at {})".format(
            report["candidates_omitted"], MAX_CANDIDATES
        ))
    return "\n".join(out)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def add_parser(subparsers):
    parser = subparsers.add_parser(
        "guard-report",
        help="Aggregate guard events into read-only audit evidence",
    )
    parser.add_argument("--log", help="Event log path (default: guard_events.py)")
    parser.add_argument("--since", help="Include events at or after this ISO time")
    parser.add_argument("--until", help="Include events at or before this ISO time")
    parser.add_argument(
        "--eligible",
        type=int,
        help="Known eligible-opportunity denominator; omitted means UNKNOWN",
    )
    parser.add_argument(
        "--tests-dir", help="Regression corpus used for coverage evidence"
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON")
    parser.set_defaults(handler=run)
    return parser


def run(args):
    try:
        since = parse_window_bound(getattr(args, "since", None), "--since")
        until = parse_window_bound(getattr(args, "until", None), "--until")
    except ReportError as exc:
        print("[verbs guard-report] {}".format(exc), file=sys.stderr)
        return 2
    if since and until and since > until:
        print("[verbs guard-report] --since is after --until", file=sys.stderr)
        return 2
    if getattr(args, "eligible", None) is not None and args.eligible < 0:
        print("[verbs guard-report] --eligible cannot be negative", file=sys.stderr)
        return 2

    path = resolve_log_path(getattr(args, "log", None))
    events = load_events(path, since, until)
    tests_dir = getattr(args, "tests_dir", None)
    if tests_dir:
        tests_path = Path(tests_dir).expanduser()
    else:
        tests_path = Path(__file__).resolve().parent.parent / "tests"
    report = build_report(
        events, since, until, getattr(args, "eligible", None),
        covered_reason_codes(tests_path),
    )
    if getattr(args, "json", False):
        print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(render_text(report))
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(prog="verbs guard-report")
    sub = parser.add_subparsers(dest="command")
    add_parser(sub)
    args = parser.parse_args(argv if argv is not None else sys.argv[1:])
    if not hasattr(args, "handler"):
        parser.print_help()
        return 2
    return args.handler(args)


if __name__ == "__main__":
    sys.exit(main())
