## Why

When a port is already in use (for Slynk on 4005 or Alive LSP on 4006), ClotCAD logs a warning to stdout and continues. In `--viewer` mode (desktop launch), terminal output is invisible — the user sees the app fail to start with no explanation. This is a poor user experience.

## What Changes

- Show a Qt dialog when Slynk or Alive LSP fails to start due to a port conflict
- The dialog informs the user which port is in use and which server failed
- The user can dismiss the dialog and continue using the viewer without the REPL server
- No change to behavior when ports are free (no extra dialogs for success)
- No change to non-viewer modes (CLI usage unaffected)

## Capabilities

### New Capabilities
- `port-conflict-alert`: Show a Qt error dialog when Slynk or Alive LSP fails to start because its port is already in use, allowing the user to continue without the server.

### Modified Capabilities
*(none)*

## Impact

- **lifecycle.lisp**: `start-slynk` and `start-alive` need to detect port-in-use errors specifically and call a new dialog function instead of just logging to stdout
- **C++ (occt_viewer.cpp)**: Needs a new CFFI-callable function `viewer_show_message` that shows a `QMessageBox` warning dialog
- **CFFI bindings**: New `%viewer-show-message` function in the viewer CFFI interface for Lisp→C++ dialog display
- **No changes** to Slynk or Alive LSP themselves — only the caller-side error handling
- **No changes** to REPL, theme, UI, or rendering modules
