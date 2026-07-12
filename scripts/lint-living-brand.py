#!/usr/bin/env python3
"""Reject retired Verbs identity and routes on living documentation."""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path


ROOT = Path(os.environ.get(
    "VERBS_LIVING_ROOT",
    Path(__file__).resolve().parent.parent,
)).resolve()
ALLOWLIST = Path(os.environ.get(
    "VERBS_BRAND_ALLOWLIST",
    ROOT / "scripts" / "living-brand-allowlist.tsv",
))

PATTERNS = {
    "retired display name": re.compile(r"\bPanda\s+Verbs\b", re.I),
    "retired repository name": re.compile(r"\bpanda-\s*verbs\b", re.I),
    "old product claim": re.compile(
        r"personal(?: context-aware)? AI operator OS|\boperator OS\b|"
        r"\bpersonal-os\b|\bone substrate\b|\bthree runtimes\b|"
        r"\bno vendor lock-in\b|\binterchangeable runtimes\b",
        re.I,
    ),
    "old plugin id": re.compile(r"\bpandastack@pandastack\b", re.I),
    "old namespace": re.compile(r"(?:/|\b)pandastack:[a-z0-9*][a-z0-9*-]*", re.I),
    "old repository": re.compile(r"panda850819/pandastack", re.I),
    "retired project init": re.compile(r"/pandastack:init\b", re.I),
    "retired lifecycle claim": re.compile(
        r"\b3 documented compositions\b|\bthree lifecycle compositions\b|"
        r"(?:/|`)ship knowledge\b|\bknowledge-ship\b",
        re.I,
    ),
    "retired route": re.compile(
        r"(?:/|`)(?:office-hours|team-orchestrate|deepwiki|boardroom)(?:\b|`)",
        re.I,
    ),
}

ROOT_FILES = (
    "README.md", "INSTALL_FOR_AGENTS.md", ".codex/INSTALL.md", "CLAUDE.md",
    "PHILOSOPHY.md", "RESOLVER.md", "ROADMAP.md", "DISPATCH.md",
    "SKILL-FRONTMATTER.md", "THIRD_PARTY_NOTICES.md",
    "docs/ADDING_A_HOST.md", "docs/HERMES.md",
)


def load_allowlist():
    rules = []
    if not ALLOWLIST.is_file():
        return rules
    for number, raw in enumerate(ALLOWLIST.read_text(encoding="utf-8").splitlines(), 1):
        if not raw or raw.startswith("#"):
            continue
        parts = raw.split("\t")
        if len(parts) != 3:
            raise ValueError(f"{ALLOWLIST}:{number}: expected 3 tab-separated fields")
        rules.append((re.compile(parts[0]), re.compile(parts[1], re.I), parts[2]))
    return rules


def living_files():
    paths = [ROOT / relative for relative in ROOT_FILES]
    paths.extend(ROOT.glob("lib/*.md"))
    paths.extend(ROOT.glob("skills/*/*/SKILL.md"))
    paths.extend(ROOT.glob("skills/*/*/eval.md"))
    return sorted({path for path in paths if path.is_file()})


def allowed(relative, line, rules):
    return any(path_re.fullmatch(relative) and content_re.search(line)
               for path_re, content_re, _ in rules)


def main():
    try:
        rules = load_allowlist()
    except (OSError, ValueError, re.error) as exc:
        print(f"FAIL: invalid living-brand allowlist: {exc}")
        return 1
    failures = []
    for path in living_files():
        relative = path.relative_to(ROOT).as_posix()
        content = path.read_text(encoding="utf-8")
        for label, pattern in PATTERNS.items():
            for match in pattern.finditer(content):
                number = content.count("\n", 0, match.start()) + 1
                snippet = " ".join(match.group(0).split())
                if not allowed(relative, snippet, rules):
                    failures.append(f"{relative}:{number}: {label}: {snippet}")
    if failures:
        print("FAIL: retired identity or routes found on living surfaces:")
        for failure in failures:
            print(f"  {failure}")
        return 1
    print("OK: living surfaces use the current Verbs identity and routes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
