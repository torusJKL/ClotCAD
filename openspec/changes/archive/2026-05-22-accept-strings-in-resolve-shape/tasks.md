## 1. Core Implementation

- [x] 1.1 Add `string` branch to `resolve-shape` in `src/viewer/ops.lisp` that does direct `gethash` lookup in `*displayed-models*` and errors on miss

## 2. Tests

- [x] 2.1 Add test `resolve-shape-finds-displayed-string` — string lookup finds displayed shape in `*displayed-models*`
- [x] 2.2 Add test `resolve-shape-errors-on-unknown-string` — string lookup errors on nonexistent key
- [x] 2.3 Register new tests in test list at bottom of `t/viewer-tests.lisp`

## 3. Documentation

- [x] 3.1 Update README Usage section to mention that wrapper functions also accept strings, and add a string-based `def` example

## 4. Bug Fix: def visibility

- [x] 4.1 Fix `viewer_sync_shapes` in `wrap/occt_viewer.cpp` — conditionally call `Display` based on `checked` instead of always displaying then erasing, which caused previous def shapes to become visible when a new shape was defined
