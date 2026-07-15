#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

canonical="lib/qa-evidence-format.md"
qa_skill="skills/engineering/qa/SKILL.md"
ship_skill="skills/engineering/ship/SKILL.md"
qa_copy="skills/engineering/qa/lib/qa-evidence-format.md"
ship_copy="skills/engineering/ship/lib/qa-evidence-format.md"

grep -Fq '<!-- verbs-qa-evidence:v1 -->' "$canonical"
grep -Fq 'patch-sha256:<digest>' "$canonical"
grep -Fq 'PASS' "$canonical"
grep -Fq 'FAIL' "$canonical"
grep -Fq 'UNPROVEN' "$canonical"
grep -Fq 'Acceptance: VERIFIED | NOT VERIFIED' "$canonical"
grep -Fq 'QA COMMENT CONFLICT' "$canonical"
grep -Fq 'Never turn an ownership conflict into another duplicate' "$canonical"
grep -Fq 'git rev-parse --git-path verbs/qa-evidence.md' "$qa_skill"
grep -Fq 'QA does not write to GitHub' "$qa_skill"
grep -Fq '**QA evidence upsert**' "$ship_skill"
grep -Fq 'Re-running `ship` updates the same comment' "$ship_skill"
grep -Fq 'blocks a ready/done claim' "$ship_skill"

cmp -s "$canonical" "$qa_copy"
cmp -s "$canonical" "$ship_copy"

qa_resources=$(sed -n '/^\[skill\.qa\]/,/^\[skill\./p' manifest.toml | grep '^resources = ' | head -1)
ship_resources=$(sed -n '/^\[skill\.ship\]/,/^\[skill\./p' manifest.toml | grep '^resources = ' | head -1)
case "$qa_resources" in *'"lib/qa-evidence-format.md"'*) ;; *) exit 1 ;; esac
case "$ship_resources" in *'"lib/qa-evidence-format.md"'*) ;; *) exit 1 ;; esac

echo "OK: QA evidence is artifact-bound and ship upserts one PR comment"
