## Why

The cl-occt submodule was updated from commit `4207763` to `69f7f3d`, adding 50 new source files with exported API functions. The apropos category tree (built via `sb-introspect` source-file introspection) automatically picks up every new source file as a separate category. Without a grouping mechanism, the category tree would grow from ~50 entries to ~100, making `(apropos)` hard to scan. We need a way to merge related source-file stems under shared categories.

## What Changes

- Add `*category-merge-groups*` parameter in `introspect.lisp` defining which source-file stems should be merged under a single category
- Modify `%build-category-index` to apply merge groups after scanning — union function lists from member stems into the target stem, then remove member stems from the index
- Add 12+ new entries to `*category-display-names*` for merged-group targets and standalone new files
- Define 8 merge groups: Graphic3D, OCAF, XCAF, Shape Utilities, Advanced Modeling, Materials & Texture, Meshing, 2D Constraints
- Merge 6 existing categories: Booleans (+BOP), File I/O (+BREP, +RWStl), Primitives (+wedge), Shape Analysis (+find-edges, +inttools, +hlr, +gcpnts-points, +geometry-evaluation, +subshape-properties, +surface-curve-local-props), Topology (+topology-data-access), Assembly (+assembly-location)
- 4 standalone new categories: Animation, Normal Projection, Transfer Parameters, Selection (OCCT)

## Capabilities

### New Capabilities

*(No new capabilities — this is an infrastructure extension to existing categories.)*

### Modified Capabilities

- `apropos-categories`: Add category merge-group support — the category-building step SHALL merge function lists from multiple source-file stems into a single category entry based on a configurable merge-group list

## Impact

- **Modified**: `src/viewer/introspect.lisp` — add `*category-merge-groups*`, modify `%build-category-index`, add display-name entries
- **Tests**: existing mock infrastructure needs to cover the merge-group code path; add test exercising the merge logic
- **No breaking changes**: existing `(apropos)`, `(apropos :keyword)`, and `(apropos "pattern")` behavior unchanged
