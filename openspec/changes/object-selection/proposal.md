## Why

Users need to select objects to perform operations on them (move, delete, boolean ops, inspect). Currently there is no way to select objects at all — the 3D view only orbits/pans/zooms, the scene tree only shows/hides shapes, and the REPL has no selection commands. Adding synchronized selection across all three modalities unlocks the entire next layer of interactive CAD workflow.

## What Changes

- **NEW**: Selection state management in Lisp (`*selected*`) — authoritative single source of truth
- **NEW**: 3D viewport object selection via OCCT's `AIS_InteractiveContext` with `ReplaceExtra` mouse scheme (click = select, Ctrl+click = add, Shift+click = toggle)
- **NEW**: Scene tree selection — click tree items to select, Ctrl/Shift for multi-select, synced with 3D view
- **NEW**: REPL `(select ...)` command — accepts symbols and strings, variadic
- **NEW**: REPL `(deselect ...)`, `(clear-selection)`, `(selected-shapes)` commands
- **NEW**: Configurable mouse selection scheme from Lisp (`apply-selection-schemes`)
- **UPDATE**: Update `cl-occt` submodule to latest for selection bindings
- **NEW**: Selection-related test coverage in `t/`
- **UPDATE**: README with selection API documentation

## Capabilities

### New Capabilities

- `selection-core`: Selection state (`*selected*`), REPL commands (`select`, `deselect`, `clear-selection`, `selected-shapes`), queue-based sync from worker thread to OCCT context on main thread
- `viewport-selection`: 3D viewport object picking with AIS_ViewController integration, `OnSelectionChanged` callback, `ReplaceExtra` mouse scheme, hover detection
- `tree-selection`: Scene tree multi-select with Qt `ExtendedSelection`, Ctrl/Shift modifier support, bidirectional sync with 3D view and REPL

### Modified Capabilities

- *(none — selection is new functionality)*

## Impact

- **C++ (wrap/)**: 5 new C API functions in `occt_viewer.h/.cpp`, `ViewerWidget` overrides (`UpdateMouseClick`, `OnSelectionChanged`), `SceneTreePanel` selection wiring
- **Lisp (src/viewer/)**: New `select.lisp` file, updated `queue.lisp` (selection sync), updated `bindings.lisp` (new CFFI), updated `repl.lisp` (callbacks), updated `package.lisp` (exports)
- **Submodule**: `lib/cl-occt` updated to `564b8ae` for selection bindings
- **Tests**: New unit tests in `t/` for selection with mocked viewer
- **Docs**: README.md updated with selection API
