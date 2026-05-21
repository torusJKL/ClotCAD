# AGENTS.md

## Build Commands

```sh
just setup    # Download + build OCCT 8.0.0 to .local/ (one-time, ~10 min)
just viewer   # CMake build → lib/libocctviewer.so
just start    # Launch viewer + Swank on port 4005
just test     # Run Lisp test suite (no display required)
just clean    # Remove build artifacts
```

## Runtime Dependencies

**Always set `LD_LIBRARY_PATH`** when running or testing:

```sh
export LD_LIBRARY_PATH=lib:.local/lib:lib/cl-occt/lib
```

Without this, the C++ library and OCCT won't load.

## Architecture

- **C++**: Thin Qt6 widgets in `wrap/` → shared lib `libocctviewer.so`. ViewerWidget (QOpenGLWidget + AIS_ViewController) handles rendering and mouse events. No business logic, no state — just event dispatch and OCCT rendering calls.
- **Lisp**: CFFI bindings in `src/viewer/` → ASDF system `:cl-occt-viewer`. All viewer state (shape storage, grid/axis visibility, render loop) lives in Lisp modules: `ui.lisp` (state management), `render.lisp` (periodic redraw), `queue.lisp` (inter-thread dispatch), `repl.lisp` (callback registration).
- **Threading**: Qt main thread runs event loop; Swank worker thread handles eval and pushes display updates via Qt events
- **Entry points**:
  - C++: `wrap/viewer_window.cpp` → `QMainWindow`
  - Lisp: `src/viewer/lifecycle.lisp` → `start-viewer`

## Design Decisions

- **File dialogs**: We use `QFileDialog::DontUseNativeDialog` for all import/export dialogs (STEP/STL) because the system-native dialog crashes the application on some configurations. See `wrap/occt_viewer.cpp` for the 4 dialog sites.

## Testing

Tests are in `t/` directory, loaded via `:cl-occt-viewer/tests` ASDF system. Run with `just test` (uses mocked CFFI, no display needed).

The `with-mocked-viewer` macro mocks `%viewer-post-event`, `%viewer-put-shape`,
`%viewer-remove-shape`, `%viewer-clear`, `%viewer-fit-all`, `%viewer-show-grid`,
`%viewer-show-axis`, `%viewer-set-antialiasing`, `%viewer-set-eval-callback`,
`%viewer-set-file-op-callback`, `%viewer-append-repl-output`, `%viewer-show-dock`,
`%viewer-is-grid-visible`, and `%viewer-is-axis-visible`. Add new CFFI function
symbols to the mock list if new tests require them.

## OpenCode Workflow

This repo uses the **openspec** workflow (see `.opencode/skills/` and `.opencode/commands/`). Key commands:
- `/opsx-explore` — Enter explore mode
- `/opsx-propose` — Propose a new change
- `/opsx-apply` — Apply a change from spec
- `/opsx-archive` — Archive completed change

## Important Paths

- OCCT installed to: `.local/`
- cl-occt dependency: `lib/cl-occt/` (git submodule)
- Shared library: `lib/libocctviewer.so`
- Swank port: `4005`

## Prerequisites

- Qt6 (Widgets + OpenGLWidgets)
- OCCT 8.0.0
- SBCL + Quicklisp
- cl-occt at `lib/cl-occt/` (git submodule)
- CMake ≥ 3.16
