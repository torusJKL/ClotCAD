## 1. Model struct extension

- [x] 1.1 Add `named-subshapes` slot (alist of `(name . query-plist)`) to the `model` struct in `src/model/model.lisp`
- [x] 1.2 Add `propagate-named-subshapes` function that re-evaluates all named subshape queries after a model's shape is recomputed, and invalidates stale cache entries

## 2. Naming module

- [x] 2.1 Create `src/viewer/naming.lisp` with `name-subshape` that stores a query plist on a model's `named-subshapes` slot
- [x] 2.2 Implement `face-ref`, `edge-ref`, `vertex-ref` that resolve a named subshape by re-evaluating its stored query
- [x] 2.3 Implement compound symbol resolution: parse `:model/name` into model name and subshape name, resolve via find-model + named-subshapes lookup
- [x] 2.4 Implement `list-named-subshapes` and `remove-named-subshape`
- [x] 2.5 Add compound symbol support to `resolve-shape` in `src/model/api.lisp`
- [x] 2.6 Write enriched markdown docstrings for every new public function in `naming.lisp` using the format: brief description, `- **param** ...` for each parameter, `**Returns:**`, `**Example:**` with code block, and `**See also:**` linking related functions

## 3. Scene Tree integration

- [x] 3.1 Add CFFI binding for Scene Tree subshape display and selection (or reuse existing AIS selection modes)
- [x] 3.2 Update Scene Tree sync logic to emit named subshape entries as children of their parent model
- [x] 3.3 Wire Scene Tree click on a named subshape to subshape highlight in the 3D view

## 4. ASDF and package updates

- [x] 4.1 Add naming.lisp to `clotcad.asd`
- [x] 4.2 Export all new public symbols from `:clotcad` package
- [x] 4.3 Ensure naming functions are available in `:clotcad-user`

## 5. Tests

- [x] 5.1 Create `t/naming.lisp` with tests for `name-subshape`, `face-ref`, `edge-ref`, `vertex-ref`, compound symbol resolution, and error cases
- [x] 5.2 Test that named subshapes survive model recomputation (defmodel param change)
- [x] 5.3 Add test system to `clotcad.asd`

## 6. API reference documentation

- [x] 6.1 Add naming function signatures and examples to `docs/clotcad-api.md` (name-subshape, face-ref, edge-ref, vertex-ref, list-named-subshapes, remove-named-subshape)
- [x] 6.2 Document compound symbol resolution in the shape designators section
