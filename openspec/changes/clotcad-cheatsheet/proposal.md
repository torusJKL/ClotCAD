## Why

ClotCAD has no quick reference for its API. New users must read the README or browse source files to find function signatures. A cheatsheet — divided by subject with function signatures and compact examples — solves this. The Parametric DSL in particular is novel and deserves visual prominence with syntax-highlighted examples.

## What Changes

- Create `docs/cheatsheet/main.typ` — a multi-page Typst document using the boxed-sheet template
- Add a `cheatsheet` recipe to the `justfile`
- Version string injected from `git describe` via `typst --input version=...` into the document header
- 4-5 pages covering: 3D primitives, sweeps, boolean ops, transforms, 2D geometry, display management, selection, view controls, theme/UI, parametric DSL (with examples), compounds/assemblies, file I/O, REPL commands
- Functions shown as signatures only (no descriptions), except DSL which gets a few compact Lisp syntax-highlighted examples
- Cousine monospace font, ~7.5pt, 3-column layout, color-coded by section

## Capabilities

### New Capabilities
- `cheatsheet`: The Typst cheatsheet document — content, layout, build integration, and version injection

### Modified Capabilities

None.

## Impact

- **New file**: `docs/cheatsheet/main.typ` (~300 lines)
- **Modified file**: `justfile` (+1 recipe)
- **No code changes** to Lisp, C++, or any build system
