## 1. Source: Rename `apropos` → `browse` in introspect.lisp

- [x] 1.1 Rename macro `apropos` → `browse`, update the `;; apropos` section header
- [x] 1.2 Rename `apropos-impl` → `browse-impl`
- [x] 1.3 Rename `%apropos-tree` → `%browse-tree`
- [x] 1.4 Rename `%apropos-category` → `%browse-category`
- [x] 1.5 Rename `%apropos-substring-search` → `%browse-substring-search`
- [x] 1.6 Update format strings in `%print-category-tree` and `%print-category-detail`: `(apropos ...)` → `(browse ...)`
- [x] 1.7 Update docstring `"See also:"` references in `doc-impl` and `doc` macros (two locations)

## 2. Source: Update package.lisp

- [x] 2.1 Remove `(:shadow :apropos)` from `:clotcad` defpackage
- [x] 2.2 Change exported symbol from `:apropos` → `:browse`
- [x] 2.3 Remove `:apropos` from `:shadowing-import-from` in `:clotcad-user` defpackage

## 3. Source: Simplify help in api.lisp

- [x] 3.1 Rewrite `help()` to show minimal quick-start with tagline, pointers to `(browse)` and `(doc ...)`, a visual feedback example like `(display "my-box" (make-box 10 10 10))`, and brief essential-command reference
- [x] 3.2 Remove the hard-coded categorized function listing from `help()` (no more "3D Primitives:", "Boolean Operations:", etc.)
- [x] 3.3 Update the `(apropos pattern)` line in help to `(browse pattern)`

## 4. Tests: Rename in viewer-tests.lisp

- [x] 4.1 Rename all `deftest apropos-*` test names to `browse-*`
- [x] 4.2 Rename all `(apropos ...)` calls in test bodies to `(browse ...)`

## 5. Docs: Update external documentation

- [x] 5.1 Rename all `apropos` refs to `browse` in `docs/clotcad-api.md`
- [x] 5.2 Rename `apropos` entry to `browse` in `docs/cheatsheet/cheatsheet.typ`

## 6. Specs: Update golden specs

- [x] 6.1 Update `openspec/specs/repl-introspect/symbol-apropos-search/spec.md` — rename all `apropos` → `browse`, remove shadowing note, update `apropos-impl` → `browse-impl`
- [x] 6.2 Update `openspec/specs/repl-introspect/apropos-categories/spec.md` — rename all `apropos` → `browse`

## 7. Verify

- [x] 7.1 Run `just test` to verify all tests pass with the rename
- [x] 7.2 Verify no remaining references to `(apropos` or `:apropos` in active source code (excluding archived changes)
