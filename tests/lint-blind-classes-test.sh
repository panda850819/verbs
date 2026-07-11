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
  - repo: skills/engineering/demo/lib/detail.md
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
---
# Demo
Use \`verbs:real\` and \`/real\`."
pass_case refs-clean python3 scripts/lint-refs-resolve.py "$refs_clean"

refs_drift="$tmp/refs-drift"
write_skill "$refs_drift" meta demo "---
name: demo
---
# Demo
Use \`verbs:ghost\` and \`/ghost-command\`."
fail_case refs-drift python3 scripts/lint-refs-resolve.py "$refs_drift"

quotes_clean="$tmp/quotes-clean"
write_skill "$quotes_clean" meta demo "---
name: demo
---
# Demo
This exact current sentence is present."
cat >"$quotes_clean/skills/meta/demo/eval.md" <<'EOF'
---
type: skill-eval
skill: demo
---
Grounding sample: L5 — "This exact current sentence is present."
EOF
pass_case quotes-clean python3 scripts/lint-eval-quotes.py "$quotes_clean"

quotes_drift="$tmp/quotes-drift"
write_skill "$quotes_drift" meta demo "---
name: demo
---
# Demo
This exact current sentence is present."
cat >"$quotes_drift/skills/meta/demo/eval.md" <<'EOF'
---
type: skill-eval
skill: demo
---
Grounding sample: L5 — "This stale quoted sentence is absent."
EOF
fail_case quotes-drift python3 scripts/lint-eval-quotes.py "$quotes_drift"

quotes_missing="$tmp/quotes-missing"
write_skill "$quotes_missing" meta demo "---
name: demo
---
# Demo
This exact current sentence is present."
cat >"$quotes_missing/skills/meta/demo/eval.md" <<'EOF'
---
type: skill-eval
skill: demo
---
No grounding sample is present.
EOF
fail_case quotes-missing python3 scripts/lint-eval-quotes.py "$quotes_missing"

if [ "$fail" -ne 0 ]; then
  echo "lint-blind-classes-test: one or more seeded checks failed"
  exit 1
fi

echo "lint-blind-classes-test: all seeded clean/drift checks behaved as expected"
