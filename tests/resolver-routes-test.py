#!/usr/bin/env python3
"""Executable resolver contract for skill-description-native routing."""
from collections import Counter
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent.parent
MANIFEST = (ROOT / "manifest.toml").read_text(encoding="utf-8")
RESOLVER = (ROOT / "RESOLVER.md").read_text(encoding="utf-8")
EXPECTED = set(re.findall(r"^\[skill\.([a-z0-9-]+)\]$", MANIFEST, re.M))
ACTIVE_RESOLVER = RESOLVER.split("\n## Aliases\n", 1)[0]
CATALOG_SECTION = ACTIVE_RESOLVER.split(
    "\n## Skill catalog\n", 1
)[-1].split("\n## Disambiguation\n", 1)[0]
CATALOG_ROWS = re.findall(r"^\| `verbs:([a-z0-9-]+)` \|", CATALOG_SECTION, re.M)
CATALOG = set(CATALOG_ROWS)
RETIRED = {
    "boardroom", "checkpoint", "deepwiki", "dojo", "freeze", "init",
    "office-hours", "team-orchestrate", "wayfinder",
}
OWNERSHIP_CLAIMS = {
    "README.md": "first-visit",
    "manifest.toml": "skill catalog",
    "SKILL.md": "machine-routing description",
}


def frontmatter(name):
    path = next(ROOT.glob(f"skills/*/{name}/SKILL.md"))
    return path.read_text(encoding="utf-8").split("\n---\n", 1)[0]


def manifest_entry(name):
    return MANIFEST.split(f"[skill.{name}]", 1)[-1].split("\n[skill.", 1)[0]


def retired_routes(text):
    names = "|".join(sorted(RETIRED))
    return re.findall(
        rf"(?:/verbs:|verbs:|/)(?:{names})(?=[^a-z0-9-]|$)", text, re.I
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
            rf"(?:Each )?`{re.escape(source)}`[^\n]*{re.escape(ownership)}",
            RESOLVER,
            re.I,
        ):
            failures.append(f"resolver does not assign {source} ownership of {ownership}")
    if re.search(r"\bVerbs\s+v\d", ACTIVE_RESOLVER, re.I):
        failures.append("resolver contains a fixed version claim")
    if "pandastack:" in ACTIVE_RESOLVER:
        failures.append("living resolver still uses the v3 namespace")
    found_retired = retired_routes(ACTIVE_RESOLVER)
    if found_retired:
        failures.append(f"retired command routes remain: {found_retired}")
    if not retired_routes("Run /office-hours now."):
        failures.append("seeded retired-route mutation was not detected")

    decision_map_surfaces = (
        ("decision-map SKILL.md", frontmatter("decision-map")),
        ("manifest decision-map entry", manifest_entry("decision-map")),
        ("resolver", ACTIVE_RESOLVER),
    )
    for label, text in decision_map_surfaces:
        if "names a map" not in text:
            failures.append(f"{label} must key on the request naming a map")
        for size_trigger in ("large, fuzzy topic", "multi-session effort"):
            if size_trigger in text:
                failures.append(f"{label} still routes by size: {size_trigger!r}")

    debug_trigger = re.compile(r"\b(?:bug|fix|regression|error|crash)\b|failing test", re.I)
    debug_description = frontmatter("debug") + manifest_entry("debug")
    grill_description = frontmatter("grill") + manifest_entry("grill")
    if not debug_trigger.search(debug_description):
        failures.append("debug description must own regressions and failing tests")
    if debug_trigger.search(grill_description):
        failures.append("grill description overlaps debug failure triggers")
    if not debug_trigger.search("Regression / feature (3+ files)"):
        failures.append("seeded overlapping regression route was not detected")
    if "including fixes expected to touch 3+ files" not in RESOLVER:
        failures.append("resolver must keep cross-file regressions under debug")

    preserved_signals = {
        "careful": ("~/.agents", "~/.claude", "~/.codex"),
        "grill": ("3+ files", "refactor"),
        "handover": ("parallel read-only research", "Agent Worker"),
        "review": ("before committing",),
    }
    for name, fragments in preserved_signals.items():
        surface = frontmatter(name)
        for fragment in fragments:
            if fragment not in surface:
                failures.append(
                    f"{name} description lost dispatch signal {fragment!r}"
                )
    if "Each `SKILL.md` description is the machine-routing surface." not in (
        ROOT / "README.md"
    ).read_text(encoding="utf-8"):
        failures.append("README must name skill descriptions as machine routing")

    if failures:
        print("FAIL: resolver route contract")
        for failure in failures:
            print(f"  {failure}")
        return 1
    print(
        f"OK: RESOLVER exposes exactly {len(EXPECTED)} Verbs skills; "
        "routing ownership lives in skill descriptions."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
