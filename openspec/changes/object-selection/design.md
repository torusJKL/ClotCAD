## Context

The viewer (built in the `qt-viewer` change) has no object selection. The 3D viewport only handles camera orbit/pan/zoom. The scene tree only toggles shape visibility. The REPL has no selection commands. OCCT's `AIS_InteractiveContext` and `AIS_ViewController` provide full selection infrastructure (hit-testing, highlighting, multi-select with modifiers), but nothing is wired — no shape has its selection mode activated, no callbacks exist, no selection state is tracked.

Meanwhile, the `cl-occt` submodule now has complete selection bindings (iteration, set/clear, detection, highlighting) via commit `564b8ae`. The design must bridge between the viewer's C++ shape management and cl-occt's selection API, with Lisp as the authoritative selection state owner.

## Goals / Non-Goals

**Goals:**
- Lisp `*selected*` is the single source of truth for which shapes are selected
- Three synchronized selection paths: REPL (`select`), Scene Tree (click), 3D View (click)
- ReplaceExtra mouse scheme: click replaces, Ctrl+click adds, Shift+click toggles
- Scene tree supports multi-select with Ctrl/Shift modifiers (Qt ExtendedSelection)
- Mouse selection scheme configurable from Lisp at runtime
- Selection callbacks fire from C++ to Lisp on all selection changes
- `cl-occt` selection API is used for all OCCT context calls (no duplication in viewer wrapper)
- Unit tests for selection with mocked viewer

**Non-Goals:**
- Sub-shape selection (faces, edges, vertices) — deferred
- Selection filters or custom highlighting styles
- Rubber-band/rectangle selection — deferred
- Drag-to-select or selection box in 3D view
- Persistent selection across viewer restarts

## Decisions

### 1. Threading: Lisp `*selected*` updated immediately on worker thread, OCCT sync deferred to main thread

**Decision:** When `(select ...)` is called from the REPL (worker thread), `*selected*` is updated immediately. A `:sync-selection` queue message is pushed. The drain handler on the main thread reads `*selected*` and calls cl-occt's `ais-clear-selected` + `ais-set-selected` + `ais-hilight-selected` to sync OCCT context.

**Rationale:** Lisp must be the source of truth. Updating `*selected*` immediately means subsequent REPL commands see the correct state without waiting for a round-trip. The OCCT context is only manipulated from the main thread (where it's safe), and the queue pattern matches the existing shape management design.

### 2. Direct OCCT calls from main-thread callbacks (no queue needed)

**Decision:** The scene tree selection callback (`%on-tree-selection`) and the 3D view selection callback (`%on-selection-changed`) both run on the main thread and call cl-occt's selection API directly — no queue round-trip.

**Rationale:** Both callbacks fire from Qt event handlers on the main thread, which IS the thread owning the OCCT context. Direct calls avoid unnecessary queue delay. The `OnSelectionChanged` callback includes a `blockSignals` guard on the tree to prevent re-entrancy.

### 3. C API bridge: `viewer_get_context` + `viewer_get_ais_object`

**Decision:** Two bridge functions expose the viewer's internal OCCT handles to Lisp's cl-occt API:

- `viewer_get_context` returns the `Handle(AIS_InteractiveContext)*` for use with `ais-clear-selected`, `ais-set-selected`, etc.
- `viewer_get_ais_object(name)` returns the `Handle(AIS_InteractiveObject)*` for a named shape (from the viewer's `shapes` map), for use with `ais-set-selected`, `ais-is-selected`, etc.

**Rationale:** Avoids duplicating any OCCT selection binding in the viewer wrapper. All selection logic uses cl-occt's existing API. The two bridge functions are thin (one pointer return, one map lookup).

### 4. C++ `OnSelectionChanged` handles tree sync before Lisp callback

**Decision:** The `ViewerWidget::OnSelectionChanged` override:
1. Reads OCCT context's current selection
2. Looks up names via `ViewerState::obj_to_name` reverse map
3. Calls `SceneTreePanel::syncSelection()` to update tree item highlights (with `blockSignals`)
4. Fires the Lisp `selection_callback`

**Rationale:** Ensures the scene tree is always consistent before Lisp processes the change. `blockSignals` prevents the tree's `itemSelectionChanged` signal from firing during programmatic updates, avoiding the C++ → OCCT → `OnSelectionChanged` loop.

### 5. ViewerState reverse map: `Standard_Transient* → string`

**Decision:** A `std::map<Standard_Transient*, std::string>` in `ViewerState` maps each `AIS_Shape`'s raw pointer to its name. Populated when shapes are created/destroyed in `viewer_sync_shapes`.

**Rationale:** When OCCT reports selection via `SelectedInteractive()`, we need to map back to the shape name. The `Handle`'s `get()` method returns the raw `Standard_Transient*` which is a stable identity pointer for the lifetime of the AIS object.

### 6. Mouse scheme config via `ViewerState::mouse_schemes` map

**Decision:** A `std::map<unsigned int, int>` in `ViewerState` stores the selection scheme per (mouse button + modifiers) key. Lisp pushes entries via `viewer_set_mouse_selection_scheme`. `UpdateMouseClick` reads from this map.

**Rationale:** Puts configuration authority in Lisp. The C++ side is a passive cache — no hard-coded scheme logic.

### 7. `sync-selection-to-occt` as a shared Lisp helper

**Decision:** A Lisp function `sync-selection-to-occt` encapsulates the OCCT sync logic (clear, set each selected shape, hilight). Called from:
- Queue drain handler for `:sync-selection` (REPL path)
- Tree selection callback (scene tree path, direct on main thread)

**Rationale:** Single code path for OCCT sync. Avoids duplicating the clear/set/hilight sequence.

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| `OnSelectionChanged` fires during `paintGL` (render is in progress) | Lisp callback blocks rendering | Callback is lightweight (iterate displayed models + `ais-is-selected`). If performance becomes an issue, defer via `QMetaObject::invokeMethod` with `Qt::QueuedConnection`. |
| `OnSelectionChanged` re-enters tree selection → OCCT → `OnSelectionChanged` loop | Infinite loop | `SceneTreePanel::syncSelection` uses `blockSignals(true)`. Programmatic OCCT calls from tree callback also suppress. Loop is impossible. |
| `ais-is-selected` called from `OnSelectionChanged` during rendering | Read-after-write race | OCCT's selection set is fully updated before `OnSelectionChanged` fires. Reads are safe. |
| Reverse map pointer (`Standard_Transient*`) becomes dangling | Crash on name lookup | Map entries are removed in the same `viewer_sync_shapes` pass that removes shapes from the `shapes` map. Both use the same lifecycle. |
| cl-occt CFFI calls from main thread (drain handler) interfere with rendering | GL context state corruption | CFFI calls to cl-occt's selection API don't touch OpenGL state — they operate on `AIS_InteractiveContext` data structures only. Rendering is unaffected. |
