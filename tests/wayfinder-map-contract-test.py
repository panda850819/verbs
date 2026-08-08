#!/usr/bin/env python3
"""Keep Wayfinder's one-entry map and trustworthy-date contract explicit."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WAYFINDER = (
    ROOT / "skills/productivity/wayfinder/SKILL.md"
).read_text(encoding="utf-8")

for fragment in (
    "take the first frontier entry",
    "trustworthy host context or a tool",
    "write `status: in-progress` without a date",
    "never infer or guess one",
    "Apply the same rule to the final closed status",
    "Stop after one entry",
):
    assert fragment in WAYFINDER, f"Wayfinder lost map rule: {fragment!r}"

print("wayfinder map contract: ok")
