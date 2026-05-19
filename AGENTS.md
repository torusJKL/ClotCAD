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

- **C++**: Qt6 widgets in `wrap/` → shared lib `libocctviewer.so`
- **Lisp**: CFFI bindings in `src/viewer/` → ASDF system `:cl-occt-viewer`
- **Threading**: Qt main thread runs event loop; Swank worker thread handles eval and pushes display updates via Qt events
- **Entry points**:
  - C++: `wrap/viewer_window.cpp` → `QMainWindow`
  - Lisp: `src/viewer/lifecycle.lisp` → `start-viewer`

## Testing

Tests are in `t/` directory, loaded via `:cl-occt-viewer/tests` ASDF system. Run with `just test` (uses mocked CFFI, no display needed).

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