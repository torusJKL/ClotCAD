## Why

Users and AI agents working through the REPL have no way to identify specific subshapes (faces, edges, vertices) of a model by spatial properties. Operations like chamfer, fillet, and hole require selecting the right edge or face, but the only available tools are `map-shape-subshapes` (returns all subshapes as a flat list) and a few low-level edge finders. Users must guess at indices or traverse OCCT topology manually. A spatial query system lets users express "the top face" or "the longest edge" naturally.

## What Changes

- **query-shape function**: Predicate-based query over a shape's subshapes. Accepts `:where` with a list of predicates and `:coordinate-system :global` or `:local`.
- **Predicates**: `face-p`, `edge-p`, `vertex-p`, `normal-along`, `surface-type`, `curve-type`, `longer-than`, `shorter-than`, `larger-than`, `smaller-than`, `max-by`, `min-by`, `z-center`, `y-center`, `x-center`, `edge-along`, `radius-around`.
- **Convenience accessors**: `top-face`, `bottom-face`, `longest-edge`, `largest-face`, `shortest-edge`, `smallest-face`.
- **Tests** for all query predicates and convenience functions.
- **API reference** documentation updated.

## Capabilities

### New Capabilities
- `spatial-subshape-queries`: Predicate-based query system for finding faces, edges, and vertices by spatial and topological properties. Supports `:global`/`:local` coordinate system keyword.

### Modified Capabilities
- (none)

## Impact

- New file `src/viewer/query.lisp`
- New test file `t/query.lisp`
- Updates to `docs/clotcad-api.md` with new function signatures
- cl-occt dependency unchanged
