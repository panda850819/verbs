#!/usr/bin/env bash
# Offline legal-file regression checks, including a seeded mutation that must fail.
set -euo pipefail
cd "$(dirname "$0")/.."

ROOT="$(pwd)"
LICENSE_FILE="$ROOT/LICENSE"
NOTICES_FILE="$ROOT/THIRD_PARTY_NOTICES.md"
SLOWMIST_LICENSE="$ROOT/skills/meta/gatekeeper/LICENSE"
EXPECTED_LICENSE_SHA256="e9ad07e73ae343c448ab49d166bdf3c35af006044459ab079e7565133e517aaa"
EXPECTED_SLOWMIST_SHA256="9885788277a4efd90fe02e69b05595e91ad6e606570bcdbb27bc99e893570d65"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  return 1
}

sha256() {
  shasum -a 256 "$1" | awk '{print $1}'
}

require_literal() {
  local file="$1" literal="$2"
  grep -Fq -- "$literal" "$file" || fail "$file is missing: $literal"
}

require_exact_line() {
  local file="$1" line="$2"
  grep -Fqx -- "$line" "$file" || fail "$file is missing exact line: $line"
}

validate_license() {
  local file="$1" actual
  [ -f "$file" ] || { fail "missing root LICENSE"; return 1; }

  actual="$(sha256 "$file")"
  [ "$actual" = "$EXPECTED_LICENSE_SHA256" ] || {
    fail "root LICENSE differs from the canonical Panda Zeng MIT text"
    return 1
  }

  require_exact_line "$file" "MIT License" || return 1
  require_exact_line "$file" "Copyright (c) 2026 Panda Zeng" || return 1
  require_literal "$file" "Permission is hereby granted, free of charge" || return 1
  require_literal "$file" "The above copyright notice and this permission notice shall be included" || return 1
  require_literal "$file" 'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND' || return 1
}

validate_notices() {
  local file="$1" license="$2" needle count notice_terms license_terms
  local required=(
    "Panda-authored portions of Panda Verbs"
    'root [`LICENSE`](LICENSE)'
    "Adapted or included material"
    "tw93/Waza"
    "Copyright (c) 2026 Tw93"
    "https://github.com/tw93/Waza/blob/main/LICENSE"
    "skills/writing/write/references/slop-zh-residue.md"
    "skills/writing/write/references/slop-zh-translation.md"
    "skills/writing/write/references/prose-zh-structure.md"
    "skills/writing/write/references/slop-zh-report-tone.md"
    "mattpocock/skills"
    "Copyright (c) 2026 Matt Pocock"
    "https://github.com/mattpocock/skills/blob/main/LICENSE"
    "skills/meta/writing-great-skills/SKILL.md"
    "skills/meta/writing-great-skills/GLOSSARY.md"
    "skills/productivity/grill/SKILL.md"
    "garrytan/gstack"
    "Copyright (c) 2026 Garry Tan"
    "https://github.com/garrytan/gstack/blob/main/LICENSE"
    "lib/push-once.md"
    "lib/escape-hatch.md"
    "lib/stop-rule.md"
    "lib/bad-good-calibration.md"
    "op7418/Humanizer-zh"
    "Copyright (c) 2026 歸藏"
    "https://github.com/op7418/Humanizer-zh/blob/main/LICENSE"
    "skills/writing/write/references/zh-slop-patterns.md"
    "obra/superpowers"
    "Copyright (c) 2025 Jesse Vincent"
    "https://github.com/obra/superpowers/blob/main/LICENSE"
    "hooks/session-start"
    "host-shim design"
    "SlowMist / slowmist-agent-security"
    "Copyright (c) 2026 evilcos"
    "https://github.com/slowmist/slowmist-agent-security/blob/main/LICENSE"
    "skills/meta/gatekeeper/**"
    "skills/meta/gatekeeper/LICENSE"
    "Addy Osmani / addyosmani/agent-skills"
    "Copyright (c) 2025 Addy Osmani"
    "https://github.com/addyosmani/agent-skills/blob/main/LICENSE"
    "Design acknowledgement only"
    "apply separately to every adapted or included MIT"
    "Each component retains its copyright line"
  )

  [ -f "$file" ] || { fail "missing THIRD_PARTY_NOTICES.md"; return 1; }
  for needle in "${required[@]}"; do
    require_literal "$file" "$needle" || return 1
  done

  count="$(grep -Fxc 'Permission is hereby granted, free of charge, to any person obtaining a copy' "$file")"
  [ "$count" = "1" ] || {
    fail "THIRD_PARTY_NOTICES.md must contain the common MIT terms exactly once"
    return 1
  }

  notice_terms="$(sed -n '/^Permission is hereby granted/,$p' "$file")"
  license_terms="$(sed -n '/^Permission is hereby granted/,$p' "$license")"
  [ "$notice_terms" = "$license_terms" ] || {
    fail "THIRD_PARTY_NOTICES.md does not reproduce the exact MIT permission and warranty text"
    return 1
  }

  if grep -Eiq '(^|[^[:alnum:]_])(TODO|TBD|FIXME|XXX|CHANGEME|PLACEHOLDER)([^[:alnum:]_]|$)' "$file" "$license"; then
    fail "legal files contain a placeholder marker"
    return 1
  fi
}

validate_affected_paths() {
  local path actual
  local paths=(
    "skills/writing/write/references/slop-zh-residue.md"
    "skills/writing/write/references/slop-zh-translation.md"
    "skills/writing/write/references/prose-zh-structure.md"
    "skills/writing/write/references/slop-zh-report-tone.md"
    "skills/meta/writing-great-skills/SKILL.md"
    "skills/meta/writing-great-skills/GLOSSARY.md"
    "skills/productivity/grill/SKILL.md"
    "lib/push-once.md"
    "lib/escape-hatch.md"
    "lib/stop-rule.md"
    "lib/bad-good-calibration.md"
    "skills/writing/write/references/zh-slop-patterns.md"
    "hooks/session-start"
    "skills/meta/gatekeeper"
    "skills/meta/gatekeeper/LICENSE"
  )

  for path in "${paths[@]}"; do
    [ -e "$ROOT/$path" ] || { fail "notice points to missing path: $path"; return 1; }
  done

  [ -f "$SLOWMIST_LICENSE" ] || { fail "nested SlowMist LICENSE is missing"; return 1; }
  actual="$(sha256 "$SLOWMIST_LICENSE")"
  [ "$actual" = "$EXPECTED_SLOWMIST_SHA256" ] || {
    fail "nested SlowMist LICENSE changed or was replaced"
    return 1
  }
  require_exact_line "$SLOWMIST_LICENSE" "Copyright (c) 2026 evilcos" || return 1
  require_literal "$SLOWMIST_LICENSE" "Permission is hereby granted, free of charge" || return 1

  require_literal "$ROOT/CHANGELOG.md" "Format adapted from addyosmani/agent-skills." || return 1
}

validate_license "$LICENSE_FILE"
validate_notices "$NOTICES_FILE" "$LICENSE_FILE"
validate_affected_paths

# Seed a missing-notice regression and prove the validator rejects it.
tmp="$(mktemp -d)"
cleanup() {
  rm -f "$tmp/THIRD_PARTY_NOTICES.md"
  rmdir "$tmp"
}
trap cleanup EXIT
sed 's/Copyright (c) 2026 Tw93/Copyright (c) 2026 MUTATED/' "$NOTICES_FILE" >"$tmp/THIRD_PARTY_NOTICES.md"
if validate_notices "$tmp/THIRD_PARTY_NOTICES.md" "$LICENSE_FILE" >/dev/null 2>&1; then
  fail "seeded third-party notice mutation unexpectedly passed"
fi

echo "OK: legal files cover root and third-party MIT notices; seeded mutation failed as expected."
