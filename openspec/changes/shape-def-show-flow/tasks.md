## 1. C++ Scene Tree Panel

- [x] 1.1 Add `setShapeCheckState(name, checked)` method to `SceneTreePanel` that blocks Qt signals and updates the checkbox
- [x] 1.2 Add `setShapeTreeVisible(name, visible)` method to `SceneTreePanel` that hides/shows the tree row

## 2. C++ Sync Function

- [x] 2.1 Add `ShapeSyncItem` struct with fields: `name`, `shape_ptr`, `checked`, `show_in_tree`, `shape_changed`
- [x] 2.2 Implement `viewer_sync_shapes`: loop over incoming items, add new shapes, recreate AIS only when `shape_changed`, toggle visibility/tree for all, remove shapes not in snapshot
- [x] 2.3 Remove old shape functions: `viewer_put_shape`, `viewer_remove_shape`, `viewer_clear`, `viewer_get_shape_count`, `viewer_get_visible_shape_count`, `viewer_get_shape_name`, `viewer_notify_shape_change`, `viewer_is_shape_visible`
- [x] 2.4 Keep `viewer_set_shape_visible` and `viewer_set_visibility_callback` for tree checkbox direct path

## 3. Lisp CFFI Bindings

- [x] 3.1 Add `shape-sync-item` CFFI struct definition in `bindings.lisp`
- [x] 3.2 Add `%viewer-sync-shapes` CFFI function binding
- [x] 3.3 Remove old shape CFFI bindings: `%viewer-put-shape`, `%viewer-remove-shape`, `%viewer-clear`, `%viewer-get-shape-count`, `%viewer-get-visible-shape-count`, `%viewer-get-shape-name`, `%viewer-notify-shape-change`, `%viewer-is-shape-visible`
- [x] 3.4 Keep `%viewer-set-shape-visible` and `%viewer-set-visibility-callback` bindings

## 4. Lisp State and Queue

- [x] 4.1 Change `*displayed-models*` value type from `shape` to `(shape visible show-in-tree dirty origin)`
- [x] 4.2 Update `queue-push` signature to accept optional `visible`, `show-in-tree` parameters
- [x] 4.3 Update `display` function with `:visible` and `:show-in-tree` keyword arguments
- [x] 4.4 Refactor `drain-queue`: remove individual CFFI calls, process messages into hash table only, call `sync-viewer` at end
- [x] 4.5 Implement `sync-viewer` function: build `ShapeSyncItem` array from `*displayed-models*`, call `%viewer-sync-shapes`, reset `dirty` flags
- [x] 4.6 Make `update-shape-count` Lisp-local (read from `*displayed-models*`, no C++ queries)
- [x] 4.7 Update `viewer-refresh` to preserve `visible`/`show-in-tree` from old hash entries

## 5. New ops.lisp

- [x] 5.1 Define `*show-defs-in-tree*` global variable (default `t`)
- [x] 5.2 Implement `resolve-shape`: etypecase on shape → pass through, symbol → check displayed-models then model-registry, error if not found
- [x] 5.3 Implement `def` macro: evaluate form, call display with `:visible nil :show-in-tree *show-defs-in-tree*`, return shape
- [x] 5.4 Implement `show`: set `visible=t`, queue sync, error on unknown symbol
- [x] 5.5 Implement `hide`: set `visible=nil`, queue sync, error on unknown symbol
- [x] 5.6 Implement `toggle`: flip `visible`, queue sync, error on unknown symbol
- [x] 5.7 Implement `show-defs`: set `*show-defs-in-tree*`, update all def-ined shapes' `show-in-tree`, queue sync
- [x] 5.8 Implement `toggle-defs`: flip `*show-defs-in-tree*`, delegate to `show-defs`
- [x] 5.9 Implement wrapper functions: `cut`, `fuse`, `common`, `section`, `translate`, `rotate`, `make-prism`, `make-revol`, `make-compound`, `make-part`, `write-step`, `write-stl`

## 6. UI Callback

- [x] 6.1 Update `%on-shape-visibility` callback to write the `visible` flag back to `*displayed-models*`
- [x] 6.2 Keep `register-shape-visibility-callback`

## 7. REPL Export Functions

- [x] 7.1 Update `export-all-step` to destructure new `*displayed-models*` value type
- [x] 7.2 Update `export-all-stl` to destructure new `*displayed-models*` value type

## 8. Package Exports

- [x] 8.1 Add `:%viewer-sync-shapes` to `cl-occt-viewer.impl` exports
- [x] 8.2 Remove old shape CFFI bindings from `cl-occt-viewer.impl` exports
- [x] 8.3 Add new symbols to `cl-occt-viewer` exports: `:*show-defs-in-tree*`, `:resolve-shape`, `:def`, `:show`, `:hide`, `:toggle`, `:show-defs`, `:toggle-defs`, wrapper functions
- [x] 8.4 Add `:sync-viewer` to `cl-occt-viewer.impl` exports (needed for drain-queue)

## 9. ASDF Registration

- [x] 9.1 Add `(:file "ops")` after `(:file "queue")` in `cl-occt-viewer.asd`

## 10. Unit Tests

- [x] 10.1 Add test for `*displayed-models*` value type: verify list with 5 elements
- [x] 10.2 Add tests for `resolve-shape`: symbol resolution, shape passthrough, unknown symbol error
- [x] 10.3 Add tests for `def` macro: stores shape, visible=nil, show-in-tree from *show-defs-in-tree*, returns shape
- [x] 10.4 Add tests for `show`: sets visible=t, errors on unknown symbol
- [x] 10.5 Add tests for `hide`: sets visible=nil, errors on unknown symbol
- [x] 10.6 Add tests for `toggle`: flips visible
- [x] 10.7 Add tests for `show-defs`/`toggle-defs`: updates all def-ined entries
- [x] 10.8 Add tests for wrapper functions: each one resolves symbols and delegates to cl-occt

## 11. README

- [x] 11.1 Update README with new `def`/`show`/`hide`/`toggle`/`show-defs`/`toggle-defs`/`resolve-shape` API documentation
- [x] 11.2 Add usage examples showing the new workflow
