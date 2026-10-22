#!/usr/bin/env bash
set -euo pipefail
build_dir=${1:?Pass the simulator build directory}
app_path=$(find "$build_dir" -type d -name SegaRallyIOS.app -print -quit)
[[ -n "$app_path" ]] || { echo 'Unsigned simulator app not found' >&2; exit 1; }
bundle_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app_path/Info.plist")
device_id=$(xcrun simctl list devices available --json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["udid"] for a in d["devices"].values() for x in a if x.get("isAvailable") and "iPhone" in x["name"]))')
state=$(xcrun simctl list devices available --json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["state"] for a in d["devices"].values() for x in a if x["udid"]==sys.argv[1]))' "$device_id")
if [[ "$state" != Booted ]]; then xcrun simctl boot "$device_id"; fi
xcrun simctl bootstatus "$device_id" -b
xcrun simctl install "$device_id" "$app_path"
SIMCTL_CHILD_PORT_RENDER_SMOKE=1 xcrun simctl launch --terminate-running-process "$device_id" "$bundle_id"
sleep 5
# Verify that the app survived startup before inspecting synthetic pixels.
xcrun simctl spawn "$device_id" launchctl list | python3 -c 'import sys; target=sys.argv[1]; rows=[r.split() for r in sys.stdin]; assert any(len(r)>2 and target in r[2] and r[0].isdigit() for r in rows), "App is no longer running"' "$bundle_id"
xcrun simctl io "$device_id" screenshot "$build_dir/metal-smoke.png"
swift "$(dirname "$0")/verify-metal-smoke.swift" "$build_dir/metal-smoke.png"
xcrun simctl terminate "$device_id" "$bundle_id"
# No ROMs, IPA, signing, archive, export or screenshot upload.
