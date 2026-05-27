## 1. Query module implementation

- [x] 1.1 Create `src/viewer/query.lisp` with `query-shape` entry point: resolve designator, call `map-shape-subshapes`, apply predicates in order, return matching subshape list
- [x] 1.2 Implement `face-p`, `edge-p`, `vertex-p` type predicates
- [x] 1.3 Implement `normal-along` with `:angle-deg` tolerance, `:coordinate-system :global`/`:local`
- [x] 1.4 Implement `surface-type` predicate (delegates to `face-surface-type`)
- [x] 1.5 Implement `curve-type` predicate (delegates to `edge-curve-type`)
- [x] 1.6 Implement `longer-than`, `shorter-than` predicates (delegates to `edge-length`)
- [x] 1.7 Implement `larger-than`, `smaller-than` predicates (delegates to `face-area`)
- [x] 1.8 Implement `max-by`, `min-by` predicates (accepts a measurement function)
- [x] 1.9 Implement `z-center`, `y-center`, `x-center` with `:tolerance` keyword
- [x] 1.10 Implement `edge-along` predicate (edge direction alignment)
- [x] 1.11 Implement `radius-around` predicate with `:tolerance` keyword
- [x] 1.12 Implement convenience functions: `top-face`, `bottom-face`, `longest-edge`, `largest-face`, `shortest-edge`, `smallest-face`
- [x] 1.13 Write enriched markdown docstrings for every new public function in `query.lisp` using the format: brief description, `- **param** ...` for each parameter, `**Returns:**`, `**Example:**` with code block, and `**See also:**` linking related functions

## 2. ASDF and package updates

- [x] 2.1 Add query.lisp to `clotcad.asd`
- [x] 2.2 Export all new public symbols from `:clotcad` package
- [x] 2.3 Ensure convenience accessors are available in `:clotcad-user`

## 3. Tests

- [x] 3.1 Create `t/query.lisp` with tests for all predicates against known shapes (box, cylinder, cone, torus) with both `:global` and `:local` coordinate systems
- [x] 3.2 Test convenience accessors against known shapes
- [x] 3.3 Add test system to `clotcad.asd`

## 4. API reference documentation

- [x] 4.1 Add query-shape function signature and examples to `docs/clotcad-api.md`
- [x] 4.2 Add all predicate function signatures and examples to `docs/clotcad-api.md`
- [x] 4.3 Add convenience accessor signatures and examples to `docs/clotcad-api.md`
