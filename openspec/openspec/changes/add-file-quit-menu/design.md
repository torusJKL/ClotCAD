## Context

The viewer application (`ViewerWindow`, a `QMainWindow`) already has File, View, and Help menus created in `setupMenus()`. File menu currently has import/export actions but no Quit action. The `ViewerWindow::closeEvent()` already calls `QApplication::quit()`, so triggering the window's close is sufficient to shut down the application cleanly.

Affected files:
- `wrap/viewer_window.h`
- `wrap/viewer_window.cpp`
- `wrap/occt_viewer.cpp`

## Goals / Non-Goals

**Goals:**
- Add a `&Quit` action to the File menu, after the export section
- Add standard keyboard shortcut `Ctrl+Q`
- Wire the action to close the viewer window
- Keep the change minimal — C++ wrapper files only

**Non-Goals:**
- No changes to Lisp lifecycle (`lifecycle.lisp`, `bindings.lisp`, etc.)
- No changes to Qt stylesheets or themes
- No changes to the existing `closeEvent` or quit mechanisms

## Decisions

1. **Close the window vs. call `viewer_quit()` directly**: Use `win->close()` rather than calling `viewer_quit()`. Closing the window triggers the existing `closeEvent`, which calls `QApplication::quit()` — consistent with how the OS window close button works. This ensures any future cleanup in `closeEvent` is also reached via File > Quit.

2. **Add a separate `QAction* myQuitAction` member**: Follows the existing pattern in `ViewerWindow` where every menu action has a named `QAction*` member. Could alternatively connect a locally scoped action, but the established convention is to store the pointer.

3. **Separator before Quit**: Follow standard desktop convention of separating the Quit/Exit action from other File menu items with a menu separator.

## Risks / Trade-offs

- **[Low] Duplicate close triggers**: If both `win->close()` and `QApplication::quit()` are called, Qt handles this safely (double-quit is a no-op). No risk.
- **[Low] macOS convention**: The Quit action normally goes in the application menu on macOS, not File. We use `QMenuBar` on all platforms uniformly. This matches the project's approach of single-platform desktop (Linux-first).
