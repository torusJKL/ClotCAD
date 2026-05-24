## 1. Core Implementation

- [x] 1.1 Add `(quit-clotcad)` function to `src/viewer/lifecycle.lisp`
- [x] 1.2 Function stops Slynk via `slynk:stop-server` (using `find-symbol`, guarded with `handler-case`)
- [x] 1.3 Function stops Alive LSP via `alive/server:stop` (using `find-symbol`, guarded with `handler-case`)
- [x] 1.4 Function stops viewer: `stop-render-loop`, `%viewer-quit`, `%viewer-destroy`, clear `*viewer*` / `*viewer-running*`
- [x] 1.5 Function resets Lisp state: clear `*repl-log*`, `*displayed-models*`, `*repl-accumulator*`, `*import-forms*`, `*selected*`
- [x] 1.6 Function calls `(sb-ext:quit)` as final step
- [x] 1.7 Add docstring to `quit-clotcad` documenting all modes and behavior

## 2. Package Exports

- [x] 2.1 Export `quit-clotcad` from `:clotcad.impl` package in `src/package.lisp`
- [x] 2.2 Export `quit-clotcad` from `:clotcad` package in `src/package.lisp`

## 3. Bug Fix

- [x] 3.1 Fix `:default-package "CL-OCCT-USER"` → `"CLOTCAD-USER"` on line 111 of `src/viewer/lifecycle.lisp`

## 4. Documentation

- [x] 4.1 Add `quit-clotcad` to the README in the headless/remote usage section
- [x] 4.2 Document that it works in all modes (`--viewer`, `--slynk`, `--alive`) and disconnects the caller

## 5. Tests

- [x] 5.1 Add test: `quit-clotcad` is fbound
- [x] 5.2 Add test: `quit-clotcad` is accessible from `:clotcad` and `:clotcad-user` packages
- [x] 5.3 Add test: `quit-clotcad` calls `%viewer-quit` and `%viewer-destroy` when viewer is running
- [x] 5.4 Register `quit-clotcad` tests in the test runner suite at the bottom of `t/viewer-tests.lisp`

## 6. Verification

- [x] 6.1 Run the test suite with `just test` and confirm all tests pass
