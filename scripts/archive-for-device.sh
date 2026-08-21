#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"

if [[ "$(/usr/bin/xcode-select -p)" == "/Library/Developer/CommandLineTools" && -z "${DEVELOPER_DIR:-}" ]]; then
  print -u2 "Full Xcode is required. Set DEVELOPER_DIR to its Contents/Developer directory."
  exit 1
fi

version="$(tr -d '\n' < VERSION)"
archive_path="$project_root/dist/PhotoTidy-v$version.xcarchive"

mkdir -p "$project_root/dist"

if [[ -e "$archive_path" ]]; then
  print -u2 "Archive already exists: $archive_path"
  print -u2 "Move it aside or choose a new version before creating another archive."
  exit 1
fi

print "Creating a signed development archive at $archive_path"
xcodebuild \
  -project PhotoTidy.xcodeproj \
  -scheme PhotoTidy \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" \
  -allowProvisioningUpdates \
  archive

print "Signed archive created."
