# Note Enough

An iPadOS note-taking app built with SwiftUI and PencilKit. Organize your handwritten notes into **stacks** (notebooks) displayed on a **heap** (home screen). Each stack contains **pages** with full Apple Pencil drawing support.

## Architecture

- **UI:** SwiftUI (iPadOS 17.0+)
- **Drawing:** PencilKit with `PKCanvasView`
- **Persistence:** SwiftData
- **Settings:** `@AppStorage` / `UserDefaults`
- **Project:** XcodeGen

## Prerequisites

- macOS 15.0+
- Xcode 26.0+
- XcodeGen (`brew install xcodegen`)
- iPadOS Simulator runtime (install via Xcode > Settings > Platforms)

## Quick Start

```bash
# Build
./scripts/build.sh

# Run unit tests
./scripts/test.sh unit

# Run all tests (unit + UI)
./scripts/test.sh

# Launch in simulator
./scripts/run.sh

# Archive for release
./scripts/release.sh
```

## Features

### Heap (Home Screen)
- Grid view of all your stacks
- Create new stacks with the **+** button
- Select and delete stacks with **Select** mode
- Access app settings via the **gear** icon

### Stacks (Notebooks)
- Configure paper type: Plain, Textured, or Graph
- Choose paper size: US Letter or A4
- Set orientation: Portrait or Landscape

### Pages
- Full PencilKit drawing canvas with Apple Pencil support
- Swipe between pages (left/right or up/down, configurable)
- Add new pages with the **+** button
- Drawing data persists automatically

### Settings
- Default paper type, size, and orientation for new stacks
- Page navigation direction (left-right or up-down)

## Project Structure

```
NoteEnough/
├── App/              # App entry point
├── Models/           # SwiftData models and enums
├── Views/            # SwiftUI views
├── ViewModels/       # Observable view models
└── Assets.xcassets/  # App icon and assets
```
