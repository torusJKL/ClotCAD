## 1. Thread-safe REPL log foundation

- [x] 1.1 Import `sb-ext:atomic-push` in `src/viewer/package.lisp` (in `cl-occt-viewer.impl` package)
- [x] 1.2 Replace `(push ... *repl-log*)` with `(sb-ext:atomic-push ... *repl-log*)` in `eval-string` (repl.lisp:90) and `process-import-tick` (repl.lisp:47)
- [x] 1.3 Add `log-remote-eval` function to `src/viewer/repl.lisp` — accepts `code-str` and `output-str`, uses `sb-ext:atomic-push` to add `(cons code-str output-str)` to `*repl-log*`
- [x] 1.4 Export `log-remote-eval` from `cl-occt-viewer` package in `src/viewer/package.lisp`

## 2. Capture Alive LSP evaluations

- [x] 2.1 Add `log-fn` slot to `state` struct, accessor, and `create` parameter in `lib/alive-lsp/src/session/state.lisp`
- [x] 2.2 Thread `:log-fn` through `accept-conn`, `wait-for-conn`, `listen-for-conns`, `start-server`, `start` in `lib/alive-lsp/src/server.lisp`
- [x] 2.3 Use `state:log-fn` in `handler/eval.lisp` `handle` and `handle-in-frame`, calling the log function with `(code . output)` after eval
- [x] 2.4 In `src/viewer/lifecycle.lisp`, pass `#'log-remote-eval` as `:log-fn` when starting the Alive LSP server

## 3. Capture Slynk evaluations

- [x] 3.1 Wrap `slynk-mrepl:mrepl-eval-1` via `fdefinition` (not `eval-for-emacs`) — captures only user REPL input, not Slynk protocol messages. Wrapping happens lazily inside the Slynk thread loop since the mrepl contrib loads on client connect.
- [x] 3.2 Format: `string` (user input) for code, values formatted with `~S` for output (same as UI REPL)

## 4. Test and verify

- [x] 4.1 No new CFFI calls added — `with-mocked-viewer` needs no update
- [x] 4.2 Add tests: `log-remote-eval-adds-entry` and `log-remote-eval-entries-are-exported` in `t/viewer-tests.lisp`, registered in test suite
- [x] 4.3 Verification: Alive LSP patch follows same pattern as existing `:default-package` — `log-fn` threaded through the same chain (`start` → `start-server` → `listen-for-conns` → `wait-for-conn` → `accept-conn` → `state:create`). Existing `:default-package` flow unchanged.
- [x] 4.4 Verification: Slynk `eval-for-emacs` is replaced via `fdefinition` — preserves original behavior by delegating to the saved original. No Slynk internals modified. Test suite confirms no regressions.
