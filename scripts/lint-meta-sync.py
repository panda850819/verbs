#!/usr/bin/env python3
"""lint-meta-sync.py — _meta.json version/description mirror SKILL.md frontmatter.

Usage: python3 scripts/lint-meta-sync.py [repo-root]
"""
import glob
import json
import os
import re
import sys


def frontmatter(text):
    if not text.startswith("---\n"):
        return ""
    end = text.find("\n---\n", 4)
    return "" if end == -1 else text[4:end]


def scalar(fm, key):
    m = re.search(rf"^{re.escape(key)}:\s*(.*)$", fm, re.M)
    if not m:
        return None
    value = m.group(1).strip()
    if value in {"|", ">"}:
        lines = []
        start = False
        for line in fm.splitlines():
            if not start:
                start = line == m.group(0)
                continue
            if re.match(r"^[A-Za-z0-9_-]+:", line):
                break
            if line.startswith("  "):
                lines.append(line[2:])
        return "\n".join(lines).strip()
    return value.strip('"').strip("'")


ROOT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = []

for meta_path in glob.glob(os.path.join(ROOT, "skills", "**", "_meta.json"), recursive=True):
    rel = os.path.relpath(meta_path, ROOT)
    if "/_deprecated/" in f"/{rel}" or "/.archive/" in f"/{rel}":
        continue
    skill_path = os.path.join(os.path.dirname(meta_path), "SKILL.md")
    if not os.path.exists(skill_path):
        failures.append(f"{rel}: no sibling SKILL.md")
        continue
    try:
        meta = json.load(open(meta_path, encoding="utf-8"))
    except Exception as exc:
        failures.append(f"{rel}: invalid json: {exc}")
        continue
    fm = frontmatter(open(skill_path, encoding="utf-8").read())
    for key in ("version", "description"):
        expected = scalar(fm, key)
        actual = meta.get(key)
        if expected is None:
            failures.append(f"{rel}: SKILL.md missing frontmatter {key}")
        elif actual != expected:
            failures.append(f"{rel}: {key} drift: _meta.json={actual!r} SKILL.md={expected!r}")

if failures:
    print("FAIL: _meta.json drift from SKILL.md frontmatter:")
    for line in failures:
        print(f"  {line}")
    sys.exit(1)

print("OK: every _meta.json version/description matches SKILL.md frontmatter.")
