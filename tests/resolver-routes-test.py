#!/usr/bin/env python3
"""Executable resolver contract: exact v4 catalog and no retired routes."""
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent.parent
MANIFEST = (ROOT / "manifest.toml").read_text(encoding="utf-8")
RESOLVER = (ROOT / "RESOLVER.md").read_text(encoding="utf-8")
DISPATCH = (ROOT / "DISPATCH.md").read_text(encoding="utf-8")

EXPECTED = set(re.findall(r"^\[skill\.([a-z0-9-]+)\]$", MANIFEST, re.M))
ACTIVE_RESOLVER = RESOLVER.split("\n## Aliases\n", 1)[0]
CATALOG = set(re.findall(r"`verbs:([a-z0-9-]+)(?:\s+[^`]*)?`", ACTIVE_RESOLVER))
RETIRED = {
    "boardroom", "checkpoint", "deepwiki", "dojo", "freeze", "init",
    "office-hours", "team-orchestrate",
}


def retired_routes(text):
    names = "|".join(sorted(RETIRED))
    return re.findall(
        rf"(?:/verbs:|verbs:|/)(?:{names})(?=[^a-z0-9-]|$)",
        text,
        re.I,
    )


def main():
    failures = []
    if not EXPECTED:
        failures.append("manifest exposed zero skills")
    if CATALOG != EXPECTED:
        failures.append(
            f"resolver catalog drift: missing={sorted(EXPECTED-CATALOG)} "
            f"extra={sorted(CATALOG-EXPECTED)}"
        )
    living = ACTIVE_RESOLVER + "\n" + DISPATCH
    if "pandastack:" in living:
        failures.append("living resolver or dispatch still uses the v3 namespace")
    found_retired = retired_routes(living)
    if found_retired:
        failures.append(f"retired command routes remain: {found_retired}")
    if not retired_routes("Run /office-hours now."):
        failures.append("seeded retired-route mutation was not detected")
    if failures:
        print("FAIL: resolver route contract")
        for failure in failures:
            print(f"  {failure}")
        return 1
    print(
        f"OK: RESOLVER exposes exactly {len(EXPECTED)} Panda Verbs skills; "
        "retired routes fail loud."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
