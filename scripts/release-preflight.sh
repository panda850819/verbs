#!/usr/bin/env bash
# Build and validate a release artifact without publishing it.
set -euo pipefail

usage() {
  echo "Usage: bash scripts/release-preflight.sh --candidate|--tag v<manifest-version>" >&2
  exit 2
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

[ "$#" -eq 2 ] || usage
mode="$1"
requested_ref="$2"
case "$mode" in
  --candidate|--tag) ;;
  *) usage ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"
cd "$repo_root"

[ -f manifest.toml ] || die "manifest.toml is missing"

if ! manifest_facts="$(python3 - manifest.toml <<'PY'
import re
import sys

path = sys.argv[1]
section = None
versions = []
product = {}
with open(path, encoding="utf-8") as handle:
    for raw_line in handle:
        line = raw_line.strip()
        section_match = re.match(r"^\[([^]]+)\]$", line)
        if section_match:
            section = section_match.group(1)
            continue
        if section == "manifest":
            version_match = re.match(r'^version\s*=\s*"([^"\r\n]+)"\s*(?:#.*)?$', line)
            if version_match:
                versions.append(version_match.group(1))
        elif section == "product":
            value_match = re.match(
                r'^(id|marketplace_id|archive_prefix)\s*=\s*"([^"\r\n]+)"\s*(?:#.*)?$',
                line,
            )
            if value_match:
                key, value = value_match.groups()
                product.setdefault(key, []).append(value)

if len(versions) != 1:
    print("manifest.toml must contain exactly one [manifest] version", file=sys.stderr)
    sys.exit(1)
for key in ("id", "marketplace_id", "archive_prefix"):
    values = product.get(key, [])
    if len(values) != 1:
        print(
            "manifest.toml must contain exactly one [product] {}".format(key),
            file=sys.stderr,
        )
        sys.exit(1)
    if re.fullmatch(r"[a-z0-9][a-z0-9._-]*", values[0]) is None:
        print("manifest.toml [product] {} is not release-safe".format(key), file=sys.stderr)
        sys.exit(1)

print(
    "\t".join(
        [
            versions[0],
            product["archive_prefix"][0],
            product["id"][0],
            product["marketplace_id"][0],
        ]
    )
)
PY
)"; then
  die "cannot derive release identity from manifest.toml"
fi

IFS=$'\t' read -r manifest_version archive_prefix product_id marketplace_id \
  <<< "$manifest_facts"
[ -n "$manifest_version" ] && [ -n "$archive_prefix" ] && \
  [ -n "$product_id" ] && [ -n "$marketplace_id" ] || \
  die "manifest.toml release identity is incomplete"

release_ref="v$manifest_version"
archive_name="$archive_prefix-$release_ref.tar.gz"
plugin_selector="$product_id@$marketplace_id"
dist_title="dist/release-title.txt"
dist_notes="dist/release-notes.md"
dist_archive="dist/$archive_name"
dist_checksum="$dist_archive.sha256"
tmp_root=""

remove_dist_outputs() {
  rm -f "$dist_title"
  rm -f "$dist_notes"
  rm -f "$dist_archive"
  rm -f "$dist_checksum"
}

cleanup_on_exit() {
  status=$?
  trap - EXIT HUP INT TERM
  if [ -n "$tmp_root" ] && [ -d "$tmp_root" ]; then
    rm -rf "$tmp_root" || true
  fi
  if [ "$status" -ne 0 ]; then
    rm -f "$dist_title" || true
    rm -f "$dist_notes" || true
    rm -f "$dist_archive" || true
    rm -f "$dist_checksum" || true
  fi
  exit "$status"
}

trap cleanup_on_exit EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

# Clear only the known outputs. Unknown dist contents are never removed.
remove_dist_outputs

[ "$requested_ref" = "$release_ref" ] || die \
  "requested release $requested_ref does not equal manifest release $release_ref"
[ -f CHANGELOG.md ] || die "CHANGELOG.md is missing"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git worktree"
head_commit="$(git rev-parse --verify 'HEAD^{commit}' 2>/dev/null)" || \
  die "HEAD is not a commit"
worktree_status="$(git status --porcelain --untracked-files=all)"
[ -z "$worktree_status" ] || die "release preflight requires a clean worktree"

if [ "$mode" = "--tag" ]; then
  tag_ref="refs/tags/$release_ref"
  git show-ref --verify --quiet "$tag_ref" || die "tag $release_ref does not exist"
  tag_type="$(git cat-file -t "$tag_ref" 2>/dev/null)" || die "cannot inspect tag $release_ref"
  [ "$tag_type" = "tag" ] || die "tag $release_ref must be annotated"
  tag_commit="$(git rev-parse --verify "$tag_ref^{commit}" 2>/dev/null)" || \
    die "annotated tag $release_ref does not point to a commit"
  [ "$tag_commit" = "$head_commit" ] || die "tag $release_ref is not at checked-out HEAD"
  git show-ref --verify --quiet refs/remotes/origin/main || \
    die "origin/main is unavailable"
  git merge-base --is-ancestor "$tag_commit" refs/remotes/origin/main || \
    die "tag $release_ref is not contained in origin/main"
fi

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/$archive_prefix-release.XXXXXX")"
stage_dir="$tmp_root/stage"
extract_dir="$tmp_root/extract"
test_home="$tmp_root/home"
mkdir -p "$stage_dir" "$extract_dir" "$test_home"

stage_title="$stage_dir/release-title.txt"
stage_notes="$stage_dir/release-notes.md"
stage_archive="$stage_dir/$archive_name"
stage_checksum="$stage_archive.sha256"
package_dir_name="$archive_prefix-$release_ref"
package_prefix="$package_dir_name/"

python3 - CHANGELOG.md "$manifest_version" "$stage_title" "$stage_notes" <<'PY'
import re
import sys
from datetime import date

source, version, title_path, notes_path = sys.argv[1:]
with open(source, encoding="utf-8") as handle:
    lines = handle.read().splitlines()

prefix = "## v{}".format(version)
same_version = [
    index for index, line in enumerate(lines)
    if line == prefix or line.startswith(prefix + " ")
]
if len(same_version) != 1:
    print(
        "CHANGELOG.md must contain exactly one heading for v{}; found {}".format(
            version, len(same_version)
        ),
        file=sys.stderr,
    )
    sys.exit(1)

start = same_version[0]
heading = lines[start]
pattern = r"## v{} — \S(?:.*\S)?".format(re.escape(version))
if re.fullmatch(pattern, heading) is None:
    print(
        "CHANGELOG.md heading must be exactly '## v{} — <codename>'".format(version),
        file=sys.stderr,
    )
    sys.exit(1)

end = len(lines)
for index in range(start + 1, len(lines)):
    if lines[index].startswith("## "):
        end = index
        break

body = lines[start + 1:end]
while body and not body[0].strip():
    body.pop(0)
while body and not body[-1].strip():
    body.pop()

released_lines = [line for line in body if line.startswith("Released:")]
if len(released_lines) != 1:
    print(
        "CHANGELOG.md section for v{} must contain exactly one Released: line; found {}".format(
            version, len(released_lines)
        ),
        file=sys.stderr,
    )
    sys.exit(1)
if not body or body[0] != released_lines[0]:
    print(
        "first nonblank line for v{} must be Released: YYYY-MM-DD".format(version),
        file=sys.stderr,
    )
    sys.exit(1)
released_match = re.fullmatch(r"Released: (\d{4}-\d{2}-\d{2})", released_lines[0])
if released_match is None:
    print(
        "Released date for v{} must use a real ISO YYYY-MM-DD date".format(version),
        file=sys.stderr,
    )
    sys.exit(1)
try:
    date.fromisoformat(released_match.group(1))
except ValueError:
    print(
        "Released date for v{} must use a real ISO YYYY-MM-DD date".format(version),
        file=sys.stderr,
    )
    sys.exit(1)
if not any(line.strip() for line in body[1:]):
    print(
        "CHANGELOG.md section for v{} must contain nonempty notes after Released:".format(version),
        file=sys.stderr,
    )
    sys.exit(1)

with open(title_path, "w", encoding="utf-8", newline="\n") as handle:
    handle.write(heading[3:] + "\n")
with open(notes_path, "w", encoding="utf-8", newline="\n") as handle:
    if body:
        handle.write("\n".join(body) + "\n")
PY

if [ "$mode" = "--tag" ]; then
  release_title="$(cat "$stage_title")"
  tag_subject="$(git for-each-ref --format='%(contents:subject)' "$tag_ref")"
  [ "$tag_subject" = "$release_title" ] || die \
    "annotated tag subject must equal release title: $release_title"
fi

git archive --format=tar --prefix="$package_prefix" HEAD | gzip -n > "$stage_archive"

python3 - "$stage_archive" "$package_prefix" <<'PY'
import collections
import subprocess
import sys
import tarfile

archive, prefix = sys.argv[1:]
expected_raw = subprocess.check_output(
    ["git", "ls-tree", "-r", "--name-only", "-z", "HEAD"]
)
expected = [item.decode("utf-8", "surrogateescape") for item in expected_raw.split(b"\0") if item]

actual = []
with tarfile.open(archive, "r:gz") as handle:
    for member in handle.getmembers():
        if member.isdir():
            continue
        if not member.name.startswith(prefix):
            print("archive member is outside expected prefix: {}".format(member.name), file=sys.stderr)
            sys.exit(1)
        relative = member.name[len(prefix):]
        if not relative:
            print("archive contains an empty normalized path", file=sys.stderr)
            sys.exit(1)
        actual.append(relative)

expected_counts = collections.Counter(expected)
actual_counts = collections.Counter(actual)
if expected_counts != actual_counts:
    missing = sorted((expected_counts - actual_counts).elements())
    extra = sorted((actual_counts - expected_counts).elements())
    print("archive file list differs from git ls-tree", file=sys.stderr)
    if missing:
        print("missing from archive: {}".format(", ".join(missing)), file=sys.stderr)
    if extra:
        print("extra in archive: {}".format(", ".join(extra)), file=sys.stderr)
    sys.exit(1)
PY

tar -xzf "$stage_archive" -C "$extract_dir"
package_root="$extract_dir/$package_dir_name"
[ -f "$package_root/LICENSE" ] || die "extracted package is missing root LICENSE"
[ -f "$package_root/THIRD_PARTY_NOTICES.md" ] || \
  die "extracted package is missing root THIRD_PARTY_NOTICES.md"

VERBS_REPO_ROOT="$package_root" \
  "$package_root/scripts/verbs" sync --check

(
  cd "$package_root"
  VERBS_RELEASE_PREFLIGHT_INNER=1 bash tests/run-all.sh
)

# Synthetic cache-layout proof only. This checks the packaged manifests and
# doctor scanner against host-shaped cache paths; it is not real installer proof.
echo "INFO: synthetic cache-layout check only (not real installer proof)"
claude_cache="$test_home/.claude/plugins/cache/$marketplace_id/$product_id/$manifest_version"
codex_cache="$test_home/.codex/plugins/cache/$marketplace_id/$product_id/$manifest_version"
mkdir -p "$(dirname "$claude_cache")" "$(dirname "$codex_cache")"
cp -R "$package_root" "$claude_cache"
cp -R "$package_root" "$codex_cache"

registry="$test_home/.claude/plugins/installed_plugins.json"
claude_settings="$test_home/.claude/settings.json"
codex_config="$test_home/.codex/config.toml"
python3 - "$registry" "$claude_cache" "$manifest_version" "$plugin_selector" \
  "$claude_settings" "$codex_config" <<'PY'
import json
import os
import sys

path, install_path, version, plugin_selector, settings_path, codex_path = sys.argv[1:]
parent = os.path.dirname(path)
if not os.path.isdir(parent):
    os.makedirs(parent)
data = {
    "version": 2,
    "plugins": {
        plugin_selector: [{
            "installPath": install_path,
            "version": version,
            "lastUpdated": "1970-01-01T00:00:00Z",
        }],
    },
}
with open(path, "w", encoding="utf-8", newline="\n") as handle:
    json.dump(data, handle, indent=2, sort_keys=True)
    handle.write("\n")

with open(settings_path, "w", encoding="utf-8", newline="\n") as handle:
    json.dump({"enabledPlugins": {plugin_selector: True}}, handle, indent=2)
    handle.write("\n")

codex_parent = os.path.dirname(codex_path)
if not os.path.isdir(codex_parent):
    os.makedirs(codex_parent)
with open(codex_path, "w", encoding="utf-8", newline="\n") as handle:
    handle.write('[plugins."{}"]\n'.format(plugin_selector))
    handle.write("enabled = true\n")
PY

HOME="$test_home" VERBS_REPO_ROOT="$package_root" \
  "$package_root/scripts/verbs" doctor --host claude --strict
HOME="$test_home" VERBS_REPO_ROOT="$package_root" \
  "$package_root/scripts/verbs" doctor --host codex --strict

archive_hash="$(python3 - "$stage_archive" <<'PY'
import hashlib
import sys

digest = hashlib.sha256()
with open(sys.argv[1], "rb") as handle:
    for chunk in iter(lambda: handle.read(1024 * 1024), b""):
        digest.update(chunk)
print(digest.hexdigest())
PY
)"
printf '%s  %s\n' "$archive_hash" "$archive_name" > "$stage_checksum"

# Publish only after the extracted package and both synthetic cache-layout
# checks pass. Real installer proof is a separate release gate.
mkdir -p dist
mv "$stage_title" "$dist_title"
mv "$stage_notes" "$dist_notes"
mv "$stage_archive" "$dist_archive"
mv "$stage_checksum" "$dist_checksum"

echo "OK: release preflight passed for $release_ref ($mode)"
echo "Artifacts: $dist_title $dist_notes $dist_archive $dist_checksum"
