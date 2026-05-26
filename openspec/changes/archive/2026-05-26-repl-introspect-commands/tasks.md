## 1. File Setup

- [x] 1.1 Create `src/viewer/introspect.lisp` with `(in-package :clotcad)` header
- [x] 1.2 Add introspect.lisp to `clotcad.asd` in the `viewer` module, between `repl` and `ui` in serial order

## 2. Implement `doc` Function

- [x] 2.1 Implement symbol resolution: accept symbol, string, or function object; resolve bare symbols in current `*package*`
- [x] 2.2 Iterate documentation types in order: `function`, `variable`, `type`, `structure`, `class`, stop at first match
- [x] 2.3 Extract arglist via `sb-kernel:%fun-lambda-list` for functions/macros, wrapped in `ignore-errors`
- [x] 2.4 Format output as `FULL-NAME (arglist)` header line, package line, then docstring body
- [x] 2.5 Print "No documentation found for SYMBOL" when nothing matches
- [x] 2.6 Return `nil` from `doc` after printing

## 3. Implement `apropos` Function

- [x] 3.1 Accept string or symbol pattern; convert to string for case-insensitive substring matching
- [x] 3.2 Determine target packages: default `(:clotcad :cl-occt)`, `:packages t` means all, or explicit list
- [x] 3.3 Walk each target package, find symbols whose name contains the substring
- [x] 3.4 Categorize each match by type: function, macro, variable, class, or symbol
- [x] 3.5 Format output grouped by package with type annotations
- [x] 3.6 Print "No matches found..." when nothing matches
- [x] 3.7 Support `:case-insensitive` keyword (default `t`)
- [x] 3.8 Return `nil` from `apropos` after printing

## 4. Export and Package

- [x] 4.1 Export `doc` and `apropos` from the `:clotcad` package in `src/package.lisp`
- [x] 4.2 Verify both symbols are accessible in `:clotcad-user` (inherits from `:clotcad`)

## 5. Update `help()` and Integration

- [x] 5.1 Add `doc` and `apropos` entries to the `help()` function in `src/model/api.lisp`
- [x] 5.2 Verify `doc` and `apropos` work correctly in the Qt REPL (output goes through `eval-string` callback to `*standard-output*`)

## 6. Tests

- [x] 6.1 Test `doc` on a function: verify output includes name, arglist, and docstring
- [x] 6.2 Test `doc` on a variable: verify output includes name and docstring
- [x] 6.3 Test `doc` on a macro: verify output includes arglist and docstring
- [x] 6.4 Test `doc` on undocumented symbol: verify "No documentation found" message
- [x] 6.5 Test `doc` on a string and function object: verify same as symbol
- [x] 6.6 Test `doc` on a CFFI callback: verify no arglist error
- [x] 6.7 Test `apropos` substring matching in default packages
- [x] 6.8 Test `apropos` with `:packages t` (all packages)
- [x] 6.9 Test `apropos` with explicit package list
- [x] 6.10 Test `apropos` with no matches
- [x] 6.11 Test `apropos` with `:case-insensitive nil`
- [x] 6.12 Test both functions return `nil`

## 7. Documentation

- [x] 7.1 Add `doc` and `apropos` to `docs/clotcad-api.md` under a new "Introspection" section
- [x] 7.2 Add `doc` and `apropos` to `docs/cheatsheet/cheatsheet.typ` under a new "Introspection" section
