#!/usr/bin/env bash
# Seeded proofs for issue #134's linter-blind drift classes.
set -uo pipefail
cd "$(dirname "$0")/.."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail=0

pass_case() {
  local label="$1"; shift
  if "$@" >/tmp/pstest-blind-"$label".log 2>&1; then
    printf 'ok    %s clean fixture passed\n' "$label"
  else
    printf 'FAIL  %s clean fixture failed\n' "$label"
    cat /tmp/pstest-blind-"$label".log
    fail=1
  fi
}

fail_case() {
  local label="$1"; shift
  if "$@" >/tmp/pstest-blind-"$label".log 2>&1; then
    printf 'FAIL  %s drift fixture unexpectedly passed\n' "$label"
    cat /tmp/pstest-blind-"$label".log
    fail=1
  else
    printf 'ok    %s drift fixture failed as expected\n' "$label"
  fi
}

write_skill() {
  local root="$1" bucket="$2" name="$3" body="$4"
  mkdir -p "$root/skills/$bucket/$name"
  printf '%s\n' "$body" >"$root/skills/$bucket/$name/SKILL.md"
}

reads_clean="$tmp/reads-clean"
mkdir -p "$reads_clean/skills/engineering/demo/lib"
printf 'details\n' >"$reads_clean/skills/engineering/demo/lib/detail.md"
write_skill "$reads_clean" engineering demo "---
name: demo
reads:
  - skill: lib/detail.md
---
# Demo
Load \`lib/detail.md\`."
pass_case reads-clean python3 scripts/lint-reads-block.py "$reads_clean"

reads_drift="$tmp/reads-drift"
mkdir -p "$reads_drift/skills/engineering/demo/lib"
printf 'details\n' >"$reads_drift/skills/engineering/demo/lib/detail.md"
write_skill "$reads_drift" engineering demo "---
name: demo
reads:
  - repo: lib/other.md
---
# Demo
Load \`lib/detail.md\`."
fail_case reads-drift python3 scripts/lint-reads-block.py "$reads_drift"

reads_root_fallback="$tmp/reads-root-fallback"
mkdir -p "$reads_root_fallback/lib"
printf 'root-only details\n' >"$reads_root_fallback/lib/detail.md"
write_skill "$reads_root_fallback" engineering demo "---
name: demo
reads:
  - repo: lib/detail.md
---
# Demo
Load \`lib/detail.md\`."
fail_case reads-root-fallback \
  python3 scripts/lint-reads-block.py "$reads_root_fallback"

reads_escape="$tmp/reads-escape"
write_skill "$reads_escape" engineering demo "---
name: demo
reads:
  - skill: ../lib/detail.md
---
# Demo
Load \`lib/detail.md\`."
fail_case reads-escape python3 scripts/lint-reads-block.py "$reads_escape"

reads_body_escape="$tmp/reads-body-escape"
mkdir -p "$reads_body_escape/skills/engineering/lib"
printf 'outside skill\n' >"$reads_body_escape/skills/engineering/lib/detail.md"
write_skill "$reads_body_escape" engineering demo "---
name: demo
reads:
  - repo: skills/engineering/lib/detail.md
---
# Demo
Load \`../lib/detail.md\`."
fail_case reads-body-escape \
  python3 scripts/lint-reads-block.py "$reads_body_escape"

reads_symlink="$tmp/reads-symlink"
mkdir -p "$reads_symlink/skills/engineering/demo/lib"
printf 'outside\n' >"$reads_symlink/outside.md"
ln -s "$reads_symlink/outside.md" \
  "$reads_symlink/skills/engineering/demo/lib/detail.md"
write_skill "$reads_symlink" engineering demo "---
name: demo
reads:
  - skill: lib/detail.md
---
# Demo
Load \`lib/detail.md\`."
fail_case reads-symlink python3 scripts/lint-reads-block.py "$reads_symlink"

meta_clean="$tmp/meta-clean"
write_skill "$meta_clean" meta demo "---
name: demo
version: 1.2.3
description: Demo description.
---
# Demo"
printf '{"version":"1.2.3","description":"Demo description."}\n' >"$meta_clean/skills/meta/demo/_meta.json"
pass_case meta-clean python3 scripts/lint-meta-sync.py "$meta_clean"

meta_drift="$tmp/meta-drift"
write_skill "$meta_drift" meta demo "---
name: demo
version: 1.2.3
description: Demo description.
---
# Demo"
printf '{"version":"9.9.9","description":"Demo description."}\n' >"$meta_drift/skills/meta/demo/_meta.json"
fail_case meta-drift python3 scripts/lint-meta-sync.py "$meta_drift"

refs_clean="$tmp/refs-clean"
write_skill "$refs_clean" engineering real "---
name: real
---
# Real"
write_skill "$refs_clean" meta demo "---
name: demo
reads:
  - skill: real
---
# Demo
Use \`verbs:real\` and \`/real\`."
pass_case refs-clean python3 scripts/lint-refs-resolve.py "$refs_clean"

refs_drift="$tmp/refs-drift"
write_skill "$refs_drift" meta demo "---
name: demo
reads:
  - skill: ghost
---
# Demo
Use \`verbs:ghost\` and \`/ghost-command\`."
fail_case refs-drift python3 scripts/lint-refs-resolve.py "$refs_drift"

refs_root_fallback="$tmp/refs-root-fallback"
mkdir -p "$refs_root_fallback/lib"
printf 'root-only details\n' >"$refs_root_fallback/lib/detail.md"
write_skill "$refs_root_fallback" meta demo "---
name: demo
reads:
  - skill: lib/detail.md
---
# Demo
Load \`lib/detail.md\`."
fail_case refs-root-fallback \
  python3 scripts/lint-refs-resolve.py "$refs_root_fallback"

refs_escape="$tmp/refs-escape"
write_skill "$refs_escape" meta demo "---
name: demo
reads:
  - skill: ../lib/detail.md
---
# Demo"
fail_case refs-escape python3 scripts/lint-refs-resolve.py "$refs_escape"

refs_symlink="$tmp/refs-symlink"
mkdir -p "$refs_symlink/skills/meta/demo/lib"
printf 'outside\n' >"$refs_symlink/outside.md"
ln -s "$refs_symlink/outside.md" "$refs_symlink/skills/meta/demo/lib/detail.md"
write_skill "$refs_symlink" meta demo "---
name: demo
reads:
  - skill: lib/detail.md
---
# Demo"
fail_case refs-symlink python3 scripts/lint-refs-resolve.py "$refs_symlink"

if [ "$fail" -ne 0 ]; then
  echo "lint-blind-classes-test: one or more seeded checks failed"
  exit 1
fi

echo "lint-blind-classes-test: all seeded clean/drift checks behaved as expected"
