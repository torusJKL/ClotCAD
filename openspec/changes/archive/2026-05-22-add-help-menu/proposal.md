## Why

Users have no way to identify the application version, view credits, or find links to the open-source dependencies (OCCT, Qt, etc.). An About dialog is standard for desktop applications and provides basic information about the project and its dependencies.

## What Changes

- Add a **Help** menu to the menu bar with an **About ClotCAD** item
- The About item opens a custom dialog showing:
  - ClotCAD logo (`share/icons/ClotCAD-logo.svg`)
  - Application name and version
  - Short description of the application
  - Links to source code repositories (ClotCAD, OCCT, Qt, etc.)
- The dialog follows the existing Qt6 widget patterns (synchronous `exec()`, no native dialogs)

## Capabilities

### New Capabilities
- `help-menu`: Help menu with About dialog showing application info, logo, credits, and dependency links

### Modified Capabilities
_(none — this is a purely additive change)_

## Impact

- `wrap/viewer_window.h` — add `QAction*` members for the Help menu and About action
- `wrap/viewer_window.cpp` — add Help menu in `setupMenus()`
- `wrap/occt_viewer.cpp` — wire About action signal to open the About dialog
- `CMakeLists.txt` — optionally add logo as Qt resource for runtime access
- `share/icons/ClotCAD-logo.svg` — existing asset, no change needed
