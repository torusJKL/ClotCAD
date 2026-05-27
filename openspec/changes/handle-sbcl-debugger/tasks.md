## 1. Core Infrastructure

- [x] 1.1 Add `*viewer-thread*` variable to `queue.lisp` with initial value `nil`
- [x] 1.2 Export `*viewer-thread*` from `:clotcad.impl` package
- [x] 1.3 Export `global-debugger-hook` from `:clotcad` package (user-facing, can be inspected/unbound)
- [x] 1.4 Export `abort-all-threads` from `:clotcad` package

## 2. Global Debugger Hook

- [x] 2.1 Implement `global-debugger-hook(condition hook)` function in `repl.lisp` that:
      - Wraps body in `handler-case` for self-protection
      - Formats condition type, message, and available restarts as a string
      - Detects Qt main thread via `*viewer-thread*` comparison (eq)
      - On Qt main thread: logs to `*repl-log*`, calls `%viewer-append-repl-output`, invokes `ABORT` restart
      - On worker thread: logs to `*repl-log*` only, invokes `ABORT` restart
      - Falls back to `cl:abort` if no `ABORT` restart exists
      - Records threads in `*stuck-threads*` hash-table
- [x] 2.2 Install hook in `bootstrap` (lifecycle.lisp) before `start-slynk`:
      `(setf sb-ext:*invoke-debugger-hook* 'global-debugger-hook)`
- [x] 2.3 Set `*viewer-thread*` in `start-viewer` immediately before `(%viewer-run vwr)`:
      `(setf *viewer-thread* sb-thread:*current-thread*)`
- [x] 2.4 Reset `*viewer-thread*` to `nil` after `%viewer-run` returns

## 3. GUI REPL Escape Commands

- [x] 3.1 Implement `handle-repl-command(input)` dispatcher in `repl.lisp` that:
      - Detects `,` prefix in REPL input (with whitespace trimming)
      - Routes `,abort` → abort stuck threads
      - Routes `,restart <name>` → abort stuck threads (simple fallback)
      - Routes `,debug` → show debugger status
      - Routes `,errors [N]` → show last N caught errors from `*repl-log*`
      - Routes `,help` / `,?` → list available commands
- [x] 3.2 Implement helper `find-stuck-threads()` that returns list of (thread condition) from `*stuck-threads*`
- [x] 3.3 Implement helper `format-stuck-threads()` that formats stuck thread info for REPL display
- [x] 3.4 Wire dispatcher into `eval-string` callback before normal form evaluation

## 4. SIGUSR1 Escape Handler

- [x] 4.1 Implement `abort-all-threads()` function in `repl.lisp` that:
      - Iterates all threads via `sb-thread:list-all-threads`
      - Skips the current thread (prevents self-interrupt deadlock)
      - For each other thread, wraps access in `handler-case`
      - Uses `sb-thread:interrupt-thread` to find and invoke ABORT restart
- [x] 4.2 Install SIGUSR1 handler in `bootstrap` via `sb-sys:enable-interrupt`:
      `(sb-sys:enable-interrupt sb-unix:sigusr1 (lambda (s) (declare (ignore s)) (abort-all-threads)))`

## 5. Slyc Escape Script

- [x] 5.1 Create `scripts/slyc-debugger-escape.lisp` containing a single form that sends SIGUSR1 to the current process

## 6. User Awareness

- [x] 6.1 Add `*debugger-invocation-count*` variable, incremented each time the hook fires
- [x] 6.2 Export `*debugger-invocation-count*` from `:clotcad`
- [x] 6.3 Implement `,errors [N]` command showing recent caught errors
- [x] 6.4 Implement `,help` command listing available commands

## 7. Tests

- [x] 7.1 Mock `sb-ext:*invoke-debugger-hook*` in `with-mocked-viewer` (not needed - hook tests call function directly)
- [x] 7.2 Test: `global-debugger-hook` logs on error with worker thread detection
- [x] 7.3 Test: `global-debugger-hook` does NOT call viewer functions on worker thread
- [x] 7.4 Test: REPL `,abort` command produces status message
- [x] 7.5 Test: REPL `,debug` command produces status message
- [x] 7.6 Test: `abort-all-threads` is safe to call with no threads in debugger
- [x] 7.7 Test: Hook failure does not enter debugger (self-protection handler-case)
- [x] 7.8 Test: `handle-repl-command` returns nil for non-command input
- [x] 7.9 Test: `eval-string` command dispatch integration
