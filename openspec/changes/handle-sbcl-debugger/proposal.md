## Why

When sending a form via Slynk (port 4005) or Alive LSP (port 4006) that triggers an unhandled condition — or when an error escapes a Qt callback — SBCL enters its interactive debugger on the offending thread. If the debugger is entered on the Qt main thread, the entire viewer freezes. The CLI tool `slyc` cannot interact with the debugger, so the user has no way to invoke restarts or resume normal operation without killing and restarting the process.

## What Changes

- Install a **global `sb-ext:*invoke-debugger-hook*`** early in `bootstrap` that catches all unhandled conditions, logs them to `*repl-log*`, formats condition + restarts as an error message, and exits cleanly without invoking any external restart (CFFI/Qt ABORT restarts cause crashes when invoked from the hook). This prevents the SBCL debugger from blocking any thread **without risking a crash**.
- Provide **user awareness of silent invocations**: a `*debugger-invocation-count*` counter and a `,errors` REPL command to view recent caught errors. Note: the hook only catches errors on non-Slynk threads (render loop, Qt callbacks). Errors during SLY eval are handled by Slynk's own debugger and never reach the hook.
- Provide an **emergency debugger escape from the GUI REPL**: a special REPL command (e.g., `,abort`) that allows the user to invoke restarts or abort back to the top level if the debugger is somehow entered.
- Provide a **slyc-based escape mechanism**: a script or form that `slyc` can evaluate to abort from any active debugger on any thread.
- Preserve Alive LSP's per-thread debugger hook for LSP client integration (conditions should still be reported to the LSP client for stack trace display), but ensure it layers on top of or cooperates with the global hook.
- Add tests for each new capability.

## Capabilities

### New Capabilities
- `global-debugger-handler`: Install a global `sb-ext:*invoke-debugger-hook*` at viewer startup that catches all unhandled conditions, logs them to `*repl-log*`, tracks invocation count, and exits cleanly without invoking external restarts — preventing SBCL's interactive debugger from blocking any thread without risking CFFI/Qt restart crashes.
- `debugger-ui-escape`: GUI-side mechanism via the Qt REPL with `,abort` (escape stuck threads), `,debug` (show debugger status), `,errors [N]` (view recent caught errors), and `,help` (list commands).
- `slyc-debugger-escape`: A CLI-invokable form (via `slyc --eval`) that can abort from any active debugger on any thread, to unstick the process remotely.

### Modified Capabilities
- *None* — no existing capabilites have requirement changes.

## Impact

- **`src/viewer/lifecycle.lisp`**: Install the global debugger hook in `bootstrap`. Coordinated with Alive LSP's per-thread hook to avoid conflicts.
- **`src/viewer/repl.lisp`**: Add `,abort` and potentially other debugger-related REPL commands. Update `eval-string` to dispatch on special commands.
- **`src/viewer/ui.lisp`**: Potentially add UI state tracking for when the debugger is active.
- **`scripts/slyc-debugger-escape.lisp`**: New script file containing the escape form.
- **Dependencies**: None new — only SBCL's `sb-ext` and `sb-debug` packages.
- **Tests**: Add tests for the global hook, UI escape command, and CLI escape form.
