## Why

The viewer currently has significant business logic and state management
in C++: shape storage, visibility tracking, menu wiring, file dialogs,
FPS timing, REPL panel, and axis/grid setup. This logic is duplicated
between C++ (ViewerState in occt_viewer.cpp) and Lisp (*displayed-models*
in queue.lisp). Every change to UI behavior requires editing C++ and
rebuilding the shared library.

cl-occt now has AIS/V3d visualization bindings. By moving state and
application logic to Common Lisp, everything becomes changeable at
runtime via the REPL — no rebuild needed. C++ becomes a thin rendering
shell.

## What Changes

- **BREAKING**: ViewerState struct stripped — shape storage, visibility
  booleans, callbacks, queue, timer, modal guard all removed from C++
- **BREAKING**: REPL dock widget removed entirely (Swank on port 4005)
- **BREAKING**: menu-bar stripped of File/View menus (Lisp drives via
  existing callbacks)
- **BREAKING**: setupAxis/setupGrid removed from ViewerWidget::initializeGL
  (Lisp configures after startup via existing C API)
- **BREAKING**: modal rendering guard (myProcessingModal) and file dialog
  lambdas removed from occt_viewer.cpp
- **BREAKING**: viewer_run no longer creates FPS timer — periodic redraw
  managed from Lisp
- **MODIFIED**: viewer_put_shape/viewer_remove_shape/viewer_clear become
  thin OCCT wrappers (no state storage)
- **MODIFIED**: viewer_show_grid/viewer_show_axis become thin OCCT
  wrappers (no boolean storage)
- **MODIFIED**: queue.lisp simplified — *displayed-models* becomes the
  single source of truth
- **NEW**: lifecycle.lisp calls initialize-viewer after viewer-show
- **NEW**: ui.lisp — Lisp-side viewer state management (grid/axis
  visibility booleans, helpers)
- **NEW**: render.lisp — Lisp-managed render loop callback
- **REMOVED**: repl_panel.h, repl_panel.cpp
- **REMOVED**: %viewer-set-eval-callback, %viewer-append-repl-output
  CFFI bindings
- **REMOVED**: eval_string callback from repl.lisp

## Capabilities

### Modified Capabilities

- `qt-viewer-core`: ViewerWidget stripped of setupAxis/setupGrid;
  ViewerState simplified; viewer_run stripped of timer

### New Capabilities

- `state-ownership`: *displayed-models* is the single source of truth
  for shape state; grid/axis visibility tracked in Lisp; C++ shape map
  kept as transient rendering cache only
- `viewer-config`: Viewer initialization (trihedron, grid, MSAA,
  antialiasing, background) done from Lisp after startup via existing
  C API
- `repl-removal`: Qt REPL dock widget deleted; Swank on port 4005 is
  the only REPL interface
- `ui-streamline`: Menu bar reduced to a lifecycle shell; scene tree
  panel kept (Qt widget); status bar labels kept but updated from Lisp

### Removed Capabilities

- `repl-panel`: Entire Qt REPL dock widget removed
- `file-io` (partial): In-C++ file dialog lambdas removed; file
  operations triggered via eval_callback from Lisp

## Impact

- **C++**: ~250 lines removed from occt_viewer.cpp, ~50 lines removed
  from viewer_widget, ~20 lines removed from viewer_window, ~100 lines
  removed (repl_panel.cpp/.h). Total ~420 lines removed from C++.
- **Lisp**: ~100 lines added (ui.lisp, render.lisp, initialize-viewer),
  ~20 lines removed (eval_string, %bindings), ~20 lines modified
  (queue.lisp simplification). Total ~60 lines net addition.
- **Tests**: ~10 tests removed (REPL-related), ~6 tests added
  (ui state, initialize-viewer, simplified register-viewer-callbacks)
- **Docs**: README.md layout diagram, interface table, architecture
  diagram, files list, usage, and export sections updated. AGENTS.md
  architecture and testing sections updated.
- **Build**: repl_panel.cpp removed from CMakeLists.txt SOURCES
