> **REVISION NOTE:** Tasks 4, 5, 9, 10, 11, and 12 were initially completed
> to remove the Qt REPL panel, strip menus, and clean up the C API. These
> decisions were later REVERSED — the Qt REPL panel, File/View menus, and
> their associated C API functions were restored. The task checklist below
> marks the original removal work as `[x]` and the subsequent restoration
> as `[r]` (restored). The important architectural changes (state ownership
> moved to Lisp, render loop in Lisp, no modal guard, axis/grid from Lisp,
> queue simplification, ui.lisp/render.lisp modules) remain in effect.

## 1. State ownership — strip ViewerState

- [x] 1.1 Remove shape_names vector, grid_visible, axis_visible, eval_callback,
        queue_mutex, pending_actions, processing_modal, timer, name_cache
        from ViewerState struct
- [x] 1.2 Keep: window, widget, context, shapes map (as cache), file_op_callback,
        drain_callback, running
- [x] 1.3 Strip viewer_put_shape: remove scene tree update (findChildren);
        keep AIS_Shape creation, Display, cache in map, FitAll
- [x] 1.4 Strip viewer_remove_shape: remove scene tree update;
        keep context->Remove, cache erase
- [x] 1.5 Strip viewer_clear: remove scene tree update;
        keep context->RemoveAll, cache clear
- [x] 1.6 Remove viewer_get_shape_count / viewer_get_shape_name
        (Lisp tracks this in *displayed-models*)
- [x] 1.7 Remove viewer_is_shape_visible / viewer_set_shape_visible
        (Lisp manages visibility via display/erase)
- [x] 1.8 Remove viewer_is_grid_visible / viewer_is_axis_visible
        (Lisp tracks booleans)
- [x] 1.9 Verify: shape display/erase/clear still works after stripping

## 2. Viewer configuration — move to Lisp

- [x] 2.1 Remove setupAxis() from viewer_widget.cpp and .h
- [x] 2.2 Remove setupGrid() from viewer_widget.cpp and .h
- [x] 2.3 Remove myFirstInit guard from initializeGL()
- [x] 2.4 Remove myAxis field from viewer_widget.h
- [x] 2.5 Add initialize-viewer function in lifecycle.lisp that calls:
        (%viewer-show-axis vwr 1), (%viewer-show-grid vwr 1),
        (%viewer-set-antialiasing vwr 1)
- [x] 2.6 Call initialize-viewer from start-viewer after %viewer-show
        and before %viewer-run
- [x] 2.7 Verify: trihedron and grid appear after viewer start

## 3. Render loop — move to Lisp

- [x] 3.1 Remove QTimer creation from viewer_run()
- [x] 3.2 viewer_run becomes just: running=true, theApp->exec(), running=false
- [x] 3.3 Remove QDateTime FPS calculation from occt_viewer.cpp
- [x] 3.4 Remove updateShapeCount / updateFps from viewer_window
        (or keep as no-ops)
- [x] 3.5 Create render.lisp with a periodic redraw timer
- [x] 3.6 Wire render timer to call %viewer-redraw at ~10fps
- [x] 3.7 Verify: viewer renders and updates without the C++ timer

## 4. REPL removal — delete Qt REPL panel [REVERSED]

- [x] 4.1 Delete wrap/repl_panel.h → [r] restored
- [x] 4.2 Delete wrap/repl_panel.cpp → [r] restored
- [x] 4.3 Remove repl_panel.cpp from CMakeLists.txt SOURCES → [r] restored
- [x] 4.4 Remove %viewer-set-eval-callback and %viewer-append-repl-output
         from src/viewer/bindings.lisp → [r] restored
- [x] 4.5 Remove eval_fn callback from occt_viewer.h → [r] restored
- [x] 4.6 Remove viewer_set_eval_callback from occt_viewer.cpp → [r] restored
- [x] 4.7 Remove viewer_append_repl_output from occt_viewer.cpp → [r] restored
- [x] 4.8 Remove myRepl, myReplAction from viewer_window.h/.cpp → [r] restored
- [x] 4.9 Remove REPLPanel references from viewer_window.cpp → [r] restored
- [x] 4.10 Remove eval_string callback from src/viewer/repl.lisp → [r] restored
- [x] 4.11 Remove %viewer-set-eval-callback, %viewer-append-repl-output
          exports from package.lisp → [r] restored
- [x] 4.12 Remove *repl-accumulator*, *repl-eof-sentinel* from
          src/viewer/repl.lisp and package.lisp → [r] restored
- [x] 4.13 Simplify register-viewer-callbacks (only file_op + drain now)
          → [r] restored to full (eval + file_op + drain)
- [x] 4.14 Verify: viewer starts without REPL panel → [r] REPL panel
          restored; viewer starts with REPL panel visible

## 5. UI streamline — simplify menus and status [REVERSED]

- [x] 5.1 Strip setupMenus(): remove File/View menus → [r] restored with
         File (Import/Export STEP/STL) and View (REPL, Scene Tree, Axis,
         Grid toggle) menus
- [x] 5.2 Remove menu wiring lambdas from viewer_create() → [r] restored:
         File menu → QFileDialog → file_op_callback; View → axis/grid
- [x] 5.3 Remove scene tree signal connection → [r] restored (visibility
         change → viewer_set_shape_visible)
- [x] 5.4 Keep SceneTreePanel without File menu → [r] REPLPanel also
         restored on the right side
- [x] 5.5 Remove eventFilter from viewer_window → [r] restored (dock
         show/hide sync with menu actions)
- [x] 5.6 Strip updateShapeCount/updateFps → kept as callable methods;
         no automatic timer updates (unchanged)
- [x] 5.7 Remove viewer_notify_shape_change → [r] restored (calls redraw)
- [x] 5.8 Verify: viewer starts with minimal UI → [r] viewer starts with
         full UI: menu bar, REPL panel, scene tree, 3D view, status bar

## 6. queue.lisp simplification

- [x] 6.1 Remove :update case from drain-queue
        (no more C++ map to update on DAG propagation)
- [x] 6.2 Remove name_cache from ViewerState (no more viewer_get_shape_name)
- [x] 6.3 Simplify viewer-refresh: only push :display or :remove,
        never :update
- [x] 6.4 Verify: DAG propagation still updates the view

## 7. ui.lisp — new viewer state module

- [x] 7.1 Create src/viewer/ui.lisp with:
        *grid-visible*, *axis-visible* globals
        show-grid, show-axis, toggle-grid, toggle-axis functions
        set-antialiasing wrapper
        fit-all wrapper
- [x] 7.2 Export symbols from package.lisp
- [x] 7.3 Verify: (show-axis nil) at REPL hides axis

## 8. render.lisp — new render loop module

- [x] 8.1 Create src/viewer/render.lisp with:
        *render-timer* — periodic redraw timer
        start-render-loop, stop-render-loop
        simple FPS counter in Lisp (optional)
- [x] 8.2 Integrate with lifecycle: start loop after viewer-show,
        stop on viewer-quit
- [x] 8.3 Verify: viewer redraws without C++ timer

## 9. Clean up occt_viewer.h C API [PARTIALLY REVERSED]

- [x] 9.1 Remove eval_fn typedef → [r] restored
- [x] 9.2 Remove viewer_set_eval_callback declaration → [r] restored
- [x] 9.3 Remove viewer_append_repl_output declaration → [r] restored
- [x] 9.4 Remove viewer_get_shape_count declaration → [r] restored
- [x] 9.5 Remove viewer_get_shape_name declaration → [r] restored
- [x] 9.6 Remove viewer_set_shape_visible declaration → [r] restored
- [x] 9.7 Remove viewer_is_shape_visible declaration → [r] restored
- [x] 9.8 Remove viewer_notify_shape_change declaration → [r] restored
- [x] 9.9 Remove viewer_is_grid_visible declaration → [r] restored
- [x] 9.10 Remove viewer_is_axis_visible declaration → [r] restored
- [x] 9.11 Verify: occt_viewer.h exports ~20 functions (down from 30)
          → now ~25 functions (restored + new: viewer_show_dock,
          viewer_is_grid_visible, viewer_is_axis_visible)

## 10. Update Lisp bindings to match [PARTIALLY REVERSED]

- [x] 10.1 Remove %viewer-set-eval-callback from bindings.lisp → [r] restored
- [x] 10.2 Remove %viewer-append-repl-output from bindings.lisp → [r] restored
- [x] 10.3 Remove %viewer-get-shape-count from bindings.lisp → [r] restored
- [x] 10.4 Remove %viewer-get-shape-name from bindings.lisp → [r] restored
- [x] 10.5 Remove %viewer-set-shape-visible from bindings.lisp → [r] restored
- [x] 10.6 Remove %viewer-is-shape-visible from bindings.lisp → [r] restored
- [x] 10.7 Remove %viewer-notify-shape-change from bindings.lisp → [r] restored
- [x] 10.8 Remove %viewer-is-grid-visible from bindings.lisp → [r] restored
- [x] 10.9 Remove %viewer-is-axis-visible from bindings.lisp → [r] restored
- [x] 10.10 Update package.lisp exports to match → [r] restored + added
          %viewer-show-dock export
- [x] 10.11 Verify: all Lisp functions resolve correctly

## 11. Update tests [PARTIALLY REVERSED]

### Restore tests that were removed

- [x] 11.1 Remove repl-accumulator-starts-empty test → [r] restored
- [x] 11.2 Remove repl-eof-sentinel-is-gensym test → [r] restored
- [x] 11.3 Remove incomplete-form-signals-error test → [r] restored
- [x] 11.4 Remove complete-form-reads-correctly test → [r] restored
- [x] 11.5 Remove read-empty-string-returns-eof test → [r] restored
- [x] 11.6 Remove file-op-dispatch-import-step test → [r] restored
- [x] 11.7 Remove file-op-dispatch-export-step test → [r] restored
- [x] 11.8 Remove file-op-dispatch-export-stl test → [r] restored
- [x] 11.9 Remove file-op-dispatch-import-stl test → [r] restored
- [x] 11.10 Remove register-viewer-callbacks-sets-viewer test → [r] restored
          and updated to check eval + file-op + drain callbacks
- [x] 11.11 Remove *repl-accumulator* / *repl-eof-sentinel* let-bindings
          → [r] restored in run-tests

### Keep existing migration tests

- [x] 11.12 Update drain-queue tests
- [x] 11.13 Verify export-all-step-warns-on-empty still works
- [x] 11.14 Verify export-all-stl-warns-on-empty still works
- [x] 11.15 Test show-grid / show-axis / toggle-grid / toggle-axis (mocked)
- [x] 11.16 Test initialize-viewer calls the right %viewer-* functions
- [x] 11.17 Test *grid-visible* / *axis-visible* state tracking
- [x] 11.18 Test register-viewer-callbacks (updated for all three callbacks)
- [x] 11.19 Verify: (run-tests) passes with all changes (40 tests)
- [x] 11.20 Verify: end-to-end viewer + shape display still works

## 12. Update README and AGENTS.md [PARTIALLY REVERSED]

- [x] 12.1 Update README layout diagram → [r] REPL panel restored in ASCII art
- [x] 12.2 Update README Interface table → [r] REPL Panel and Menu Bar rows restored
- [x] 12.3 Update README Architecture diagram → [r] REPLPanel block restored; ui.lisp/render.lisp kept
- [x] 12.4 Update README Files list → [r] repl_panel.h/.cpp restored; ui.lisp, render.lisp kept
- [x] 12.5 Update README Usage section → [r] describes both in-window REPL and SLIME workflow
- [x] 12.6 Update README Export section → [r] describes both menu-based and REPL-driven export
- [x] 12.7 Update AGENTS.md Architecture section — mention ui.lisp, render.lisp state management (kept)
- [x] 12.8 Update AGENTS.md Testing section — document which CFFI functions are mocked (updated)

## 13. Delegate pure OCCT operations to cl-occt

- [x] 13.1 Add viewer_get_view / viewer_get_trihedron getter functions
        to occt_viewer.h/.cpp (returns V3d_View* and AIS_Trihedron*)
- [x] 13.2 Remove viewer_set_background_color from C API — Lisp calls
        cl-occt's %v3d-view-set-bg-color directly via viewer_get_view
- [x] 13.3 Remove viewer_set_axis_color from C API — Lisp calls cl-occt's
        %ais-trihedron-set-datum-part-color directly via viewer_get_trihedron
- [x] 13.4 Remove Quantity_Color.hxx and Prs3d_DatumParts.hxx includes
        from occt_viewer.cpp (no longer needed)
- [x] 13.5 Move status bar logic to Lisp — update-shape-count queries
        %viewer-get-shape-count and %viewer-get-visible-shape-count,
        formats the string, pushes via %viewer-set-status-text
- [x] 13.6 Add visibility callback — shape_visibility_callback in
        ViewerState fires when scene tree toggles shape visibility;
        Lisp's %on-shape-visibility handler calls update-shape-count
- [x] 13.7 Wire update-shape-count into drain-queue (after processing
        each batch) and register-shape-visibility-callback in
        register-viewer-callbacks
- [x] 13.8 Update tests — replace mocked %viewer-set-background-color
        and %viewer-set-axis-color with %viewer-get-view and
        %viewer-get-trihedron

## Task dependencies

```
1 (state ownership) ──→ 2 (viewer config)
1 ──→ 5 (UI streamline)
1 ──→ 9 (C API cleanup)
2 ──→ 8 (render loop)
3 (render timer) ──→ 5
4 (REPL removal) ──→ 5
5 ──→ 9
9 ──→ 10 (Lisp bindings)
6 (queue simplification) ──→ 10
7 (ui.lisp) ──→ 10
8 (render.lisp) ──→ 10
10 ──→ 11 (update tests)
11 ──→ 12 (README + AGENTS.md)

Parallel groups:
  [1, 4] — independent
  [2, 3, 6, 7, 8] — depend on 1
  [5] — depends on 1, 4
  [9] — depends on 1, 5
  [10] — depends on 9, 6, 7, 8
  [11] — depends on 10
  [12] — depends on 11
```
