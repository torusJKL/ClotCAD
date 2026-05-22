## 1. Update cl-occt submodule

- [x] 1.1 Update `lib/cl-occt` submodule to commit `564b8ae1586dba09e3fed4d443424c6da7f513d7`
- [x] 1.2 Verify new selection API is available: `ais-clear-selected`, `ais-set-selected`, `ais-hilight-selected`, `ais-is-selected`, `ais-nb-selected`, `ais-selected-objects`, etc.
- [x] 1.3 Run `just test` to confirm no regressions from submodule update

## 2. C API: ViewerState and bridge functions

- [x] 2.1 Add `obj_to_name` reverse map (`std::map<Standard_Transient*, std::string>`) to `ViewerState`
- [x] 2.2 Add `selection_changed_fn selection_callback` and `tree_selection_fn tree_callback` fields to `ViewerState`
- [x] 2.3 Add `mouse_schemes` map (`std::map<unsigned int, int>`) to `ViewerState`
- [x] 2.4 Implement `viewer_get_context`: return `ViewerState::context` as `void*`
- [x] 2.5 Implement `viewer_get_ais_object`: look up name in `ViewerState::shapes`, return pointer to `Handle(AIS_Shape)` as `void*`
- [x] 2.6 Implement `viewer_set_selection_callback`: store function pointer in `ViewerState`
- [x] 2.7 Implement `viewer_set_tree_selection_callback`: store function pointer in `ViewerState`
- [x] 2.8 Implement `viewer_set_mouse_selection_scheme`: insert into `ViewerState::mouse_schemes` map
- [x] 2.9 Declare all five new functions in `occt_viewer.h`

## 3. C++: Activate selection on shape display

- [x] 3.1 In `viewer_sync_shapes`, after `context->Display(ais_shape, false)`, call `context->Activate(ais_shape, 0)`
- [x] 3.2 After creating/recreating a shape, populate `obj_to_name[ais_shape.get()] = item.name`
- [x] 3.3 When removing a shape, erase corresponding entry from `obj_to_name`

## 4. C++: ViewerWidget selection overrides

- [x] 4.1 Add `ViewerState* myViewerState` member to `ViewerWidget`
- [x] 4.2 Set `myViewerState` in `viewer_create` after widget creation
- [x] 4.3 Override `UpdateMouseClick`: read scheme from `ViewerState::mouse_schemes` keyed by `theButton | (theModifiers << 16)`, fall back to `Replace`, call `SelectInViewer`
- [x] 4.4 Override `OnSelectionChanged`: iterate OCCT context selection via `InitSelected`/`MoreSelected`/`NextSelected`/`SelectedInteractive`, build name set via `obj_to_name`, call `SceneTreePanel::syncSelection`, fire `selection_callback`

## 5. C++: SceneTreePanel multi-select wiring

- [x] 5.1 In `SceneTreePanel` constructor, set `myTree->setSelectionMode(QAbstractItemView::ExtendedSelection)`
- [x] 5.2 Connect `myTree->itemSelectionChanged` to new slot `onTreeSelectionChanged`
- [x] 5.3 Implement `syncSelection(const std::set<std::string>& selected)`: iterate tree items, call `item->setSelected(true/false)` with `blockSignals`
- [x] 5.4 Implement `onTreeSelectionChanged` slot: collect selected item names, build `const char**` array, fire `state->tree_callback(names, count)`
- [x] 5.5 Declare new methods in `SceneTreePanel` header

## 6. CFFI bindings

- [x] 6.1 Add `%viewer-get-context` defcfun in `bindings.lisp`
- [x] 6.2 Add `%viewer-get-ais-object` defcfun in `bindings.lisp`
- [x] 6.3 Add `%viewer-set-selection-callback` defcfun in `bindings.lisp`
- [x] 6.4 Add `%viewer-set-tree-selection-callback` defcfun in `bindings.lisp`
- [x] 6.5 Add `%viewer-set-mouse-selection-scheme` defcfun in `bindings.lisp`
- [x] 6.6 Export all five new `%` symbols from `cl-occt-viewer.impl`

## 7. Lisp: selection state and REPL commands

- [x] 7.1 Create `src/viewer/select.lisp` with `*selected*` hash table variable
- [x] 7.2 Implement `(select &rest designators)`: stringify, clrhash *selected*, set each, push `:sync-selection`
- [x] 7.3 Implement `(deselect &rest designators)`: remove from *selected*, push `:sync-selection`
- [x] 7.4 Implement `(clear-selection)`: clrhash *selected*, push `:sync-selection`
- [x] 7.5 Implement `(selected-shapes)`: return hash keys as a list
- [x] 7.6 Implement `sync-selection-to-occt`: get context, clear, set each from *selected*, hilight

## 8. Lisp: queue and drain handling

- [x] 8.1 Add `:sync-selection` case to `drain-queue` that calls `sync-selection-to-occt`
- [x] 8.2 Verify `queue-push` works with `:sync-selection` (no extra args needed)

## 9. Lisp: callback registration and handlers

- [x] 9.1 Implement `%on-selection-changed` callback: iterate `*displayed-models*`, call `ais-is-selected` for each, update `*selected*`
- [x] 9.2 Implement `%on-tree-selection` callback: build new `*selected*` from passed names, call `sync-selection-to-occt`
- [x] 9.3 Register both callbacks in `register-viewer-callbacks` in `repl.lisp`
- [x] 9.4 Implement `apply-selection-schemes` with keyword args, push schemes to C

## 10. Lisp: package exports

- [x] 10.1 Export `*selected*`, `select`, `deselect`, `clear-selection`, `selected-shapes`, `apply-selection-schemes` from `cl-occt-viewer`
- [x] 10.2 Export new `%` symbols from `cl-occt-viewer.impl`

## 11. Tests

- [x] 11.1 Add selection mocks to `with-mocked-viewer` for any new CFFI functions
- [x] 11.2 Test: `*selected*` is empty at start
- [x] 11.3 Test: `(select :a :b)` updates `*selected*` and pushes `:sync-selection`
- [x] 11.4 Test: `(select)` with no args clears selection
- [x] 11.5 Test: `(select :a)` replaces previous selection
- [x] 11.6 Test: `(deselect :a)` removes from `*selected*`
- [x] 11.7 Test: `(clear-selection)` empties `*selected*`
- [x] 11.8 Test: `(selected-shapes)` returns list of selected names
- [x] 11.9 Test: `sync-selection-to-occt` calls ais-clear-selected and ais-set-selected for each entry
- [x] 11.10 Test: `apply-selection-schemes` with no args pushes default scheme entries

## 12. Build and integration

- [x] 12.1 Rebuild the viewer library: `just viewer`
- [x] 12.2 Launch viewer: `just start`
- [x] 12.3 Verify: clicking a shape in 3D view selects and highlights it
- [x] 12.4 Verify: Ctrl+click adds to selection in 3D view
- [x] 12.5 Verify: Shift+click toggles selection in 3D view
- [x] 12.6 Verify: clicking a tree item selects the shape in the 3D view
- [x] 12.7 Verify: Ctrl+click in tree multi-selects
- [x] 12.8 Verify: Shift+click in tree selects range
- [x] 12.9 Verify: `(select :box)` in REPL selects the shape in both tree and 3D view
- [x] 12.10 Verify: 3D view selection updates tree highlights
- [x] 12.11 Verify: no infinite loop or crash during rapid selection changes
- [x] 12.12 Run `just test` to confirm all tests pass

## 13. Documentation

- [x] 13.1 Update README.md with selection API section covering `select`, `deselect`, `clear-selection`, `selected-shapes`, `apply-selection-schemes`
- [x] 13.2 Document the three selection paths (REPL, tree, 3D view) and their sync behavior
