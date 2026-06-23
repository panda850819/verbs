"""Shared lifecycle + readiness logic for pandastack-drive and pandastack-linear-reduce.

Single source for the Linear state<->phase map, per-phase readiness, acceptance
parsing, work-order completeness, and the codex RESULT parser — so the reduce
(decision core) and drive (executor) cannot drift (review finding K).
"""
import json
import os
import re

# Linear project name -> repo dir the build runs in (single source; pandastack-drive imports
# this, drive-pulse resolves each build's repo from it for cross-repo promote checks). An
# optional ~/.config/pandastack/projects.json (env PSDRIVE_PROJECTS_CONFIG) overrides it.
PROJECT_REPO = {
    "murmur": "~/site/apps/murmur",
    "pandastack": "~/site/skills/pandastack",
    "shawn-trade": "~/site/trading/shawn-trade",
    "equity-research-desk": "~/site/trading/equity-research-desk",
    "hermes-vault": "~/site/hermes-vault",
}


def _projects_map():
    """The project->repo map. A readable config file is authoritative (so it can extend or
    correct the built-in map without a code change); the built-in PROJECT_REPO is the fallback
    ONLY when no config path was explicitly given — an explicit PSDRIVE_PROJECTS_CONFIG that is
    empty/unreadable yields an empty map, which keeps tests hermetic (no real-repo leak)."""
    path = os.environ.get("PSDRIVE_PROJECTS_CONFIG")
    explicit = path is not None
    path = path or os.path.expanduser("~/.config/pandastack/projects.json")
    try:
        with open(path, encoding="utf-8") as f:
            data = f.read().strip()
        cfg = json.loads(data) if data else {}
        if isinstance(cfg, dict):
            return {k: v for k, v in cfg.items() if isinstance(v, str)}
    except (OSError, ValueError):
        pass
    return {} if explicit else dict(PROJECT_REPO)


def repo_for_project(project):
    """Expanded repo dir for a Linear project name, or None if unknown (see _projects_map)."""
    p = _projects_map().get(project) if project else None
    return os.path.expanduser(p) if p else None


# Linear workflow state -> pandastack 7-phase (docs/linear-contract.md lifecycle-map),
# incl. the stock-state fallback (Todo / In Progress) for teams without custom states.
STATE_PHASE = {"Backlog": "DEFINE", "Planning": "PLAN", "Needs Decision": "GATE",
               "Building": "BUILD", "Verifying": "VERIFY", "In Review": "REVIEW", "Done": "SHIP"}
STOCK_FALLBACK = {"Todo": "PLAN", "In Progress": "BUILD"}
NEXT_PHASE = {"DEFINE": "PLAN", "PLAN": "GATE", "GATE": "BUILD", "BUILD": "VERIFY",
              "VERIFY": "REVIEW", "REVIEW": "SHIP", "SHIP": "(done)"}

# Machine-readable ledger handoff: pandastack-drive --execute emits one
# `@@PSDRIVE_LEDGER@@ {json}` line; drive-cron.py appends it verbatim to
# drive-log.jsonl instead of regex-parsing the human stdout (LG, F-K/F-L).
# Single source so the emitter and the consumer cannot drift.
LEDGER_SENTINEL = "@@PSDRIVE_LEDGER@@"

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
# An acceptance is run as `bash <job_dir>/verify.sh` with cwd = the worktree root;
# verify.sh lives in the job dir, NOT the worktree. So a path anchored on $BASH_SOURCE
# /$0 resolves outside the worktree and FAILs a correct build (PRO-71; the PRO-22
# first-build trap). Such a block is not yet runnable — it must be rewritten relative
# to cwd (the repo root). It surfaces for a fix instead of auto-building into a FAIL.
_ACC_CWD_UNSAFE = re.compile(r"\bBASH_SOURCE\b|\bdirname\s+\"?\$0\"?")
# PRO-73: an acceptance block may declare the sensor LAYERS its verify covers, as an
# optional leading `layers: typecheck, test` line (ordered cheapest-first by convention).
# It is metadata (PRO-74 granularity / PRO-75 coverage read it), stripped from the runnable
# body before materialization so it never runs as a shell command.
_LAYERS_RE = re.compile(r"(?i)^\s*layers:\s*(.+?)\s*$")


def phase_of(state):
    return STATE_PHASE.get(state) or STOCK_FALLBACK.get(state)


def next_phase(state):
    return NEXT_PHASE.get(phase_of(state) or "")


def acceptance_block(desc):
    m = _ACC_RE.search(desc or "")
    return m.group(1).strip() if m else ""


def acceptance_layers(desc):
    """Sensor layers this card's verify declares it covers (PRO-73), from an optional
    leading `layers: a, b` line in the acceptance block — ordered, lowercased, cheapest
    -first by convention. [] when undeclared. PRO-74 (granularity) / PRO-75 (coverage)
    read this to know which layers a verify actually senses."""
    b = acceptance_block(desc)
    m = _LAYERS_RE.match(b.split("\n", 1)[0]) if b else None
    return [s.strip().lower() for s in m.group(1).split(",") if s.strip()] if m else []


def acceptance_body(desc):
    """The runnable acceptance — the acceptance block minus an optional leading `layers:`
    declaration (PRO-73). This is what gets materialized into verify.sh; the layers line is
    metadata, never a shell command. No declaration -> the block unchanged."""
    b = acceptance_block(desc)
    if not b:
        return ""
    head, _, rest = b.partition("\n")
    return rest.strip() if _LAYERS_RE.match(head) else b


def acceptance_cwd_safe(block):
    """True unless the acceptance anchors paths on $BASH_SOURCE/$0 — which break under
    drive's `bash <job_dir>/verify.sh` cwd=worktree invocation (see _ACC_CWD_UNSAFE)."""
    return not _ACC_CWD_UNSAFE.search(block or "")


def acceptance_runnable(desc):
    """A machine-checkable acceptance: a runnable BODY present (PRO-73: excluding the
    `layers:` declaration, so a layers-only card with no real check is NOT runnable and
    surfaces as needs-spec instead of a silent model-PASS), machine-checkable (not human
    prose), AND cwd-safe (no $BASH_SOURCE/$0 anchor — it would FAIL under drive's verify)."""
    b = acceptance_body(desc)
    return bool(b and _RUNNABLE_HINT.search(b) and acceptance_cwd_safe(b))


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


# PRO-74: granularity-alignment (the loop's Nyquist criterion). A build whose task touches an
# axis its verify can't sense ships a blind-loop bug aliased into "done". We derive the sensor
# layers a card REQUIRES from unambiguous work-order signals and gate (needs-spec) when the
# verify can neither declare (`layers:`) nor exercise them, naming the gap.
_DELIVERABLE_RE = re.compile(r"(?is)deliverab\w*\b(.*)$")
_SHIPS_EXECUTABLE = re.compile(r"(?i)\bbin/\S|\bexecutab\w+|\bexec[ -]?bit\b|\bchmod \+x")
_RUNS_EXECUTABLE = re.compile(r"(?i)\bbin/\S|(?:^|\s)\./\S|\bchmod \+x|\btest -x\b")


def required_layers(desc):
    """Sensor layers a card's work order REQUIRES, from unambiguous signals (PRO-74).
    Today: a Deliverable that ships an executable (`bin/foo`, exec bit, chmod +x) requires the
    `runtime` layer — a verify that only typechecks would pass while the binary is broken or
    non-executable (the PRO-22 class). Scoped to the Deliverable section so an acceptance that
    merely RUNS a binary is not mistaken for the task PRODUCING one. Extensible."""
    m = _DELIVERABLE_RE.search(desc or "")
    return ["runtime"] if (m and _SHIPS_EXECUTABLE.search(m.group(1))) else []


def _layer_covered(layer, desc):
    """A required layer is covered when the card declares it in `layers:` (PRO-73) or the
    acceptance body actually exercises it — for `runtime`, the acceptance runs the artifact."""
    if layer in acceptance_layers(desc):
        return True
    if layer == "runtime":
        return bool(_RUNS_EXECUTABLE.search(acceptance_body(desc)))
    return False


def sensor_gap(desc):
    """Granularity-alignment gap (PRO-74): a layer the task requires that the verify can
    neither declare (`layers:`) nor exercise. None when aligned. Non-None = the verify is
    coarser than the task and would alias that class of bug into 'done'."""
    missing = [l for l in required_layers(desc) if not _layer_covered(l, desc)]
    if not missing:
        return None
    return ("sensor gap: " + ", ".join(missing) + " — the Deliverable requires it but the "
            "verify neither declares it in `layers:` nor exercises it")


def readiness_gap(state, desc):
    """Per-phase readiness keyed on the TO-RUN (next) phase — the input the driver
    actually consumes (review finding D). VERIFY (next, from Building) needs a runnable
    acceptance or named evidence block; REVIEW (next, from Verifying) needs a
    diff/artifact. PLAN (next, grill) bootstraps from a title, so it is not gated
    — grill self-reports BLOCKED if it cannot plan. GATE/SHIP-next are human steps,
    no machine readiness."""
    nxt = next_phase(state)
    desc = desc or ""
    if nxt == "VERIFY":
        if not acceptance_lane(desc):
            b = acceptance_block(desc)
            if b and not acceptance_cwd_safe(b):
                return ("next=VERIFY: acceptance anchors on $BASH_SOURCE/$0; rewrite "
                        "cwd-relative (verify runs `bash verify.sh` with cwd=worktree)")
            return "next=VERIFY: missing runnable acceptance or named evidence"
        gap = sensor_gap(desc)                                  # PRO-74: granularity alignment
        if gap:
            return "next=VERIFY: " + gap
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


# ── verify materialization + ledger/evidence (the trace) — contract surface ──
# Moved from pandastack-drive (PRO-78, the seam): "what counts as correct" lives
# in the contract; the daemon re-exports these via `from pslib import ...`.
# harden_verify materializes a strict verify script; ledger_record defines the
# append-only drive-log schema (the fake-green grep predicate); evidence_body
# renders the inline host-verify evidence for the merge commit.

def harden_verify(script):
    """Force strict mode on a materialized verify script (review F-B). Without
    `set -euo pipefail`, a real assertion that fails mid-script is masked by a
    trailing success (e.g. `grep -q X` then `echo done` exits 0), so host-verify
    reports a false green. Inject strict mode right after any author shebang.

    Also pin cwd to the repo root (PRO-71): verify runs `bash <job_dir>/verify.sh`
    with cwd=worktree, so cwd-relative paths already resolve, but an acceptance that
    cd's away mid-script then uses a repo-relative path would break. The explicit cd
    makes the worktree root the deterministic anchor for every acceptance."""
    body = script or ""
    cd = 'cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 2\n'
    if body.lstrip().startswith("#!"):
        first, _, rest = body.partition("\n")
        return f"{first}\nset -euo pipefail\n{cd}{rest}"
    return "#!/usr/bin/env bash\nset -euo pipefail\n" + cd + body


def ledger_record(x, r):
    """Normalize one executed item into a structured ledger record (LG, F-K/F-L).

    The fields that make 'zero fake-green' git-greppable: `verify_required` (does
    this advance need a real host-verify — True for BUILD/merge, False for a
    read-only AUTO advisory step, F-M) and `verify_ran` (did host-verify actually
    run). The success-signal counter-example is one grep:

        verdict == "PASS" AND advance AND verify_required AND NOT verify_ran

    i.e. a PASS that proposed a state advance it was supposed to host-verify, but
    no host-verify ran. In healthy operation that count is 0 (a BUILD-auto issue
    always carries a machine-runnable acceptance, so host-verify always runs; a
    failed host-verify is demoted to FAIL upstream by maybe_apply_verification)."""
    v = (r.get("verification") or {}) if isinstance(r, dict) else {}
    ran = bool(v.get("ran"))
    return {
        "id": x.get("id"),
        "project": x.get("project"),
        "phase": x.get("next"),
        "verdict": r.get("verdict"),
        "summary": (r.get("summary") or "")[:200],
        "advance": (r.get("advance") or None),
        # BUILD lands code → its advance must be host-verified; read-only AUTO is advisory.
        "verify_required": bool(x.get("build")),
        "verify_ran": ran,
        "verify_ok": v.get("ok"),
        # prefer the human-meaningful acceptance text (exec_build attaches it); fall
        # back to the materialized script path the worker actually executed.
        "verify_cmd": r.get("verify_cmd") or v.get("command"),
        "verify_tail": ((v.get("stdout_tail") or v.get("stderr_tail") or "").strip()[-400:]) or None,
        # T03: blast class + the integration branch this merged into (None = PR-only).
        # A merge event must be host-verified, so the merge-scoped fake-green grep is
        # `verdict==PASS AND merged AND verify_required AND NOT verify_ran` → must be 0.
        "blast": r.get("blast"),
        "merged": (r.get("merged") or None),
        "merged_sha": (r.get("merged_sha") or None),
        # PRO-77 (re-auditability): the sensor profile the verify covered (declared
        # `layers:`) + a one-line judgment rationale, so an autonomous merge can be
        # re-judged later without re-running. Bounds comprehension debt.
        "verify_profile": (acceptance_layers(x.get("desc") or "") if isinstance(x, dict) else []),
        "judgment": ((r.get("judgment") or r.get("summary") or None) if isinstance(r, dict) else None),
    }


def trace_complete(rec):
    """Re-auditability gate (PRO-77): a MERGED build's ledger record must carry enough to
    re-judge it later without re-running anything — exit evidence (host-verify actually ran),
    the blast class, a judgment rationale, and the verify-profile field. Non-merge records are
    always complete (nothing landed to re-audit). The systematization acceptance bar is not
    "it ran" but "it can be re-judged": a merge you cannot reconstruct is comprehension debt,
    not an asset (the OpenClaw-while-sleeping risk)."""
    if not isinstance(rec, dict) or not rec.get("merged"):
        return True
    return (rec.get("verify_ran") is True
            and rec.get("blast") is not None
            and bool(rec.get("judgment"))
            and "verify_profile" in rec)


def evidence_body(wr, acceptance, staged):
    """A commit-message body that puts the host-verify evidence inline (T04), so a human's
    30-second pre-graduation stamp is honest: the verify result + command, the acceptance
    checked, the verify-output tail, and the changed-file count — all from the worker result."""
    v = wr.get("verification") or {}
    lines = ["[auto-build evidence]"]
    if v.get("ran"):
        cmd = v.get("command")
        lines.append(f"host-verify: {'PASS' if v.get('ok') else 'FAIL'}" + (f"  ({cmd})" if cmd else ""))
        tail = (v.get("stdout_tail") or "").strip()
        if tail:
            lines.append("verify-output (tail):")
            lines += ["  " + ln for ln in tail.splitlines()[-6:]]
    else:
        lines.append("host-verify: not run")
    acc = (acceptance or "").strip()
    if acc and not acc.startswith("No explicit acceptance"):
        lines.append("acceptance:")
        lines += ["  " + ln for ln in acc.splitlines()[:8]]
    n = len([s for s in (staged or "").splitlines() if s.strip()])
    lines.append(f"changed files: {n}")
    return "\n".join(lines)
