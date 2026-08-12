#!/usr/bin/env python3
"""Keep the #365 matched Review canary reproducible and honestly scoped."""

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CANARY = ROOT / "evals/2026-08-12-review-major-model-canary"
DECISION = (CANARY / "README.md").read_text(encoding="utf-8")
PROMPT = (CANARY / "prompt.md").read_text(encoding="utf-8")
FROZEN_SKILL = (CANARY / "review-skill.md").read_bytes()
CURRENT_SKILL = (ROOT / "skills/engineering/review/SKILL.md").read_bytes()
FROZEN_RECALL = (CANARY / "learning-recall.md").read_bytes()
CURRENT_RECALL = (ROOT / "lib/learning-recall.md").read_bytes()

for fragment in (
    "Status: **KEEP**",
    "Codex CLI `0.144.4`",
    "`gpt-5.6-sol`",
    "`high` in every arm",
    "`ee631904192de738547529f7c820ac703301ddeb`",
    "Same read-only sandbox",
    "Defect recall",
    "Evidence grounding",
    "Severe harm",
    "Interaction",
    "Cost",
    "initial run was discarded",
    "**KEEP**",
):
    assert fragment in DECISION, fragment

for case in ("low", "high"):
    for arm in ("baseline", "treatment"):
        report = CANARY / "runs" / f"{case}-{arm}.md"
        meta = CANARY / "runs" / f"{case}-{arm}.meta.json"
        assert report.is_file() and report.stat().st_size > 100, report
        data = json.loads(meta.read_text(encoding="utf-8"))
        assert data["exit"] == 0, meta
        assert data["tokens_used"] > 0, meta
        assert data["wall_seconds"] > 0, meta

assert "Do not inspect commits beyond HEAD" in PROMPT
assert FROZEN_SKILL == CURRENT_SKILL
assert FROZEN_RECALL == CURRENT_RECALL
assert hashlib.sha256(FROZEN_SKILL).hexdigest() == (
    "1190d26df99ea2cff623e80b7e9bf1bc13ec4ba4a2ac61d31834434e804e8d5d"
)
assert not (CANARY / "fixtures").exists(), "historical source copies must not be committed"
assert not list(CANARY.rglob("*.stderr")), "raw host traces are not stable public artifacts"

print("review canary artifact contract: ok")
