## 1. Rename viewer functions

- [x] 1.1 Rename `fit-all` to `fit-view` in `src/viewer/ui.lisp`
- [x] 1.2 Rename `set-antialiasing` to `set-view-aa` in `src/viewer/ui.lisp`
- [x] 1.3 Update exports in `src/viewer/package.lisp` (`cl-occt-viewer.impl` and `cl-occt-viewer`)

## 2. Create workspace package

- [x] 2.1 Add `:cl-occt-user` package definition in `src/viewer/package.lisp` with `:use :cl :cl-occt :cl-occt-viewer` and nicknames `:cad-user`, `:occt-user`
- [x] 2.2 Register `:cl-occt-user` as a dependency in `cl-occt-viewer.asd` (it needs `:cl-occt-viewer` loaded first) — no ASDF changes needed, package is defined in the same source file

## 3. Update startup

- [x] 3.1 Change `start.lisp` from `(in-package :cl-occt-viewer)` to `(in-package :cl-occt-user)`

## 4. Update tests

- [x] 4.1 Rename test function `set-antialiasing-calls-c-api` → `set-view-aa-calls-c-api` and update calls to use new name
- [x] 4.2 Rename test function `fit-all-calls-c-api` → `fit-view-calls-c-api` and update calls to use new name
- [x] 4.3 Update test runner references in `t/viewer-tests.lisp`
- [x] 4.4 Add test for `cl-occt-user` package existence and symbol accessibility

## 5. Update documentation

- [x] 5.1 Update `README.md` Usage section to show unqualified calls (e.g., `(make-sphere 20)`)
- [x] 5.2 Update `README.md` Usage section to use `fit-view` and `set-view-aa` in examples
- [x] 5.3 Add `cl-occt-user` to the Files section in `README.md`
- [x] 5.4 Add workspace package section to `README.md` explaining the convenience layer

## 6. Verify

- [x] 6.1 Run test suite (`just test`) and confirm all tests pass — 74 pass, 0 fail
