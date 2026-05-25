## Why

Lisp developers coming from Clojure or functional backgrounds are accustomed to threading macros (`->`, `->>`, `as->`) for writing nested function calls in a linear, readable pipeline. These macros eliminate deeply nested expressions, making data transformation code more comprehensible and reducing paren mismatches. Adding them to ClotCAD gives users a familiar, ergonomic tool for both REPL exploration and parametric model code.

## What Changes

- **Add**: `->` (thread-first) macro — threads a value as the first argument of each form
- **Add**: `->>` (thread-last) macro — threads a value as the last argument of each form
- **Add**: `as->` (thread-as) macro — threads a value through forms via a named binding
- **Add**: Update `clotcad-api.md` docstring reference and the cheatsheet to include the new macros

## Capabilities

### New Capabilities
- `threading-macros`: Implement `->`, `->>`, and `as->` macros exported from the `clotcad` package, with full test coverage

### Modified Capabilities

None.

## Impact

- **Lisp**: New file `src/threading.lisp` with three macro definitions. Export additions to `src/package.lisp` (both `clotcad.impl` and `clotcad`). ASDF component addition in `clotcad.asd`.
- **Tests**: New test cases in `t/viewer-tests.lisp` covering basic threading, edge cases (single form, no forms, symbol forms), and macro expansion correctness.
- **Docs**: Update `docs/clotcad-api.md` and `docs/cheatsheet/cheatsheet.typ` with the three macros.
