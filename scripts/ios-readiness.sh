#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode=${1:---configure-only}
sdk=${2:-iphoneos}
case "$mode" in --configure-only|--compile-check) ;; *) echo 'Only --configure-only or --compile-check is supported; no IPA packaging.' >&2; exit 2;; esac
case "$sdk" in iphoneos|iphonesimulator) ;; *) echo 'Expected iphoneos or iphonesimulator' >&2; exit 2;; esac
[[ $(uname -s) == Darwin ]] || { echo 'macOS/Xcode is required for Apple SDK validation.' >&2; exit 1; }
for tool in xcodebuild xcrun cmake; do command -v "$tool" >/dev/null; done
xcodebuild -version
xcrun --sdk "$sdk" --show-sdk-path
xcrun --sdk "$sdk" --find metal
cmake -S . -B "build/ios-$sdk" -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO
if [[ $mode == --compile-check ]]; then
  cmake --build "build/ios-$sdk" --target SegaRallyIOS --config Debug -- CODE_SIGNING_ALLOWED=NO
fi
