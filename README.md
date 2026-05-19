# cl-occt-viewer (Qt)

Qt6-based 3D viewer for [cl-occt](https://github.com/anomalyco/cl-occt) using OCCT's Application Interactive Services (AIS/TKV3d). Renders shapes in a QOpenGLWidget with `AIS_ViewController` camera control, native Qt widget panels, and Swank/SLIME connectivity.

## Quickstart

```sh
just viewer       # build libocctviewer.so
just start        # launch viewer + Swank server on port 4005
```

From Emacs: `M-x slime-connect` (port 4005).

## Usage

Display shapes from the in-window REPL (right panel) or from SLIME:

```lisp
(display :box (cl-occt:make-box 10 20 30))
(display :sphere (cl-occt:make-sphere 25))
(undisplay :box)
(clear-all)
```

## Layout

```
┌──────────────────────────────────────────────────┐
│ [File ▼]  [View ▼]                               │
├──────────┬───────────────────────────┬───────────┤
│ Scene    │    3D Viewport            │  REPL     │
│ Tree     │    (OCCT AIS rendering)   │           │
│          │                           │ > (code)  │
│ ☑ :box   │    ┌──┐  axis            │ #<SHAPE   │
│ ☑ :sphere│    │╳ │                   │           │
│          │    └──┘                   │           │
│          │    Grid                   │           │
├──────────┴───────────────────────────┴───────────┤
│ Displaying 2 shapes                  FPS: 60     │
└──────────────────────────────────────────────────┘
```

## Export

File → Export writes **all visible shapes** to a single file:

- **STEP** — Uses OCCT's XDE framework. Each shape is written as a separate named part, preserving all metadata.
- **STL** — Shapes are combined into a compound via `cl-occt:make-compound` and written as one mesh.

## Interface

| Component | Description |
|-----------|-------------|
| **3D Viewport** | QOpenGLWidget with OCCT AIS rendering. Orbit (LMB), pan (MMB), zoom (RMB/scroll) |
| **REPL Panel** (right) | QPlainTextEdit output + QLineEdit input, history via Up/Down arrows |
| **Scene Tree** (left) | Shape list with visibility checkboxes |
| **Menu Bar** | File → Import/Export STEP/STL (exports all visible shapes), View → toggle panels/axis/grid |
| **Status Bar** | Shape count + FPS |

## Architecture

```
Main Thread (Qt)               Worker Thread (Swank)
┌─────────────────────────┐    ┌──────────────────────┐
│ QApplication::exec()    │    │ Swank :port 4005     │
│   ViewerWindow          │    │   └─ SLIME eval      │
│     ViewerWidget        │    │                      │
│       paintGL()         │◀───│ display() → push q   │
│         OCCT redraw     │    │ → postEvent()        │
│         FlushViewEvents │    │ → WakeReceiver       │
│     REPLPanel           │    │ → drain_queue()      │
│     SceneTreePanel      │    │ → update() → paintGL │
└─────────────────────────┘    └──────────────────────┘
```

## Files

```
wrap/
├── occt_viewer.h/.cpp      C API (26 extern "C" functions)
├── viewer_widget.h/.cpp     QOpenGLWidget + AIS_ViewController
├── viewer_window.h/.cpp     QMainWindow, menus, status bar
├── repl_panel.h/.cpp        REPL dock widget
├── scene_tree_panel.h/.cpp  Scene tree dock widget
├── OcctQtTools.h/.cpp       Qt↔OCCT glue helpers
└── OcctGlTools.h/.cpp       GL context/FBO wrapping

src/viewer/
├── package.lisp             Package exports
├── bindings.lisp            CFFI bindings
├── queue.lisp               Event queue + DAG bridge
├── repl.lisp                Eval/file-op callbacks
└── lifecycle.lisp           start-viewer, stop-viewer
```

## Prerequisites

- Qt6 (Widgets + OpenGLWidgets) — `apt install qt6-base-dev libqt6opengl6-dev`
- OCCT 8.0.0
- SBCL + Quicklisp
- cl-occt (at `~/code/cl-occt/main/`)
- CMake ≥ 3.16

## Build OCCT (one-time)

```sh
just setup
```

This downloads OCCT 8.0.0 source, configures with CMake (Release, Shared libraries, Visualization + DataExchange modules), builds, and installs to `.local/`. Takes ~10 minutes.

To configure manually:

```sh
mkdir -p .local
curl -Lo .local/occt.tar.gz https://github.com/Open-Cascade-SAS/OCCT/archive/refs/tags/V8_0_0.tar.gz
mkdir -p .local/occt-src
tar xzf .local/occt.tar.gz -C .local/occt-src --strip-components=1
mkdir -p .local/occt-build
cd .local/occt-build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=../ \
    -DBUILD_LIBRARY_TYPE=Shared \
    -DBUILD_MODULE_ApplicationFramework=OFF \
    -DBUILD_MODULE_DataExchange=ON \
    -DBUILD_MODULE_Draw=OFF \
    -DBUILD_MODULE_FoundationClass=ON \
    -DBUILD_MODULE_ModelingAlgorithms=ON \
    -DBUILD_MODULE_ModelingData=ON \
    -DBUILD_MODULE_Visualization=ON \
    ../occt-src
cmake --build . -- -j$(nproc)
cmake --install .
```

## Build Viewer

```sh
just viewer        # cmake build → lib/libocctviewer.so
```

Or manually:

```sh
cmake -S . -B build
cmake --build build
cp build/libocctviewer.so lib/
```

## Tests

Run the Lisp unit test suite (no display required):

```sh
just test
```

Tests cover queue operations, display/undisplay/clear, helper functions, REPL multiline input parsing, file operation dispatch, multi-shape export warnings, and callback registration. CFFI functions are mocked via `with-mocked-viewer`.

To run from a Lisp REPL:

```lisp
(asdf:load-system :cl-occt-viewer/tests)
(in-package :cl-occt-viewer)
(run-tests)
```
