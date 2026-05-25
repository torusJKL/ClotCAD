# AGENTS.md

## Build Commands

```sh
just setup        # Download + build OCCT 8.0.0 to .local/ (one-time, ~10 min)
just viewer       # CMake build → lib/libclotcad.so
just alive-lsp    # Clone alive-lsp LSP server → lib/alive-lsp/
just core         # SBCL core dump → ClotCAD.core (for distribution)
just dist         # Assemble distribution → dist/ + tarball + AppImage
just package-all  # viewer + core + dist (full distribution pipeline)
just start        # Launch viewer + Slynk (4005) + Alive LSP (4006)
just test         # Run Lisp test suite (no display required)
just clean        # Remove build artifacts
```

## Runtime Dependencies

**Always set `LD_LIBRARY_PATH`** when running or testing:

```sh
export LD_LIBRARY_PATH=lib:.local/lib:lib/cl-occt/lib
```

Without this, the C++ library and OCCT won't load.

## Architecture

- **C++**: Thin Qt6 widgets in `wrap/` → shared lib `libclotcad.so`. ViewerWidget (QOpenGLWidget + AIS_ViewController) handles rendering and mouse events. No business logic, no state — just event dispatch and OCCT rendering calls.
- **Lisp**: CFFI bindings in `src/viewer/` → ASDF system `:clotcad`. All viewer state (shape storage, grid/axis visibility, render loop) lives in Lisp modules: `ui.lisp` (state management), `render.lisp` (periodic redraw), `queue.lisp` (inter-thread dispatch), `repl.lisp` (callback registration).
- **Threading**: Qt main thread runs event loop; Slynk worker thread (port 4005) and Alive LSP worker thread (port 4006) handle eval and push display updates via Qt events
- **Entry points**:
  - C++: `wrap/viewer_window.cpp` → `QMainWindow`
  - Lisp: `src/viewer/lifecycle.lisp` → `start-viewer`, `bootstrap`
  - Distribution: `run.sh` / `AppRun` → `sbcl --core ClotCAD.core --eval '(bootstrap)'`

## Design Decisions

- **File dialogs**: We use `QFileDialog::DontUseNativeDialog` for all import/export dialogs (STEP/STL) because the system-native dialog crashes the application on some configurations. See `wrap/occt_viewer.cpp` for the 4 dialog sites.
- **alive-lsp patches**: We patch `lib/alive-lsp/` source in 3 files to add `:default-package` support. Alive LSP's eval handler hardcodes `"cl-user"` as the default package, but the viewer operates in `CLOTCAD-USER`. The upstream project has no configurable default package, so we added a `:default-package` parameter to `alive/server:start` threaded through the state → eval handler. When the client sends `"cl-user"` or `"common-lisp-user"` (or omits the package), the server substitutes the configured default. The clone is pinned to a specific commit in `justfile` so patches are reproducible. Patches are stored at `scripts/patches/alive-lsp-default-package.patch` and applied automatically by `just alive-lsp`.

- **Init file loading**: ClotCAD evaluates an init script at startup if one is found. The default path is `~/.config/clotcad/init.lisp`. Users can override with `--init FILE` or skip entirely with `--no-init`. In UI (`--viewer`) mode, the init file is loaded asynchronously through the same `process-import-tick` pipeline as File > Import Lisp — forms appear in the REPL output one at a time. In headless (`--slynk`, `--alive`) mode, the init file is evaluated synchronously before the server starts. The path is controlled by the `*init-file-path*` and `*no-init*` special variables in `repl.lisp`. The `bootstrap` function calls `load-init-file-headless` before `start-viewer`; `start-viewer` calls `load-init-file-ui` (guarded by `*init-loaded*` to prevent double-loading). See `scripts/run.sh` for CLI parsing and `t/viewer-tests.lisp` for tests.

- **AppImage Qt6 OpenGL plugins**: When bundling Qt6 applications in AppImages, you **must** include the `xcbglintegrations` plugins (`libqxcb-glx-integration.so` and `libqxcb-egl-integration.so`) in `lib/plugins/xcbglintegrations/`. These plugins bridge between the XCB platform plugin and the GL libraries (GLX/EGL). Without them, Qt6 cannot create OpenGL contexts and fails with:
  ```
  QXcbIntegration: Cannot create platform OpenGL context, neither GLX nor EGL are enabled
  QOpenGLWidget is not supported on this platform.
  ```
  This error is misleading—it's not about missing GL libraries, but missing Qt plugins. The plugins are located at `/usr/lib/x86_64-linux-gnu/qt6/plugins/xcbglintegrations/` on Debian/Ubuntu systems. See `scripts/package.sh` for the bundling logic.

## Testing

Tests are in `t/` directory, loaded via `:clotcad/tests` ASDF system. Run with `just test` (uses mocked CFFI, no display needed).

The `with-mocked-viewer` macro mocks `%viewer-post-event`, `%viewer-sync-shapes`,
`%viewer-post-event-delayed`, `%viewer-fit-all`, `%viewer-show-grid`,
`%viewer-show-axis`, `%viewer-set-antialiasing`, `%viewer-set-eval-callback`,
`%viewer-set-file-op-callback`, `%viewer-append-repl-output`, `%viewer-show-dock`,
`%viewer-is-grid-visible`, `%viewer-is-axis-visible`, `%viewer-set-stylesheet`,
`%viewer-color-scheme`, `%viewer-set-color-scheme-callback`, `%viewer-get-view`,
`%viewer-get-trihedron`, `%viewer-set-placeholder-color`, `%viewer-set-status-text`,
`%viewer-set-visibility-callback`, `%viewer-set-import-status`, `%viewer-get-context`,
`%viewer-get-ais-object`, `%viewer-set-selection-callback`, `%viewer-set-tree-selection-callback`,
`%viewer-set-mouse-selection-scheme`, `%viewer-sync-tree-selection`,
`%viewer-set-repl-history-modifier`, and `%viewer-set-repl-submit-modifier`.
Add new CFFI function symbols to the mock list if new tests require them.

All IDE connectivity is via SLY (not SLIME). Slynk serves SLY natively; SLIME compatibility is not supported due to protocol differences. Alive LSP provides LSP protocol support for editors like Visual Studio Code.

The Lisp import/export system uses `*repl-log*` (REPL history log),
`*import-speed*` (replay delay), `*import-cancelled*` (cancellation flag),
and `*export-with-output*` (debug mode toggle). User-facing functions:
`cancel-import`, `replay-speed`, `result-export`, and `export-repl-history`.

Tests for `bootstrap` use inline mocking of `%viewer-create`, `%viewer-show`,
`%viewer-run`, `%viewer-quit`, and `start-viewer`. The `make-core-loads-systems`
test mocks `sb-ext:save-lisp-and-die`.

## OpenCode Workflow

This repo uses the **openspec** workflow (see `.opencode/skills/` and `.opencode/commands/`). Key commands:
- `/opsx-explore` — Enter explore mode
- `/opsx-propose` — Propose a new change
- `/opsx-apply` — Apply a change from spec
- `/opsx-archive` — Archive completed change

## Rename Translation Matrix (May 2026)

This change (`rename-to-clotcad`) renamed all project identifiers from the legacy
`cl-occt-viewer` to `ClotCAD`. Use this table to map old references to new:

| Old Name | New Name |
|---|---|
| `cl-occt-viewer.asd` (file) | `clotcad.asd` |
| `:cl-occt-viewer` (ASDF system) | `:clotcad` |
| `:cl-occt-viewer/tests` (ASDF test system) | `:clotcad/tests` |
| `:cl-occt-viewer.impl` (Lisp package) | `:clotcad.impl` |
| `:cl-occt-viewer` (Lisp package) | `:clotcad` |
| `:cl-occt-user` (Lisp workspace) | `:clotcad-user` |
| `occt-viewer-qt` (CMake project) | `ClotCAD` |
| `occtviewer` (CMake target) | `clotcad` |
| `libocctviewer.so` (shared library) | `libclotcad.so` |
| `libocctviewer` (CFFI foreign lib) | `libclotcad` |
| `cl-occt-viewer:bootstrap` (Lisp function) | `clotcad:bootstrap` |

OpenSpec archive documents (under `openspec/changes/archive/`) were intentionally
left unchanged — they are historical records. All active code, build scripts, and
documentation have been updated.

## Important Paths

- OCCT installed to: `.local/`
- cl-occt dependency: `lib/cl-occt/` (git submodule)
- alive-lsp dependency: `lib/alive-lsp/` (git clone)
- Shared library: `lib/libclotcad.so`
- SBCL core dump: `ClotCAD.core` (product of `just core`)
- Distribution: `dist/` (product of `just dist`), `ClotCAD-*.tar.gz`, `ClotCAD-*.AppImage`
- Slynk port: `4005`
- Alive LSP port: `4006`

## Prerequisites

- Qt6 (Widgets + OpenGLWidgets)
- OCCT 8.0.0
- SBCL + Quicklisp
- cl-occt at `lib/cl-occt/` (git submodule)
- CMake ≥ 3.16
