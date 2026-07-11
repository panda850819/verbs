#!/usr/bin/env bash
# Offline synthetic fixtures for scripts/release-preflight.sh.
set -euo pipefail

if [ "${PANDA_VERBS_RELEASE_PREFLIGHT_INNER:-}" = "1" ]; then
  echo "SKIP: release-preflight-test.sh is exercised only by the outer suite; packaged preflight set PANDA_VERBS_RELEASE_PREFLIGHT_INNER=1"
  exit 0
fi

export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
script_under_test="$repo_root/scripts/release-preflight.sh"
real_mv="$(command -v mv)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/panda-verbs-release-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

fail=0
case_number=0
fixture=""
repo=""
remote=""
run_log=""

pass() {
  echo "PASS: $1"
}

fail_t() {
  echo "FAIL: $1"
  fail=1
}

git_in_repo() {
  git -C "$repo" "$@"
}

new_fixture() {
  case_number=$((case_number + 1))
  fixture="$tmp/case-$case_number"
  repo="$fixture/repo"
  remote="$fixture/origin.git"
  run_log="$fixture/preflight.log"
  mkdir -p "$repo/scripts" "$repo/tests"

  cp "$script_under_test" "$repo/scripts/release-preflight.sh"
  cat > "$repo/scripts/verbs" <<'EOF'
#!/usr/bin/env bash
set -u

root="${PANDA_VERBS_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
command_name="${1:-}"
shift || true

case "$command_name" in
  sync)
    [ "${1:-}" = "--check" ] || exit 20
    if [ -f "$root/.fixture-fail-sync" ]; then
      echo "fixture sync forced failure" >&2
      exit 21
    fi
    echo "fixture sync passed"
    ;;
  doctor)
    host=""
    strict=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --host) host="${2:-}"; shift 2 ;;
        --strict) strict=1; shift ;;
        *) exit 22 ;;
      esac
    done
    [ "$strict" -eq 1 ] || exit 23
    [ -f "$root/LICENSE" ] || exit 24
    case "$host" in
      claude)
        if [ -f "$root/.fixture-fail-claude" ]; then
          echo "fixture Claude strict forced failure" >&2
          exit 25
        fi
        cache="$HOME/.claude/plugins/cache/verbs/verbs/7.8.9"
        registry="$HOME/.claude/plugins/installed_plugins.json"
        [ -f "$cache/LICENSE" ] || exit 26
        python3 - "$registry" "$cache" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
records = data["plugins"]["verbs@verbs"]
if not isinstance(records, list) or len(records) != 1:
    sys.exit(1)
if records[0].get("installPath") != sys.argv[2]:
    sys.exit(1)
if records[0].get("version") != "7.8.9":
    sys.exit(1)
PY
        ;;
      codex)
        if [ -f "$root/.fixture-fail-codex" ]; then
          echo "fixture Codex strict forced failure" >&2
          exit 27
        fi
        cache="$HOME/.codex/plugins/cache/verbs/verbs/7.8.9"
        [ -f "$cache/LICENSE" ] || exit 28
        ;;
      *) exit 29 ;;
    esac
    echo "fixture $host doctor passed"
    ;;
  *) exit 30 ;;
esac
EOF

  cat > "$repo/tests/run-all.sh" <<'EOF'
#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
[ "${PANDA_VERBS_RELEASE_PREFLIGHT_INNER:-}" = "1" ] || exit 31
bash tests/release-preflight-test.sh || exit 32
if [ -f .fixture-fail-tests ]; then
  echo "fixture canonical suite forced failure" >&2
  exit 33
fi
echo "fixture canonical suite passed"
EOF

  cat > "$repo/tests/release-preflight-test.sh" <<'EOF'
#!/usr/bin/env bash
if [ "${PANDA_VERBS_RELEASE_PREFLIGHT_INNER:-}" = "1" ]; then
  echo "SKIP: fixture release-preflight self-test skipped under the packaged suite"
  exit 0
fi
echo "FAIL: fixture self-test was invoked recursively without the inner guard"
exit 1
EOF

  cat > "$repo/manifest.toml" <<'EOF'
[product]
id = "verbs"
marketplace_id = "verbs"
archive_prefix = "panda-verbs"

[manifest]
version = "7.8.9"
EOF
  cat > "$repo/CHANGELOG.md" <<'EOF'
# Changelog

## v7.8.9 — Test Codename

Released: 2026-07-10

First release note.

- Second release note.

## v7.8.8 — Older

This older body must not enter the release notes.
EOF
  cat > "$repo/LICENSE" <<'EOF'
Fixture license
EOF
  cat > "$repo/THIRD_PARTY_NOTICES.md" <<'EOF'
Fixture third-party notices
EOF
  cat > "$repo/.gitignore" <<'EOF'
/dist/
EOF

  chmod +x "$repo/scripts/release-preflight.sh" "$repo/scripts/verbs" \
    "$repo/tests/run-all.sh" "$repo/tests/release-preflight-test.sh"

  git init -q --bare "$remote"
  git -C "$repo" init -q
  git_in_repo config user.name "Release Fixture"
  git_in_repo config user.email "fixture@example.invalid"
  git_in_repo add .
  git_in_repo commit -q -m "fixture: initial"
  git_in_repo branch -M main
  git_in_repo remote add origin "$remote"
  git_in_repo push -q -u origin main
}

commit_and_push() {
  git_in_repo add -A
  git_in_repo commit -q -m "fixture: $1"
  git_in_repo push -q origin HEAD:main
}

commit_local_only() {
  git_in_repo add -A
  git_in_repo commit -q -m "fixture: $1"
}

run_preflight() {
  (cd "$repo" && bash scripts/release-preflight.sh "$@") >"$run_log" 2>&1
}

archive_path() {
  echo "$repo/dist/panda-verbs-v7.8.9.tar.gz"
}

checksum_path() {
  echo "$repo/dist/panda-verbs-v7.8.9.tar.gz.sha256"
}

seed_stale_outputs() {
  mkdir -p "$repo/dist"
  printf '%s\n' stale > "$repo/dist/release-title.txt"
  printf '%s\n' stale > "$repo/dist/release-notes.md"
  printf '%s\n' stale > "$(archive_path)"
  printf '%s\n' stale > "$(checksum_path)"
}

assert_no_outputs() {
  label="$1"
  if [ -e "$repo/dist/release-title.txt" ] || \
     [ -e "$repo/dist/release-notes.md" ] || \
     [ -e "$(archive_path)" ] || \
     [ -e "$(checksum_path)" ]; then
    fail_t "$label left a release output after failure"
  else
    pass "$label leaves no publishable outputs"
  fi
}

assert_log_contains() {
  label="$1"
  expected="$2"
  if grep -Fq "$expected" "$run_log"; then
    pass "$label reports its failure class"
  else
    fail_t "$label diagnostic missing '$expected': $(tail -20 "$run_log")"
  fi
}

file_sha256() {
  python3 - "$1" <<'PY'
import hashlib
import sys

with open(sys.argv[1], "rb") as handle:
    print(hashlib.sha256(handle.read()).hexdigest())
PY
}

case_happy_candidate() {
  new_fixture
  if run_preflight --candidate v7.8.9; then
    pass "candidate happy path exits 0"
  else
    fail_t "candidate happy path failed: $(tail -20 "$run_log")"
    return
  fi

  if grep -Fq "INFO: synthetic cache-layout check only (not real installer proof)" "$run_log"; then
    pass "candidate labels synthetic cache-layout proof honestly"
  else
    fail_t "candidate did not label synthetic cache-layout proof"
  fi

  if [ "$(cat "$repo/dist/release-title.txt")" = "v7.8.9 — Test Codename" ]; then
    pass "candidate derives the release title"
  else
    fail_t "candidate release title is wrong"
  fi

  cat > "$fixture/expected-notes.md" <<'EOF'
Released: 2026-07-10

First release note.

- Second release note.
EOF
  if cmp -s "$fixture/expected-notes.md" "$repo/dist/release-notes.md"; then
    pass "candidate extracts only the matching CHANGELOG body"
  else
    fail_t "candidate release notes are wrong"
  fi

  archive="$(archive_path)"
  checksum="$(checksum_path)"
  if [ -f "$archive" ] && [ -f "$checksum" ]; then
    pass "candidate publishes archive and checksum"
  else
    fail_t "candidate did not publish archive and checksum"
  fi

  expected_checksum="$(file_sha256 "$archive")  panda-verbs-v7.8.9.tar.gz"
  if [ "$(cat "$checksum")" = "$expected_checksum" ]; then
    pass "candidate checksum matches archive bytes"
  else
    fail_t "candidate checksum does not match archive"
  fi

  if python3 - "$archive" <<'PY'
import sys
import tarfile

prefix = "panda-verbs-v7.8.9/"
with tarfile.open(sys.argv[1], "r:gz") as handle:
    names = [member.name for member in handle.getmembers() if not member.isdir()]
if not names or not all(name.startswith(prefix) for name in names):
    sys.exit(1)
if prefix + "LICENSE" not in names or prefix + "THIRD_PARTY_NOTICES.md" not in names:
    sys.exit(1)
PY
  then
    pass "candidate archive uses the release prefix and contains required notices"
  else
    fail_t "candidate archive prefix or root notices are wrong"
  fi

  if [ -z "$(git_in_repo tag)" ]; then
    pass "candidate mode creates no tag"
  else
    fail_t "candidate mode must not create a tag"
  fi
}

case_deterministic_candidate() {
  new_fixture
  if ! run_preflight --candidate v7.8.9; then
    fail_t "first deterministic candidate run failed: $(tail -20 "$run_log")"
    return
  fi
  first_hash="$(file_sha256 "$(archive_path)")"
  first_checksum="$(cat "$(checksum_path)")"
  if ! run_preflight --candidate v7.8.9; then
    fail_t "second deterministic candidate run failed: $(tail -20 "$run_log")"
    return
  fi
  second_hash="$(file_sha256 "$(archive_path)")"
  second_checksum="$(cat "$(checksum_path)")"
  if [ "$first_hash" = "$second_hash" ] && [ "$first_checksum" = "$second_checksum" ]; then
    pass "candidate archive and checksum are deterministic across two runs"
  else
    fail_t "candidate output changed across identical runs"
  fi
}

case_manifest_archive_prefix() {
  new_fixture
  python3 - "$repo/manifest.toml" <<'PY'
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = text.replace('archive_prefix = "panda-verbs"', 'archive_prefix = "fixture-verbs"', 1)
open(path, "w", encoding="utf-8", newline="\n").write(text)
PY
  commit_and_push "change manifest archive prefix"
  if run_preflight --candidate v7.8.9; then
    pass "candidate derives archive name from manifest product identity"
  else
    fail_t "manifest-derived archive candidate failed: $(tail -20 "$run_log")"
    return
  fi

  derived_archive="$repo/dist/fixture-verbs-v7.8.9.tar.gz"
  derived_checksum="$derived_archive.sha256"
  if [ -f "$derived_archive" ] && [ -f "$derived_checksum" ] && \
     [ ! -e "$(archive_path)" ] && [ ! -e "$(checksum_path)" ]; then
    pass "manifest archive prefix controls both release outputs"
  else
    fail_t "release outputs did not follow the manifest archive prefix"
  fi

  if python3 - "$derived_archive" <<'PY'
import sys
import tarfile

prefix = "fixture-verbs-v7.8.9/"
with tarfile.open(sys.argv[1], "r:gz") as handle:
    names = [member.name for member in handle.getmembers() if not member.isdir()]
if not names or not all(name.startswith(prefix) for name in names):
    sys.exit(1)
PY
  then
    pass "manifest archive prefix controls the package root"
  else
    fail_t "package root did not follow the manifest archive prefix"
  fi
}

case_candidate_feature_branch() {
  new_fixture
  git_in_repo checkout -q -b feature/release-candidate
  if run_preflight --candidate v7.8.9; then
    pass "candidate mode passes on a clean feature branch"
  else
    fail_t "candidate mode must remain branch-agnostic: $(tail -20 "$run_log")"
  fi
}

case_version_mismatch() {
  new_fixture
  seed_stale_outputs
  if run_preflight --candidate v9.9.9; then
    fail_t "version mismatch should fail"
  else
    pass "version mismatch fails"
  fi
  assert_log_contains "version mismatch" \
    "requested release v9.9.9 does not equal manifest release v7.8.9"
  assert_no_outputs "version mismatch"
}

case_missing_changelog_section() {
  new_fixture
  python3 - "$repo/CHANGELOG.md" <<'PY'
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = text.replace("## v7.8.9 — Test Codename", "## v7.8.7 — Wrong Release")
open(path, "w", encoding="utf-8", newline="\n").write(text)
PY
  commit_and_push "remove current changelog section"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "missing CHANGELOG section should fail"
  else
    pass "missing CHANGELOG section fails"
  fi
  assert_log_contains "missing CHANGELOG section" \
    "CHANGELOG.md must contain exactly one heading for v7.8.9; found 0"
  assert_no_outputs "missing CHANGELOG section"
}

case_ambiguous_changelog_section() {
  new_fixture
  cat >> "$repo/CHANGELOG.md" <<'EOF'

## v7.8.9 — Duplicate

Released: 2026-07-11

Duplicate body.
EOF
  commit_and_push "duplicate current changelog section"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "ambiguous CHANGELOG section should fail"
  else
    pass "ambiguous CHANGELOG section fails"
  fi
  assert_log_contains "ambiguous CHANGELOG section" \
    "CHANGELOG.md must contain exactly one heading for v7.8.9; found 2"
  assert_no_outputs "ambiguous CHANGELOG section"
}

case_missing_released_line() {
  new_fixture
  python3 - "$repo/CHANGELOG.md" <<'PY'
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = text.replace("Released: 2026-07-10\n\n", "")
open(path, "w", encoding="utf-8", newline="\n").write(text)
PY
  commit_and_push "remove Released metadata"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "missing Released line should fail"
  else
    pass "missing Released line fails"
  fi
  assert_log_contains "missing Released line" \
    "must contain exactly one Released: line; found 0"
  assert_no_outputs "missing Released line"
}

case_duplicate_released_line() {
  new_fixture
  python3 - "$repo/CHANGELOG.md" <<'PY'
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = text.replace(
    "Released: 2026-07-10\n",
    "Released: 2026-07-10\nReleased: 2026-07-11\n",
    1,
)
open(path, "w", encoding="utf-8", newline="\n").write(text)
PY
  commit_and_push "duplicate Released metadata"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "duplicate Released line should fail"
  else
    pass "duplicate Released line fails"
  fi
  assert_log_contains "duplicate Released line" \
    "must contain exactly one Released: line; found 2"
  assert_no_outputs "duplicate Released line"
}

case_malformed_released_date() {
  new_fixture
  python3 - "$repo/CHANGELOG.md" <<'PY'
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = text.replace("Released: 2026-07-10", "Released: 2026-02-30", 1)
open(path, "w", encoding="utf-8", newline="\n").write(text)
PY
  commit_and_push "malform Released date"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "malformed Released date should fail"
  else
    pass "malformed Released date fails"
  fi
  assert_log_contains "malformed Released date" \
    "Released date for v7.8.9 must use a real ISO YYYY-MM-DD date"
  assert_no_outputs "malformed Released date"
}

case_empty_release_notes() {
  new_fixture
  cat > "$repo/CHANGELOG.md" <<'EOF'
# Changelog

## v7.8.9 — Test Codename

Released: 2026-07-10

## v7.8.8 — Older

Older body.
EOF
  commit_and_push "empty release notes"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "empty release notes should fail"
  else
    pass "empty release notes fail"
  fi
  assert_log_contains "empty release notes" \
    "must contain nonempty notes after Released:"
  assert_no_outputs "empty release notes"
}

case_released_line_not_first() {
  new_fixture
  python3 - "$repo/CHANGELOG.md" <<'PY'
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = text.replace(
    "Released: 2026-07-10",
    "Intro before metadata.\n\nReleased: 2026-07-10",
    1,
)
open(path, "w", encoding="utf-8", newline="\n").write(text)
PY
  commit_and_push "move Released metadata after notes"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "Released line after notes should fail"
  else
    pass "Released line after notes fails"
  fi
  assert_log_contains "Released line after notes" \
    "first nonblank line for v7.8.9 must be Released: YYYY-MM-DD"
  assert_no_outputs "Released line after notes"
}

case_export_ignore_drift() {
  new_fixture
  printf '%s\n' 'exported.txt export-ignore' > "$repo/.gitattributes"
  printf '%s\n' 'must be in release' > "$repo/exported.txt"
  commit_and_push "add export-ignore drift"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "export-ignore file-list drift should fail"
  else
    pass "export-ignore file-list drift fails"
  fi
  assert_log_contains "export-ignore drift" \
    "archive file list differs from git ls-tree"
  assert_no_outputs "export-ignore drift"
}

case_tests_failure() {
  new_fixture
  : > "$repo/.fixture-fail-tests"
  commit_and_push "force canonical suite failure"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "canonical tests failure should fail preflight"
  else
    pass "canonical tests failure fails preflight"
  fi
  assert_log_contains "canonical tests failure" \
    "fixture canonical suite forced failure"
  assert_no_outputs "canonical tests failure"
}

case_sync_failure() {
  new_fixture
  : > "$repo/.fixture-fail-sync"
  commit_and_push "force sync failure"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "sync failure should fail preflight"
  else
    pass "sync failure fails preflight"
  fi
  assert_log_contains "sync failure" "fixture sync forced failure"
  assert_no_outputs "sync failure"
}

case_claude_strict_failure() {
  new_fixture
  : > "$repo/.fixture-fail-claude"
  commit_and_push "force Claude strict failure"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "Claude strict failure should fail preflight"
  else
    pass "Claude strict failure fails preflight"
  fi
  assert_log_contains "Claude strict failure" \
    "fixture Claude strict forced failure"
  assert_no_outputs "Claude strict failure"
}

case_codex_strict_failure() {
  new_fixture
  : > "$repo/.fixture-fail-codex"
  commit_and_push "force Codex strict failure"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "Codex strict failure should fail preflight"
  else
    pass "Codex strict failure fails preflight"
  fi
  assert_log_contains "Codex strict failure" \
    "fixture Codex strict forced failure"
  assert_no_outputs "Codex strict failure"
}

case_publish_mv_failure_cleanup() {
  new_fixture
  fake_bin="$fixture/fake-bin"
  mv_counter="$fixture/mv-counter"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/mv" <<'EOF'
#!/usr/bin/env bash
set -eu

count=0
if [ -f "$FAKE_MV_COUNTER" ]; then
  count="$(cat "$FAKE_MV_COUNTER")"
fi
count=$((count + 1))
printf '%s\n' "$count" > "$FAKE_MV_COUNTER"
if [ "$count" -eq 3 ]; then
  echo "fixture mv forced failure on final move 3" >&2
  exit 88
fi
exec "$FAKE_MV_REAL" "$@"
EOF
  chmod +x "$fake_bin/mv"
  seed_stale_outputs
  if (
    cd "$repo"
    PATH="$fake_bin:$PATH" FAKE_MV_REAL="$real_mv" FAKE_MV_COUNTER="$mv_counter" \
      bash scripts/release-preflight.sh --candidate v7.8.9
  ) >"$run_log" 2>&1; then
    fail_t "later final mv failure should fail preflight"
  else
    pass "later final mv failure fails preflight"
  fi
  assert_log_contains "later final mv failure" \
    "fixture mv forced failure on final move 3"
  if [ "$(cat "$mv_counter")" = "3" ]; then
    pass "fake mv failed after two outputs were moved"
  else
    fail_t "fake mv did not fail on final move 3"
  fi
  assert_no_outputs "later final mv failure"
}

case_lightweight_tag() {
  new_fixture
  git_in_repo update-ref refs/tags/v7.8.9 HEAD
  if [ "$(git_in_repo cat-file -t refs/tags/v7.8.9)" != "commit" ]; then
    fail_t "fixture did not create a lightweight tag"
    return
  fi
  seed_stale_outputs
  if run_preflight --tag v7.8.9; then
    fail_t "lightweight tag should fail"
  else
    pass "lightweight tag fails"
  fi
  assert_log_contains "lightweight tag" "tag v7.8.9 must be annotated"
  assert_no_outputs "lightweight tag"
}

case_tag_not_at_head() {
  new_fixture
  git_in_repo tag -a v7.8.9 -m "v7.8.9 — Test Codename"
  printf '%s\n' 'later commit' > "$repo/later.txt"
  commit_and_push "advance HEAD after tag"
  seed_stale_outputs
  if run_preflight --tag v7.8.9; then
    fail_t "tag not at HEAD should fail"
  else
    pass "tag not at HEAD fails"
  fi
  assert_log_contains "tag not at HEAD" \
    "tag v7.8.9 is not at checked-out HEAD"
  assert_no_outputs "tag not at HEAD"
}

case_tag_not_in_origin_main() {
  new_fixture
  printf '%s\n' 'local release commit' > "$repo/local-release.txt"
  commit_local_only "local release commit"
  git_in_repo tag -a v7.8.9 -m "v7.8.9 — Test Codename"
  seed_stale_outputs
  if run_preflight --tag v7.8.9; then
    fail_t "tag outside origin/main should fail"
  else
    pass "annotated tag outside origin/main fails"
  fi
  assert_log_contains "tag outside origin/main" \
    "tag v7.8.9 is not contained in origin/main"
  assert_no_outputs "tag outside origin/main"
}

case_tag_subject_mismatch() {
  new_fixture
  git_in_repo tag -a v7.8.9 -m "v7.8.9 — Wrong Subject"
  seed_stale_outputs
  if run_preflight --tag v7.8.9; then
    fail_t "tag subject mismatch should fail"
  else
    pass "tag subject mismatch fails"
  fi
  assert_log_contains "tag subject mismatch" \
    "annotated tag subject must equal release title: v7.8.9 — Test Codename"
  assert_no_outputs "tag subject mismatch"
}

case_happy_annotated_tag() {
  new_fixture
  git_in_repo tag -a v7.8.9 -m "v7.8.9 — Test Codename"
  if run_preflight --tag v7.8.9; then
    pass "annotated tag at HEAD contained in origin/main passes"
  else
    fail_t "valid annotated tag failed: $(tail -20 "$run_log")"
  fi
}

case_unstaged_dirty_worktree() {
  new_fixture
  printf '%s\n' dirty >> "$repo/LICENSE"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "dirty worktree should fail"
  else
    pass "unstaged dirty worktree fails"
  fi
  assert_log_contains "unstaged dirty worktree" \
    "release preflight requires a clean worktree"
  assert_no_outputs "unstaged dirty worktree"
}

case_staged_dirty_worktree() {
  new_fixture
  printf '%s\n' staged >> "$repo/LICENSE"
  git_in_repo add LICENSE
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "staged-only dirty worktree should fail"
  else
    pass "staged-only dirty worktree fails"
  fi
  assert_log_contains "staged-only dirty worktree" \
    "release preflight requires a clean worktree"
  assert_no_outputs "staged-only dirty worktree"
}

case_untracked_dirty_worktree() {
  new_fixture
  printf '%s\n' untracked > "$repo/untracked.txt"
  seed_stale_outputs
  if run_preflight --candidate v7.8.9; then
    fail_t "untracked dirty worktree should fail"
  else
    pass "untracked dirty worktree fails"
  fi
  assert_log_contains "untracked dirty worktree" \
    "release preflight requires a clean worktree"
  assert_no_outputs "untracked dirty worktree"
}

case_happy_candidate
case_deterministic_candidate
case_manifest_archive_prefix
case_candidate_feature_branch
case_version_mismatch
case_missing_changelog_section
case_ambiguous_changelog_section
case_missing_released_line
case_duplicate_released_line
case_malformed_released_date
case_empty_release_notes
case_released_line_not_first
case_export_ignore_drift
case_tests_failure
case_sync_failure
case_claude_strict_failure
case_codex_strict_failure
case_publish_mv_failure_cleanup
case_lightweight_tag
case_tag_not_at_head
case_tag_not_in_origin_main
case_tag_subject_mismatch
case_happy_annotated_tag
case_unstaged_dirty_worktree
case_staged_dirty_worktree
case_untracked_dirty_worktree

if [ "$fail" -eq 0 ]; then
  echo "OK: Panda Verbs release-preflight synthetic cache-layout fixtures all green (not installer proof)"
else
  echo "FAILURES present"
fi
exit "$fail"
