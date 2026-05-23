## 1. ASDF System Definition

- [x] 1.1 Rename `cl-occt-viewer.asd` to `clotcad.asd`
- [x] 1.2 Change `defsystem :cl-occt-viewer` to `:clotcad` and update description
- [x] 1.3 Change `defsystem :cl-occt-viewer/tests` to `:clotcad/tests` and update description + dependency

## 2. Lisp Package Definitions

- [x] 2.1 In `src/viewer/package.lisp`, rename `:cl-occt-viewer.impl` to `:clotcad.impl`
- [x] 2.2 In `src/viewer/package.lisp`, rename `:cl-occt-viewer` to `:clotcad` (update `:use` clause)
- [x] 2.3 In `src/viewer/package.lisp`, rename `:cl-occt-user` to `:clotcad-user` (update `:use` clause, shadowing imports, and nicknames)

## 3. Source File `in-package` Forms

- [x] 3.1 Update `(in-package :cl-occt-viewer.impl)` in `bindings.lisp`
- [x] 3.2 Update `(in-package :cl-occt-viewer)` in `lifecycle.lisp`, `ops.lisp`, `queue.lisp`, `render.lisp`, `repl.lisp`, `select.lisp`, `theme.lisp`, `ui.lisp`
- [x] 3.3 Update `(in-package :cl-occt-viewer)` in `t/viewer-tests.lisp`

## 4. Qualified Symbol References

- [x] 4.1 In `bindings.lisp:6`, update `asdf:system-source-directory :cl-occt-viewer` to `:clotcad`
- [x] 4.2 In `bindings.lisp:3-7`, update foreign library name and `.so` paths from `libocctviewer` to `libclotcad`
- [x] 4.3 In `repl.lisp:224-226`, update `cl-occt-viewer.impl:%viewer-*` to `clotcad.impl:%viewer-*`
- [x] 4.4 In `t/viewer-tests.lisp`, update all qualified symbol references (`cl-occt-viewer::*` → `clotcad::*`)
- [x] 4.5 In `t/viewer-tests.lisp`, update test description string (`"=== cl-occt-viewer tests ==="`)

## 5. CMake Build System

- [x] 5.1 Update CMake project name from `occt-viewer-qt` to `ClotCAD`
- [x] 5.2 Update CMake target `occtviewer` to `clotcad` throughout (add_library, target_compile_definitions, qt6_add_resources, target_include_directories, target_link_libraries, install)
- [x] 5.3 Update `justfile` references: echo description, `libocctviewer.so` → `libclotcad.so`, test system name, in-package name

## 6. Build Scripts

- [x] 6.1 Update `scripts/run.sh` — change `(cl-occt-viewer:bootstrap)` to `(clotcad:bootstrap)`
- [x] 6.2 Update `scripts/start.lisp` — change `:cl-occt-viewer` → `:clotcad`, `:cl-occt-user` → `:clotcad-user`, `"CL-OCCT-USER"` → `"CLOTCAD-USER"`
- [x] 6.3 Update `scripts/make-core.lisp` — change `:cl-occt-viewer` to `:clotcad`
- [x] 6.4 Update `scripts/package.sh` — change all `libocctviewer.so` to `libclotcad.so`

## 7. Documentation

- [x] 7.1 Update `README.md` — change all `cl-occt-viewer` and `libocctviewer.so` references
- [x] 7.2 Update `docs/clotcad-api.md` — change `CL-OCCT-VIEWER` and `CL-OCCT-USER` references
- [x] 7.3 Update `CHANGELOG.md` — update `CL-OCCT-USER` references to `CLOTCAD-USER`
- [x] 7.4 Add translation matrix to `AGENTS.md` mapping all old names to new names

## 8. Verification

- [x] 8.1 Run `just test` to verify the Lisp test suite passes
  *(120/120 pass, 0 fail, 0 errors)*
- [x] 8.2 Run `just viewer` to verify the C++ shared library builds
  *(Built: lib/libclotcad.so, 1MB)*
- [x] 8.3 Verify `just start` launches correctly — works with REPL and viewer commands
