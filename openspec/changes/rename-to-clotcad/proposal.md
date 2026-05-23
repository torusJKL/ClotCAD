## Why

The project has been branded as "ClotCAD" throughout its UI, documentation, and distribution (logo, About dialog, cheatsheet, website references), but the mechanical names — ASDF system, Lisp packages, CMake target, shared library — still use the legacy name `cl-occt-viewer`. This inconsistency causes confusion: users see "ClotCAD" in the UI but must type `(ql:quickload :cl-occt-viewer)` in their editor. A full rename aligns the project identity with its brand name.

## What Changes

- **BREAKING**: Rename ASDF system from `:cl-occt-viewer` to `:clotcad`
- **BREAKING**: Rename ASDF test system from `:cl-occt-viewer/tests` to `:clotcad/tests`
- **BREAKING**: Rename Lisp packages from `:cl-occt-viewer.impl`, `:cl-occt-viewer`, `:cl-occt-user` to `:clotcad.impl`, `:clotcad`, `:clotcad-user`
- **BREAKING**: Rename CMake project from `occt-viewer-qt` to `ClotCAD` and CMake target from `occtviewer` to `clotcad`, producing `libclotcad.so` instead of `libocctviewer.so`
- Rename `.asd` file from `cl-occt-viewer.asd` to `clotcad.asd`
- Update foreign library definition in `bindings.lisp` to reference `libclotcad.so`
- Update all `in-package` forms and qualified symbol references in Lisp source
- Update build scripts: `justfile`, `scripts/run.sh`, `scripts/start.lisp`, `scripts/make-core.lisp`, `scripts/package.sh`
- Update documentation: `README.md`, `AGENTS.md`, `docs/clotcad-api.md`, `CHANGELOG.md`
- Add a translation matrix to `AGENTS.md` mapping old names → new names for historical reference
- Leave OpenSpec archive documents unchanged (historical records)

## Capabilities

### New Capabilities

None — this is a rename, no new functionality is introduced.

### Modified Capabilities

None — behavior and APIs are identical; only names change.

## Impact

- **All Lisp source files** — every `in-package` form, every qualified symbol reference
- **ASDF system definition** — file rename + system name
- **CMake build** — project name, target name, output `.so` filename
- **Build scripts** — justfile, shell scripts, Lisp bootstrap scripts
- **Documentation** — README, AGENTS.md, API docs, changelog
- **Downstream consumers** — any code doing `(ql:quickload :cl-occt-viewer)` or `(in-package :cl-occt-viewer)` must update
