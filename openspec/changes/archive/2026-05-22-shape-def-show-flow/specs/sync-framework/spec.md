## ADDED Requirements

### Requirement: Drain-based full-state sync

The system SHALL replace individual per-shape CFFI calls (`viewer_put_shape`, `viewer_remove_shape`, `viewer_clear`) with a single `viewer_sync_shapes` call at the end of `drain-queue`. The C++ function `viewer_sync_shapes` SHALL accept an array of `ShapeSyncItem` structs representing the complete desired state. The C++ side SHALL reconcile the incoming snapshot against its current state: removing shapes not in the snapshot, adding/updating shapes in the snapshot, and syncing checkbox and tree visibility for all items.

#### Scenario: Sync adds new shapes
- **WHEN** `sync-viewer` is called with a snapshot containing a new shape `:s`
- **THEN** the shape appears in the 3D view
- **THEN** the shape appears in the Scene Tree

#### Scenario: Sync removes shapes not in snapshot
- **WHEN** `sync-viewer` is called with a snapshot that does not contain a previously displayed shape `:s`
- **THEN** the shape is removed from the 3D view
- **THEN** the shape is removed from the Scene Tree

### Requirement: Shape-diff optimization

The `ShapeSyncItem` struct SHALL include a `shape_changed` flag. When `shape_changed` is `0` (visibility-only update), the C++ side SHALL reuse the existing `AIS_Shape` and only toggle `Display`/`Erase`. When `shape_changed` is `1` (geometry changed), the C++ side SHALL remove the old `AIS_Shape` and create a new one. The Lisp side SHALL track a `dirty` flag in `*displayed-models*` entries, set to `t` by `display`/`def`/DAG refresh, and reset to `nil` after each sync.

#### Scenario: Visibility-only update does not recreate AIS
- **WHEN** user evaluates `(hide :s)` on an existing shape
- **THEN** `shape_changed` is `0` in the sync snapshot
- **THEN** C++ reuses the existing `AIS_Shape` and calls `Erase`

#### Scenario: Geometry change recreates AIS
- **WHEN** user evaluates `(display :s new-shape)` where `:s` exists
- **THEN** `shape_changed` is `1` in the sync snapshot
- **THEN** C++ removes the old `AIS_Shape` and creates a new one

### Requirement: Scene Tree API

The C++ `SceneTreePanel` SHALL provide `setShapeCheckState(name, checked)` and `setShapeTreeVisible(name, visible)` methods. `setShapeCheckState` SHALL block Qt signals to prevent callback loops. Both methods SHALL be called from `viewer_sync_shapes`.

#### Scenario: setShapeCheckState without callback loop
- **WHEN** `viewer_sync_shapes` calls `setShapeCheckState("s", 0)`
- **THEN** the checkbox is unchecked
- **THEN** the `visibilityChanged` signal is NOT emitted

### Requirement: update-shape-count is Lisp-local

The `update-shape-count` function SHALL derive shape counts from `*displayed-models*` instead of querying C++. Total count SHALL be `(hash-table-count *displayed-models*)`. Visible count SHALL be the number of entries with `visible=t`. The status bar text SHALL be computed from these Lisp-local values.

#### Scenario: Status bar reflects hidden shapes
- **WHEN** `:s` is displayed and `:b` is hidden
- **THEN** status bar shows "Displaying 1 shape (1 hidden)"

### Requirement: Old shape CFFI functions are removed

The following C++ functions and their CFFI bindings SHALL be removed: `viewer_put_shape`, `viewer_remove_shape`, `viewer_clear`, `viewer_get_shape_count`, `viewer_get_visible_shape_count`, `viewer_get_shape_name`, `viewer_notify_shape_change`, `viewer_is_shape_visible`. Only `viewer_set_shape_visible` and `viewer_set_visibility_callback` SHALL remain for the tree checkbox → 3D direct path and bidirectional sync.

#### Scenario: Old functions cannot be called
- **WHEN** code attempts to call `%viewer-put-shape`
- **THEN** a undefined function error is signaled
