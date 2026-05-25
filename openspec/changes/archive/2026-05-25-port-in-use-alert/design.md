## Context

ClotCAD's `bootstrap` function starts Slynk (port 4005), Alive LSP (port 4006), then the viewer. Both servers spawn threads for the actual socket binding — Slynk via `sb-thread:make-thread` in `start-slynk`, Alive LSP via `bt:make-thread` inside `alive/server:start-server`. This means the `handler-case` wrappers in both `start-slynk` and `start-alive` do NOT catch port-in-use errors: the error happens in a different thread, which crashes the thread and — in `--disable-debugger` mode — aborts the entire process. Terminal warnings are also invisible when launched via `--viewer` mode (desktop shortcut).

## Goals / Non-Goals

**Goals:**
- Show a Qt warning dialog when Slynk fails because port 4005 is in use
- Show a Qt warning dialog when Alive LSP fails because port 4006 is in use
- Dialog must appear after the viewer window exists but before the event loop blocks
- User dismisses the dialog and continues using the viewer normally (no REPL server)
- All existing behavior preserved when ports are free

**Non-Goals:**
- No dialog for success cases (no "server started" notifications)
- No changes to Slynk, Alive LSP, or other dependencies
- No changes to terminal logging behavior (keep warnings)
- No retry/reconnect mechanism
- No changes to CLI/non-viewer modes

## Decisions

1. **Deferred dialog display via `*pending-port-errors*`**: Port errors happen before the viewer exists (see thread model below). Rather than splitting `start-viewer`, store error messages in a global list during `start-slynk`/`start-alive`, then display a single combined dialog in `initialize-viewer` (called after `%viewer-show`). All messages are collected and shown together to avoid spamming the user with multiple dialogs. This is minimal, keeps `bootstrap` order unchanged, and reuses the existing initialization hook.

2. **C++ `viewer_show_message` function**: A new CFFI-callable function in `occt_viewer.cpp` that calls `QMessageBox::warning(parent, title, text)`. Follows the existing pattern of all other `viewer_*` C API functions. The function grabs `QMessageBox::warning` which is safe on the Qt main thread (where `initialize-viewer` runs).

3. **Pre-check both ports before spawning threads**: Both Slynk and Alive LSP bind sockets in separate threads, so their `handler-case` wrappers never catch port-in-use errors. Solution for both: probe the port synchronously before spawning the thread.

    - **Slynk**: Use `sb-bsd-sockets:inet-socket` directly (always available in SBCL). Create a socket, set `reuse-address`, attempt `socket-bind`. If `address-in-use-error` is signalled, record the error in `*pending-port-errors*` and return nil — the Slynk thread is never spawned.
    - **Alive LSP**: Use `usocket:socket-listen` (available when Alive LSP is loaded). If `address-in-use-error` is signalled, record the error and return nil — the `start-server` thread is never spawned.

4. **Spawned thread body wrapped in error handler**: As a safety net against the race where a port becomes occupied between the pre-check and the actual bind inside the spawned thread, wrap the thread body in a `handler-case` that silently catches socket errors and terminates the thread normally (instead of crashing the process). This applies to the Slynk thread (which we control). Alive LSP's thread body is in upstream code and unchanged — the pre-check is sufficient since the race is negligible and the consequence is the same as current behavior.

5. **Separate error detection by error type**: Detect `sb-bsd-sockets:address-in-use-error` / `usocket:address-in-use-error` specifically (port-conflict case). Catch all other errors generically (only terminal warning, no dialog). This avoids showing misleading dialogs for non-port errors (e.g., missing dependencies).

## Risks / Trade-offs

*Race on Alive LSP pre-check*: Port could become free after the probe but before `socket-listen` in the thread runs. Mitigation: the thread succeeds normally — no harm. Port becomes busy after probe but before bind: thread crashes silently (current behavior). Acceptable.
*Race on Slynk pre-check*: Same race. Thread body has a `handler-case` safety net so the thread won't crash the process even if the port becomes occupied between probe and bind.
*Dialog blocks initialization*: `QMessageBox::warning` is modal — it blocks until the user clicks OK. Since we show it after the window is visible and before the event loop, the user sees the window + dialog, clicks OK, and the app continues normally.
*No viewer_show_message call if viewer fails to create*: If `%viewer-create` returns nil, the viewer never starts and there's no window to attach a dialog to. In this case, port errors can't be shown as dialogs — they're already in the terminal output. Acceptable.
