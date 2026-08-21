#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  print -u2 "This project must be in a Git repository before packaging."
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  print -u2 "Refusing to package a dirty worktree. Commit or stash the changes first."
  exit 1
fi

version="$(tr -d '\n' < VERSION)"
release_ref="${1:-v$version}"
package_directory="$project_root/dist"
archive="$package_directory/PhotoTidy-v$version-source.zip"
checksum="$archive.sha256"

if ! git rev-parse --verify --quiet "$release_ref^{commit}" >/dev/null; then
  print -u2 "Release ref does not resolve to a commit: $release_ref"
  exit 1
fi

if [[ -e "$archive" || -e "$checksum" ]]; then
  print -u2 "Release artifact already exists for v$version. Choose a new version; do not overwrite it."
  exit 1
fi

mkdir -p "$package_directory"
git archive --format=zip --prefix="PhotoTidy-v$version/" "$release_ref" > "$archive"
shasum -a 256 "$archive" > "$checksum"

print "Packaged Git ref $release_ref"
print "Created $archive"
print "Created $checksum"
