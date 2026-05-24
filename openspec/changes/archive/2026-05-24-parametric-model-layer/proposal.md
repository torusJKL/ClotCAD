## Why

cl-occt removed its parametric DSL and DAG layer (commit 8ee4a1e) to keep the library a thin 1:1 OCCT wrapper. ClotCAD needs this functionality to provide parametric modeling — `defmodel`, parameter propagation, and a reactive evaluation graph. Moving it to ClotCAD's own source keeps cl-occt clean while restoring the high-level modeling API users depend on.

## What Changes

- **NEW** `src/model/` module in ClotCAD with DAG layer (model struct, registry, propagation) and DSL layer (`defmodel`, `param`, `with-params`, `model-ref`, metadata)
- **NEW** `resolve-shape` in the model layer — resolves symbols/strings to cached shapes from the DAG registry
- **MODIFIED** `def` — stores shape in DAG registry and appears in Scene Tree (grayed), no longer skips the tree
- **MODIFIED** `display` — also registers a simple model in the DAG registry alongside the viewer display entry
- **MODIFIED** `show` — resolves from DAG registry if shape not yet in `*displayed-models*`
- **REMOVED** `undisplay` — no longer needed; `hide` is sufficient
- **REMOVED** `resolve-shape` from `viewer/ops.lisp` — moved to model layer
- **REMOVED** monkey-patch on `cl-occt.impl:propagate-changes` in `queue.lisp` — replaced with ClotCAD's own propagation and an `*after-propagation-hook*`
- **NEW** `write-dag-models-to-step` and `read-step-into-dag` — serialise the DAG registry to/from STEP with metadata
- **REFACTOR** Package definitions extracted to top-level `src/package.lisp`
- **UPDATED** `docs/clotcad-api.md` and `docs/cheatsheet/cheatsheet.typ` with new DSL/DAG API

## Capabilities

### New Capabilities
- `reactive-dag`: Parametric DAG with model registry, dependency tracking, dirty propagation, and topological evaluation order
- `dsl-metadata`: Metadata (color, name, layer) on defmodel definitions, preserved through re-evaluation
- `ddag-step-io`: Export/import the entire DAG model registry to/from STEP with metadata
- `parametric-dsl`: defmodel, param, with-params, model-ref, set-param!, set-params!, model-color, model-display-name, model-layer, help

### Modified Capabilities

None — no existing specs to modify.

## Impact

- **Code**: ~400 lines added across 6 new files in `src/model/`; modified files in `src/viewer/` (queue.lisp, ops.lisp, lifecycle.lisp, package.lisp)
- **API**: New public symbols in the `CLOTCAD` package: `defmodel`, `param`, `with-params`, `model-ref`, `set-param!`, `set-params!`, `model-color`, `model-display-name`, `model-layer`, `*params*`, `*model-registry*`, `help`, `write-dag-models-to-step`, `read-step-into-dag`. Removed: `undisplay`, `resolve-shape` (moved, same name)
- **Packages**: Package definitions consolidated to `src/package.lisp`
- **Dependencies/no change**
- **Docs**: `docs/clotcad-api.md` and `docs/cheatsheet/cheatsheet.typ` updated with new DSL/DAG API
