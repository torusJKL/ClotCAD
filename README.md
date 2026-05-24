# ClotCAD

Qt6-based 3D viewer for [cl-occt](https://github.com/torusJKL/cl-occt) using OCCT's Application Interactive Services (AIS/TKV3d). Renders shapes in a QOpenGLWidget with `AIS_ViewController` camera control, native Qt dock widgets, Slynk/SLY connectivity, and an LSP server for VS Code and other LSP-compatible editors.

The source code is available at [github.com/torusJKL/ClotCAD](https://github.com/torusJKL/ClotCAD).

## Quickstart

```sh
just setup         # Build OCCT + cl-occt (one-time, ~10 min)
just viewer        # Build libclotcad.so
just start         # Launch viewer + Slynk (4005) + Alive LSP (4006)
```

From Emacs: `M-x sly-connect` (port 4005).
From VS Code: connect to `localhost:4006` via the alive-lsp extension.

## Usage

The viewer starts in the `CL-OCCT-USER` package, which gives you
unqualified access to all modeling and viewer commands:

```lisp
;; Classic display workflow:
(display :box (make-box 10 20 30))
(display :sphere (make-sphere 25))
(undisplay :box)
(clear-all)
(fit-view)                ; fit all shapes to viewport

;; Named shape workflow (def → show):
(def :s (make-sphere 20))           ; define, hidden from view
(def :b (make-box 10 20 30))        ; define, hidden from view
(def :result (cut :s :b))           ; operate by symbol
(show :result)                      ; show just the result

;; String names also work (def with string, operate by string):
(def "box2" (make-box 20 20 40))    ; define with string name
(cut :s "box2")                     ; operate using string designator

;; Visibility control:
(hide :result)                      ; hide from 3D view
(show :result)                      ; show again
(toggle :result)                    ; toggle visibility

;; Scene Tree control:
(show-defs nil)                     ; hide all def-ined shapes from tree
(toggle-defs)                       ; toggle tree visibility for def shapes

;; Explicit shape resolution (symbols and strings):
(cut (resolve-shape :s) (resolve-shape :b))
(cut (resolve-shape :s) (resolve-shape "box2"))

;; Selection (three synchronized paths):
(select :box :sphere)               ; select shapes — replaces any previous
(select "box2")                     ; string names also work
(select)                            ; deselect all
(deselect :sphere)                  ; remove from selection
(clear-selection)                   ; deselect all
(selected-shapes)                   ; → ("BOX" "SPHERE")

;; Mouse selection scheme (configurable from Lisp):
(apply-selection-schemes)           ; default: ReplaceExtra, Ctrl=Add, Shift=XOR
(apply-selection-schemes :click :add :ctrl-click :xor)
```

Wrapper functions (`cut`, `fuse`, `common`, `section`, `translate`, `rotate`,
`make-prism`, `make-revol`, `make-compound`, `make-part`, `write-step`,
`write-stl`) accept symbols, strings, and raw shapes. Use symbols or strings to
reference def-ined or displayed shapes; pass raw shapes for ad-hoc geometry.

All viewer settings are changeable at runtime from either REPL:

```lisp
(show-axis nil)          ; hide axis helper
(toggle-grid)            ; toggle grid
(toggle-repl)            ; toggle REPL dock
(toggle-scene-tree)      ; toggle Scene Manager
(set-view-aa nil)        ; disable antialiasing
(show-viewcube nil)      ; hide ViewCube
(toggle-viewcube)        ; toggle ViewCube visibility
(show-viewcube-axes nil) ; hide ViewCube's embedded trihedron
(toggle-viewcube-axes)   ; toggle ViewCube's embedded trihedron
(set-view :top)          ; look at top (+Z) face — shows X-Y plane
(set-view :bottom)       ; look at bottom (-Z) face
(set-view :front)        ; look in -Y direction — shows X-Z plane
(set-view :back)         ; look in +Y direction
(set-view :left)         ; look in -X direction — shows Y-Z plane
(set-view :right)        ; look in +X direction
(set-view :iso)          ; isometric view
(current-view)           ; → :TOP (or nil if non-standard orientation)
```

You can switch to the `cl-occt` or `clotcad` packages directly
for qualified access, or use the package nicknames `:cad-user` / `:occt-user`:

```lisp
(in-package :cad-user)   ; same as CL-OCCT-USER
```

### REPL

The in-window REPL supports multi-line input (paste any amount of code) and
multi-form evaluation — all complete S-expressions entered at once are
evaluated:

```lisp
> (+ 1 2) (+ 3 4)            ; two forms → "3" and "7"
> (def :b1 (make-box 10 10 10))
  (def :s1 (make-sphere 10))  ; multi-line input, both def'd
```

**Key bindings** (default, configurable at runtime):

<table>
  <tr><th>Key</th><th>Action</th></tr>
  <tr><td><b>Enter</b></td><td>Submit expression</td></tr>
  <tr><td><b>Shift+Enter</b></td><td>Insert newline</td></tr>
  <tr><td><b>Ctrl+Up</b></td><td>Previous history entry</td></tr>
  <tr><td><b>Ctrl+Down</b></td><td>Next history entry</td></tr>
  <tr><td><b>Tab</b></td><td>Insert 2-space indent</td></tr>
</table>

To change the modifiers from Lisp:

```lisp
;; Use plain Up/Down arrow for history (no Ctrl needed)
(set-repl-history-key :none)

;; Use Ctrl+Enter to submit, plain Enter for newlines
(set-repl-submit-key :ctrl)
```

Accepts `:ctrl`, `:none`, and `:alt` for each modifier.

## Workspace Package

The system provides `:clotcad-user` — a convenience workspace package
that combines `:cl-occt` (modeling API) and `:clotcad` (viewer
commands) into a single namespace. Load it through nicknames:

<table>
  <tr><th>Package</th><th>Nicknames</th></tr>
  <tr><td><code>CL-OCCT-USER</code></td><td><code>CAD-USER</code>, <code>OCCT-USER</code></td></tr>
</table>

This is the default package when starting the viewer via `just start`.
From a SLY REPL, type `(in-package :cad-user)` to switch.

## Remote Shutdown

Gracefully stop all services and exit the process from any connected
REPL (SLY, Alive LSP, or the in-window REPL):

```lisp
(quit-clotcad)
```

This stops the Slynk server (port 4005), Alive LSP server (port 4006),
and 3D viewer (if running), resets Lisp state, and exits cleanly.
Works in all run modes (`--viewer`, `--slynk`, `--alive`).

> **Note:** Calling `quit-clotcad` will disconnect the remote client
> as the Lisp process exits. Reconnect to start a new session.

## Layout

```
┌──────────────────────────────────────────────────┐
│ ┌──────────┬──────────────────────┬────────────┐ │
│ │ Scene    │     3D Viewport     │   REPL     │ │
│ │ Tree     │     (OCCT AIS)      │   ──────── │ │
│ │          │           ┌──┐      │ > (display │ │
│ │ ☑ :box   │     cube  │╳ │ axis │ > :box ... │ │
│ │ ☑ :sphere│           └──┘      │ > (+ 1 2)  │ │
│ │          │          Grid       │ 3          │ │
│ │          │                     │ > (def :b  │ │
│ │          │                     │     (make  │ │
│ │          │                     │      :box)) │ │
│ └──────────┴──────────────────────┴────────────┘ │
│ Displaying N shapes         FPS: 60               │
└──────────────────────────────────────────────────┘
```

## Lisp File Import

You can load a `.lisp` file of forms and evaluate them sequentially (same as
typing each form in the REPL). Use **File > Import Lisp...** from the menu.

A **danger warning** is shown before any code executes — importing a Lisp file
gives it full access to your system (files, network, shell).

```lisp
;; Example "model.lisp" you might import:
(def :s (make-sphere 20))
(show :s)
(def :b (make-box 10 10 10))
(cut :s :b)
(display :result *)
```

Import forms are evaluated one at a time on the Qt main thread, yielding to
the event loop between forms. The 3D view stays interactive while importing.

**Controls during import:**

<table>
  <tr><th>Action</th><th>What it does</th></tr>
  <tr><td><b>Ctrl+G</b></td><td>Cancel the current import</td></tr>
  <tr><td>Click "Importing N/M..." in status bar</td><td>Cancel the current import</td></tr>
  <tr><td><code>(cancel-import)</code></td><td>Cancel the current import</td></tr>
  <tr><td><code>(replay-speed 500)</code></td><td>Wait 500ms between forms (nil = immediate)</td></tr>
</table>

The status bar shows "Importing 5/42..." during an active import. Click it
to cancel.

## REPL History Export

Use **File > Export REPL History...** to save the REPL session log to a
`.lisp` file.

```lisp
;; Toggle debug mode (includes results as comments):
(result-export t)     ;; include outputs like "; NIL"
(result-export nil)   ;; code only (default)

;; Export manually from the REPL:
(export-repl-history "session.lisp")
```

If `result-export` is `nil` (default), the exported file contains only the
code you submitted. If `t`, each output line is included as a `;` comment
after the corresponding input.

## Export STEP/STL

Use **File > Export STEP/STL** from the menu (opens a save dialog), or
export directly from the REPL using either the classic API or the new
symbol-based export:

```lisp
;; Export a specific shape:
(write-step :result "output.step")
(write-stl :s "output.stl")
```

## Interface

<table>
  <tr><th>Component</th><th>Description</th></tr>
  <tr><td><b>Menu Bar</b> (top)</td><td>File (Import/Export STEP/STL, Import Lisp, Export REPL History) and View (REPL, Scene Tree, Axis, Grid, ViewCube toggles)</td></tr>
  <tr><td><b>3D Viewport</b> (center)</td><td>QOpenGLWidget with OCCT AIS rendering. Orbit (LMB), pan (MMB), zoom (RMB/scroll). ViewCube in top-right corner for one-click view orientation</td></tr>
  <tr><td><b>Scene Tree</b> (left)</td><td>Shape list with visibility checkboxes. Click to select, Ctrl+click to toggle, Shift+click for range</td></tr>
  <tr><td><b>REPL</b> (right)</td><td>In-window Lisp REPL with multi-line input, multi-form evaluation, input/output history, and configurable key bindings</td></tr>
  <tr><td><b>Status Bar</b> (bottom)</td><td>Shape count, import progress/cancel label, and FPS</td></tr>
</table>

## Download

Pre-built binaries are available for Linux:

<table>
  <tr><th>Format</th><th>Description</th></tr>
  <tr><td><b>ClotCAD-*.AppImage</b></td><td>Single-file executable — <code>chmod +x</code> and run</td></tr>
  <tr><td><b>ClotCAD-*.tar.gz</b></td><td>Portable tarball — extract and run <code>run.sh</code></td></tr>
</table>

**Requirements:** glibc ≥ 2.39 (Ubuntu 24.04+, Fedora 39+, Arch, etc.).

Both bundles include SBCL, OCCT, Qt6, Slynk, and Alive LSP — zero installation steps.

**Source code:** https://github.com/torusJKL/ClotCAD (GPL-3.0)

### From AppImage

```sh
chmod +x ClotCAD-*.AppImage
./ClotCAD-*.AppImage
```

### From tarball

```sh
tar xzf ClotCAD-*.tar.gz
cd ClotCAD-*
./run.sh
```

Connect from Emacs: `M-x sly-connect` (port 4005).

## Architecture

```
Main Thread (Qt)               Worker Thread (Slynk)
┌─────────────────────────┐    ┌──────────────────────┐
│ QApplication::exec()    │    │ Slynk :port 4005     │
│                         │    │   └─ SLY eval        │
│   ViewerWindow          │    │   └─ SLIME eval      │
│     Menu Bar            │    │                      │
│       File→Import/Export│    │ Qt REPL eval:        │
│       View→Axis/Grid/.. │    │   eval_string cb     │
│                         │    │   → loop over forms   │
│     ViewerWidget        │    │   → snprintf result  │
│       paintGL()         │◀───│ display() → push q   │
│         OCCT redraw     │    │ → postEvent()        │
│         FlushViewEvents │    │ → WakeReceiver       │
│     SceneTreePanel      │    │ → drain_queue()      │
│     REPLPanel           │    │ → update() → paintGL │
│       eval callback ────│───→│                      │
│     Status Bar          │    │  Lisp modules:       │
│                         │    │   ui.lisp — state    │
│ Lisp modules:           │    │   render.lisp—redraw │
│   ui.lisp    — state    │    │   queue.lisp—dispatch│
│   render.lisp— redraw   │    │   repl.lisp—callbacks│
│   queue.lisp — dispatch │    │                      │
│   repl.lisp  — callbacks│    │   select.lisp—sel stt│
│   select.lisp— selection│    │                      │
│  Menu actions wire:     │    │  Menu actions wire:  │
│                         │    │  File→file_op_cb     │
│                         │    │  View→show_axis/grid │
│                         │    │       /viewcube      │
│  ViewCube:              │    │  set-view / current  │
│  onAnimationFinished    │    │  → %viewer-set-view  │
│  → viewcube_cb          │    │                      │
└─────────────────────────┘    └──────────────────────┘
```

Alive LSP runs on a third worker thread on port 4006, following the same pattern as Slynk but speaking the LSP protocol instead of the Slynk protocol.

## Files

```
wrap/
├── occt_viewer.h/.cpp      C API (~25 extern "C" functions)
├── viewer_widget.h/.cpp     QOpenGLWidget + AIS_ViewController
├── viewer_window.h/.cpp     QMainWindow (menus, panels, status bar)
├── repl_panel.h/.cpp        Qt REPL dock widget
├── scene_tree_panel.h/.cpp  Scene tree dock widget
├── OcctQtTools.h/.cpp       Qt↔OCCT glue helpers
└── OcctGlTools.h/.cpp       GL context/FBO wrapping

src/viewer/
├── package.lisp             Package exports (clotcad, clotcad-user)
├── bindings.lisp            CFFI bindings
├── queue.lisp               Event queue + full-state sync
├── ops.lisp                 def, show, hide, toggle, resolve-shape, wrappers
├── select.lisp              *selected*, select, deselect, clear-selection
├── repl.lisp                Drain callback registration
├── ui.lisp                  Viewer state management
├── render.lisp              Periodic redraw loop
└── lifecycle.lisp           start-viewer, stop-viewer

lib/cl-occt/
└── cl-occt (git submodule)  Lisp OCCT bindings (incl. AIS/V3d)
```

## Prerequisites

- Qt6 (Widgets + OpenGLWidgets) — `apt install qt6-base-dev libqt6opengl6-dev`
- OCCT 8.0.0
- SBCL + Quicklisp
- cl-occt (included as git submodule at `lib/cl-occt/`)
- alive-lsp (auto-cloned to `lib/alive-lsp/` by `just alive-lsp`)
- CMake ≥ 3.16

## Build OCCT + cl-occt (one-time)

```sh
just setup
```

This downloads OCCT 8.0.0 source, configures with CMake (Release, Shared libraries, Visualization + DataExchange modules), builds, installs to `.local/`, then initializes the cl-occt submodule and builds its C wrapper library. Takes ~10-15 minutes.

If you cloned without `--recursive`:

```sh
git submodule update --init lib/cl-occt
just setup
```

To configure OCCT manually:

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
just viewer        # cmake build → lib/libclotcad.so
```

Or manually:

```sh
cmake -S . -B build
cmake --build build
cp build/libclotcad.so lib/
```

## Tests

Run the Lisp unit test suite (no display required):

```sh
just test
```

Tests cover queue operations, display/undisplay/clear, UI state management
(grid/axis visibility toggles), callback registration, multi-form REPL
evaluation, Lisp file import (tick processing, cancellation, error recovery),
REPL history export (clean and debug modes), and the full set of operations:
`def`, `show`, `hide`, `toggle`, `show-defs`, `toggle-defs`, `resolve-shape`,
selection (`select`, `deselect`, `clear-selection`), and all wrapper functions.
CFFI functions are mocked via `with-mocked-viewer`.

To run from a Lisp REPL:

```lisp
(asdf:load-system :clotcad/tests)
(in-package :clotcad)
(run-tests)
```
