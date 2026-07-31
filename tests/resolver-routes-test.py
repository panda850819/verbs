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

WAYFINDER_SKILL = (
    ROOT / "skills/productivity/wayfinder/SKILL.md"
).read_text(encoding="utf-8").split("\n---\n", 1)[0]
WAYFINDER_MANIFEST_DESCRIPTION = MANIFEST.split("[skill.wayfinder]", 1)[-1].split(
    "\n[skill.", 1
)[0]

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


# Dispatch must route on a signal visible in the message, never on how big the
# effort is (#290). The wayfinder row keys on naming a map; every other fuzzy
# input belongs to grill, which hands off once the drilling shows the route.
SIZE_LANGUAGE = re.compile(
    r"large|big effort|spanning sessions|multi-session|fuzzy", re.I
)
DEBUG_SIGNAL_LANGUAGE = re.compile(
    r"\b(?:bug|fix|regression|error|crash)\b|failing test", re.I
)


def wayfinder_dispatch_row(text):
    """The row wayfinder OWNS, matched on its Invoke cell.

    Substring matching would also catch grill's row, whose Invoke cell names
    `wayfinder` as a hand-off target and whose Signal cell legitimately says
    "large" — leaving the check dependent on row order.
    """
    for line in text.splitlines():
        cells = line.split("|")
        if len(cells) > 2 and cells[2].strip().startswith("`wayfinder`"):
            return line
    return ""


def size_keyed_map_route(text):
    """True when the wayfinder dispatch row claims work by size, not by map."""
    row = wayfinder_dispatch_row(text)
    if not row:
        return False
    signal = row.split("|")[1]
    return bool(SIZE_LANGUAGE.search(signal))


def retired_routes(text):
    names = "|".join(sorted(RETIRED))
    return re.findall(
        rf"(?:/verbs:|verbs:|/)(?:{names})(?=[^a-z0-9-]|$)",
        text,
        re.I,
    )


def dispatch_signal_for(text, invoke_fragment):
    """Return the signal cell for the row that directly invokes a skill."""
    for line in text.splitlines():
        cells = line.split("|")
        if len(cells) > 2 and invoke_fragment in cells[2]:
            return cells[1].strip()
    return ""


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
    if not wayfinder_dispatch_row(DISPATCH):
        failures.append("dispatch has no wayfinder row")
    if size_keyed_map_route(DISPATCH):
        failures.append(
            "dispatch routes to wayfinder by effort size; it must key on the "
            "message naming a map"
        )
    if "a large effort with no map yet" not in DISPATCH:
        failures.append(
            "dispatch grill row must absorb a large effort that has no map yet"
        )
    if "A large effort with no map still enters `grill`" not in RESOLVER:
        failures.append("resolver does not agree with the dispatch map split")
    grill_signal = dispatch_signal_for(DISPATCH, "`grill` plan pass")
    debug_signal = dispatch_signal_for(DISPATCH, "`debug`")
    if not grill_signal or DEBUG_SIGNAL_LANGUAGE.search(grill_signal):
        failures.append(
            "dispatch broad multi-file route must exclude bug fixes so "
            "regressions deterministically enter debug"
        )
    if "regression" not in debug_signal:
        failures.append("dispatch debug row must own regressions")
    if "including fixes expected to touch 3+ files" not in RESOLVER:
        failures.append(
            "resolver must state that cross-file regressions still enter debug"
        )
    if not DEBUG_SIGNAL_LANGUAGE.search("Regression / feature (3+ files)"):
        failures.append("seeded overlapping regression route was not detected")
    if not size_keyed_map_route(
        "| Large/fuzzy effort spanning sessions / 建立 map | `wayfinder` (x) |"
    ):
        failures.append("seeded size-keyed map-route mutation was not detected")
    # The description is the hot routing surface (maintainer/SKILL-FRONTMATTER.md
    # "the description is the routing surface"), so the split must hold there too
    # or DISPATCH and the skill index disagree.
    for label, text in (
        ("wayfinder SKILL.md", WAYFINDER_SKILL),
        ("manifest wayfinder entry", WAYFINDER_MANIFEST_DESCRIPTION),
    ):
        if "names a map" not in text:
            failures.append(
                f"{label} description must key on the request naming a map"
            )
        for size_trigger in ("large, fuzzy topic", "multi-session effort"):
            if size_trigger in text:
                failures.append(
                    f"{label} description still routes by size: {size_trigger!r}"
                )
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
