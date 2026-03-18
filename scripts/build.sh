#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Check prerequisites
if ! command -v xcodegen &>/dev/null; then
    echo "Error: XcodeGen is not installed. Install with: brew install xcodegen"
    exit 1
fi

if ! command -v xcodebuild &>/dev/null; then
    echo "Error: Xcode command-line tools are not installed."
    exit 1
fi

# Generate project if needed
if [[ ! -d "NoteEnough.xcodeproj" ]] || [[ "project.yml" -nt "NoteEnough.xcodeproj/project.pbxproj" ]]; then
    echo "Generating Xcode project..."
    xcodegen generate
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
# Fallback: try any available iOS simulator
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime:
        for d in devices:
            if d['isAvailable']:
                print(d['udid'])
                sys.exit(0)
print('none')
" 2>/dev/null || echo "none")

if [[ "$SIMULATOR" == "none" ]]; then
    echo "Warning: No iPad simulator found. Building for generic destination."
    DESTINATION="generic/platform=iOS Simulator"
else
    DESTINATION="platform=iOS Simulator,id=$SIMULATOR"
fi

echo "Building NoteEnough for iPad Simulator..."
xcodebuild build \
    -project NoteEnough.xcodeproj \
    -scheme NoteEnough \
    -destination "$DESTINATION" \
    -quiet \
    CODE_SIGNING_ALLOWED=NO

echo "Build succeeded."
