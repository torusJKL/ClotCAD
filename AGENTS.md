# AGENTS.md

## Build Commands

```sh
just setup        # Download + build OCCT 8.0.0 to .local/ (one-time, ~10 min)
just submodules   # Init cl-occt submodule + symlink + wrap (requires OCCT built)
just viewer       # CMake build → lib/libclotcad.so
just alive-lsp    # Clone alive-lsp LSP server → lib/alive-lsp/
just core         # SBCL core dump → ClotCAD.core (for distribution)
just dist         # Assemble distribution → dist/ + tarball + AppImage
just package-all  # viewer + core + dist (full distribution pipeline)
just start        # Launch viewer + Slynk (4005) + Alive LSP (4006)
just test         # Run Lisp test suite (no display required)
just docs         # Generate Staple documentation → homepage/output/
just cheatsheet   # Build ClotCAD cheatsheet PDF
just clean        # Remove build artifacts
```

## Runtime Dependencies

**Always set `LD_LIBRARY_PATH`** when running or testing:

```sh
export LD_LIBRARY_PATH=lib:.local/lib:lib/cl-occt/lib
```

Without this, the C++ library and OCCT won't load.

For headless modes (`--slynk`, `--alive`): set `QT_QPA_PLATFORM=offscreen`.

## Architecture

- **C++**: Thin Qt6 widgets in `wrap/` → shared lib `libclotcad.so`. ViewerWidget (QOpenGLWidget + AIS_ViewController) handles rendering and mouse events. No business logic, no state — just event dispatch and OCCT rendering calls.
- **Lisp**: Two ASDF components under `:clotcad`:
  - `src/model/` — parametric DAG model system: `model.lisp`, `params.lisp`, `propagation.lisp`, `api.lisp`. Handles model registration, parameter management, change propagation, and DAG evaluation.
  - `src/viewer/` — all viewer logic across 16 files: `bindings.lisp` (CFFI), `queue.lisp` (event dispatch), `ops.lisp` (def/show/hide/toggle/wrappers), `ui.lisp` (state), `render.lisp` (redraw loop), `repl.lisp` (callbacks + init loader), `select.lisp` (selection), `lifecycle.lisp` (start/stop/bootstrap), `frame.lisp` (coordinate frames), `query.lisp` (subshape queries), `naming.lisp` (named subshapes), `sketch.lisp` (sketch-on-face), `text.lisp` (3D text), `theme.lisp` (dark/light themes), `introspect.lisp` (doc/browse/help).
- **Entry points**:
  - C++: `wrap/viewer_window.cpp` → `QMainWindow`
  - Lisp: `src/viewer/lifecycle.lisp` → `start-viewer`, `bootstrap`
  - Distribution: `run.sh` / `AppRun` → `sbcl --core ClotCAD.core --eval '(bootstrap)'`
- **Threading**: Qt main thread runs event loop + `drain-queue-callback` (called from `%viewer-set-drain-callback`); Slynk worker thread (port 4005) and Alive LSP worker thread (port 4006) handle eval via `%viewer-set-eval-callback` and push display updates via `%viewer-post-event`.

## Design Decisions

- **File dialogs**: `QFileDialog::DontUseNativeDialog` for all import/export dialogs because system-native dialog crashes on some configurations. See `wrap/occt_viewer.cpp`.
- **alive-lsp patches**: We patch `lib/alive-lsp/` to add `:default-package` support (`"CLOTCAD-USER"`). Patches at `scripts/patches/alive-lsp-default-package.patch`, applied automatically by `just alive-lsp`.
- **Init file loading**: Default path `~/.config/clotcad/init.lisp`, override with `--init FILE`, skip with `--no-init`. In UI mode, loaded asynchronously via `process-import-tick` pipeline. In headless mode, evaluated synchronously before server start. Guarded by `*init-loaded*` to prevent double-loading. See `repl.lisp:56-150`.
- **AppImage Qt6 OpenGL plugins**: Must include `libqxcb-glx-integration.so` and `libqxcb-egl-integration.so` in `lib/plugins/xcbglintegrations/`. Without these, Qt6 cannot create OpenGL contexts and shows a misleading "QXcbIntegration: Cannot create platform OpenGL context" error. See `scripts/package.sh`.

## Testing

Tests in `t/`: `viewer-tests.lisp`, `query.lisp`, `naming.lisp`, `frame.lisp`, `sketch.lisp`, `text.lisp`. Loaded via `:clotcad/tests` ASDF system.

**Always clean `~/.cache/common-lisp/` before running tests**, otherwise stale FASLs can cause SBCL to enter the debugger instead of running cleanly.

Run with `just test` (mocked CFFI, no display needed). Or from REPL:

```lisp
(asdf:load-system :clotcad/tests :force t)
(in-package :clotcad)
(run-tests)
```

The `with-mocked-viewer` macro in `t/viewer-tests.lisp:102` mocks all `%viewer-*` CFFI functions. When adding new CFFI functions, add corresponding mocks there. Tests for `bootstrap` inline-mock `%viewer-create`, `%viewer-show`, `%viewer-run`, `%viewer-quit`, and `start-viewer`. The `make-core-loads-systems` test mocks `sb-ext:save-lisp-and-die`.

All IDE connectivity is via SLY (not SLIME). Slynk serves SLY natively. Alive LSP provides LSP protocol for VS Code.

## OpenCode Workflow

This repo uses the **openspec** workflow (see `.opencode/skills/` and `.opencode/commands/`). Key commands:
- `/opsx-explore` — Explore mode
- `/opsx-propose` — Propose a new change
- `/opsx-apply` — Apply a change from spec
- `/opsx-archive` — Archive completed change

## Important Paths

- OCCT installed to: `.local/`
- cl-occt dependency: `lib/cl-occt/` (git submodule)
- alive-lsp dependency: `lib/alive-lsp/` (git clone, pinned commit in `justfile`)
- Shared library: `lib/libclotcad.so`
- SBCL core dump: `ClotCAD.core` (product of `just core`)
- Distribution output: `dist/`, `ClotCAD-*.tar.gz`, `ClotCAD-*.AppImage`
- Slynk port: `4005` | Alive LSP port: `4006`
