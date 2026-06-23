#!/usr/bin/env bash
# tests/drive-trace-acceptance.sh — PRO-77: re-auditability as an acceptance criterion.
# A MERGED build's ledger record must carry enough to re-judge it later without re-running:
# the verify profile (which sensor layers it declared, PRO-73), exit evidence (host-verify
# actually ran), the blast class, and a one-line judgment rationale. `trace_complete` is the
# gate — a merge you cannot reconstruct is comprehension debt, not an asset. Non-merge
# records are always complete (nothing landed to re-audit).
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root/scripts" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pslib
ok = True
def chk(cond, label):
    global ok
    print(("PASS: " if cond else "FAIL: ") + label)
    ok = ok and bool(cond)

DESC = "## Goal x\n## Context y\n```acceptance\nlayers: typecheck, test\nnpm test\n```\n## Deliverable\nx"
x_merge = {"id": "MUR-1", "project": "murmur", "next": "BUILD", "build": True, "desc": DESC}
VER = {"ran": True, "ok": True, "command": "/tmp/job/verify.sh", "stdout_tail": "1 pass"}

# a complete merged build: profile derived from desc, judgment from summary, verify ran, blast set
r_ok = {"verdict": "PASS", "summary": "built drift checker; merged low-blast",
        "blast": "low", "merged": "psdrive/integration", "merged_sha": "abc1234",
        "verification": VER}
rec = pslib.ledger_record(x_merge, r_ok)
chk(rec["verify_profile"] == ["typecheck", "test"], "verify_profile derived from the card's declared layers")
chk(rec["judgment"] == "built drift checker; merged low-blast", "judgment populated (the verdict rationale)")
chk(pslib.trace_complete(rec) is True, "merged build with full trace -> re-auditable")

# missing judgment (no summary, no judgment) -> NOT re-auditable
r_nojudg = {"verdict": "PASS", "summary": "", "blast": "low",
            "merged": "psdrive/integration", "merged_sha": "def5678", "verification": VER}
chk(pslib.trace_complete(pslib.ledger_record(x_merge, r_nojudg)) is False, "merge missing judgment -> FAIL (not re-auditable)")

# missing blast -> NOT re-auditable
r_noblast = {"verdict": "PASS", "summary": "built", "blast": None,
             "merged": "psdrive/integration", "merged_sha": "0a1b2c3", "verification": VER}
chk(pslib.trace_complete(pslib.ledger_record(x_merge, r_noblast)) is False, "merge missing blast class -> FAIL")

# host-verify never ran on a merge -> NOT re-auditable
r_noverify = {"verdict": "PASS", "summary": "built", "blast": "low",
              "merged": "psdrive/integration", "merged_sha": "9f8e7d6", "verification": {}}
chk(pslib.trace_complete(pslib.ledger_record(x_merge, r_noverify)) is False, "merge with no host-verify evidence -> FAIL")

# a non-merge advisory record is always complete (nothing landed)
x_ro = {"id": "MUR-2", "project": "murmur", "next": "REVIEW"}
r_ro = {"verdict": "PASS", "summary": "looks good", "verification": {}}
chk(pslib.trace_complete(pslib.ledger_record(x_ro, r_ro)) is True, "non-merge advisory record -> always complete")

# the four re-auditable fields exist in the schema for every record
keys = pslib.ledger_record(x_ro, r_ro)
chk(all(k in keys for k in ("verify_profile", "judgment", "blast", "verify_ran")), "re-auditable fields present in the ledger schema")

sys.exit(0 if ok else 1)
PY
rc=$?
[ "$rc" -eq 0 ] && echo "OK: drive-trace-acceptance all green" || echo "FAILURES present"
exit "$rc"
