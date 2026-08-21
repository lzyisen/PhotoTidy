#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="$project_root/build/verification"

if [[ "$(/usr/bin/xcode-select -p)" == "/Library/Developer/CommandLineTools" && -z "${DEVELOPER_DIR:-}" ]]; then
  print -u2 "Full Xcode is required. Set DEVELOPER_DIR to its Contents/Developer directory."
  exit 1
fi

cd "$project_root"

print "== Project discovery =="
xcodebuild -list -project PhotoTidy.xcodeproj

print "\n== Simulator compilation =="
xcodebuild \
  -project PhotoTidy.xcodeproj \
  -scheme PhotoTidy \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$build_root/simulator" \
  CODE_SIGNING_ALLOWED=NO \
  build

print "\n== Unit-test compilation =="
xcodebuild \
  -project PhotoTidy.xcodeproj \
  -scheme PhotoTidy \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$build_root/simulator-tests" \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing

print "\n== iPhone arm64 compilation =="
xcodebuild \
  -project PhotoTidy.xcodeproj \
  -scheme PhotoTidy \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$build_root/device" \
  CODE_SIGNING_ALLOWED=NO \
  build

print "\nVerification compilation succeeded."
