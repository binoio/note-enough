#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Check prerequisites
if ! command -v xcodegen &>/dev/null; then
    echo "Error: XcodeGen is not installed."
    exit 1
fi

# Generate project if needed
if [[ ! -d "NoteEnough.xcodeproj" ]] || [[ "project.yml" -nt "NoteEnough.xcodeproj/project.pbxproj" ]]; then
    echo "Generating Xcode project..."
    xcodegen generate
fi

ARCHIVE_PATH="$PROJECT_DIR/build/NoteEnough.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"

echo "Archiving NoteEnough..."
xcodebuild archive \
    -project NoteEnough.xcodeproj \
    -scheme NoteEnough \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -quiet

echo "Archive created at: $ARCHIVE_PATH"

# Check if export options plist exists
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"
if [[ -f "$EXPORT_OPTIONS" ]]; then
    echo "Exporting IPA..."
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        -exportPath "$EXPORT_PATH" \
        -quiet

    echo "IPA exported to: $EXPORT_PATH"
else
    echo "No ExportOptions.plist found. Archive is ready at:"
    echo "  $ARCHIVE_PATH"
    echo ""
    echo "To export, create ExportOptions.plist with your signing configuration"
    echo "and run this script again, or open the archive in Xcode Organizer:"
    echo "  open $ARCHIVE_PATH"
fi

echo "Release build complete."
