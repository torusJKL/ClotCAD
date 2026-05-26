## Why

The ClotCAD REPL has no lightweight way to inspect symbol documentation, arglists, or discover API symbols. Users must either recall the `documentation` type parameter (`'function`, `'variable`) or use `describe` which dumps verbose implementation details. Clojure's `doc` and `apropos` provide a simpler model — one command works for any symbol type.

## What Changes

- New `(doc name)` macro: prints docstring and arglist for any symbol (function, macro, variable, type, class) without requiring a type argument; implemented as a macro that auto-quotes bare symbols, backed by `doc-impl` function
- New `(apropos pattern)` macro: searches for symbols matching a substring, defaulting to `:clotcad` and `:cl-occt` packages with optional wider scope; implemented as a macro that auto-quotes bare symbols, backed by `apropos-impl` function
- `(:shadow :apropos)` in `:clotcad` package and `:shadowing-import-from` in `:clotcad-user` to work around CL package lock on `cl:apropos`
- New `src/viewer/introspect.lisp` file containing both macro/function pairs
- Export both symbols from `:clotcad` package (available in `:clotcad-user`)
- Update `eval-string` callback and `process-import-tick` in `repl.lisp` to capture `*standard-output*` during eval, so printed output (from `doc`, `apropos`, `help`, etc.) appears in the GUI REPL instead of the terminal
- Update `help()` output to mention the new commands
- Update `docs/clotcad-api.md` with new functions
- Update `docs/cheatsheet/cheatsheet.typ` with new functions

## Capabilities

### New Capabilities

- `symbol-doc-lookup`: Print docstring and arglist for any named symbol, auto-detecting its type (function, macro, variable, type, class)
- `symbol-apropos-search`: Search packages for symbols matching a substring, with type-categorized output and smart default scope

### Modified Capabilities

*(No existing capability specs are changing.)*

## Impact

- **New file**: `src/viewer/introspect.lisp`
- **Modified**: `clotcad.asd` (add file to viewer module), `src/viewer/repl.lisp` (update `help()`), `docs/clotcad-api.md`, `docs/cheatsheet/cheatsheet.typ`
- **Dependencies**: `sb-kernel` (already present in SBCL, no require needed) for `%fun-lambda-list` arglist extraction
- **No breaking changes**: All existing APIs remain unchanged
