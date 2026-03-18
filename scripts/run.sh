#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Ensure project is built
"$SCRIPT_DIR/build.sh"

# Find an iPad simulator
SIMULATOR_INFO=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime or 'iPadOS' in runtime:
        for d in devices:
            if 'iPad' in d['name'] and d['isAvailable']:
                print(d['udid'] + '|' + d['name'])
                sys.exit(0)
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime:
        for d in devices:
            if d['isAvailable']:
                print(d['udid'] + '|' + d['name'])
                sys.exit(0)
print('none|none')
" 2>/dev/null || echo "none|none")

SIMULATOR_UDID="${SIMULATOR_INFO%%|*}"
SIMULATOR_NAME="${SIMULATOR_INFO##*|}"

if [[ "$SIMULATOR_UDID" == "none" ]]; then
    echo "Error: No iPad simulator available."
    exit 1
fi

echo "Using simulator: $SIMULATOR_NAME ($SIMULATOR_UDID)"

# Boot simulator if needed
BOOT_STATE=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$SIMULATOR_UDID':
            print(d['state'])
            sys.exit(0)
print('Unknown')
" 2>/dev/null || echo "Unknown")

if [[ "$BOOT_STATE" != "Booted" ]]; then
    echo "Booting simulator..."
    xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
fi

# Open Simulator app
open -a Simulator

# Find the built app
BUILD_DIR=$(xcodebuild -project NoteEnough.xcodeproj -scheme NoteEnough -showBuildSettings \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" 2>/dev/null | \
    grep -m1 "BUILT_PRODUCTS_DIR" | awk '{print $3}')

APP_PATH="$BUILD_DIR/NoteEnough.app"

if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: Built app not found at $APP_PATH"
    echo "Try running ./scripts/build.sh first."
    exit 1
fi

# Install and launch
echo "Installing app..."
xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"

echo "Launching app..."
xcrun simctl launch "$SIMULATOR_UDID" io.bino.noteenough

echo "NoteEnough is running on $SIMULATOR_NAME."
