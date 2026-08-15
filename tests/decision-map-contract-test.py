#!/usr/bin/env python3
"""Keep Decision Map bounded to named, cross-session decision state."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
text = (ROOT / "skills/productivity/decision-map/SKILL.md").read_text()


def section(heading):
    marker = f"\n## {heading}\n"
    start = text.index(marker) + len(marker)
    end = text.find("\n## ", start)
    return text[start:] if end == -1 else text[start:end]


create = section("Create a map")
work = section("Work a map")
completion = section("Completion")

for fragment in (
    "If the Work Contract can be completed now, create no map",
    "Stop after creation",
):
    assert fragment in create, fragment
for fragment in (
    "Never schedule the\n   frontier autonomously",
    "update\n   the map status and newly unblocked entries, then stop",
):
    assert fragment in work, fragment
assert "Implementation remains a new,\nhuman-selected coding task" in completion
assert "Ordinary ambiguity stays\ninside the automatic Grilling Session" in text.split("\n## Create a map", 1)[0]
print("decision map contract: ok")
