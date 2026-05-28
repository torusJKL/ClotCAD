## Context

The apropos category tree in `src/viewer/introspect.lisp` groups exported fbound symbols by their source-file stem, discovered via `sb-introspect:FIND-DEFINITION-SOURCE`. Each stem becomes a category key, resolved to a display name via `*category-display-names*`. Unmapped stems get `string-capitalize` as a fallback.

The cl-occt submodule was updated from `4207763` to `69f7f3d`, adding 50 new source files. Each file that exports functions will appear as a separate category in the `(apropos)` tree — ballooning the tree from ~50 entries to ~100.

The current code has no mechanism to merge multiple stems under one category. Adding display-name entries for all 50 stems individually would solve the naming issue but not the tree bloat.

## Goals / Non-Goals

**Goals:**
- Provide a declarative merge-group mechanism that consolidates multiple source-file stems under a single target category
- Keep existing behavior untouched — all existing categories, display names, and lookup logic remain identical
- Add display-name entries and merge-group definitions for the new cl-occt source files (target: 8 merged groups + 4 standalone entries, vs 50 individual entries)
- Merge 6 existing categories with related new stems to keep the tree compact

**Non-Goals:**
- No change to substring search mode (`(apropos "pattern")`)
- No change to keyword drill-down mode (`(apropos :keyword)`)
- No change to the `%build-category-index` caching mechanism
- No changes to the package or export system

## Decisions

### Decision: Post-scan merge in `%build-category-index`

The merge step runs after the initial `do-external-symbols` scan and sort, but before the index is cached in `*category-fn-index*`. This keeps the scanning logic simple (no per-symbol routing) and makes the merge visible only in the index building phase.

**Alternatives considered:**
- **Per-symbol routing**: Check merge groups during scanning and assign symbols directly to the target stem's bucket. Rejected because it couples scanning with grouping logic and makes the code harder to reason about.
- **Display-name-layer merge**: Assign the same display name to multiple stems and merge at print time. Rejected because each stem still produces a separate hash entry; merging at print time would require another dedup pass.
- **No merge, just reorganize cl-occt source files**: Rejected — source files are organized by OCCT class/module boundaries and shouldn't be rearranged for UI convenience.

### Decision: `*category-merge-groups*` uses keyword symbols

```lisp
(defparameter *category-merge-groups*
  '((:booleans :bop-splitter :bop-utilities :bop-volume)
    (:graphic3d :graphic3d-aspects ...)
    ...))
```

Each entry is `(target-kw &rest source-kws)`. Converted to strings via `string-downcase` for hash-key lookup, matching how `pathname-name` returns lowercase stem strings. Keywords are consistent with `*category-display-names*` convention.

### Decision: Merge groups defined as parameter, not configuration file

The merge groups are static data defined at the top of `introspect.lisp`, next to `*category-display-names*`. Keeping them in code:
- Requires no extra file loading at startup
- Is consistent with the existing `*category-display-names*` convention
- Makes the grouping visible and editable in one place

### Decision: Group composition

| Target | Member Stems | Rationale |
|---|---|---|
| `booleans` (existing) | `bop-splitter`, `bop-utilities`, `bop-volume` | All BOPAlgo operations extending boolean functionality |
| `io` (existing) | `brep-io`, `rwstl-io` | Both are file format I/O modules alongside existing STEP/STL |
| `primitives` (existing) | `wedge-primitive` | Wedge is a geometric primitive type |
| `shape-analysis` (existing) | `find-edges`, `inttools`, `hlr`, `gcpnts-points`, `geometry-evaluation`, `subshape-properties`, `surface-curve-local-props` | All analyze or query shape/geometry properties |
| `topology` (existing) | `topology-data-access` | Topology navigation and traversal helpers |
| `assembly` (existing) | `assembly-location` | Assembly placement and location utilities |
| `graphic3d` (new) | `graphic3d-aspects`, `graphic3d-clip-plane`, `graphic3d-group`, `graphic3d-rendering-params`, `graphic3d-shader-program`, `graphic3d-structure`, `prs3d-tools`, `viewer-ais-types` | All are low-level Graphic3D visualization wrappers; each is thin and benefits from consolidation |
| `ocaf` (new) | `ocaf-attributes`, `ocaf-functions`, `ocaf-label-tree`, `ocaf-naming` | OCAF parametric data framework — tightly related sub-modules |
| `xcaf` (new) | `xcaf-dimtol`, `xcaf-doc` | XCAF GD&T extensions |
| `shape-utilities` (new) | `shape-check`, `shape-conversion`, `shape-copy`, `shape-tolerance`, `small-faces`, `sewing`, `defeaturing`, `remove-features` | All are shape manipulation/healing utilities |
| `advanced-modeling` (new) | `advanced-surface-filling`, `fair-curve`, `drafted-prism` | Advanced surface and curve modeling beyond primitives |
| `materials-texture` (new) | `materials`, `texture` | Material and texture property wrappers |
| `meshing` (new) | `mesh` | Mesh generation (single file, but given its own category for discoverability) |
| `2d-constraints` (new) | `constrained-2d`, `expression-interp` | Constrained 2D geometry and parametric expression parsing |

### Decision: 4 standalone categories for files too distinct to merge

- `animation` — AIS animation (start/stop/pause/progress) is a standalone concern
- `normal-project` — Normal projection of points onto shapes is a distinct geometric operation
- `transfer-params` — Parameter transfer between edges is a narrow but distinct utility
- `selection` — OCCT selection API (filters, modes, pixel tolerance) is separate from ClotCAD's internal `:select` category

### Decision: Target categories use the same display name as before

For existing targets (booleans, io, primitives, shape-analysis, topology, assembly), the display name in `*category-display-names*` is unchanged. New target categories get added with:
- `:graphic3d` → "Graphic3D"
- `:ocaf` → "OCAF"
- `:xcaf` → "XCAF"
- `:shape-utilities` → "Shape Utilities"
- `:advanced-modeling` → "Advanced Modeling"
- `:materials-texture` → "Materials & Texture"
- `:meshing` → "Meshing"
- `:2d-constraints` → "2D Constraints"

## Risks / Trade-offs

- **Merge groups are static** — Adding a new cl-occt file later requires a manual update to `*category-merge-groups*` and `*category-display-names*`. Mitigation: the fallback behavior (unmapped stems get `string-capitalize` display and appear as independent categories) is preserved, so new files won't silently disappear; they'll show up with a reasonable default name until manually grouped.
- **Removed stems lose their independent category** — Once a stem is in a merge group, its functions no longer appear as a standalone category. This is the intended trade-off. Users can still find functions via `(apropos "pattern")` substring search.
