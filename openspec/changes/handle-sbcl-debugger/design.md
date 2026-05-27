## Context

When a form sent via Slynk or Alive LSP triggers an unhandled condition — or when an error escapes any CFFI callback on the Qt main thread — SBCL enters its interactive debugger. If entered on the Qt main thread, the entire viewer UI freezes. The CLI tool `slyc` cannot interact with the debugger's recursive REPL within the thread.

The codebase already has per-callback `handler-case` wrappers in `eval-string`, `process-import-tick`, and `handle-file-op`. However:
- The `drain-queue-callback` itself is unprotected (errors during `sync-viewer` or shape allocation escape).
- The render loop in `render.lisp` has no error handling.
- Alive LSP already installs per-thread debugger hooks (`threads.lisp:run-with-debugger`), but these only cover the Alive eval thread.
- Slynk relies on its own internal debugger protocol — if that fails, the raw SBCL debugger appears.

No global `*debugger-hook*` or `sb-ext:*invoke-debugger-hook*` is installed anywhere in ClotCAD's own code.

## Goals / Non-Goals

**Goals:**
- Prevent the SBCL interactive debugger from ever blocking a thread during normal viewer operation.
- Catch all unhandled conditions, log them to `*repl-log*`, and abort back to the top level safely.
- Provide a GUI-based escape mechanism (via the Qt REPL) to abort if the debugger is somehow entered.
- Provide a CLI-based escape mechanism (via `slyc --eval`) to unstick the process remotely.
- Cooperate with Alive LSP's existing per-thread debugger hooks (Alive's hook takes precedence during its evals).
- Thread-safe: behavior differs safely between Qt main thread and worker threads.

**Non-Goals:**
- Not a full condition handling system (no condition restarts, no interactive debugging from the GUI).
- Not modifying Alive LSP's internal debugger protocol (conditions are still reported to the LSP client).
- Not modifying Slynk's debugger protocol.
- Not retrofitting every existing call site with additional error handling.

## Decisions

### Decision 1: Global `sb-ext:*invoke-debugger-hook*` over per-thread hooks

Install a single global `sb-ext:*invoke-debugger-hook*` in `bootstrap`, before starting any services.

**Rationale:**
- `sb-ext:*invoke-debugger-hook*` is called BEFORE the debugger is entered — we can abort without any debugger UI ever appearing.
- A per-thread binding in Alive LSP's `run-with-debugger` will shadow the global hook for Thread 4006, which is correct — Alive's own handler manages debugger communication with the LSP client.
- The global hook acts as the ultimate safety net for all threads, including Slynk's threads, the Qt main thread, and the render thread.
- **Alternative considered:** Wrapping each CFFI callback individually. This was rejected because it doesn't protect threads that aren't callbacks (e.g., Slynk worker threads, Alive's own threads if its hook fails).

### Decision 2: Hook behavior differs by thread context

The global hook function detects whether it is on the Qt main thread and behaves accordingly:

| Thread | Action |
|---|---|
| Qt main thread | Log to `*repl-log*`, call `%viewer-append-repl-output` (safe, we're on the main thread), increment `*debugger-invocation-count*`, clean up `*stuck-threads*`, return. Never invoke external restarts. |
| Worker thread | Log to `*repl-log*` only (thread-safe atomics), do NOT call Qt functions, increment `*debugger-invocation-count*`, clean up `*stuck-threads*`, return. Never invoke external restarts. |

**Rationale:**
- Calling `%viewer-append-repl-output` from a non-Qt thread would crash or corrupt Qt's internal state.
- `*repl-log*` uses `sb-ext:atomic-push`, which is lock-free and safe from any thread.
- **Alternative considered:** Invoking the ABORT restart. Rejected because CFFI/Qt establish ABORT restarts around callbacks; invoking them from the hook causes a crash on the Qt main thread.
- **Alternative considered:** Always use `%viewer-append-repl-output` (simpler). Rejected because it's unsafe from worker threads.

### Decision 3: Thread detection via `*viewer-thread*`

Store the thread object `sb-thread:*current-thread*` in `*viewer-thread*` at the start of `%viewer-run`. The hook compares with `eq` to determine if it's on the Qt main thread.

**Rationale:**
- Thread name strings are mutable and unreliable for identification.
- `sb-thread:thread-id` is not available in all SBCL versions. The thread object is stable and `eq` comparison is reliable.
- **Alternative considered:** Thread name matching (e.g., searching for "qt" in the name). Rejected because the Qt thread name is not guaranteed — it depends on when and how Qt names its thread internally.

### Decision 4: GUI escape via `,` REPL command prefix

Extend the `eval-string` callback to recognize commands starting with `,`:
- `,abort` — Iterate `*stuck-threads*` and interrupt each stuck thread with ABORT restart.
- `,restart` — Fallback to `,abort` behavior.
- `,debug` — Display stuck threads from `*stuck-threads*`.
- `,errors [N]` — Show last N errors from `*repl-log*` that were caught by the hook.
- `,help` — List all available commands.

**Rationale:**
- Commands starting with `,` work when the Qt main thread is not stuck (eval-string runs on Qt thread). If the Qt thread IS stuck, recovery goes through SIGUSR1.
- The `,` prefix convention is familiar from SLIME's `,` commands.
- `*debugger-invocation-count*` provides a lightweight check: user can poll `*debugger-invocation-count*` to detect if an error was silently caught.
- The hook toggle commands (`,debugger-off`/`,debugger-on`) were considered but removed — they have no visible effect from the Qt REPL (which wraps eval in `handler-case`) or from SLY (which handles errors before they reach `invoke-debugger`). The hook's behavior is always-on for non-Slynk threads.
- **Alternative considered:** A dedicated button in the GUI. Rejected because it requires modifying C++ code in `wrap/`. The REPL approach is purely Lisp-side.

### Decision 5: CLI escape via SIGUSR1 signal handler

Install a `sb-sys:enable-interrupt` handler for `SIGUSR1` in `bootstrap`. The handler iterates all threads, finds any that are in the debugger, and aborts them.

The `scripts/slyc-debugger-escape.lisp` script sends SIGUSR1 to the ClotCAD process:

```lisp
;; evaluable via slyc --eval
(sb-unix:unix-kill (sb-unix:unix-getpid) sb-unix:sigusr1)
```

Or from the shell:
```sh
kill -USR1 <pid>
```

**Rationale:**
- Signals interrupt any thread atomically — even if Slynk or Alive is blocked in the debugger.
- SIGUSR1 is not used by any other part of the system.
- **Alternative considered:** Relying on Slynk to still be responsive. Rejected because if Slynk's own thread enters the debugger, it cannot process new eval requests.

### Decision 6: Hook wraps itself in `handler-case`

The global hook function must never itself cause a debugger entry. The entire body is wrapped in `handler-case (error (e) ...)` that writes to `*error-output*` as a last resort.

**Rationale:**
- A failing debugger hook is catastrophic — it would cause infinite recursion or a hard crash.
- Last-resort error output is better than a hung process.

## Risks / Trade-offs

**[Risk] Hook suppresses useful debugging information** → The condition message, type, and available restarts are all logged to `*repl-log*`. The `,errors` REPL command and `*debugger-invocation-count*` provide quick access. The user can poll `*debugger-invocation-count*` to detect silent errors.

**[Risk] Hook doesn't affect SLY eval errors** → Slynk catches errors in its eval wrapper before they reach `invoke-debugger`, so the global hook is never consulted for errors during SLY eval. The user always gets the SLY debugger for remote evals — which is desired behavior. The hook only protects the Qt main thread and non-Slynk threads (render loop, callbacks).

**[Risk] Hook toggle appears invisible from REPL** → The Qt REPL wraps eval in `handler-case`, so `(error "test")` never reaches `invoke-debugger`. The hook's effect is only visible when errors occur in callbacks like `drain-queue-callback` or the render loop. `*debugger-invocation-count*` and `,errors` provide the only way to detect silent hook invocations.

**[Risk] `%viewer-append-repl-output` might not be safe during early startup** → The hook checks `*viewer*` is non-nil before calling any viewer functions. During `bootstrap`, before `start-viewer`, the hook will just log to `*repl-log*`.

**[Risk] SIGUSR1 conflicts with other uses** → Check that no other component in the system (OCCT, Qt) uses SIGUSR1. Qt does not use SIGUSR1. OCCT does not use POSIX signals.
