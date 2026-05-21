## Why

The application crashes when users open the system-native file dialog for import/export operations (STEP/STL). Using Qt6's built-in file dialog (non-native) eliminates the crash and provides consistent cross-platform behavior.

## What Changes

- Add `dialog.setOption(QFileDialog::DontUseNativeDialog)` to all four file dialogs in `wrap/occt_viewer.cpp`:
  - Import STEP
  - Import STL
  - Export STEP
  - Export STL
- No other code changes required — the dialog setup and Lisp-side handling remain unchanged.

## Capabilities

### New Capabilities

- `qt-file-dialog`: Force Qt6's non-native file dialog for all import/export operations to prevent crashes caused by the system dialog.

### Modified Capabilities

*(None — no existing specs to modify.)*

## Impact

- **File**: `wrap/occt_viewer.cpp` — 4 lines added (one `DontUseNativeDialog` call per dialog)
- **Dependencies**: None (pure Qt6 change, no new libraries)
- **Behavior**: Dialogs will look slightly different (Qt6 style instead of system-native), but all functionality (file selection, filtering, accept/reject) remains identical.
