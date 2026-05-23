## Context

The project `cl-occt-viewer` wraps an OCCT 3D viewer as a shared library with Lisp CFFI bindings. Its mechanical names were chosen early in development when the project was primarily a viewer library for `cl-occt`. Over time it has evolved into a standalone parametric CAD application branded "ClotCAD", but the internal names never caught up.

The rename touches three layers:
- **Lisp**: ASDF system name, package names, qualified symbol references
- **C++/CMake**: CMake project name, CMake target name (→ shared library filename)
- **Shell/docs**: Scripts, README, AGENTS.md

## Goals / Non-Goals

**Goals:**
- Rename ASDF system from `:cl-occt-viewer` to `:clotcad`
- Rename test system from `:cl-occt-viewer/tests` to `:clotcad/tests`
- Rename Lisp packages `:cl-occt-viewer.impl` → `:clotcad.impl`, `:cl-occt-viewer` → `:clotcad`, `:cl-occt-user` → `:clotcad-user`
- Rename CMake project and target to produce `libclotcad.so`
- Update all scripts, documentation, and references
- Provide a backward-compatibility reference (translation matrix)
- Keep the existing code architecture, test strategy, and CFFI interface intact

**Non-Goals:**
- Renaming C++ source files (`occt_viewer.cpp`, `occt_viewer.h`) — these are internal implementation details
- Renaming the opaque pointer type `occt_viewer` — this is a CFFI opaque handle managed by the C++ side
- Renaming the external `cl-occt` submodule — that is a separate dependency
- Updating OpenSpec archive documents — left as historical records
- Changing any behavior, API signatures, or functionality

## Decisions

### Decision 1: Package naming scheme

| Old Name | New Name | Rationale |
|---|---|---|
| `:cl-occt-viewer.impl` | `:clotcad.impl` | Implementation package, matches brand |
| `:cl-occt-viewer` | `:clotcad` | Public API package, matches brand |
| `:cl-occt-user` | `:clotcad-user` | Workspace package; renamed for consistency, but note it still `:use`s the external `:cl-occt` package |

The nickname `:cad-user` is kept as a convenient shorthand. No new nicknames added.

### Decision 2: Shared library naming

The CMake target `occtviewer` becomes `clotcad`, producing `libclotcad.so` instead of `libocctviewer.so`. The Lisp foreign library definition in `bindings.lisp` is updated to match. This is a mechanical change with no behavioral impact — `LD_LIBRARY_PATH` already includes the `lib/` directory, so the runtime linker finds the `.so` by path regardless of filename.

### Decision 3: Execution order

The rename runs in dependency order:
1. **ASDF file** — rename + edit first so the system can be loaded
2. **Lisp packages** — package.lisp is the root of all other sources
3. **Lisp source files** — update `in-package` forms
4. **Qualified symbol refs** — repl.lisp, viewer-tests.lisp, bindings.lisp
5. **Foreign library** — bindings.lisp `.so` references
6. **CMake** — project name + target, affects build
7. **Scripts** — justfile, shell scripts, Lisp bootstrap
8. **Documentation** — README, AGENTS.md, API docs, changelog
9. **Translation matrix** — final addition to AGENTS.md

## Risks / Trade-offs

- **[Breaking change]** Any downstream code using `(ql:quickload :cl-occt-viewer)` or `(in-package :cl-occt-viewer)` will break. Mitigation: the translation matrix in AGENTS.md provides the mapping for manual migration. Given the project's maturity this is acceptable.
- **[Stale references in archives]** OpenSpec archive documents reference old names. Mitigation: explicitly excluded from rename per scope decision.
- **[Test disruption]** The test file has 23+ qualified symbol references that must all be updated. Mitigation: run test suite after rename to catch any missed refs.
- **[Shared library name change]** If other projects depend on `libocctviewer.so` by name, they will break. Mitigation: this is an internal artifact — external consumers load via CFFI at the Lisp level, not by direct `.so` reference.
