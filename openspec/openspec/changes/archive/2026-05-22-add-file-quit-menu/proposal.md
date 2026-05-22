## Why

ClotCAD is a desktop application but has no menu-based way to quit. Users must use the window close button or the Lisp REPL. Every desktop GUI application should offer a conventional Quit/Exit command in the File menu.

## What Changes

- Add a "Quit" action to the File menu with standard "Ctrl+Q" shortcut
- Wire it to close the window (which triggers `QApplication::quit()` via existing `closeEvent`)
- Change is limited to C++ wrapper files — no Lisp changes needed

## Capabilities

### New Capabilities
- `file-quit`: Quit command in the File menu that closes the application

### Modified Capabilities

None — no existing specs to modify.

## Impact

- `wrap/viewer_window.h` — add `QAction*` member + accessor
- `wrap/viewer_window.cpp` — add menu item in `setupMenus()`
- `wrap/occt_viewer.cpp` — connect action signal in `viewer_create()`
