#!/usr/bin/env python3
"""Require one line-grounded exact quote in every active skill eval."""
import glob
import os
import re
import sys


ROOT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))
)
SAMPLE = re.compile(
    r'^Grounding sample: L(\d+) — "([^"\n]{12,})"\s*$'
)
failures = []
checked = 0

for eval_path in glob.glob(os.path.join(ROOT, "skills", "**", "eval.md"), recursive=True):
    rel = os.path.relpath(eval_path, ROOT)
    if "/_deprecated/" in f"/{rel}" or "/.archive/" in f"/{rel}":
        continue
    skill_path = os.path.join(os.path.dirname(eval_path), "SKILL.md")
    if not os.path.isfile(skill_path):
        continue
    skill_lines = open(skill_path, encoding="utf-8").read().splitlines()
    eval_lines = open(eval_path, encoding="utf-8").read().splitlines()
    samples = []
    for eval_lineno, line in enumerate(eval_lines, 1):
        match = SAMPLE.fullmatch(line)
        if match:
            samples.append((eval_lineno, int(match.group(1)), match.group(2)))
    if len(samples) != 1:
        failures.append(
            f"{rel}: expected exactly one Grounding sample; found {len(samples)}"
        )
        continue
    eval_lineno, skill_lineno, quote = samples[0]
    if skill_lineno < 1 or skill_lineno > len(skill_lines):
        failures.append(
            f"{rel}:{eval_lineno}: cited SKILL.md line L{skill_lineno} is out of range"
        )
        continue
    actual = " ".join(skill_lines[skill_lineno - 1].split())
    expected = " ".join(quote.split())
    if expected not in actual:
        failures.append(
            f"{rel}:{eval_lineno}: quote is absent from sibling SKILL.md L{skill_lineno}"
        )
        continue
    checked += 1

if failures:
    print("FAIL: eval grounding samples are missing or stale:")
    for failure in sorted(failures):
        print("  " + failure)
    sys.exit(1)
if checked == 0:
    print("FAIL: no active eval grounding samples were checked")
    sys.exit(1)

print(f"OK: {checked} eval grounding sample(s) match the cited SKILL.md line.")
