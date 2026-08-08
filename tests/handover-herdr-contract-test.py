#!/usr/bin/env python3
"""Keep Handover's Herdr transport detection explicit and non-invasive."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HANDOVER = (
    ROOT / "skills/engineering/handover/SKILL.md"
).read_text(encoding="utf-8")

required = (
    'test "${HERDR_ENV:-}" = 1',
    "`HERDR_ENV=1`, not binary presence",
    "Managed Herdr pane (`HERDR_ENV=1`) and `herdr` available",
    "Managed Herdr pane but `herdr` unavailable or unhealthy",
    "Not managed by Herdr",
    "Do not issue Herdr commands even when its binary is installed",
    "command -v herdr",
    "Require `HERDR_PANE_ID` and `HERDR_WORKSPACE_ID`",
    "herdr pane split --current",
    '`--cwd\n"$PWD"`',
    "`--no-focus`",
    "herdr agent start",
    "herdr agent prompt ... --wait",
    "Herdr owns pane transport and lifecycle state; Handover owns",
    "Invoke `scripts/verbs fresh-run`",
)
for fragment in required:
    assert fragment in HANDOVER, f"Handover lost Herdr contract: {fragment!r}"

assert "never run\nbare `herdr`" in HANDOVER
assert "silently fall back" in HANDOVER
assert "Use `sprint`" not in HANDOVER

print("handover Herdr transport contract: ok")
