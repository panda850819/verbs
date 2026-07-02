#!/usr/bin/env python3
"""lint-refs-resolve.py — every internal skills/ | lib/ | docs/ | contexts/
path referenced inside a SKILL.md must resolve to a real file/dir.

Born from the flat -> skills/<bucket>/<skill> restructure: cross-skill refs
hid in `reads:`, `capability_required:`, body links, and `skills/{voice}`
templates, and a single grep pattern never caught them all. This checks the
property directly (does the path exist?) instead of pattern-matching the bug.

Usage: python3 scripts/lint-refs-resolve.py   (exit 0 = clean, 1 = broken refs)

Accepted non-repo tokens (skipped): output convention dirs skills create at
runtime (docs/sessions, docs/checkpoints, docs/retros, docs/plans, docs/briefs,
docs/handoffs — not tracked when empty), absolute-path substrings
(skills/pandastack/...), external URLs (skills/tree/main/...), and template
placeholders containing { or < (verified by shape, not existence).
"""
import os
import re
import sys
import glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

BUCKETS = {"engineering", "productivity", "writing", "meta"}
skill_bucket = {}
for b in BUCKETS:
    for n in os.listdir(f"skills/{b}"):
        if os.path.isdir(f"skills/{b}/{n}"):
            skill_bucket[n] = b

TOKEN = re.compile(r"(?:skills|lib|docs|contexts)/[A-Za-z0-9_./{}<>-]+")


def accepted(t):
    return (
        t.startswith(("docs/sessions", "docs/checkpoints", "docs/retros", "docs/plans", "docs/briefs", "docs/handoffs"))
        or t.startswith("skills/pandastack/scripts")  # abs-path substring of ~/site/skills/pandastack/...
        or t.startswith("skills/tree/main")           # github URL substring
        or t == "skills/SKILL.md"                       # substring of writing-great-skills/SKILL.md
        or "{" in t or "<" in t                         # template placeholder
    )


broken = {}
for f in glob.glob("skills/**/SKILL.md", recursive=True):
    if "/.archive/" in f or "/_deprecated/" in f:
        continue
    for m in set(TOKEN.findall(open(f).read())):
        tok = m.rstrip(".,):;`")
        if accepted(tok) or os.path.exists(tok):
            continue
        mm = re.match(r"skills/([A-Za-z0-9_-]+)(/.*)?$", tok)
        hint = "does not resolve"
        if mm and mm.group(1) in skill_bucket:
            n = mm.group(1)
            hint = f"flat ref — bucket it: skills/{skill_bucket[n]}/{n}"
        broken.setdefault(f, []).append((tok, hint))

if broken:
    print("FAIL: unresolved internal refs in SKILL.md files:")
    for f in sorted(broken):
        for tok, hint in sorted(set(broken[f])):
            print(f"  {f}: {tok}  [{hint}]")
    sys.exit(1)

print("OK: every internal skills/ | lib/ | docs/ | contexts/ ref in SKILL.md resolves.")
