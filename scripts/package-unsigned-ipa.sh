#!/usr/bin/env bash
# Default mode verifies packaging prerequisites; it does not create an IPA.
set -euo pipefail
mode=${1:---check}
app=${2:-build/ios-iphoneos/SegaRallyIOS.app}
output=${3:-build/SegaRallyIOS-unsigned.ipa}
case "$mode" in --check|--create) ;; *) echo 'Usage: package-unsigned-ipa.sh [--check|--create] [APP] [OUTPUT.ipa]' >&2; exit 2;; esac
[[ $(uname -s) == Darwin ]] || { echo 'Run on the macOS build host.' >&2; exit 1; }
[[ -d "$app" && -s "$app/Info.plist" ]] || { echo 'Device app bundle is missing.' >&2; exit 1; }
executable=$(/usr/libexec/PlistBuddy -c 'Print CFBundleExecutable' "$app/Info.plist")
bundle=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")
[[ -n "$bundle" && -n "$executable" && "$executable" != */* && -x "$app/$executable" ]]
[[ -s "$app/PortShaders.metallib" ]] || { echo 'Compiled Metal library is missing.' >&2; exit 1; }
platform=$(xcrun vtool -show-build "$app/$executable" | awk '$1=="platform"{print $2}')
[[ "$platform" == IOS ]] || { echo 'Expected an iPhoneOS binary, not a simulator or macOS binary.' >&2; exit 1; }
lipo -archs "$app/$executable" | tr ' ' '\n' | grep -qx arm64
forbidden=$(find "$app" -type f \( -iname '*.bin' -o -iname '*.rom' -o -iname '*.zip' -o -iname '*.7z' -o -name 'epr-*' -o -name 'mpr-*' \) -print -quit)
[[ -z "$forbidden" ]] || { echo 'Unexpected game asset/archive in app bundle.' >&2; exit 1; }
if [[ "$mode" == --check ]]; then
  echo "IPA packaging prerequisites passed for $bundle; no IPA created."
  exit 0
fi
[[ "$output" == *.ipa && ! -e "$output" ]] || { echo 'Choose a new .ipa output path.' >&2; exit 1; }
mkdir -p "$(dirname "$output")"
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
mkdir "$staging/Payload"
ditto "$app" "$staging/Payload/$(basename "$app")"
ditto -c -k --sequesterRsrc --keepParent "$staging/Payload" "$output"
echo "Created unsigned personal-use package: $output"
# This package still needs personal signing before installation; no upload occurs.
