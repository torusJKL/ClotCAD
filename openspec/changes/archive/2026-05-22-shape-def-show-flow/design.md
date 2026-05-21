## Context

The viewer currently uses individual CFFI calls for shape management: `%viewer-put-shape` to add, `%viewer-remove-shape` to remove, `%viewer-clear` to wipe, and `%viewer-set-shape-visible` to toggle visibility. The Scene Tree panel is populated by these individual calls but never synced back to Lisp when the user toggles a checkbox. `*displayed-models*` is a flat hash table mapping string → CLOS shape object. There is no support for named references without display, or symbol-based resolution in operations.

The C++ side uses `ViewerState` with `std::map<std::string, Handle(AIS_Shape)> shapes` and `std::vector<std::string> shape_names` to track displayed shapes. The Scene Tree is a flat `QTreeWidget` populated by `addShape`/`removeShape` calls.

## Goals / Non-Goals

**Goals:**

- Provide a `def` macro that names a shape without displaying it
- Provide `show`/`hide`/`toggle` for programmatic visibility control
- Provide `show-defs`/`toggle-defs` for batch Scene Tree visibility of def-ined shapes
- Provide `resolve-shape` and auto-resolving wrapper functions for all shape-taking operations
- Implement drain-based full-state sync replacing individual CFFI calls
- Use shape-diff optimization to avoid recreating AIS objects on visibility-only updates
- Bidirectional Scene Tree ↔ Lisp sync for checkbox state
- Make `update-shape-count` Lisp-local

**Non-Goals:**

- Hierarchical or nested Scene Tree (remains flat)
- Per-shape color/layer properties (only origin tracking for def vs display)
- Removal of `viewer_set_shape_visible` (kept for direct checkbox→3D path)
- Performance optimization beyond shape-diff (no spatial indexing, no lazy loading)

## Decisions

### D1: Wipe-and-rebuild with shape-diff (not full wipe, not per-shape incremental)

**Chosen**: `viewer_sync_shapes` receives a complete snapshot. Items with `shape_changed=1` recreate AIS_Shape. Items with `shape_changed=0` reuse existing AIS and only toggle visibility/tree state. Items not in snapshot are removed.

**Alternatives considered:**
- **Full per-shape incremental** (old approach): Each operation calls individual CFFI functions. Simple but no batch optimization, no tree sync.
- **Pure wipe-and-rebuild**: Simplest C++ code but recreates all AIS objects every sync, wasteful for visibility-only operations.

**Rationale**: Shape-diff gives nearly the same C++ complexity as pure wipe (single loop over incoming items) while avoiding unnecessary AIS recreation. The `shape_changed` flag is cheap to track in Lisp.

### D2: Value type change for `*displayed-models*`

**Chosen**: Change from `shape` → `(shape visible show-in-tree dirty origin)`.

**Alternatives considered:**
- **Parallel metadata hash table**: Keep `*displayed-models*` as-is, add `*shape-properties*` hash. More registers to keep in sync.
- **CFFI struct stored in hash**: Store a foreign struct pointer. Overengineered for the use case.

**Rationale**: A single hash table with a list value is the simplest approach. Four extra fields (one boolean for dirty, one keyword for origin) are minimal. All existing code that reads the shape value must be updated anyway (breaking change), so there's no migration cost advantage to the parallel table.

### D3: Bidirectional sync via visibility callback

**Chosen**: The existing `visibility_callback` fires when the user clicks a tree checkbox. The Lisp callback updates the `visible` flag in `*displayed-models*`. The reverse direction (`show`/`hide`/`toggle` from Lisp) updates the checkbox via `setShapeCheckState` during sync, with `blockSignals` to prevent callback loop.

**Alternatives considered:**
- **Poll-based**: Lisp periodically checks C++ state. Complex and race-prone.
- **One-way (C++ is source of truth)**: Lisp never writes visibility, only reads. Doesn't support programmatic show/hide.

**Rationale**: The callback path already exists. The only change is expanding the callback to write to `*displayed-models*`, and adding `setShapeCheckState` with signal blocking.

### D4: `*show-defs-in-tree*` as both toggle and retroactive batch

**Chosen**: Changing `*show-defs-in-tree*` immediately applies to all existing def-ined shapes, not just future ones.

**Alternatives considered:**
- **Future-only**: Only affects subsequent `def` calls. Users would be confused why existing shapes don't respond.
- **Per-shape API**: Individual `(show-in-tree :s nil)` for fine-grained control. Adds complexity without clear need.

**Rationale**: Retroactive batch is simpler to understand and matches user expectation ("hide all intermediate shapes"). Per-shape control can be added later if needed.

### D5: `show` only toggles visibility, not show-in-tree

**Chosen**: `show` and `hide` only change the `visible` flag. `show-in-tree` is controlled separately by `show-defs`/`toggle-defs`.

**Alternatives considered:**
- **`show` also sets show-in-tree=t**: Couples orthogonal concerns. A hidden-from-tree shape would appear in the tree just because you made it visible.
- **`show` does nothing if show-in-tree=nil**: Surprising — shape stays invisible despite `show`.

**Rationale**: Orthogonal controls are less surprising. `show` means "see it in 3D." `show-defs` means "list it in the tree." They compose.

## Risks / Trade-offs

- **Risk: Callback loop** → Mitigation: `setShapeCheckState` blocks Qt signals. Only the user's physical click triggers `visibilityChanged`.
- **Risk: Thread safety** → Mitigation: Same pattern as existing code (Swank thread writes, Qt thread reads during drain). The hash table value is a list — `gethash` returns atomically, destructive `setf` on the list is safe since only the Swank thread performs it.
- **Risk: Sync performance with 1000+ shapes** → Mitigation: Shape-diff avoids AIS recreation. If needed, the snapshot array can be CFFI-allocated once and reused. Not a concern at typical CAD scales (10-100 shapes).
- **Trade-off: Breaking change** → All existing code using `*displayed-models*` values needs updating. This is acceptable since this is a pre-1.0 project with no public API guarantee.
