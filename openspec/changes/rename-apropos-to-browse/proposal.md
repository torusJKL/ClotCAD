## Why

The custom `apropos` macro shadows `cl:apropos`, preventing users in the `:clotcad` and `:clotcad-user` packages from using CL's standard symbol search without explicit package qualification. Renaming to `browse` avoids this conflict and better describes the function's purpose — it's an API browser (category tree, category drill-down, substring search), not a general-purpose symbol searcher. The `help` function currently duplicates what `browse` dynamically provides, creating a maintenance burden as the API grows.

## What Changes

- **Rename `apropos` → `browse`** across all source files, tests, package definitions, and documentation. Remove the `(:shadow :apropos)` from `:clotcad` defpackage and `:shadowing-import-from` from `:clotcad-user`. The old name will not be kept as an alias.
- **Simplify `help` to a minimal quick-start** that points users to `browse` and `doc` for discovery, plus a tiny set of examples that give immediate visual feedback. This reduces maintenance surface — `help` no longer lists every function.
- **Update all internal references** — docstring "See also:" links, formatting strings in `%print-category-tree` and `%print-category-detail`, and the `help` function text itself.

## Capabilities

### New Capabilities
- `help-minimal`: Simplified help that shows only quick-start examples and pointers to `browse`/`doc`, with one working example that gives immediate visual feedback (e.g. `(display "my-box" (make-box 10 10 10))`)

### Modified Capabilities
- `repl-introspect/symbol-apropos-search`: Change the macro name from `apropos` to `browse`. All behavior (substring search, package scoping, case-insensitive matching) stays identical.
- `repl-introspect/apropos-categories`: Change the macro name from `apropos` to `browse` in all three modes (tree, keyword drill-down, substring search). All scenarios and requirements ref:`apropos` → `browse`.

## Impact

- **Source**: `src/package.lisp`, `src/viewer/introspect.lisp`, `src/model/api.lisp` — rename the macro and its helpers, remove shadowing, update help text, update internal format strings
- **Tests**: `t/viewer-tests.lisp` — rename all `apropos` test function names and `(apropos ...)` calls
- **Docs**: `docs/clotcad-api.md` — rename all refs; `docs/cheatsheet/cheatsheet.typ` — rename entry
- **Specs**: `openspec/specs/repl-introspect/symbol-apropos-search/spec.md` — rename macro; `openspec/specs/repl-introspect/apropos-categories/spec.md` — rename macro
- **Archived history**: `openspec/changes/archive/2026-05-26-repl-introspect-commands/` — leave unchanged (historical record)
