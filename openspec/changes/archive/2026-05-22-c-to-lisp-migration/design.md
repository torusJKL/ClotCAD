## Context

The viewer was built with substantial state management in C++
(ViewerState struct in occt_viewer.cpp) because cl-occt had no
visualization bindings at the time. All OCCT rendering calls
(AIS_Shape creation, AIS_InteractiveContext Display/Erase, V3d_View
FitAll, V3d_Viewer ActivateGrid, AIS_Trihedron) were made from
C++ because Lisp had no way to call them.

cl-occt now provides full AIS/V3d bindings (viewer.lisp, bindings.lisp)
with CLOS wrapper classes for viewer, ais-context, ais-object, plus
trihedron creation, grid control, MSAA/antialiasing, styling, and
camera control.

Constraint: cl-occt has no v3d_view_set_window() binding, so
Lisp-created viewers cannot render into the Qt widget. The ViewerWidget
must keep creating its own V3d_Viewer/V3d_View/AIS_InteractiveContext
for the rendering surface.

What CAN move is all state ownership and application logic. The existing
C API becomes thin OCCT wrappers. Where cl-occt already wraps a pure OCCT
operation (no Qt involvement), those calls are made directly from Lisp
instead of through our viewer's C API. Only minimal getter functions
(viewer_get_view, viewer_get_trihedron) are added to bridge C++-owned
handles to Lisp.

## Goals / Non-Goals

**Goals:**
- Eliminate all state duplication between C++ and Lisp
- All viewer configuration (axis, grid, MSAA, lights) done from Lisp
- Qt REPL panel kept as thin UI shell; eval logic stays in Lisp
- File/View menus kept as thin UI shell; all state managed from Lisp
- C++ occt_viewer.cpp reduced to thin OCCT wrappers + event dispatch
- All changes work with existing C API (with a small number of new
  bindings: viewer_show_dock, viewer_is_axis_visible,
  viewer_is_grid_visible)
- All changes are runtime-REPL-inspectable

**Non-Goals:**
- Replace QTreeWidget (scene tree) with Lisp widget
- Add dynamic menu creation from Lisp (requires new C function)
- Replace Qt file dialogs with Lisp equivalents
- Make the Lisp-created viewer render into the Qt widget

## Decisions

### 1. C++ shape map kept as transient cache

**Decision:** A minimal std::map<std::string, Handle(AIS_Shape)> stays
in C++ so that name-based operations (viewer_remove_shape,
viewer_set_shape_visible) can look up the AIS_Shape handle. The map
is no longer authoritative — *displayed-models* is the source of truth.

**Rationale:** name-based lookup requires the C++ side to remember
which TopoDS_Shape maps to which AIS_Shape handle. Eliminating this
would require changing the C API to pass handles instead of names,
which is a new binding. The map is ~5 lines of code and is a pure
rendering cache with no logic attached.

**Alternatives considered:**
- Eliminate the map entirely — would require Lisp to pass
  Handle(AIS_Shape)* pointers through the C API. New binding.
- Keep the full ViewerState — defeats the purpose of the migration.

### 2. Trihedron/grid setup deferred to Lisp

**Decision:** ViewerWidget::initializeGL no longer creates the
trihedron or activates the grid. Lisp calls %viewer-show-axis,
%viewer-show-grid, %viewer-set-antialiasing after %viewer-show.

**Rationale:** These are pure OCCT calls that the existing C API
wraps. Moving them to Lisp removes ~30 lines from viewer_widget.cpp
and makes every setting REPL-changeable.

### 3. Qt REPL kept as thin UI widget

**Decision:** REPLPanel (repl_panel.h/.cpp) is kept as a Qt dock widget.
Eval logic stays in Lisp — the C++ widget calls a Lisp callback via
eval_fn, and Lisp pushes output back via viewer_append_repl_output
(thread-safe via Qt::QueuedConnection).

**Rationale:** The in-window Qt REPL provides immediate feedback for
quick Lisp expressions without requiring an external SLIME connection.
Both the Qt REPL and Swank on port 4005 coexist — users can use either.
The callback mechanism is synchronous on the Qt thread, which is
acceptable for short expressions; blocking operations should use SLIME.

**C API additions:**
- eval_fn typedef (restored)
- viewer_set_eval_callback (restored, propagates to REPLPanel)
- viewer_append_repl_output (restored)

### 4. Viewer_run timer removed

**Decision:** viewer_run no longer creates a QTimer for FPS and shape
count. Periodic redraw is triggered from Lisp via a timer.

**Rationale:** The timer duplicated state (reading shapes.size() for
shape count) and was tied to modal guards. Moving it to Lisp gives
control over update frequency and content.

### 5. Modal guard removed (menus restored safely)

**Decision:** myProcessingModal and processing_modal flags kept removed.
The paintGL guard that skipped rendering during dialogs stays removed.

**Rationale:** Although File menu actions are restored, the C++ render
timer was removed (replaced by Lisp's render.lisp running on the
worker thread). File dialog modal loops on the Qt thread no longer race
with a C++ timer callback, so the guard is unnecessary.

### 6. Pure OCCT operations delegated to cl-occt

**Decision:** Pure OCCT operations (no Qt/widget involvement) use
cl-occt's CFFI bindings directly from Lisp, rather than going through
our viewer's C API wrapper. Affected operations:
- **Viewport background color**: `v3d_view_set_bg_color` (cl-occt)
  replaces `viewer_set_background_color` (removed)
- **Trihedron axis colors**: `ais_trihedron_set_datum_part_color`
  (cl-occt) replaces `viewer_set_axis_color` (removed)
- **Status bar text**: `viewer_set_status_text` (new minimal setter)
  replaces `updateShapeCount` logic (moved to Lisp `update-shape-count`)

**Rationale:** The old approach duplicated OCCT wrapping code — our
viewer's C API replicated what cl-occt already provides. Removing the
duplicate C functions and calling cl-occt directly eliminates the
middle layer, reduces the viewer C API surface, and removes OCCT header
dependencies (`Quantity_Color.hxx`, `Prs3d_DatumParts.hxx`) from the
viewer's C++.

**C API additions:**
- `viewer_get_view` — returns V3d_View* for use with cl-occt view functions
- `viewer_get_trihedron` — returns AIS_Trihedron* for use with cl-occt
  trihedron functions

**C API removals:**
- `viewer_set_background_color` — replaced by cl-occt
- `viewer_set_axis_color` — replaced by cl-occt

**Implementation notes:**
- cl-occt functions use double floats (0.0–1.0); Lisp converts hex
  colors via `(/ r 255.0)` at the call site
- `update-shape-count` in ui.lisp formats the status bar text using
  Lisp string logic (singular/plural, hidden count) and pushes it
  through `%viewer-set-status-text`
- Shape visibility changes from the scene tree fire a CFFI callback
  into Lisp, which re-queries counts and updates the status bar

## Architecture

### Before (simplified)

```
viewer_create()
  → ViewerState { shapes, names, grid_bool, axis_bool,
                  eval_cb, file_cb, drain_cb, mutex, queue,
                  timer, modal_flag }
  → ViewerWindow → setupMenus(), setupPanels(), setupStatusBar()
  → Wire all menu actions with lambdas

viewer_put_shape()
  → new AIS_Shape, context->Display()
  → shapes[name] = ais_shape, shape_names.push(name)
  → scene_tree->addShape(name)

viewer_remove_shape()
  → context->Remove(shapes[name])
  → shapes.erase(name), shape_names.erase(...)
  → scene_tree->removeShape(name)

viewer_run()
  → Start QTimer (FPS + shape count + redraw)
  → QApplication::exec()

ViewerWidget::initializeGL()
  → Create GraphicDriver, V3d_Viewer, V3d_View, AIS_Context
  → setupAxis(), setupGrid()

drain-queue()
  → %viewer-put-shape → C++ stores in shapes[]
  → *displayed-models*[name] = shape   ← DUPLICATE
```

### After (simplified)

```
viewer_create()
  → ViewerState { window, widget, context,
                  eval_cb, file_cb, drain_cb, vis_cb, shapes (cache),
                  shape_names, name_cache, running }
  → ViewerWindow → setupMenus(), setupPanels(), setupStatusBar()
  → Wire File menu → QFileDialog → file_op_callback
  → Wire View menu → viewer_show_axis/grid
  → Wire scene tree visibility → viewer_set_shape_visible (fires vis_cb)
  → Wire drain callback

viewer_put_shape()
  → new AIS_Shape, context->Display(), view->FitAll()
  → shapes[name] = ais_shape   (transient cache)
  → scene_tree->addShape(name)

viewer_remove_shape()
  → context->Remove(shapes[name])
  → scene_tree->removeShape(name)

viewer_run()
  → QApplication::exec() only

ViewerWidget::initializeGL()
  → Create GraphicDriver, V3d_Viewer, V3d_View, AIS_Context
  → (no setupAxis, no setupGrid)

initialize-viewer()  (Lisp, after viewer-show)
  → (%viewer-show-grid vwr 1)
  → (%viewer-show-axis vwr 1)
  → (%viewer-set-antialiasing vwr 1)
  → (apply-theme *theme-mode*)     ← pushes QSS + OCCT viewport/axis colors

apply-theme()  (Lisp)
  → %viewer-set-stylesheet          ← QSS
  → cl-occt:%v3d-view-set-bg-color ← viewport background (via viewer_get_view)
  → cl-occt:%ais-trihedron-set-datum-part-color ← axis colors (via viewer_get_trihedron)
  → %viewer-set-placeholder-color   ← placeholder text

update-shape-count()  (Lisp, after queue drain + visibility callback)
  → %viewer-get-shape-count
  → %viewer-get-visible-shape-count
  → format status text with Lisp string logic
  → %viewer-set-status-text

drain-queue()
  → %viewer-put-shape → C++ displays + caches + tree
  → *displayed-models*[name] = shape  ← SINGLE source of truth
  → update-shape-count()              ← Lisp updates status bar
```

## Communication Flows

### Shape display (Lisp worker → Qt main thread)
```
display(name, shape)
  → queue-push (:display name shape)
  → %viewer-post-event

WakeEvent received
  → drain-queue()
    → %viewer-put-shape (C++ displays + caches)
    → *displayed-models*[name] = shape  (Lisp)
```

### Viewer configuration (Lisp → Qt main thread)
```
initialize-viewer()  (called from same thread as viewer_create)
  → %viewer-show-grid *viewer* 1         ← C function, synchronous
  → %viewer-show-axis *viewer* 1         ← C function, synchronous
  → %viewer-set-antialiasing *viewer* 1  ← C function, synchronous
  → (apply-theme *theme-mode*)           ← QSS + OCCT colors from Lisp

apply-theme()  (Lisp → cl-occt → OCCT)
  → %viewer-set-stylesheet               ← Qt QSS
  → viewer_get_view → %v3d-view-set-bg-color  ← cl-occt, viewport bg
  → viewer_get_trihedron → %ais-trihedron-set-datum-part-color ← cl-occt, axes
  → %viewer-set-placeholder-color        ← Qt palette
```

### Shape visibility change (scene tree → Lisp → status bar)
```
Scene tree checkbox → viewer_set_shape_visible
  → OCCT Display/Erase
  → visibility_callback(name, visible) → Lisp %on-shape-visibility
    → update-shape-count()
      → %viewer-get-shape-count, %viewer-get-visible-shape-count
      → format string (singular/plural, hidden count)
      → %viewer-set-status-text
```

### File operation (C++ menu → native dialog → Lisp)
```
Menu → C++ lambda → QFileDialog → file_op_callback → Lisp handler

Or from Lisp REPL directly:
  (display "part" (read-step "path.step"))
  (export-all-step "export.step")
```

## File Structure Changes

```
Before:                              After:
wrap/                                wrap/
├── occt_viewer.h   (62 lines)       ├── occt_viewer.h   (~75 lines)
├── occt_viewer.cpp (562 lines)      ├── occt_viewer.cpp (~560 lines)
├── viewer_window.h  (58 lines)      ├── viewer_window.h  (~67 lines)
├── viewer_window.cpp(105 lines)     ├── viewer_window.cpp(~85 lines)
├── viewer_widget.h  (59 lines)      ├── viewer_widget.h  (~50 lines)
├── viewer_widget.cpp(187 lines)     ├── viewer_widget.cpp(~150 lines)
├── repl_panel.h     (43 lines)      repl_panel.h        (same)
├── repl_panel.cpp   (100 lines)     repl_panel.cpp      (same)
├── scene_tree_panel.h(39 lines)     scene_tree_panel.h  (same)
├── scene_tree_panel.cpp(51 lines)   scene_tree_panel.cpp(same)
├── OcctQtTools.h    (36 lines)      OcctQtTools.h        (same)
├── OcctQtTools.cpp  (139 lines)     OcctQtTools.cpp      (same)
├── OcctGlTools.h    (45 lines)      OcctGlTools.h        (same)
└── OcctGlTools.cpp  (87 lines)      OcctGlTools.cpp      (same)

src/viewer/                          src/viewer/
├── package.lisp   (65 lines)        ├── package.lisp    (~92 lines)
├── bindings.lisp (105 lines)        ├── bindings.lisp   (~112 lines)
├── lifecycle.lisp (23 lines)        ├── lifecycle.lisp  (~30 lines)
├── queue.lisp     (76 lines)        ├── queue.lisp      (~76 lines)
├── repl.lisp      (98 lines)        ├── repl.lisp       (~100 lines)
├── theme.lisp     —                 ├── theme.lisp       NEW(~430 lines)
├── t/             (tests)           ├── ui.lisp          (~55 lines)
                                     ├── render.lisp      (~30 lines)
                                     └── t/              (~728 lines)
```

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| Qt REPL eval blocks Qt thread | Short eval blocks UI briefly | Keep expressions short in Qt REPL; use SLIME for complex work |
| Scene tree not updatable from Lisp | Tree can only be populated via C API (existing) | Keep current C API for tree updates; acceptable cost |
| No dynamic menu creation | Menu actions hardcoded in C++ | Add viewer_add_menu_item C function post-MVP if needed |
| File dialog from C++ menu could race render | Modal loop on Qt thread | Render timer moved to Lisp worker thread; no race |
| C++ shape map still exists | Minor duplication kept | Kept only as rendering cache (name→AIS_Shape lookup); no logic copies |
| Tests reference removed functions | Some tests removed during migration, then restored | Current test suite covers both old and new functionality |
