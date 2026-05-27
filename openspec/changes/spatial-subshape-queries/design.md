## Context

cl-occt provides low-level topology access (`map-shape-subshapes`, `face-edges`, `edge-curve-type`, `face-surface-type`, `face-area`, `edge-length`, etc.) but no way to filter or select subshapes by spatial criteria. The ClotCAD layer in `src/viewer/ops.lisp` wraps boolean ops and transforms but doesn't help with subshape selection.

## Goals / Non-Goals

**Goals:**
- Provide predicate-based spatial queries over a shape's subshapes (faces, edges, vertices).
- Support both global and local coordinate frames for spatial predicates.
- Provide convenience accessors for common patterns (top face, longest edge, etc.).
- All new functions work in the REPL with minimal typing and accept shape designators.

**Non-Goals:**
- Persistent naming or subshape identity tracking (handled by named-subshape-system).
- Modifying the OCCT or cl-occt layer.
- 3D spatial queries beyond subshape center/direction properties.

## Decisions

### D1: Predicate list query style
`(query-shape box :where (list (face-p) (normal-along 0 0 1) (max-by #'face-area)))`
- Predicates are applied left-to-right as filters, then selectors.
- **Rationale**: Familiar Lisp idiom, composable, easy for AI to generate.

### D2: coordinate-system keyword
All spatial predicates accept `:coordinate-system :local` (default) or `:global`.
- `:local` — coordinates relative to the shape's own placement (ignores TopoDS_Location).
- `:global` — coordinates in the absolute world frame.

### D3: Shape designator support
All query functions accept symbols, strings, and raw shape objects via `resolve-shape`.

## Risks / Trade-offs

- **[Performance] Queries traverse all subshapes** — `map-shape-subshapes` is O(n). Acceptable for user-driven queries.
- **[Accuracy] normal-along uses angle tolerance** — Default 1 degree. User can override via `:angle-deg`.

### D4: Edge direction for edge-along predicate
`edge-along` uses the **bounding box dominant axis** to infer edge direction.
For each edge, compute `edge-bounding-box`, find the axis (X/Y/Z) with the
largest extent, and compare that axis direction against the query vector.
Accepts `:angle-deg` tolerance (default 1°) consistent with `normal-along`.
- **Rationale**: Bounding boxes are cheap, available for all edges, and avoid
  curve evaluation complexity. Sufficient for spatial alignment queries.

### D5: Center computation for subshapes
- **Faces**: use `face-center` (returns UV-midpoint XYZ from cl-occt).
- **Edges**: compute midpoint of `edge-bounding-box` → `(xmin+xmax)/2` etc.
- **Vertices**: midpoint of `subshape-bounding-box` (degenerates to a point).
- Default `:tolerance` for `x-center`/`y-center`/`z-center` is `1e-6`.

### D6: Coordinate-system handling
- **`:local`** (default) — use coordinates as returned by cl-occt functions,
  which report in the shape's own frame (no additional transform).
- **`:global`** — if the shape carries a `TopoDS_Location`, transform computed
  coordinates by the location. If `cl-occt` does not expose location access,
  `:global` falls back to `:local` behavior with a documented caveat.
- Currently both modes produce identical results; `:global` will become
  functional when `cl-occt` provides location query.

### D7: File ordering in ASDF
`query.lisp` loads after `select` and before `repl` in the viewer module.
Position 6 of 11 in `:module "viewer"`.

### D8: Test approach
Query tests do not require `with-mocked-viewer` because `query-shape` and
all predicates are pure shape computations — they only use `cl-occt` topology
functions and `resolve-shape`. Tests are in `t/query.lisp` with the same
inline `deftest`/`assert-*` framework used by existing tests.

## Open Questions (Resolved)

- **Should convenience accessors like `top-face` work on any shape or only boxes?**
  Any shape. `top-face` finds the planar face with highest Z center whose
  normal aligns with +Z.
