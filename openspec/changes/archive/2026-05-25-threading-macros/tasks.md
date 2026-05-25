## 1. Core Implementation

- [x] 1.1 Create `src/threading.lisp` with `->`, `->>`, and `as->` macro definitions in package `clotcad.impl`
- [x] 1.2 Add `#:->`, `#:->>`, `#:as->` to `clotcad.impl` export list in `src/package.lisp`
- [x] 1.3 Add `#:->`, `#:->>`, `#:as->` to `clotcad` export list in `src/package.lisp`
- [x] 1.4 Add `"threading"` component after `"package"` in `clotcad.asd` serial load order

## 2. Tests

- [x] 2.1 Add thread-first (`->`) tests: basic pipeline, symbol forms, single form, no forms, expansion correctness
- [x] 2.2 Add thread-last (`->>`) tests: basic pipeline, symbol forms, single form, expansion correctness
- [x] 2.3 Add thread-as (`as->`) tests: basic pipeline, single form, no forms
- [x] 2.4 Add package export tests verifying symbols are accessible in `clotcad-user`

## 3. Documentation

- [x] 3.1 Add Threading Macros section to `docs/clotcad-api.md` with `->`, `->>`, `as->` signatures and examples
- [x] 3.2 Add `->`, `->>`, `as->` entries to cheatsheet in `docs/cheatsheet/cheatsheet.typ`

## 4. Verify

- [x] 4.1 Run `just test` to confirm all tests pass
