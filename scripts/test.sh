#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Ensure project is generated
if [[ ! -d "NoteEnough.xcodeproj" ]]; then
    echo "Project not found. Running build first..."
    "$SCRIPT_DIR/build.sh"
fi

# Find an iPad simulator
SIMULATOR=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime or 'iPadOS' in runtime:
        for d in devices:
            if 'iPad' in d['name'] and d['isAvailable']:
                print(d['udid'])
                sys.exit(0)
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime:
        for d in devices:
            if d['isAvailable']:
                print(d['udid'])
                sys.exit(0)
print('none')
" 2>/dev/null || echo "none")

if [[ "$SIMULATOR" == "none" ]]; then
    echo "Error: No iPad simulator available. Install an iPadOS simulator runtime in Xcode."
    exit 1
fi

RUN_UNIT=${1:-all}

echo "Running tests on simulator $SIMULATOR..."

if [[ "$RUN_UNIT" == "unit" ]]; then
    echo "Running unit tests only..."
    xcodebuild test \
        -project NoteEnough.xcodeproj \
        -scheme NoteEnough \
        -destination "platform=iOS Simulator,id=$SIMULATOR" \
        -only-testing:NoteEnoughTests \
        -quiet \
        CODE_SIGNING_ALLOWED=NO
elif [[ "$RUN_UNIT" == "ui" ]]; then
    echo "Running UI tests only..."
    xcodebuild test \
        -project NoteEnough.xcodeproj \
        -scheme NoteEnough \
        -destination "platform=iOS Simulator,id=$SIMULATOR" \
        -only-testing:NoteEnoughUITests \
        -quiet \
        CODE_SIGNING_ALLOWED=NO
else
    echo "Running all tests..."
    xcodebuild test \
        -project NoteEnough.xcodeproj \
        -scheme NoteEnough \
        -destination "platform=iOS Simulator,id=$SIMULATOR" \
        -quiet \
        CODE_SIGNING_ALLOWED=NO
fi

echo "Tests passed."
