#!/usr/bin/env python3
"""lint-refs-resolve.py — every resolvable reference token in SKILL.md grounds.

Born from the flat -> skills/<bucket>/<skill> restructure: cross-skill refs
hid in `reads:`, `capability_required:`, body links, and `skills/{voice}`
templates, and a single grep pattern never caught them all. This checks the
property directly (does the path exist?) instead of pattern-matching the bug.

Usage: python3 scripts/lint-refs-resolve.py [repo-root]

Accepted non-repo tokens (skipped): output convention dirs skills create at
runtime (docs/sessions, docs/checkpoints, docs/retros, docs/plans, docs/briefs,
docs/handoffs — not tracked when empty), absolute-path substrings
(skills/verbs/...), external URLs (skills/tree/main/...), and template
placeholders containing { or < (verified by shape, not existence).

Pack token limits: verbs:<name> resolves to this pack's skill dirs; and
slash commands are checked only when shaped as backticked `/lower-kebab` (or
`/verbs:name`) so prose slashes, paths, and CLI flags do not false-positive.
Bare skill names in prose are outside this deterministic token shape.
"""
import os
import re
import sys
import glob

from skill_path_utils import skill_local_path

ROOT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

skill_bucket = {}
for skill_dir in glob.glob("skills/*/*"):
    if os.path.isdir(skill_dir):
        n = os.path.basename(skill_dir)
        skill_bucket[n] = os.path.dirname(skill_dir)
TOKEN = re.compile(
    r"(?:skills|lib|references|patterns|reviews|templates|docs|contexts)/"
    r"[A-Za-z0-9_./{}<>-]+"
)
SKILL_READ = re.compile(r"^\s*-\s*skill:\s*([^\s#]+)\s*$", re.MULTILINE)
PACK_TOKEN = re.compile(r"\bverbs:([a-z0-9][a-z0-9-]*)\b")
RETIRED_PACK_TOKEN = re.compile(r"\bpandastack:([a-z0-9][a-z0-9-]*)\b")
SLASH_COMMAND = re.compile(r"`(/(?:verbs:)?[a-z0-9][a-z0-9-]*)`")


def accepted(t):
    return (
        t.startswith(("docs/sessions", "docs/checkpoints", "docs/retros", "docs/plans", "docs/briefs", "docs/handoffs"))
        or t.startswith("skills/verbs/scripts")  # repo URL/path substring
        or t.startswith("skills/tree/main")           # github URL substring
        or t == "skills/SKILL.md"                       # substring of writing-great-skills/SKILL.md
        or "{" in t or "<" in t                         # template placeholder
    )


broken = {}
allowlist_path = os.path.join(ROOT, "scripts", "lint-command-allowlist.txt")
command_allowlist = set()
if os.path.exists(allowlist_path):
    for line in open(allowlist_path, encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#"):
            command_allowlist.add(line)

for f in glob.glob("skills/**/SKILL.md", recursive=True):
    if "/.archive/" in f or "/_deprecated/" in f:
        continue
    text = open(f, encoding="utf-8").read()
    skill_dir = os.path.dirname(f)
    for m in set(TOKEN.findall(text)):
        tok = m.rstrip(".,):;`")
        local = tok.startswith(("lib/", "references/", "patterns/", "reviews/", "templates/"))
        candidate = skill_local_path(skill_dir, tok) if local else tok
        if local and candidate is None:
            broken.setdefault(f, []).append((tok, "unsafe skill-local path"))
            continue
        if accepted(tok) or os.path.exists(candidate):
            continue
        mm = re.match(r"skills/([A-Za-z0-9_-]+)(/.*)?$", tok)
        hint = "does not resolve"
        if mm and mm.group(1) in skill_bucket:
            n = mm.group(1)
            hint = f"flat ref — bucket it: skills/{skill_bucket[n]}/{n}"
        broken.setdefault(f, []).append((tok, hint))

    for raw in set(SKILL_READ.findall(text)):
        value = raw.strip().strip('"\'')
        if "/" in value or value.endswith(".md"):
            candidate = skill_local_path(skill_dir, value)
            if candidate is None:
                broken.setdefault(f, []).append(
                    (f"skill: {value}", "unsafe skill-local read")
                )
            elif not os.path.exists(candidate):
                broken.setdefault(f, []).append(
                    (f"skill: {value}", "skill-local read does not resolve")
                )
        elif value not in skill_bucket:
            broken.setdefault(f, []).append(
                (f"skill: {value}", "no matching installed companion skill")
            )

    for name in set(PACK_TOKEN.findall(text)):
        if name not in skill_bucket:
            broken.setdefault(f, []).append((f"verbs:{name}", "no matching skills/*/<name>/ directory"))

    for name in set(RETIRED_PACK_TOKEN.findall(text)):
        broken.setdefault(f, []).append((f"pandastack:{name}", "retired v3 namespace; use verbs:<name>"))

    for command in set(SLASH_COMMAND.findall(text)):
        name = command[1:]
        if name.startswith("verbs:"):
            name = name.split(":", 1)[1]
        if name in skill_bucket or command in command_allowlist:
            continue
        broken.setdefault(f, []).append((command, "slash command does not match a Verbs skill or allowlist entry"))

if broken:
    print("FAIL: unresolved internal refs in SKILL.md files:")
    for f in sorted(broken):
        for tok, hint in sorted(set(broken[f])):
            print(f"  {f}: {tok}  [{hint}]")
    sys.exit(1)

print("OK: every internal path, pack, and slash-command ref in SKILL.md resolves.")
