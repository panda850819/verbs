#!/usr/bin/env python3
"""Keep Decision Map bounded to named, cross-session decision state."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
text = (ROOT / "skills/productivity/decision-map/SKILL.md").read_text()
for fragment in (
    "Ordinary ambiguity stays\ninside the automatic Grilling Session",
    "If the Work Contract can be completed now, create no map",
    "Stop after creation",
    "Never schedule the\n   frontier autonomously",
    "update\n   the map status and newly unblocked entries, then stop",
    "Implementation remains a new,\nhuman-selected coding task",
):
    assert fragment in text, fragment
print("decision map contract: ok")
