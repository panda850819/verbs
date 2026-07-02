#!/usr/bin/env python3
"""lint-eval-quotes.py — eval.md SKILL.md evidence quotes must still ground.

Only explicit quote-evidence contexts are checked: lines that say "evidence
quote" or "quoted evidence", cite SKILL.md by line number (L12, L12-18, etc.),
and contain double-quoted snippets of at least 12 characters. This catches the
stale-literal class without treating evaluator paraphrases, behavioral-case
inputs, proposed rewrites, or rubric axis names as SKILL.md citations.

Usage: python3 scripts/lint-eval-quotes.py [repo-root]
"""
import glob
import os
import re
import sys

QUOTE = re.compile(r'"([^"\n]{12,})"')
LINE_CITE = re.compile(r"\bL\d+(?:-\d+)?\b")
QUOTE_CONTEXT = re.compile(r"\b(evidence quote|quoted evidence)\b", re.I)


ROOT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = {}

for eval_path in glob.glob(os.path.join(ROOT, "skills", "**", "eval.md"), recursive=True):
    rel = os.path.relpath(eval_path, ROOT)
    if "/_deprecated/" in f"/{rel}" or "/.archive/" in f"/{rel}":
        continue
    skill_path = os.path.join(os.path.dirname(eval_path), "SKILL.md")
    if not os.path.exists(skill_path):
        continue
    skill_text = open(skill_path, encoding="utf-8").read()
    for lineno, line in enumerate(open(eval_path, encoding="utf-8"), 1):
        if not LINE_CITE.search(line) or not QUOTE_CONTEXT.search(line):
            continue
        for quote in QUOTE.findall(line):
            snippet = " ".join(quote.split())
            haystack = " ".join(skill_text.split())
            if snippet not in haystack:
                failures.setdefault(rel, []).append((lineno, quote))

if failures:
    print("FAIL: eval.md evidence quotes not found in sibling SKILL.md:")
    for rel in sorted(failures):
        for lineno, quote in failures[rel]:
            print(f"  {rel}:{lineno}: {quote!r}")
    sys.exit(1)

print("OK: every eval.md evidence quote grounds in sibling SKILL.md.")
