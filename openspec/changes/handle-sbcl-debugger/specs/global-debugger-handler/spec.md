## ADDED Requirements

### Requirement: Global debugger hook installed at startup

The system SHALL install a global `sb-ext:*invoke-debugger-hook*` in the `bootstrap` function, before starting Slynk or Alive LSP. The hook SHALL catch all unhandled conditions on every thread and prevent the SBCL interactive debugger from appearing.

#### Scenario: Hook installed before services start

- **WHEN** `bootstrap` is called
- **THEN** `sb-ext:*invoke-debugger-hook*` SHALL be bound to a function before `start-slynk` and `start-alive` are called

#### Scenario: Hook does not interfere with Alive LSP's per-thread hook

- **WHEN** Alive LSP evaluates a form via `run-with-debugger`
- **THEN** Alive LSP's per-thread `sb-ext:*invoke-debugger-hook*` SHALL take precedence over the global hook
- **THEN** conditions during Alive LSP eval SHALL be reported to the LSP client via the existing `$/alive/debugger` mechanism

### Requirement: Hook logs and aborts on Qt main thread

When an unhandled condition occurs on the Qt main thread, the hook SHALL log the condition type and message to `*repl-log*`, append the error to the REPL output widget, and invoke the `ABORT` restart to return control to the Qt event loop.

#### Scenario: Error on Qt main thread displays in REPL and aborts

- **WHEN** an unhandled error occurs on the Qt main thread (e.g., in a CFFI callback not wrapped in `handler-case`)
- **THEN** the hook SHALL push a `(code-str . output-str)` pair to `*repl-log*` via `sb-ext:atomic-push`
- **THEN** the hook SHALL call `%viewer-append-repl-output` with a message describing the condition
- **THEN** the hook SHALL invoke the `ABORT` restart
- **THEN** the SBCL debugger SHALL NOT appear
- **THEN** the Qt event loop SHALL continue running

#### Scenario: Hook is safe to call regardless of viewer state

- **WHEN** an unhandled error occurs before `*viewer*` is bound (e.g., during `initialize-viewer`)
- **THEN** the hook SHALL NOT call any `%viewer-*` function
- **THEN** the hook SHALL still log to `*repl-log*` and invoke the `ABORT` restart

### Requirement: Hook logs and aborts on worker threads

When an unhandled condition occurs on a worker thread (Slynk thread, Alive LSP thread, render thread), the hook SHALL log the condition to `*repl-log*` (thread-safe via `sb-ext:atomic-push`) and invoke the `ABORT` restart on that thread. It SHALL NOT call any Qt functions.

#### Scenario: Error on worker thread logs to REPL log and aborts

- **WHEN** an unhandled error occurs on a thread that is not the Qt main thread
- **THEN** the hook SHALL push a condition message to `*repl-log*`
- **THEN** the hook SHALL NOT call `%viewer-append-repl-output` or any other `%viewer-*` function
- **THEN** the hook SHALL invoke the `ABORT` restart on that thread
- **THEN** the SBCL debugger SHALL NOT appear

#### Scenario: Worker thread continues after abort

- **WHEN** an unhandled error occurs on the render thread and the hook invokes ABORT
- **THEN** the render thread SHALL continue its loop (the ABORT restart unwinds to the top level of the thread's start function)

### Requirement: Hook wraps itself in error handling

The global hook function SHALL wrap its entire body in `handler-case` to prevent its own failure from entering the debugger.

#### Scenario: Hook failure writes to stderr

- **WHEN** the hook's own execution signals an error (e.g., `*repl-log*` is not bound)
- **THEN** the hook SHALL catch the error with `handler-case`
- **THEN** the hook SHALL write an error message to `*error-output*`
- **THEN** the hook SHALL invoke `sb-debug:abort` as final fallback
- **THEN** the SBCL debugger SHALL NOT appear

### Requirement: Qt main thread detection via `*viewer-thread-id*`

The system SHALL introduce a special variable `*viewer-thread-id*` that stores the SBCL thread ID of the Qt main thread. The hook SHALL detect whether it is on the Qt main thread by comparing the current thread's ID to `*viewer-thread-id*`.

#### Scenario: *viewer-thread-id* set before Qt event loop

- **WHEN** `start-viewer` is called and `%viewer-run` is about to enter the Qt event loop
- **THEN** `*viewer-thread-id*` SHALL be set to `(sb-thread:thread-id (sb-thread:current-thread))`

#### Scenario: Hook detects Qt main thread

- **WHEN** the hook is called and `(sb-thread:thread-id (sb-thread:current-thread))` equals `*viewer-thread-id*`
- **THEN** the hook SHALL consider itself on the Qt main thread and may call `%viewer-append-repl-output`
