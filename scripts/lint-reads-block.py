#!/usr/bin/env python3
"""lint-reads-block.py — SKILL.md body file reads must be declared in reads:.

The check is intentionally narrow and deterministic. It only looks for body
references to repo-root lib/, skill-local lib/ and references/, and @-import
lines. Declared-but-unused reads are warnings because a cold reference can be
valid even when prose no longer mentions it.

Usage: python3 scripts/lint-reads-block.py [repo-root]
"""
import glob
import os
import re
import sys

from skill_path_utils import skill_local_path


def split_frontmatter(text):
    if not text.startswith("---\n"):
        return "", text
    end = text.find("\n---\n", 4)
    if end == -1:
        return "", text
    return text[4:end], text[end + 5 :]


def frontmatter_reads(fm, skill_dir, root):
    reads = set()
    unsafe = []
    in_reads = False
    for line in fm.splitlines():
        if re.match(r"^[A-Za-z0-9_-]+:", line):
            in_reads = line.startswith("reads:")
            continue
        if not in_reads:
            continue
        m = re.match(r"\s*-\s*(?:(repo|skill):\s*)?(.+?)\s*$", line)
        if not m:
            continue
        kind = m.group(1) or "repo"
        value = m.group(2).strip().strip('"').strip("'")
        if value.startswith(("vault:", "cli:", "git:", "external:", "brain:")):
            continue
        if kind == "skill":
            if "/" not in value and not value.endswith(".md"):
                continue
            candidate = skill_local_path(skill_dir, value)
            if candidate is None:
                unsafe.append(value)
                continue
            value = os.path.relpath(candidate, root)
        if value:
            reads.add(value)
    return reads, unsafe


def skill_dirs(root):
    for path in glob.glob(os.path.join(root, "skills", "**", "SKILL.md"), recursive=True):
        rel = os.path.relpath(path, root)
        if "/_deprecated/" in f"/{rel}" or "/.archive/" in f"/{rel}":
            continue
        yield path


def canonical_ref(skill_dir, token):
    token = token.strip().strip("`'\"").rstrip(".,):;")
    if not token or "{" in token or "<" in token:
        return None
    if token.startswith("@"):
        token = token[1:]
    if token.startswith("./"):
        token = token[2:]
    if token.startswith("../"):
        return f"UNSAFE:{token}"
    if token.startswith("references/"):
        candidate = skill_local_path(skill_dir, token)
        return os.path.relpath(candidate, ROOT) if candidate else f"UNSAFE:{token}"
    if token.startswith("lib/"):
        candidate = skill_local_path(skill_dir, token)
        return os.path.relpath(candidate, ROOT) if candidate else f"UNSAFE:{token}"
    if token.startswith("skills/") or token.startswith("lib/"):
        return token
    return None


def body_refs(root, skill_path, body):
    skill_dir = os.path.dirname(skill_path)
    refs = set()

    for m in re.finditer(r"@((?:\./|\.\./)*[A-Za-z0-9_./-]+)", body):
        ref = canonical_ref(skill_dir, m.group(1))
        if ref:
            refs.add(ref)

    token_re = re.compile(r"(?<![A-Za-z0-9_@./-])(?:(?:\./|\.\./)*)(?:lib|references)/[A-Za-z0-9_./-]+")
    for m in token_re.finditer(body):
        ref = canonical_ref(skill_dir, m.group(0))
        if ref:
            refs.add(ref)

    markdown_re = re.compile(r"\]\((((?:\./|\.\./)*)(?:lib|references)/[A-Za-z0-9_./-]+)\)")
    for m in markdown_re.finditer(body):
        ref = canonical_ref(skill_dir, m.group(1))
        if ref:
            refs.add(ref)

    return refs


ROOT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = {}
warnings = {}

for path in skill_dirs(ROOT):
    text = open(path, encoding="utf-8").read()
    fm, body = split_frontmatter(text)
    if not re.search(r"^reads:", fm, re.M):
        continue
    declared, unsafe = frontmatter_reads(fm, os.path.dirname(path), ROOT)
    actual = body_refs(ROOT, path, body)

    missing = actual - declared
    unused = {r for r in declared - actual if r.startswith(("lib/", "skills/", "references/"))}
    if missing:
        failures[os.path.relpath(path, ROOT)] = sorted(missing)
    if unsafe:
        failures.setdefault(os.path.relpath(path, ROOT), []).extend(
            f"unsafe skill read: {value}" for value in sorted(unsafe)
        )
    if unused:
        warnings[os.path.relpath(path, ROOT)] = sorted(unused)

for rel in sorted(warnings):
    for ref in warnings[rel]:
        print(f"WARN: {rel}: declared reads entry not referenced in body: {ref}")

if failures:
    print("FAIL: SKILL.md body reads missing from frontmatter reads:")
    for rel in sorted(failures):
        for ref in failures[rel]:
            print(f"  {rel}: missing reads entry for {ref}")
    sys.exit(1)

print("OK: every SKILL.md body lib/ | references/ | @ read is declared.")
