## Why

The current REPL workflow requires users to display every shape immediately and manually track names. There's no way to defer display, no symbol-based resolution for operations, and no programmatic visibility control. This makes iterative modeling tedious — intermediate shapes clutter the view, and operations require verbose shape references.

## What Changes

- **New `def` macro**: Associates a symbol with a shape without displaying it. Shapes are stored as hidden in the viewer and optionally hidden from the Scene Tree. **BREAKING**: This changes the value type of `*displayed-models*`.
- **New `show` / `hide` / `toggle` functions**: Programmatic visibility control. Bidirectional sync with Scene Tree checkboxes.
- **New `show-defs` / `toggle-defs` functions**: Controls whether `def`-ined shapes appear in the Scene Tree. Retroactively applies to all existing shapes.
- **New `resolve-shape` function**: Resolves symbols (or shapes) to shape objects from `*displayed-models*` or the DAG `*model-registry*`.
- **Wrapper functions**: `cut`, `fuse`, `common`, `section`, `translate`, `rotate`, `make-prism`, `make-revol`, `make-compound`, `make-part`, `write-step`, `write-stl` all auto-resolve symbol arguments to shapes.
- **Drain-based sync**: Replaces individual CFFI calls (`viewer_put_shape`, `viewer_remove_shape`, etc.) with a single `viewer_sync_shapes` call that sends the full state snapshot. **BREAKING**: Removes ~9 C++ API functions. **BREAKING**: Removes old shape-related CFFI bindings.
- **Shape-diff optimization**: C++ `viewer_sync_shapes` only recreates AIS_Shape objects when geometry actually changed, not on visibility-only updates.
- **`*displayed-models*` value type** changes from `shape` to `(shape visible show-in-tree dirty origin)`. **BREAKING**: All direct access to hash values must be updated.
- **`update-shape-count`** becomes Lisp-local (no longer queries C++).
- **Scene Tree checkbox** is now bidirectional: user clicks update Lisp state, Lisp `show`/`hide` update tree checkboxes.

## Capabilities

### New Capabilities
- `symbolic-shapes`: Named shape references via `def` macro, `resolve-shape`, and auto-resolving wrapper functions.
- `visibility-control`: Programmatic `show`/`hide`/`toggle` for shapes with bidirectional Scene Tree sync.
- `sync-framework`: Drain-based full-state sync via `viewer_sync_shapes` with shape-diff optimization.

### Modified Capabilities

<!-- No existing specs to modify -->

## Impact

- **C++** (`wrap/`): Add `viewer_sync_shapes`, `setShapeCheckState`, `setShapeTreeVisible`. Remove ~9 old shape management functions.
- **Lisp bindings** (`src/viewer/bindings.lisp`): Add `shape-sync-item` struct and `%viewer-sync-shapes`. Remove old shape bindings.
- **Lisp state** (`src/viewer/queue.lisp`): Value type change for `*displayed-models*`, `drain-queue` refactor, `display` keyword args.
- **New file** (`src/viewer/ops.lisp`): All new user-facing functions.
- **UI** (`src/viewer/ui.lisp`): Visibility callback now syncs `*displayed-models*`.
- **REPL** (`src/viewer/repl.lisp`): Export functions updated for new value type.
- **Package** (`src/viewer/package.lisp`): New exports added, old ones removed.
- **ASDF** (`cl-occt-viewer.asd`): Register new `ops` file.
- **Tests** (`t/`): New test cases for `def`, `show`, `hide`, `toggle`, `show-defs`, `resolve-shape`, and wrapper functions.
