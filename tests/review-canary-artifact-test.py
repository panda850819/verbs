#!/usr/bin/env python3
"""Keep the #365 matched Review canary byte-bound and honestly scoped."""

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CANARY = ROOT / "evals/2026-08-12-review-major-model-canary"
DECISION = (CANARY / "README.md").read_text(encoding="utf-8")
EXPECTED = {
    "snapshot": "ee631904192de738547529f7c820ac703301ddeb",
    "prompt_sha256": "a561ca6bdecf253da6703d71c2229282c8255d4fff0b34bfda5b8e61cee5a58c",
    "skill_sha256": "1190d26df99ea2cff623e80b7e9bf1bc13ec4ba4a2ac61d31834434e804e8d5d",
    "recall_sha256": "93c8620ec6ab1f3b42ee29d2a139c9598dbf817d12c60a5c74a6340e673d4dde",
    "model": "gpt-5.6-sol",
    "effort": "high",
}
CASE = {
    "low": {
        "base": "4e2574b65d29b8cf0fa7b071e45746838c9c07f5",
        "head": "32a2dc13b636eeb72cdd21bff01f4314a583592c",
        "base_tree": "0590a77f9b70a89c913d6a685811f6a60632ebf2",
        "head_tree": "930eca27f0360edd139e3f621a91e743dbc5d864",
    },
    "high": {
        "base": "31b055bfac7664760205000eb57a6fd92984ad3d",
        "head": "14f4cd5fc5ad52e7125fcfc1dd99dfaa93d50fbc",
        "base_tree": "0f1c54a2e52b192f510e90bd8064f310412a0ae1",
        "head_tree": "627e0b3ecd1ea4c64096de73a88cbadcbf1675ee",
    },
}
ARM_INSTRUCTION = {
    "baseline": "bb1d955ced203ec42f2c9e8cedd86b4b41cb546d799973ffaa7205b63b1e7e0d",
    "treatment": "9e8d22faa60ce8743421e3d82954898f845a72c62caf02f248557596ac32d4cc",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


for fragment in (
    "Status: **KEEP**",
    "Codex CLI `0.144.4`",
    "Defect recall",
    "Evidence grounding",
    "Severe harm",
    "Interaction",
    "Cost",
    "initial run was discarded",
    "**KEEP**",
):
    assert fragment in DECISION, fragment

assert sha(CANARY / "prompt.md") == EXPECTED["prompt_sha256"]
assert sha(CANARY / "review-skill.md") == EXPECTED["skill_sha256"]
assert sha(CANARY / "learning-recall.txt") == EXPECTED["recall_sha256"]
assert sha(ROOT / "skills/engineering/review/SKILL.md") == EXPECTED["skill_sha256"]
assert sha(ROOT / "lib/learning-recall.md") == EXPECTED["recall_sha256"]

for arm, instruction_sha in ARM_INSTRUCTION.items():
    assert sha(CANARY / f"{arm}-instruction.txt") == instruction_sha

for case, case_meta in CASE.items():
    for arm in ARM_INSTRUCTION:
        report = CANARY / "runs" / f"{case}-{arm}.md"
        meta = CANARY / "runs" / f"{case}-{arm}.meta.json"
        data = json.loads(meta.read_text(encoding="utf-8"))
        for key, value in EXPECTED.items():
            assert data[key] == value, (meta, key)
        for key, value in case_meta.items():
            assert data[key] == value, (meta, key)
        assert data["case"] == case, meta
        assert data["arm"] == arm, meta
        assert data["arm_instruction_sha256"] == ARM_INSTRUCTION[arm], meta
        assert data["report_sha256"] == sha(report), meta
        assert data["exit"] == 0, meta
        assert data["tokens_used"] > 0 and data["wall_seconds"] > 0, meta

assert "Do not inspect commits beyond HEAD" in (CANARY / "prompt.md").read_text()
assert not (CANARY / "fixtures").exists(), "historical source copies must not be committed"
assert not list(CANARY.rglob("*.stderr")), "raw host traces are not stable public artifacts"

print("review canary artifact contract: ok")
