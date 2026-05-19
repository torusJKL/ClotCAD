## Why

The existing GLFW+ImGui viewer on the `main` branch is not functional. A clean-slate Qt-based viewer is needed — using OCCT's Application Interactive Services (TKV3d/AIS) for high-quality 3D presentation, native Qt widgets for the UI, and `AIS_ViewController` for camera control. The viewer must run on all three major platforms (Linux, Windows, macOS) and integrate with the existing cl-occt Lisp REPL/SLIME workflow.

## What Changes

- **BREAKING**: Replace GLFW windowing with Qt6 (QMainWindow + QOpenGLWidget)
- **BREAKING**: Replace ImGui panels with native Qt widgets (QPlainTextEdit REPL, QTreeWidget scene tree, QMenuBar, QStatusBar)
- **BREAKING**: Remove all ImGui lifecycle code (viewer_setup_imgui, viewer_shutdown_imgui, viewer_frame)
- **BREAKING**: Replace manual camera orbit/pan/zoom with OCCT's AIS_ViewController
- **BREAKING**: Redesigned threading model — Qt on main thread, Swank/SLIME on worker thread
- **BREAKING**: New C API (occt_viewer.h) — remove GLFW/ImGui functions, add Qt lifecycle functions
- Add: Qt-based REPL dock widget (QPlainTextEdit output + QLineEdit input)
- Add: Qt-based scene tree dock widget (QTreeWidget with visibility checkboxes)
- Add: Native file dialogs (QFileDialog) for STEP/STL import/export
- Add: OcctNeutralWindow + OcctGlTools helpers (adapted from occt-samples-qt)
- New build system: CMakeLists.txt for Qt6 + OCCT

## Capabilities

### New Capabilities

- `qt-viewer-core`: Qt6 window and 3D viewport with OCCT AIS rendering, AIS_ViewController camera control, AIS_Trihedron axis helper, rectangular grid, and event-driven redraw
- `repl-panel`: In-window REPL dock widget with QPlainTextEdit output, QLineEdit input, history navigation, and synchronous eval callback to Lisp
- `scene-tree-panel`: Scene tree dock widget with shape list, visibility checkboxes, and sync with OCCT display/erase
- `file-io`: Native file dialogs for STEP (import/export) and STL (import/export) via cl-occt Lisp callbacks

### Modified Capabilities

*(none — this is a clean-slate implementation)*

## Impact

- **C++**: New files in `wrap/` — viewer_window, viewer_widget, repl_panel, scene_tree_panel, OcctQtTools, OcctGlTools. Rewritten occt_viewer.h/cpp.
- **Lisp**: Updated `bindings.lisp` (new CFFI), `lifecycle.lisp` (Qt on main thread, Swank on worker), `queue.lisp` (minor wake rename), `repl.lisp` (unchanged), `package.lisp` (updated exports)
- **Dependencies**: Add Qt6 (Widgets + OpenGLWidgets), remove GLFW + ImGui
- **Build**: CMakeLists.txt replaces bare g++ invocation in justfile
