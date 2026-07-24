#!/usr/bin/env python3
"""Executable resolver contract: exact catalog, source ownership, no stale routes."""
from collections import Counter
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent.parent
MANIFEST = (ROOT / "manifest.toml").read_text(encoding="utf-8")
RESOLVER = (ROOT / "RESOLVER.md").read_text(encoding="utf-8")
DISPATCH = (ROOT / "DISPATCH.md").read_text(encoding="utf-8")

EXPECTED = set(re.findall(r"^\[skill\.([a-z0-9-]+)\]$", MANIFEST, re.M))
ACTIVE_RESOLVER = RESOLVER.split("\n## Aliases\n", 1)[0]
CATALOG_SECTION = ACTIVE_RESOLVER.split(
    "\n## Skill catalog\n", 1
)[-1].split("\n## Disambiguation\n", 1)[0]
CATALOG_ROWS = re.findall(
    r"^\| `verbs:([a-z0-9-]+)` \|", CATALOG_SECTION, re.M
)
CATALOG = set(CATALOG_ROWS)
RETIRED = {
    "boardroom", "checkpoint", "deepwiki", "dojo", "freeze", "init",
    "office-hours", "team-orchestrate",
}
OWNERSHIP_CLAIMS = {
    "README.md": "first-visit",
    "DISPATCH.md": "machine routing",
    "manifest.toml": "skill catalog",
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
    duplicates = sorted(
        name for name, count in Counter(CATALOG_ROWS).items() if count != 1
    )
    if duplicates or len(CATALOG_ROWS) != len(EXPECTED):
        failures.append(
            "resolver catalog must contain exactly one row per manifest skill: "
            f"rows={len(CATALOG_ROWS)} duplicates={duplicates}"
        )
    if "## Operating model" not in RESOLVER:
        failures.append("resolver is missing the public operating model")
    for source, ownership in OWNERSHIP_CLAIMS.items():
        if not re.search(
            rf"`{re.escape(source)}`[^\n]*{re.escape(ownership)}",
            RESOLVER,
            re.I,
        ):
            failures.append(
                f"resolver does not assign {source} ownership of {ownership}"
            )
    if re.search(r"\bVerbs\s+v\d", ACTIVE_RESOLVER, re.I):
        failures.append("resolver contains a fixed version claim")
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
        f"OK: RESOLVER exposes exactly {len(EXPECTED)} Verbs skills; "
        "source ownership is explicit; retired routes fail loud."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
