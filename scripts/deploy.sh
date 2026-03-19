#!/bin/zsh
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Note Enough — App Store & TestFlight Deployment Guide
# Interactive walkthrough for individual Apple Developer account holders
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/NoteEnough.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"
BUNDLE_ID="io.bino.noteenough"
APP_NAME="Note Enough"

cd "$PROJECT_DIR"

# ─── Colors & Formatting ─────────────────────────────────────────────────────

R='\033[0;31m'    # Red
G='\033[0;32m'    # Green
Y='\033[0;33m'    # Yellow
B='\033[0;34m'    # Blue
M='\033[0;35m'    # Magenta
C='\033[0;36m'    # Cyan
W='\033[1;37m'    # White bold
DIM='\033[2m'     # Dim
BOLD='\033[1m'    # Bold
UL='\033[4m'      # Underline
NC='\033[0m'      # No Color

CHECKMARK="${G}✓${NC}"
CROSSMARK="${R}✗${NC}"
ARROW="${C}→${NC}"
STAR="${Y}★${NC}"
ROCKET="${M}🚀${NC}"
WARN="${Y}⚠${NC}"
INFO="${B}ℹ${NC}"

# ─── Helpers ──────────────────────────────────────────────────────────────────

banner() {
    echo ""
    echo "${M}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo "${M}║${NC}  ${W}$1${NC}"
    echo "${M}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

section() {
    echo ""
    echo "  ${C}┌──────────────────────────────────────────────────────────┐${NC}"
    echo "  ${C}│${NC}  ${BOLD}$1${NC}"
    echo "  ${C}└──────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

step() {
    echo "  ${ARROW} ${BOLD}$1${NC}"
}

substep() {
    echo "      ${DIM}$1${NC}"
}

success() {
    echo "  ${CHECKMARK} ${G}$1${NC}"
}

fail() {
    echo "  ${CROSSMARK} ${R}$1${NC}"
}

warn() {
    echo "  ${WARN} ${Y}$1${NC}"
}

info() {
    echo "  ${INFO} ${B}$1${NC}"
}

manual_action() {
    echo ""
    echo "  ${STAR} ${Y}MANUAL STEP:${NC} ${W}$1${NC}"
    echo ""
}

pause_for_user() {
    echo ""
    echo "  ${DIM}────────────────────────────────────────────────────────${NC}"
    printf "  ${C}Press Enter when ready to continue...${NC} "
    read -r
    echo ""
}

ask_yes_no() {
    local prompt="$1"
    local answer
    printf "  ${C}${prompt}${NC} ${DIM}[y/n]${NC} "
    read -r answer
    [[ "$answer" =~ ^[Yy] ]]
}

choose_option() {
    local prompt="$1"
    shift
    local options=("$@")
    echo "  ${C}${prompt}${NC}" >&2
    local i=1
    for opt in "${options[@]}"; do
        echo "    ${W}${i})${NC} ${opt}" >&2
        ((i++))
    done
    local choice
    printf "  ${C}Enter choice:${NC} " >&2
    read -r choice
    echo "$choice"
}

# ─── Intro ────────────────────────────────────────────────────────────────────

clear
echo ""
echo "${M}  ███╗   ██╗ ██████╗ ████████╗███████╗${NC}"
echo "${M}  ████╗  ██║██╔═══██╗╚══██╔══╝██╔════╝${NC}"
echo "${M}  ██╔██╗ ██║██║   ██║   ██║   █████╗  ${NC}"
echo "${M}  ██║╚██╗██║██║   ██║   ██║   ██╔══╝  ${NC}"
echo "${M}  ██║ ╚████║╚██████╔╝   ██║   ███████╗${NC}"
echo "${M}  ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚══════╝${NC}"
echo ""
echo "${C}  ███████╗███╗   ██╗ ██████╗ ██╗   ██╗ ██████╗ ██╗  ██╗${NC}"
echo "${C}  ██╔════╝████╗  ██║██╔═══██╗██║   ██║██╔════╝ ██║  ██║${NC}"
echo "${C}  █████╗  ██╔██╗ ██║██║   ██║██║   ██║██║  ███╗███████║${NC}"
echo "${C}  ██╔══╝  ██║╚██╗██║██║   ██║██║   ██║██║   ██║██╔══██║${NC}"
echo "${C}  ███████╗██║ ╚████║╚██████╔╝╚██████╔╝╚██████╔╝██║  ██║${NC}"
echo "${C}  ╚══════╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝${NC}"
echo ""
echo "  ${DIM}App Store & TestFlight Deployment Guide${NC}"
echo "  ${DIM}Individual Apple Developer Account${NC}"
echo ""

DEPLOY_TARGET=$(choose_option "What would you like to do?" \
    "Deploy to TestFlight (beta testing)" \
    "Submit to the App Store (public release)" \
    "Both — TestFlight first, then App Store")

echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: Prerequisites
# ═══════════════════════════════════════════════════════════════════════════════

banner "PHASE 1: Checking Prerequisites"

# 1a. Xcode
step "Checking Xcode installation..."
if command -v xcodebuild &>/dev/null; then
    XCODE_VER=$(xcodebuild -version | awk 'NR==1')
    success "Found: $XCODE_VER"
else
    fail "Xcode is not installed or xcode-select is not configured."
    echo "    Run: ${W}xcode-select --install${NC}"
    exit 1
fi

# 1b. XcodeGen
step "Checking XcodeGen..."
if command -v xcodegen &>/dev/null; then
    success "XcodeGen is installed"
else
    fail "XcodeGen is not installed."
    if ask_yes_no "Install via Homebrew now?"; then
        brew install xcodegen
        success "XcodeGen installed"
    else
        echo "    Install manually: ${W}brew install xcodegen${NC}"
        exit 1
    fi
fi

# 1c. Apple Developer account
step "Checking Apple Developer account..."
echo ""
info "This script requires an active Apple Developer Program membership (\$99/year)."
info "Enrollment: ${UL}https://developer.apple.com/programs/enroll/${NC}"
echo ""
if ! ask_yes_no "Do you have an active Apple Developer Program membership?"; then
    echo ""
    fail "An Apple Developer Program membership is required."
    step "Go to ${UL}https://developer.apple.com/programs/enroll/${NC}"
    step "Sign up as an ${W}Individual${NC} (not organization)."
    step "Enrollment takes up to 48 hours to process."
    echo ""
    exit 1
fi
success "Apple Developer Program membership confirmed"

# 1d. Signing certificates
step "Checking code signing identities..."
echo ""
IDENTITIES=$(security find-identity -v -p codesigning 2>/dev/null || true)
DIST_CERT=$(echo "$IDENTITIES" | grep -i "Apple Distribution" || true)
DEV_CERT=$(echo "$IDENTITIES" | grep -i "Apple Development" || true)

if [[ -n "$DIST_CERT" ]]; then
    success "Found Apple Distribution certificate"
    echo "    ${DIM}$(echo "$DIST_CERT" | awk 'NR==1' | sed 's/^[[:space:]]*//')${NC}"
elif [[ -n "$DEV_CERT" ]]; then
    warn "Found Apple Development certificate (good for TestFlight)"
    echo "    ${DIM}$(echo "$DEV_CERT" | awk 'NR==1' | sed 's/^[[:space:]]*//')${NC}"
    echo ""
    info "For App Store submission you will also need an Apple Distribution certificate."
    info "Xcode can create one automatically in the next steps."
else
    warn "No signing certificates found in Keychain."
    echo ""
    info "Xcode will create them automatically when you enable Automatic Signing."
    info "This happens in the next phase."
fi

# 1e. xcrun altool / notarytool check
step "Checking upload tools..."
if xcrun --find altool &>/dev/null 2>&1; then
    success "altool (Xcode upload utility) available"
else
    warn "altool not found — uploads will use Xcode Organizer instead"
fi

echo ""
success "Prerequisites check complete!"
pause_for_user

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: App Store Connect Setup (Manual)
# ═══════════════════════════════════════════════════════════════════════════════

banner "PHASE 2: App Store Connect Setup"

info "Some steps in this phase require the App Store Connect web portal."
info "Open ${UL}https://appstoreconnect.apple.com${NC} in your browser."
echo ""

section "2A. Register the App ID"

step "Open ${UL}https://developer.apple.com/account/resources/identifiers/list${NC}"
step "Click the ${W}+${NC} button to register a new identifier."
step "Select ${W}App IDs${NC}, then ${W}App${NC}."
step "Fill in:"
substep "Description: ${W}Note Enough${NC}"
substep "Bundle ID:   ${W}${BUNDLE_ID}${NC}  (select 'Explicit')"
step "Capabilities — leave defaults (no special entitlements needed)."
step "Click ${W}Continue${NC}, then ${W}Register${NC}."
echo ""
info "If the bundle ID is already registered, skip this step."

pause_for_user

section "2B. Create the App in App Store Connect"

step "Open ${UL}https://appstoreconnect.apple.com/apps${NC}"
step "Click the ${W}+${NC} button → ${W}New App${NC}."
step "Fill in the form:"
echo ""
echo "  ${W}┌─────────────────────────────────────────────────────────┐${NC}"
echo "  ${W}│${NC}  Platform:       ${G}iPadOS${NC}                                 ${W}│${NC}"
echo "  ${W}│${NC}  Name:           ${G}Note Enough${NC}                             ${W}│${NC}"
echo "  ${W}│${NC}  Primary Lang:   ${G}English (U.S.)${NC}                          ${W}│${NC}"
echo "  ${W}│${NC}  Bundle ID:      ${G}${BUNDLE_ID}${NC}                   ${W}│${NC}"
echo "  ${W}│${NC}  SKU:            ${G}noteenough-001${NC}                          ${W}│${NC}"
echo "  ${W}│${NC}  Full Access:    ${G}(your individual account)${NC}               ${W}│${NC}"
echo "  ${W}├─────────────────────────────────────────────────────────┤${NC}"
echo "  ${W}│${NC}  ${DIM}Pricing: Free (set in the Pricing section later)${NC}      ${W}│${NC}"
echo "  ${W}└─────────────────────────────────────────────────────────┘${NC}"
echo ""
step "Click ${W}Create${NC}."

pause_for_user

section "2C. Configure the App Listing"

step "In App Store Connect, navigate to your app → ${W}App Information${NC}."
echo ""
info "You will need to fill in these sections. Here are suggested values:"
echo ""

echo "  ${B}── App Information ──${NC}"
step "Category:          ${W}Productivity${NC} (or Utilities)"
step "Content Rights:    ${W}Does not contain third-party content${NC}"
echo ""

echo "  ${B}── Pricing and Availability ──${NC}"
step "Price:             ${W}Free${NC}"
step "Availability:      ${W}All territories${NC} (or select specific ones)"
echo ""

echo "  ${B}── Privacy Policy ──${NC}"
step "A ${W}PRIVACY.md${NC} file has been created in your project root."
step "You need to host it at a public URL. Options:"
echo ""
echo "    ${W}Option A:${NC} Push to GitHub and use the raw URL:"
substep "${UL}https://github.com/YOUR_USERNAME/note-enough/blob/main/PRIVACY.md${NC}"
echo ""
echo "    ${W}Option B:${NC} Create a free GitHub Pages site:"
substep "${UL}https://YOUR_USERNAME.github.io/note-enough/PRIVACY.html${NC}"
echo ""
echo "    ${W}Option C:${NC} Host on any web server or paste into a Notion/Google Doc public link."
echo ""
step "Paste the public URL into the ${W}Privacy Policy URL${NC} field in App Store Connect."

pause_for_user

echo "  ${B}── App Privacy (Data Collection) ──${NC}"
step "Go to ${W}App Privacy${NC} in App Store Connect."
step "Click ${W}Get Started${NC}."
step "Question: ${W}Do you or your third-party partners collect data?${NC}"
step "Answer:   ${G}No, we do not collect data from this app${NC}"
echo ""
info "Note Enough stores everything locally. No analytics, no tracking, no network."
info "This is the simplest and most honest privacy declaration."

pause_for_user

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: Prepare the Version Listing (Manual)
# ═══════════════════════════════════════════════════════════════════════════════

banner "PHASE 3: Prepare the Version Listing"

section "3A. App Description & Keywords"

info "Suggested App Store description (you can customize this):"
echo ""
echo "  ${DIM}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${NC}"
cat <<'DESCRIPTION'

  Note Enough is a simple, focused note-taking app for iPad and
  Apple Pencil. Organize your handwritten notes into notebooks
  with customizable paper — plain, textured, or graph — in US
  Letter or A4 sizes.

  Features:
  - Create up to 9 notebooks with custom paper styles
  - Full Apple Pencil support with native PencilKit tools
  - Pinch to zoom (0.25x to 4x) and pan across pages
  - Portrait and landscape paper orientations
  - Swipe between pages or use the page picker
  - Reorder pages and notebooks with drag and drop
  - Export notebooks to PDF for sharing
  - Remembers your zoom level and last-viewed page
  - Works completely offline — your notes stay on your device

  Your privacy matters. Note Enough collects no data, requires
  no account, and never connects to the internet.

DESCRIPTION
echo "  ${DIM}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${NC}"
echo ""
step "Suggested Keywords (100 characters max):"
echo "    ${G}notes,handwriting,pencil,notebook,drawing,paper,graph,sketch,journal,pad${NC}"
echo ""
step "Support URL: your GitHub repo or any contact page"
step "Marketing URL: (optional) your landing page"

pause_for_user

section "3B. Screenshots"

echo "  ${Y}You need iPad screenshots. Minimum requirements:${NC}"
echo ""
echo "  ${W}┌─────────────────────────────────────────────────────────┐${NC}"
echo "  ${W}│${NC}  ${UL}Required iPad sizes (at least one set):${NC}               ${W}│${NC}"
echo "  ${W}│${NC}                                                         ${W}│${NC}"
echo "  ${W}│${NC}  ${G}iPad Pro 13\" (6th gen):${NC}  2064 × 2752 px             ${W}│${NC}"
echo "  ${W}│${NC}  ${DIM}or${NC}  ${G}iPad Pro 12.9\" (2nd gen):${NC}  2048 × 2732 px       ${W}│${NC}"
echo "  ${W}│${NC}                                                         ${W}│${NC}"
echo "  ${W}│${NC}  ${DIM}Minimum 1, maximum 10 screenshots per size.${NC}           ${W}│${NC}"
echo "  ${W}│${NC}  ${DIM}Upload in App Store Connect → Version → Media.${NC}        ${W}│${NC}"
echo "  ${W}└─────────────────────────────────────────────────────────┘${NC}"
echo ""
step "How to capture screenshots:"
echo ""
substep "1. Run the app in the iPad simulator:"
echo "       ${W}./scripts/run.sh${NC}"
substep "2. Set up some sample notebooks with drawings."
substep "3. Take screenshots:  ${W}Cmd + S${NC}  in Simulator"
substep "4. Screenshots land in ${W}~/Desktop${NC} by default."
echo ""
step "Recommended screenshots to capture:"
echo "    ${W}1.${NC} Heap view with several notebook cards"
echo "    ${W}2.${NC} Drawing canvas with Apple Pencil strokes"
echo "    ${W}3.${NC} Graph paper with notes"
echo "    ${W}4.${NC} Page picker popover open"
echo "    ${W}5.${NC} Settings screen"

pause_for_user

section "3C. App Review Information"

step "Fill in App Store Connect → ${W}App Review Information${NC}:"
echo ""
substep "Contact: Your name, email, and phone"
substep "Notes to reviewer:"
echo ""
echo "    ${DIM}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${NC}"
echo "    ${G}Note Enough is a straightforward handwriting app.${NC}"
echo "    ${G}No sign-in is required. Tap + to create a notebook,${NC}"
echo "    ${G}then draw with Apple Pencil or your finger. The app${NC}"
echo "    ${G}works entirely offline with no network requests.${NC}"
echo "    ${DIM}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${NC}"
echo ""
step "Sign-in required:  ${W}No${NC}"
step "Demo account:      ${W}Not needed${NC}"

pause_for_user

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 4: Configure Code Signing in Xcode
# ═══════════════════════════════════════════════════════════════════════════════

banner "PHASE 4: Configure Code Signing"

section "4A. Set up Automatic Signing in Xcode"

step "Open the project in Xcode:"
echo "       ${W}open NoteEnough.xcodeproj${NC}"
echo ""
if ask_yes_no "Open the Xcode project now?"; then
    open NoteEnough.xcodeproj
    success "Opened NoteEnough.xcodeproj"
else
    info "Open it manually when ready."
fi
echo ""
step "In Xcode:"
substep "1. Select the ${W}NoteEnough${NC} project in the navigator"
substep "2. Select the ${W}NoteEnough${NC} target"
substep "3. Go to ${W}Signing & Capabilities${NC} tab"
substep "4. Check ${W}Automatically manage signing${NC}"
substep "5. Set Team to ${W}your Apple Developer account${NC}"
substep "6. Bundle Identifier should be: ${W}${BUNDLE_ID}${NC}"
echo ""
info "Xcode will automatically create:"
substep "- An Apple Development certificate (for building)"
substep "- An Apple Distribution certificate (for App Store)"
substep "- A provisioning profile for your app"
echo ""
warn "If Xcode shows signing errors, ensure your Developer Program is active"
warn "and your Apple ID is added in Xcode → Settings → Accounts."

pause_for_user

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 5: Build, Test, Archive
# ═══════════════════════════════════════════════════════════════════════════════

banner "PHASE 5: Build, Test & Archive"

section "5A. Generate Xcode Project"

step "Regenerating Xcode project from project.yml..."
if [[ ! -d "NoteEnough.xcodeproj" ]] || [[ "project.yml" -nt "NoteEnough.xcodeproj/project.pbxproj" ]]; then
    xcodegen generate
    success "Project regenerated"
else
    success "Project is up to date"
fi

section "5B. Run Tests"

if ask_yes_no "Run the test suite before archiving?"; then
    step "Running unit tests..."
    echo ""

    SIM_DEVICE=$(xcrun simctl list devices available -j 2>/dev/null \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devs in data.get('devices', {}).items():
    if 'iOS' in runtime or 'iPadOS' in runtime:
        for d in devs:
            if 'iPad' in d['name'] and d['isAvailable']:
                print(d['name'])
                sys.exit(0)
print('iPad Air 13-inch (M3)')
" 2>/dev/null || echo "iPad Air 13-inch (M3)")

    info "Using simulator: $SIM_DEVICE"
    echo ""

    if xcodebuild test \
        -scheme NoteEnough \
        -destination "platform=iOS Simulator,name=$SIM_DEVICE" \
        -only-testing:NoteEnoughTests \
        -quiet 2>&1 | tail -3; then
        success "All tests passed!"
    else
        fail "Some tests failed. Fix them before submitting."
        if ! ask_yes_no "Continue anyway?"; then
            exit 1
        fi
    fi
else
    warn "Skipping tests"
fi

section "5C. Create Release Archive"

step "Archiving for App Store distribution..."
echo ""
info "This builds with ${W}generic/platform=iOS${NC} (real device architecture)."
info "Signing is managed by Xcode with your configured team."
echo ""

mkdir -p "$BUILD_DIR"

if ask_yes_no "Build the archive now? (This takes 1-3 minutes)"; then
    echo ""
    step "Archiving... ${DIM}(this may take a moment)${NC}"
    echo ""

    if xcodebuild archive \
        -project NoteEnough.xcodeproj \
        -scheme NoteEnough \
        -destination "generic/platform=iOS" \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_STYLE=Automatic \
        2>&1 | while IFS= read -r line; do
            if [[ "$line" == *"ARCHIVE SUCCEEDED"* ]]; then
                echo "  ${CHECKMARK} ${G}$line${NC}"
            elif [[ "$line" == *"error:"* ]]; then
                echo "  ${CROSSMARK} ${R}$line${NC}"
            elif [[ "$line" == *"warning:"* ]]; then
                echo "  ${WARN} ${DIM}$line${NC}"
            fi
        done; then
        echo ""
        success "Archive created: $ARCHIVE_PATH"
    else
        echo ""
        fail "Archive failed. Common fixes:"
        substep "- Ensure signing is configured (Phase 4)"
        substep "- Check that your Developer Program is active"
        substep "- Try archiving from Xcode: Product → Archive"
        echo ""
        if ! ask_yes_no "Continue with manual archive instructions?"; then
            exit 1
        fi
    fi
else
    warn "Skipping archive build."
    info "You can archive from Xcode: ${W}Product → Archive${NC}"
fi

pause_for_user

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 6: Upload to App Store Connect
# ═══════════════════════════════════════════════════════════════════════════════

banner "PHASE 6: Upload to App Store Connect"

UPLOAD_METHOD=$(choose_option "How would you like to upload?" \
    "Xcode Organizer (recommended for the VERY FIRST upload — handles signing)" \
    "Command line (xcodebuild — often fails if first-time profiles don't exist)" \
    "Transporter app (drag-and-drop IPA upload)")

echo ""

case "$UPLOAD_METHOD" in
    1)
        section "6A. Upload via Xcode Organizer"
        info "Use this if this is the first time uploading io.bino.noteenough."
        info "Xcode UI is the most reliable way to register App IDs and profiles automatically."
        echo ""
        step "Opening the archive in Xcode Organizer..."
        if [[ -d "$ARCHIVE_PATH" ]]; then
            open "$ARCHIVE_PATH"
            success "Archive opened in Xcode Organizer"
        else
            warn "Archive not found at $ARCHIVE_PATH"
            info "Open Xcode → Window → Organizer to see existing archives."
        fi
        echo ""
        step "In the Organizer window:"
        substep "1. Select the ${W}NoteEnough${NC} archive"
        substep "2. Click ${W}Distribute App${NC}"
        if [[ "$DEPLOY_TARGET" == "1" ]]; then
            substep "3. Select ${W}TestFlight & App Store${NC}"
        elif [[ "$DEPLOY_TARGET" == "2" ]]; then
            substep "3. Select ${W}App Store Connect${NC}"
        else
            substep "3. Select ${W}TestFlight & App Store${NC} (covers both)"
        fi
        substep "4. Select ${W}Upload${NC}"
        substep "5. Leave ${W}Automatically manage signing${NC} checked"
        substep "6. Click ${W}Upload${NC} and wait for completion"
        echo ""
        info "Upload typically takes 2-5 minutes."
        info "After upload, the build is processed by Apple (5-30 minutes)."
        ;;
    2)
        section "6A. Upload via Command Line"

        warn "NOTE: This method often fails on the VERY FIRST upload of a new app"
        warn "because it cannot automatically create missing App Store profiles."
        info "Use Choice 1 (Xcode Organizer) instead if you haven't uploaded once yet."
        echo ""

        step "Creating ExportOptions.plist..."

        if [[ ! -f "$EXPORT_OPTIONS" ]]; then
            # Detect the signing team ID
            TEAM_ID=""
            if [[ -n "$DIST_CERT" ]]; then
                TEAM_ID=$(echo "$DIST_CERT" | awk 'NR==1' | grep -oE '\([A-Z0-9]{10}\)' | tr -d '()')
            elif [[ -n "$DEV_CERT" ]]; then
                TEAM_ID=$(echo "$DEV_CERT" | awk 'NR==1' | grep -oE '\([A-Z0-9]{10}\)' | tr -d '()')
            fi

            if [[ -z "$TEAM_ID" ]]; then
                printf "  ${C}Enter your Apple Developer Team ID (10-char alphanumeric):${NC} "
                read -r TEAM_ID
            fi

            cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
PLIST
            success "Created ExportOptions.plist with Team ID: $TEAM_ID"
        else
            success "Using existing ExportOptions.plist"
        fi

        echo ""

        if [[ -d "$ARCHIVE_PATH" ]]; then
            step "Exporting and uploading..."
            echo ""

            if xcodebuild -exportArchive \
                -archivePath "$ARCHIVE_PATH" \
                -exportOptionsPlist "$EXPORT_OPTIONS" \
                -exportPath "$EXPORT_PATH" \
                2>&1 | while IFS= read -r line; do
                    if [[ "$line" == *"EXPORT SUCCEEDED"* ]] || [[ "$line" == *"UPLOAD SUCCEEDED"* ]]; then
                        echo "  ${CHECKMARK} ${G}$line${NC}"
                    elif [[ "$line" == *"error:"* ]]; then
                        echo "  ${CROSSMARK} ${R}$line${NC}"
                    fi
                done; then
                echo ""
                success "Upload complete!"
            else
                echo ""
                fail "Export/upload failed."
                info "Common reasons: signing issues, Team ID mismatch, or network errors."
                info "You can also try the Xcode Organizer method (Choice 1)."
                echo ""
                exit 1
            fi
        else
            fail "No archive found. Run Phase 5 to build the archive first."
        fi
        ;;
    3)
        section "6A. Upload via Transporter"

        step "Transporter is a free app from Apple for uploading builds."
        step "Download from the Mac App Store:"
        echo "    ${UL}https://apps.apple.com/app/transporter/id1450874784${NC}"
        echo ""
        step "Steps:"
        substep "1. First, export the archive to an IPA from Xcode Organizer"
        substep "2. Open Transporter"
        substep "3. Sign in with your Apple ID"
        substep "4. Drag and drop the .ipa file"
        substep "5. Click ${W}Deliver${NC}"
        ;;
esac

pause_for_user

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 7: TestFlight (if applicable)
# ═══════════════════════════════════════════════════════════════════════════════

if [[ "$DEPLOY_TARGET" == "1" ]] || [[ "$DEPLOY_TARGET" == "3" ]]; then

    banner "PHASE 7: TestFlight Setup"

    section "7A. Wait for Build Processing"

    step "After uploading, Apple processes the build (5-30 minutes)."
    step "You will receive an email when it's ready."
    step "Check status at: ${UL}https://appstoreconnect.apple.com${NC}"
    substep "→ Your app → ${W}TestFlight${NC} tab"

    pause_for_user

    section "7B. Compliance & Encryption"

    step "When the build appears in TestFlight, it may show ${W}Missing Compliance${NC}."
    step "Click ${W}Manage${NC} next to the build."
    step "Question: ${W}Does this app use encryption?${NC}"
    step "Answer:   ${G}No${NC}"
    echo ""
    info "Note Enough does not use any custom encryption."
    info "Standard HTTPS (if any) is exempt, but this app makes no network requests."

    pause_for_user

    section "7C. Internal Testing"

    step "Your individual account has access to ${W}Internal Testing${NC}."
    step "As the account holder, you are automatically an internal tester."
    step "Go to ${W}TestFlight → Internal Testing → App Store Connect Users${NC}."
    step "Open the TestFlight app on your iPad to install the build."

    pause_for_user

    section "7D. External Testing (optional)"

    step "To invite others who are not on your development team:"
    substep "1. Go to TestFlight → ${W}External Testing${NC}"
    substep "2. Click ${W}+${NC} to create a new group"
    substep "3. Name it (e.g., 'Beta Testers')"
    substep "4. Add the build to the group"
    substep "5. Add testers by email (up to 10,000)"
    echo ""
    warn "External testing requires a ${W}Beta App Review${NC} by Apple (usually < 24 hours)."
    info "You will need to fill in test information: what to test, contact info."

    pause_for_user
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 8: App Store Submission (if applicable)
# ═══════════════════════════════════════════════════════════════════════════════

if [[ "$DEPLOY_TARGET" == "2" ]] || [[ "$DEPLOY_TARGET" == "3" ]]; then

    banner "PHASE 8: Submit to the App Store"

    section "8A. Final Checklist"

    echo "  ${W}Before submitting, verify everything is in place:${NC}"
    echo ""
    echo "  ${DIM}In App Store Connect → Your App → iOS App (Version):${NC}"
    echo ""
    echo "    ${C}□${NC}  Screenshots uploaded (at least 1 for iPad 13\")"
    echo "    ${C}□${NC}  App description filled in"
    echo "    ${C}□${NC}  Keywords set"
    echo "    ${C}□${NC}  Support URL provided"
    echo "    ${C}□${NC}  Privacy Policy URL set (from PRIVACY.md)"
    echo "    ${C}□${NC}  App Privacy → 'Data not collected' selected"
    echo "    ${C}□${NC}  Category set (Productivity)"
    echo "    ${C}□${NC}  Build selected (from your upload)"
    echo "    ${C}□${NC}  Pricing set to Free"
    echo "    ${C}□${NC}  Age Rating questionnaire completed"
    echo "    ${C}□${NC}  App Review contact info filled in"
    echo "    ${C}□${NC}  Copyright field set (e.g., '2026 Your Name')"
    echo ""

    pause_for_user

    section "8B. Age Rating"

    step "Go to ${W}App Information → Age Rating${NC} in App Store Connect."
    step "Answer all questions ${W}None${NC} / ${W}No${NC} — the app has no objectionable content."
    step "This should result in a ${W}4+${NC} age rating."

    section "8C. Select Build & Submit"

    step "In your app version page, click ${W}Build +${NC} to select the uploaded build."
    step "Choose the build you uploaded in Phase 6."
    step "Review all sections — App Store Connect will highlight anything missing."
    step "When everything is green, click ${W}Submit for Review${NC}."
    echo ""

    echo "  ${W}┌─────────────────────────────────────────────────────────┐${NC}"
    echo "  ${W}│${NC}                                                         ${W}│${NC}"
    echo "  ${W}│${NC}  ${G}Review Timeline${NC}                                       ${W}│${NC}"
    echo "  ${W}│${NC}                                                         ${W}│${NC}"
    echo "  ${W}│${NC}  Most apps are reviewed within ${W}24-48 hours${NC}.            ${W}│${NC}"
    echo "  ${W}│${NC}  Simple apps like Note Enough often clear in ${W}<24h${NC}.     ${W}│${NC}"
    echo "  ${W}│${NC}                                                         ${W}│${NC}"
    echo "  ${W}│${NC}  You will receive an email when your app is:            ${W}│${NC}"
    echo "  ${W}│${NC}    ${G}✓${NC} Approved and live on the App Store                ${W}│${NC}"
    echo "  ${W}│${NC}    ${R}✗${NC} Rejected (with reasons and how to fix)            ${W}│${NC}"
    echo "  ${W}│${NC}                                                         ${W}│${NC}"
    echo "  ${W}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""

    pause_for_user
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 9: Common Rejection Reasons & Tips
# ═══════════════════════════════════════════════════════════════════════════════

banner "PHASE 9: Tips & Common Pitfalls"

echo "  ${R}Common rejection reasons for simple apps:${NC}"
echo ""
echo "  ${W}1.${NC} ${Y}Missing screenshots or wrong size${NC}"
echo "     Ensure iPad screenshots match required dimensions."
echo ""
echo "  ${W}2.${NC} ${Y}Broken privacy policy link${NC}"
echo "     Test the URL in a private/incognito browser window."
echo ""
echo "  ${W}3.${NC} ${Y}Insufficient functionality (Guideline 4.2)${NC}"
echo "     Note Enough has rich features (PencilKit, PDF export, zoom,"
echo "     multiple paper types) — this should not be an issue."
echo ""
echo "  ${W}4.${NC} ${Y}Crashes on launch${NC}"
echo "     Test on a real iPad if possible. Run tests before submitting."
echo ""
echo "  ${W}5.${NC} ${Y}Missing iPad optimization${NC}"
echo "     Note Enough is iPad-native — no issue here."
echo ""

echo "  ${G}Tips for a smooth review:${NC}"
echo ""
echo "  ${STAR} Test thoroughly on a real iPad with Apple Pencil"
echo "  ${STAR} Keep reviewer notes brief and helpful"
echo "  ${STAR} Respond quickly to any review questions"
echo "  ${STAR} Fill in every field — don't leave blanks"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Done
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo "${M}╔══════════════════════════════════════════════════════════════╗${NC}"
echo "${M}║${NC}                                                              ${M}║${NC}"
echo "${M}║${NC}   ${ROCKET}  ${W}Deployment walkthrough complete!${NC}                      ${M}║${NC}"
echo "${M}║${NC}                                                              ${M}║${NC}"
echo "${M}║${NC}   ${DIM}Summary of what was done and what's left:${NC}                 ${M}║${NC}"
echo "${M}║${NC}                                                              ${M}║${NC}"

if [[ -d "$ARCHIVE_PATH" ]]; then
echo "${M}║${NC}   ${CHECKMARK} Archive built                                         ${M}║${NC}"
else
echo "${M}║${NC}   ${C}□${NC} Archive: run ${W}./scripts/release.sh${NC} or Xcode archive   ${M}║${NC}"
fi

echo "${M}║${NC}   ${C}□${NC} App Store Connect: create listing & upload             ${M}║${NC}"
echo "${M}║${NC}   ${C}□${NC} Screenshots: capture & upload                          ${M}║${NC}"
echo "${M}║${NC}   ${C}□${NC} Privacy Policy: host PRIVACY.md & paste URL            ${M}║${NC}"

if [[ "$DEPLOY_TARGET" == "1" ]] || [[ "$DEPLOY_TARGET" == "3" ]]; then
echo "${M}║${NC}   ${C}□${NC} TestFlight: configure & invite testers                 ${M}║${NC}"
fi
if [[ "$DEPLOY_TARGET" == "2" ]] || [[ "$DEPLOY_TARGET" == "3" ]]; then
echo "${M}║${NC}   ${C}□${NC} App Store: submit for review                           ${M}║${NC}"
fi

echo "${M}║${NC}                                                              ${M}║${NC}"
echo "${M}║${NC}   ${DIM}Key files:${NC}                                                ${M}║${NC}"
echo "${M}║${NC}     ${B}PRIVACY.md${NC}         — Privacy policy for App Store        ${M}║${NC}"
echo "${M}║${NC}     ${B}scripts/deploy.sh${NC}  — This script (run again anytime)     ${M}║${NC}"
echo "${M}║${NC}     ${B}scripts/release.sh${NC} — Quick archive build                 ${M}║${NC}"
echo "${M}║${NC}                                                              ${M}║${NC}"
echo "${M}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
