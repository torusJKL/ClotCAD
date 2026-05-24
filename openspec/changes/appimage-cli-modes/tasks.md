## 1. Lisp Refactor — Extract headless entry points

- [x] 1.1 Extract Slynk startup code from `bootstrap` into a standalone `start-slynk` function accepting `&key (port 4005)`
- [x] 1.2 Extract Alive LSP startup code from `bootstrap` into a standalone `start-alive` function accepting `&key (port 4006)`
- [x] 1.3 Rewrite `bootstrap` to call `start-slynk` and `start-alive` then `start-viewer`
- [x] 1.4 Add `wait-forever` function with `handler-case` for `interactive-interrupt` and `terminate-interrupt`
- [x] 1.5 Export `start-slynk`, `start-alive`, and `wait-forever` from the `clotcad` package

## 2. AppRun — Mode routing

- [x] 2.1 Add `case` dispatch on `$1` for `--viewer`, `--slynk`, `--alive`
- [x] 2.2 Implement flag parsing (`-p`/`--port`, `-a`/`--alive-port`) for each mode
- [x] 2.3 Set `QT_QPA_PLATFORM=offscreen` in `--slynk` and `--alive` branches
- [x] 2.4 Preserve default behavior (no args = viewer with default ports)
- [x] 2.5 Add usage message for unknown modes

## 3. Tests

- [x] 3.1 Add test coverage for `start-slynk`, `start-alive`, and `wait-forever` in `t/viewer-tests.lisp` using mocked CFFI
- [x] 3.2 Test that `bootstrap` still works correctly after refactor (existing test covers this)
