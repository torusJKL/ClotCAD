## Why

Subshapes (faces, edges, vertices) returned by `map-shape-subshapes` are anonymous — they have no stable name or identity. An AI agent that finds "the top face" in one step cannot refer to it in the next step. Compound symbols like `:my-box/top-face` provide stable, human-readable references that survive as long as the parent model exists. Displaying them in the Scene Tree lets users visually identify which face or edge a name refers to.

## What Changes

- **name-subshape**: Register a named query on a model, storing the query specification for later re-evaluation.
- **face-ref / edge-ref / vertex-ref**: Resolve a named subshape by re-evaluating its stored query on the model's current shape.
- **Compound symbol resolution**: Parse `:model/name` designators in all ClotCAD functions that accept shape designators.
- **list-named-subshapes / remove-named-subshape**: Manage named references.
- **Scene Tree integration**: Display named subshapes as children of their parent model, with click-to-select in the 3D view.
- **Tests** for all naming functions.
- **API reference** documentation updated.

## Capabilities

### New Capabilities
- `named-subshape-system`: Compound symbol naming (`:model/name`) for stable subshape references. Stored queries on parent models. Scene Tree display of named subshapes.

### Modified Capabilities
- (none)

## Impact

- New file `src/viewer/naming.lisp`
- Model struct in `src/model/model.lisp` gains `named-subshapes` slot
- Updates to `src/model/api.lisp` `resolve-shape` for compound symbol support
- Potential CFFI binding additions for Scene Tree subshape interaction
- New test file `t/naming.lisp`
- Updates to `docs/clotcad-api.md`
